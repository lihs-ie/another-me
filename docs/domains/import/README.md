# import パッケージ モデル（公式カタログダウンロード）

アプリ提供者が用意した公式 lo-fi 楽曲カタログから、ユーザーが選択した曲をダウンロードしてローカルに展開する役割を担う。URL やライセンス情報はすべて事前に定義され、ユーザー入力は不要である。

## モデル方針

- 公式カタログは library パッケージの AssetCatalog に収録され、各曲に `CatalogTrackMetadata` と `CatalogLicenseMetadata` が紐付いている。
- `CatalogDownloadJob` 集約がダウンロード進行を管理し、失敗時の再試行や整合性チェックを実施する。
- ダウンロード完了後は catalog メタから `Track` と `LicenseRecord` を自動生成し、ライセンステキストも `licenseFilePath` に配置する。
- 以降の管理（Playlist 追加など）は media / licensing パッケージが担当する。
- ダウンロード前に StorageQuotaService で容量チェックを行い、上限（例：1GB）を超えないことを保証する。容量不足の場合はジョブを Failed 状態にし、FailureCode.storageQuotaExceeded を記録する。
- ライセンスファイルは `licenses/<trackIdentifier>_LICENSE.txt` へ自動配置し、licenseFilePath として管理する。配置は Verified 状態到達後、Registering フェーズで実行する。
- 素材キャッシュの消去機能（clearCache）を提供し、アプリケーション層から明示的に実行する。再ダウンロード時は既存ファイルを上書きし、カタログメタに基づき整合性チェック（チェックサム検証）を行う。
- 検証フェーズでは expectedChecksum と actualChecksum を集約内で保持し、不変条件として「不一致の場合は Failed へ遷移」を保証する。検証は Verifying → Verified の 2 段階で実行し、Verified 到達後に登録フェーズへ移行する。
- ダウンロードジョブは最大 3 回まで自動再試行する。再試行可能な失敗（NetworkError, ChecksumMismatch）の場合のみ retryCount を増やし Pending に戻す。再試行不可能な失敗（StorageQuotaExceeded 等）または再試行上限到達時は Failed 状態で終了する。
- 状態遷移は以下の順序で実行される：`Pending → Downloading → Verifying → Verified → Registering → Completed`。各フェーズの責務を明確に分離し、前提条件チェックで不正な遷移を防ぐ。
- trackMetadata/licenseMetadata はダウンロード開始時のスナップショットとして集約内に保持する。カタログ更新時は新しいジョブを作成する。
- FileDownloadService, StorageQuotaService, LicenseFileWriter はドメイン層のインターフェースとして定義し、実装はインフラ層で提供する。
- **Checksum および ChecksumCalculator** は複数パッケージで利用される汎用概念のため、`common/storage` パッケージに定義されている。import パッケージでは VerificationChecksums 値オブジェクト内で使用し、ダウンロードファイルの整合性検証に利用する。

## CatalogDownloadJob 集約

### CatalogDownloadJobIdentifier （カタログダウンロードジョブ識別子／値オブジェクト）

- 目的：カタログダウンロードジョブを一意に識別し、システム内で追跡可能にする。
- フィールド：
  - `value`: `String` - ULID 文字列（26 文字）
- 不変条件：
  - `value` は ULID フォーマット（`[0-7][0-9A-HJKMNP-TV-Z]{25}`）に一致する
- 振る舞い：
  - **新規生成できる(generate)**
    - 入力：なし
    - 出力：`CatalogDownloadJobIdentifier`
    - 副作用：なし

### CatalogTrackIdentifier （カタログトラック識別子／値オブジェクト）

- 目的：公式カタログ内の楽曲エントリを一意に識別し、ダウンロード対象を明確にする。
- フィールド：
  - `value`: `String` - ULID 文字列（26 文字）
- 不変条件：
  - `value` は ULID フォーマットに一致する
- 振る舞い：
  - **新規生成できる(generate)**
    - 入力：なし
    - 出力：`CatalogTrackIdentifier`
    - 副作用：なし

### CatalogDownloadJob （カタログダウンロードジョブ／集約）

- 目的：公式カタログからの楽曲およびライセンスのダウンロード処理を管理し、進行状況を追跡し、失敗時の再試行や整合性検証を実施する。
- フィールド：
  - `identifier`: `CatalogDownloadJobIdentifier` - ジョブの識別子
  - `catalogTrack`: `CatalogTrackIdentifier` - ダウンロード対象のカタログトラック識別子
  - `status`: `DownloadStatus` - ダウンロードステータス（`Pending` / `Downloading` / `Verifying` / `Verified` / `Registering` / `Completed` / `Failed`）
  - `downloadUrl`: `SignedURL` - ダウンロード元の署名付き URL（一時アクセス権限付き）
  - `estimatedSizeBytes`: `int` - ダウンロード予定サイズ（バイト）
  - `timeline`: `Timeline` - 作成・更新時刻情報（`createdAt`, `updatedAt`）
  - `checksums`: `VerificationChecksums` - チェックサム検証情報（`expectedChecksum`, `actualChecksum`）
  - `retryState`: `RetryState` - 再試行状態（`failureReason`, `retryCount`）
  - `paths`: `DownloadAssetPaths` - ファイルパス情報（`targetPath`, `licenseFilePath`）
  - `metadata`: `DownloadJobMetadata` - ダウンロードジョブメタデータ（楽曲・ライセンス情報の最小限の集約）
- 不変条件：
  - `status` は定義順に遷移し、検証を飛ばして登録状態にならない（`Pending → Downloading → Verifying → Verified → Registering → Completed`）
  - `estimatedSizeBytes` は 1〜200MB（209,715,200 バイト）以内
  - `timeline` の不変条件（`createdAt <= updatedAt`）は `Timeline` 値オブジェクトが保証
  - `checksums` の不変条件（チェックサム一致検証）は `VerificationChecksums` 値オブジェクトが保証
  - `retryState` の不変条件（`retryCount` 範囲、失敗理由との整合性）は `RetryState` 値オブジェクトが保証
  - `paths` の不変条件（ライセンスファイルパス形式）は `DownloadAssetPaths` 値オブジェクトが保証
  - `metadata` の不変条件（楽曲・ライセンス情報の整合性）は `DownloadJobMetadata` 値オブジェクトが保証
  - `status` が `Completed` の場合、`paths.isComplete()` が真であること（両パスが設定済み）
- 振る舞い：

  - **ダウンロードを開始できる(startDownload)**

    - 入力：
    - `startedAt`: `DateTime` - 開始時刻
    - `expectedChecksum`: `Checksum` - ダウンロード前の期待チェックサム
    - 出力：なし
    - 副作用：
    - 前提条件：`status` が `Pending` であること
    - `checksums` を `checksums.withExpected(expectedChecksum)` で更新
    - `status` を `Downloading` に更新
    - `timeline` を `timeline.markUpdated(DateTime.now())` で更新
    - `CatalogDownloadStarted` イベントを発行
    - 前提条件違反時に `InvalidStatusTransitionError` 例外を投げる

  - **検証フェーズへ遷移できる(markVerifying)**
    - 入力：
    - `actualChecksum`: `Checksum` - ダウンロード後に計算された実際のチェックサム
    - 出力：なし
    - 副作用：
    - 前提条件：`status` が `Downloading` であること
    - 前提条件：`checksums.expected` が設定されていること
    - `checksums` を `checksums.withActual(actualChecksum)` で更新
    - チェックサム検証を実施（`checksums.verificationResult()` が `Mismatched` の場合は `markFailed` を呼び出して終了）
    - `status` を `Verifying` に更新
    - `timeline` を `timeline.markUpdated(DateTime.now())` で更新
    - `CatalogDownloadVerifying` イベントを発行
    - 前提条件違反時に `InvalidStatusTransitionError` または `StateError` 例外を投げる
  - **検証完了できる(markVerified)**
    - 入力：
    - `fileInfo`: `FileInfo` - ダウンロードファイルの情報
    - 出力：なし
    - 副作用：
    - 前提条件：`status` が `Verifying` であること
    - `status` を `Verified` に更新
    - `timeline` を `timeline.markUpdated(DateTime.now())` で更新
    - `CatalogDownloadVerified` イベントを発行
    - 前提条件違反時に `InvalidStatusTransitionError` 例外を投げる
  - **登録フェーズを開始できる(startRegistration)**
    - 入力：なし
    - 出力：なし
    - 副作用：
    - 前提条件：`status` が `Verified` であること
    - `status` を `Registering` に更新
    - `timeline` を `timeline.markUpdated(DateTime.now())` で更新
    - イベントは発行しない（内部状態のみ）
    - 前提条件違反時に `InvalidStatusTransitionError` 例外を投げる
  - **資産登録を完了できる(completeRegistration)**
    - 入力：
    - `licenseFilePath`: `FilePath` - ライセンステキストの保存先パス
    - 出力：なし
    - 副作用：
    - 前提条件：`status` が `Registering` であること
    - `paths` を `paths.withLicense(licenseFilePath)` で更新
    - `paths.requireLicense()` でライセンスパスが設定されていることを強制（不変条件チェック）
    - `status` を `Completed` に更新
    - `timeline` を `timeline.markUpdated(DateTime.now())` で更新
    - `CatalogDownloadCompleted` イベントを発行
    - 前提条件違反時に `InvalidStatusTransitionError` または `InvariantViolationError` 例外を投げる
  - **失敗状態へ遷移できる(markFailed)**
    - 入力：
    - `reason`: `FailureReason` - 失敗理由
    - 出力：なし
    - 副作用：
    - `retryState` を `retryState.recordFailure(reason)` で更新
    - `retryState.shouldAutoRetry()` が真の場合：
      - `status` を `Pending` に更新（自動再試行）
      - `CatalogDownloadFailed` イベントを発行（`willRetry: true`）
    - それ以外の場合：
      - `status` を `Failed` に更新
      - `CatalogDownloadFailed` イベントを発行（`retriesExhausted: retryState.isRetryExhausted`, `willRetry: false`）
    - `timeline` を `timeline.markUpdated(DateTime.now())` で更新
  - **キャッシュをクリアできる(clearCache)**
    - 入力：なし
    - 出力：なし
    - 副作用：
    - 前提条件：`status` が `Downloading`, `Verifying`, `Registering` のいずれでもないこと
    - `status` を `Pending` に更新
    - `checksums` を初期状態にリセット
    - `retryState` を `RetryState.initial()` でリセット
    - `paths` のライセンスパスをクリア（`target` は保持）
    - `timeline` を `timeline.markUpdated(DateTime.now())` で更新
    - `CatalogCacheCleared` イベントを発行
    - 前提条件違反時に `StateError` 例外を投げる
    - 注記：`paths.target` は保持される（再ダウンロード時に上書き）
  - **再ダウンロードを要求できる(requestRedownload)**
    - 入力：なし
    - 出力：なし
    - 副作用：
    - 前提条件：`status` が `Completed` または `Failed` であること
    - `clearCache()` を呼び出してキャッシュをクリア
    - `CatalogRedownloadRequested` イベントを発行
    - 前提条件違反時に `StateError` 例外を投げる

### VerificationChecksums （検証チェックサム／値オブジェクト）

- 目的：ダウンロードファイルの整合性検証に必要なチェックサムペアを管理し、検証ロジックをカプセル化する。
- フィールド：
  - `expected`: `Checksum` - ダウンロード前の期待チェックサム
  - `actual`: `Checksum?` - ダウンロード後に計算された実際のチェックサム
- 不変条件：
  - `expected` は必須
  - `actual` が設定されている場合、`expected` も必ず設定されている
- 振る舞い：
  - **期待チェックサムを設定できる(withExpected)**
    - 入力：
      - `expected`: `Checksum` - 期待チェックサム
    - 出力：`VerificationChecksums` - 新しいインスタンス
    - 副作用：なし
  - **実際のチェックサムを設定できる(withActual)**
    - 入力：
      - `actual`: `Checksum` - 実際のチェックサム
    - 出力：`VerificationChecksums` - 新しいインスタンス
    - 副作用：なし
  - **検証済みか判定できる(isVerified)**
    - 入力：なし
    - 出力：`bool` - `actual` が設定されているかどうか
    - 副作用：なし
  - **検証結果を取得できる(verificationResult)**
    - 入力：なし
    - 出力：`VerificationResult` - 検証結果（`Pending` / `Matched` / `Mismatched`）
    - 副作用：なし
  - **一致を強制できる(requireMatched)**
    - 入力：なし
    - 出力：なし
    - 副作用：
      - 検証結果が `Mismatched` の場合、`ChecksumMismatchError` 例外を投げる
      - 検証結果が `Pending` の場合、`StateError` 例外を投げる

### VerificationResult （検証結果／列挙型）

- 目的：チェックサム検証の結果を表現する列挙型。
- 列挙値：
  - `Pending` - 検証未実施（`actual` が未設定）
  - `Matched` - チェックサム一致
  - `Mismatched` - チェックサム不一致

### RetryState （再試行状態／値オブジェクト）

- 目的：ダウンロードジョブの失敗と再試行の状態を管理し、再試行可能性の判定ロジックをカプセル化する。
- フィールド：
  - `failureReason`: `FailureReason?` - 失敗理由
  - `retryCount`: `int` - 再試行回数
- 不変条件：
  - `retryCount >= 0 && retryCount <= 3`
  - `retryCount > 0` の場合、`failureReason` が必ず設定されている
  - `failureReason` が null の場合、`retryCount == 0`
- 振る舞い：
  - **初期状態を生成できる(initial)**
    - 入力：なし
    - 出力：`RetryState` - 初期状態（`failureReason`: null, `retryCount`: 0）
    - 副作用：なし
  - **失敗を記録できる(recordFailure)**
    - 入力：
      - `reason`: `FailureReason` - 失敗理由
    - 出力：`RetryState` - 失敗を記録し、`retryCount` を増やした新しいインスタンス
    - 副作用：なし
  - **リセットできる(reset)**
    - 入力：なし
    - 出力：`RetryState` - 失敗情報をクリアした初期状態
    - 副作用：なし
  - **再試行可能か判定できる(canRetry)**
    - 入力：なし
    - 出力：`bool` - 再試行可能かどうか（`retryCount < 3` かつ `failureReason.isRetryable`）
    - 副作用：なし
  - **再試行上限に達したか判定できる(isRetryExhausted)**
    - 入力：なし
    - 出力：`bool` - 再試行上限に達したかどうか（`retryCount >= 3`）
    - 副作用：なし

### DownloadAssetPaths （ダウンロード資産パス／値オブジェクト）

- 目的：ダウンロードされた資産ファイル（音源とライセンス）のファイルパスを管理し、パス生成規約を保証する。
- フィールド：
  - `target`: `FilePath` - ダウンロード先のファイルパス（音源ファイル）
  - `license`: `FilePath?` - ライセンステキストの保存先パス
- 不変条件：
  - `target` は必須
  - `license` が設定されている場合、パスが `licenses/<trackIdentifier>_LICENSE.txt` の形式に従う
- 振る舞い：
  - **音源パスを設定できる(withTarget)**
    - 入力：
      - `target`: `FilePath` - 音源ファイルパス
    - 出力：`DownloadAssetPaths` - 新しいインスタンス
    - 副作用：なし
  - **ライセンスパスを設定できる(withLicense)**
    - 入力：
      - `license`: `FilePath` - ライセンスファイルパス
    - 出力：`DownloadAssetPaths` - 新しいインスタンス
    - 副作用：なし
  - **ライセンスパスが設定されているか判定できる(hasLicense)**
    - 入力：なし
    - 出力：`bool`
    - 副作用：なし
  - **完全か判定できる(isComplete)**
    - 入力：なし
    - 出力：`bool` - `target` と `license` 両方が設定されているか
    - 副作用：なし
  - **ライセンスパスを強制できる(requireLicense)**
    - 入力：なし
    - 出力：なし
    - 副作用：
      - `license` が null の場合、`StateError` 例外を投げる
  - **ライセンスパスを生成できる(generateLicensePath)**（静的メソッド）
    - 入力：
      - `baseDirectory`: `String` - ベースディレクトリ
      - `track`: `CatalogTrackIdentifier` - トラック識別子
    - 出力：`FilePath` - 生成されたライセンスファイルパス（`<baseDirectory>/licenses/<trackIdentifier>_LICENSE.txt`）
    - 副作用：なし

### DownloadJobMetadata （ダウンロードジョブメタデータ／値オブジェクト）

- 目的：カタログから取得される楽曲とライセンスのメタデータを最小限の形でまとめて管理し、library パッケージへの依存を最小化する。
- フィールド：
  - `track`: `CatalogTrackIdentifier` - カタログトラック識別子
  - `title`: `String` - 楽曲タイトル
  - `artist`: `String` - 提供者名
  - `durationMilliseconds`: `int` - 楽曲の長さ（ミリ秒）
  - `licenseName`: `String` - ライセンス名
  - `licenseUrl`: `URL` - ライセンスの URL（HTTPS）
  - `attributionText`: `String` - 帰属表示テキスト
- 不変条件：
  - `title` / `artist` は空文字不可、最大 100 文字以内
  - `durationMilliseconds` は 1,000〜3,600,000（1 秒〜60 分）
  - `licenseName` / `attributionText` は空文字不可
  - `licenseUrl` は URL 値オブジェクトとして検証される（HTTPS スキームを含む）
- 振る舞い：
  - **カタログメタデータから生成できる(fromCatalog)**
    - 入力：
      - `track`: `CatalogTrackMetadata` - 楽曲メタデータ
      - `license`: `CatalogLicenseMetadata` - ライセンスメタデータ
    - 出力：`DownloadJobMetadata` - 新しいインスタンス
    - 副作用：なし
  - **Track 登録用 DTO に変換できる(toTrackSeed)**
    - 入力：なし
    - 出力：`TrackRegistrationSeed` - Track 登録用 DTO
    - 副作用：なし
  - **LicenseRecord 登録用 DTO に変換できる(toLicenseSeed)**
    - 入力：なし
    - 出力：`LicenseRegistrationSeed` - LicenseRecord 登録用 DTO
    - 副作用：なし

### CatalogTrackMetadata （カタログ楽曲メタ／値オブジェクト）

- 目的：公式カタログが提供する楽曲メタデータと音源仕様を保持する値オブジェクト。Track 集約登録時の入力データとして使用され、楽曲の基本情報を提供する。

- フィールド：

  - `track`: `CatalogTrackIdentifier` - カタログトラックの識別子
  - `title`: `String` - 楽曲タイトル
  - `artist`: `String` - 提供者名
  - `durationMilliseconds`: `int` - 楽曲の長さ（ミリ秒）
  - `audioFormat`: `AudioFormat` - 音声フォーマット（`aac` / `m4a` / `mp3` / `wav`）
  - `loopPoint`: `LoopPoint` - ループポイント（`startMilliseconds`, `endMilliseconds`）

- 不変条件：

  - `title` / `artist` は空文字不可、最大 100 文字以内
  - `durationMilliseconds` は 1,000〜3,600,000（1 秒〜60 分）
  - `audioFormat` はサポート対象に含まれる
  - `loopPoint.startMilliseconds < loopPoint.endMilliseconds <= durationMilliseconds`

- 振る舞い：
  - **toTrackSeed（Track 生成用入力の構築）**
    - 入力：なし
    - 出力：Track 登録用 DTO（`track`, `title`, `artist`, `durationMilliseconds`, `audioFormat`, `loopPoint`）
    - 副作用：
    - なし
    - 検証失敗時に例外を投げる

### CatalogLicenseMetadata （カタログライセンスメタ／値オブジェクト）

- 目的：楽曲に紐付くライセンス情報を保持する値オブジェクト。許諾条件、帰属文、ファイルチェックサムを管理し、LicenseRecord 登録時の入力データを提供する。

- フィールド：

  - `licenseName`: `String` - ライセンス名
  - `licenseURL`: `URL` - ライセンスの URL（HTTPS）
  - `attributionText`: `String` - 帰属表示テキスト
  - `allowOffline`: `bool` - オフライン使用許可フラグ
  - `redistributionAllowed`: `bool` - 再配布許可フラグ
  - `licenseFileChecksum`: `Checksum` - ライセンスファイルのチェックサム

- 不変条件：

  - `licenseName` / `attributionText` は空文字不可
  - `licenseURL` は URL 値オブジェクトとして検証される（HTTPS スキームを含む）
  - `licenseFileChecksum` は提供側が提示した値と一致する

- 振る舞い：
  - **toLicenseSeed（LicenseRecord 生成用入力の構築）**
    - 入力：なし
    - 出力：ライセンス登録 DTO（`licenseName`, `licenseUrl`, `attributionText`, `allowOffline`, `redistributionAllowed`, `licenseFileChecksum`）
    - 副作用：
    - なし
    - 検証失敗時に例外を投げる

### FileInfo （取得ファイル情報／値オブジェクト）

- 目的：ダウンロード済みファイルのメタ情報を保持する値オブジェクト。ファイルの整合性検証に必要な情報を管理し、検証処理を提供する。

- フィールド：

  - `path`: `FilePath` - ファイルパス
  - `checksum`: `Checksum` - ファイルのチェックサム
  - `sizeBytes`: `int` - ファイルサイズ（バイト）

- 不変条件：

  - `sizeBytes` は 1〜200MB（209,715,200 バイト）以内
  - `path` は OS ごとのパス制約に準拠
  - `checksum` は実ファイルと一致する

- 振る舞い：
  - **verify（整合性検証）**
    - 入力：
      - `calculator`: `ChecksumCalculator` - チェックサム計算サービス
    - 出力：`bool` - 検証結果（真偽値）
    - 副作用：
      - 計算サービスでファイルをハッシュ化
      - `checksum` と一致しない場合に例外を投げる

### FailureReason （失敗理由／値オブジェクト）

- 目的：CatalogDownloadJob の失敗理由を表現する値オブジェクト。失敗の原因を分類し、詳細なメッセージと共に保持する。

- フィールド：

  - `code`: `FailureCode` - 失敗理由コード（`NetworkError` / `ChecksumMismatch` / `StorageFull` / `StorageQuotaExceeded` / `Unknown` 等）
  - `message`: `String?` - 詳細説明（任意）

- 不変条件：

  - `code` は定義済み列挙に含まれる
  - `message` は 1〜500 文字

- 振る舞い：
  - **再試行可能か判定できる(isRetryable)**
    - 入力：なし
    - 出力：`bool` - `code.isRetryable` を返す
    - 副作用：なし

### FailureCode （失敗理由コード／列挙型）

- 目的：ダウンロードジョブの失敗原因を分類する列挙型。失敗理由を標準化し、再試行可能性の判定に使用される。

**列挙値**

- `NetworkError` - ネットワークエラー（再試行可能）
- `ChecksumMismatch` - チェックサム不一致（再試行可能）
- `StorageFull` - ストレージ満杯（再試行不可）
- `StorageQuotaExceeded` - 容量上限超過（再試行不可）
- `Unknown` - 不明なエラー（再試行不可）

**振る舞い**

- **再試行可能か判定できる(isRetryable)**
  - 入力：なし
  - 出力：`bool` - 再試行可能な失敗コードの場合は `true`、それ以外は `false`
  - 副作用：なし
  - 注記：`NetworkError` と `ChecksumMismatch` のみ再試行可能

### CatalogFileLayout （カタログファイル配置規約／値オブジェクト）

- 目的：カタログファイルの配置規約を表現する値オブジェクト。トラックファイルとライセンスファイルのパス生成ルールを統一する。

- フィールド：

  - `baseDirectory`: `String` - ベースディレクトリパス

- 振る舞い：

  - **getTrackPath（トラックファイルパスの生成）**
    - 入力：
      - `track`: `CatalogTrackIdentifier` - トラック識別子
    - 出力：`FilePath` - トラックファイルのパス（`<baseDirectory>/tracks/<trackIdentifier>.m4a`）
    - 副作用：なし

- **getLicensePath（ライセンスファイルパスの生成）**
  - 入力：
    - `track`: `CatalogTrackIdentifier` - トラック識別子
  - 出力：`FilePath` - ライセンスファイルのパス（`<baseDirectory>/licenses/<trackIdentifier>_LICENSE.txt`）
  - 副作用：なし

#### ドメインイベント

### CatalogDownloadStarted（カタログダウンロード開始）

- 目的：ダウンロードジョブが開始されたことを通知するイベント。ダウンロード処理の開始をサブスクライバに通知する。

- フィールド：
  - `job`: `CatalogDownloadJobIdentifier` - ジョブ識別子
  - `catalogTrack`: `CatalogTrackIdentifier` - カタログトラック識別子
  - `downloadUrl`: `SignedURL` - ダウンロード URL（署名付き）
  - `expectedChecksum`: `Checksum` - ダウンロード前の期待チェックサム

---

### CatalogDownloadVerifying（カタログダウンロード検証中）

- 目的：ダウンロード済みファイルの整合性検証フェーズに入ったことを通知するイベント。検証処理の開始をサブスクライバに通知する。

- フィールド：
  - `job`: `CatalogDownloadJobIdentifier` - ジョブ識別子
  - `checksum`: `Checksum` - ファイルチェックサム

---

### CatalogDownloadVerified（カタログダウンロード検証完了）

- 目的：ダウンロードファイルの検証が完了したことを通知するイベント。検証成功を確定し、登録フェーズへの移行をトリガーする。

- フィールド：
  - `job`: `CatalogDownloadJobIdentifier` - ジョブ識別子
  - `checksum`: `Checksum` - 検証済みチェックサム
  - `fileInfo`: `FileInfo` - ダウンロードファイルの情報（サイズ、タイムスタンプ等）

---

### CatalogDownloadCompleted（カタログダウンロード完了）

- 目的：ダウンロードと検証が成功し、登録処理が完了したことを通知するイベント。ダウンロード完了を通知し、後続の登録処理をトリガーする。

- フィールド：
  - `job`: `CatalogDownloadJobIdentifier` - ジョブ識別子
  - `trackMetadata`: `CatalogTrackMetadata` - トラックメタデータ
  - `licenseMetadata`: `CatalogLicenseMetadata` - ライセンスメタデータ
  - `targetPath`: `FilePath` - 保存先パス
  - `licenseFilePath`: `FilePath` - ライセンスファイルの保存先パス

---

### CatalogDownloadFailed（カタログダウンロード失敗）

- 目的：ダウンロードまたは検証が失敗したことを通知するイベント。失敗の発生と原因をサブスクライバに通知する。

- フィールド：
  - `job`: `CatalogDownloadJobIdentifier` - ジョブ識別子
  - `reason`: `FailureReason` - 失敗理由
  - `retriesExhausted`: `bool` - 再試行上限に達したかどうか
  - `willRetry`: `bool` - 自動再試行が予定されているかどうか

---

### CatalogCacheCleared（カタログキャッシュクリア）

- 目的：ダウンロード済みファイルのキャッシュがクリアされたことを通知するイベント。キャッシュクリア操作の完了を通知し、ファイル削除処理をトリガーする。

- フィールド：
  - `job`: `CatalogDownloadJobIdentifier` - ジョブ識別子
  - `catalogTrack`: `CatalogTrackIdentifier` - カタログトラック識別子
  - `targetPath`: `FilePath` - クリア対象のファイルパス

---

### CatalogRedownloadRequested（カタログ再ダウンロード要求）

- 目的：ダウンロード済みファイルの再ダウンロードが要求されたことを通知するイベント。再ダウンロード要求を通知し、ダウンロードジョブを再スケジュールする。

- フィールド：
  - `job`: `CatalogDownloadJobIdentifier` - ジョブ識別子
  - `catalogTrack`: `CatalogTrackIdentifier` - カタログトラック識別子

#### リポジトリ契約

### CatalogDownloadJobRepository（カタログダウンロードジョブリポジトリ）

- 目的：CatalogDownloadJob 集約の永続化と取得を担うリポジトリ。ダウンロードジョブのライフサイクル管理に必要な永続化操作を提供する。

- 振る舞い：

  - **find（識別子による一見取得）**

    - 入力：
      - `identifier`: `CatalogDownloadJobIdentifier` - ジョブ識別子
    - 出力：`CatalogDownloadJob` - ダウンロードジョブ
    - 副作用：
      - 該当ジョブが存在しない場合、`AggregateNotFoundError` 例外を投げる

  - **findOrNull（識別子による取得（nullable））**

    - 入力：
      - `identifier`: `CatalogDownloadJobIdentifier` - ジョブ識別子
    - 出力：`CatalogDownloadJob?` - ダウンロードジョブまたは null
    - 副作用：なし

  - **persist（永続化）**

    - 入力：
      - `job`: `CatalogDownloadJob` - 永続化するジョブ
    - 出力：なし
    - 副作用：
      - データストアにジョブを保存または更新

  - **findByStatus（ステータスによる取得）**

    - 入力：
      - `status`: `DownloadStatus` - ダウンロードステータス
      - `limit`: `int?` - 取得件数上限（任意）
    - 出力：`List<CatalogDownloadJob>` - ジョブリスト（`createdAt` 昇順でソート）
    - 副作用：なし

  - **findPending（保留中ジョブの取得）**

    - 入力：
      - `limit`: `int?` - 取得件数上限（任意、デフォルト: 10）
    - 出力：`List<CatalogDownloadJob>` - 保留中のジョブリスト（`createdAt` 昇順でソート）
    - 副作用：なし

  - **findRetryable（再試行可能ジョブの取得）**
    - 入力：
      - `limit`: `int?` - 取得件数上限（任意）
    - 出力：`List<CatalogDownloadJob>` - 再試行可能なジョブリスト
    - 副作用：なし
  - 注記：`retryCount < 3` かつ `status == Pending` のジョブを取得

  - **findByCatalogTrack（カタログトラックによる取得）**
    - 入力：
      - `track`: `CatalogTrackIdentifier` - カタログトラック識別子
    - 出力：`CatalogDownloadJob?` - ジョブまたは null
    - 副作用：なし
  - 注記：同一トラックの重複ダウンロードを防ぐために使用

  - **terminate（削除）**
    - 入力：
      - `identifier`: `CatalogDownloadJobIdentifier` - ジョブ識別子
    - 出力：なし
    - 副作用：
      - データストアからジョブを削除
      - 該当ジョブが存在しない場合、例外を投げる

## イベントサブスクライバ

### CatalogDownloadExecutor（カタログダウンロード実行者）

- 目的：ダウンロード処理を実行するサブスクライバ。HTTP 経由でファイルをダウンロードし、検証フェーズへ遷移させる。

**購読イベント**

- `CatalogDownloadStarted`（import）

**処理内容**

1. `CatalogDownloadJobRepository` からジョブを取得
2. `StorageQuotaService.reserveSpace` で容量を予約
   - 容量不足時は `StorageQuotaExceededError` を捕捉し、`markFailed` を呼び出す
3. `FileDownloadService.download` でファイルをダウンロード
4. `FileDownloadService.calculateChecksum` でチェックサムを計算
5. ダウンロード成功時：`CatalogDownloadJob.markVerifying(actualChecksum)` を呼び出す
   - チェックサム一致時：`CatalogDownloadVerifying` イベントを発火
   - チェックサム不一致時：自動的に `markFailed` が呼ばれ `CatalogDownloadFailed` イベントを発火
6. ダウンロード失敗時：`CatalogDownloadJob.markFailed(reason)` を呼び出し、`CatalogDownloadFailed` イベントを発火
7. `StorageQuotaService.releaseSpace` で容量予約を解放（失敗時のみ）
8. リポジトリで永続化

**発火イベント**

- `CatalogDownloadVerifying`（import）
- `CatalogDownloadFailed`（import）

**依存ドメインサービス**

- `StorageQuotaService`
- `FileDownloadService`

---

### CatalogVerificationSubscriber（カタログ検証サブスクライバ）

- 目的：ダウンロード完了後にファイル整合性を検証するサブスクライバ。追加の整合性検証を実施し、検証完了を確定する。

**購読イベント**

- `CatalogDownloadVerifying`（import）

**処理内容**

1. `CatalogDownloadJobRepository` からジョブを取得
2. チェックサム検証は既に `markVerifying` 内で完了しているため、追加検証を実施
   - ファイルサイズの検証
   - ファイルフォーマットの検証
   - その他の整合性チェック
3. 検証成功時：`CatalogDownloadJob.markVerified(fileInfo)` を呼び出し、`CatalogDownloadVerified` イベントを発火
4. 検証失敗時：`CatalogDownloadJob.markFailed(reason)` を呼び出し、`CatalogDownloadFailed` イベントを発火
5. リポジトリで永続化

**発火イベント**

- `CatalogDownloadVerified`（import）
- `CatalogDownloadFailed`（import）

---

### LicenseRegistrationSubscriber（ライセンス登録サブスクライバ）

- 目的：検証済みファイルのライセンステキストを規定の場所に配置するサブスクライバ。ライセンスファイルを自動配置し、登録フェーズへ移行する。

**購読イベント**

- `CatalogDownloadVerified`（import）

**処理内容**

1. `CatalogDownloadJobRepository` からジョブを取得
2. `CatalogDownloadJob.startRegistration()` を呼び出し、`Registering` 状態に遷移
3. `LicenseFileWriter.write` でライセンステキストを書き込む
   - パス：`licenses/<trackIdentifier>_LICENSE.txt`
4. `CatalogDownloadJob.completeRegistration(licenseFilePath)` を呼び出し、`CatalogDownloadCompleted` イベントを発火
5. リポジトリで永続化

**発火イベント**

- `CatalogDownloadCompleted`（import）

**依存ドメインサービス**

- `LicenseFileWriter`

---

### TrackRegistrationSubscriber（トラック登録サブスクライバ）

- 目的：検証済みバンドルから Track/Licensing を登録するサブスクライバ。ダウンロード完了後、media および licensing ドメインへ登録処理を委譲する。

**購読イベント**

- `CatalogDownloadCompleted`（import）

**処理内容**

1. ダウンロード完了イベントを受信（`licenseFilePath` を含む）
2. media の `Track.registerFromCatalog` を呼び出し、`TrackRegistered` イベントを発火
3. licensing の `LicenseRecord.registerFromCatalog` を呼び出し（`licenseFilePath` を渡す）、`LicenseRecordRegistered` イベントを発火
4. 登録後に下流へ通知

**発火イベント**

- `TrackRegistered`（media）
- `LicenseRecordRegistered`（licensing）

## ドメインサービス

### FileDownloadService （ファイルダウンロードサービス／ドメインサービス契約）

- 目的：ファイルのダウンロードとチェックサム計算を実行する。
- 責務：HTTP 通信の詳細を隠蔽し、ドメイン層がファイルダウンロード操作を実行できるようにする。
- 振る舞い：
  - **ファイルをダウンロードできる(download)**
    - 入力：
    - `url`: `SignedURL` - ダウンロード元 URL（署名付き）
    - `destination`: `FilePath` - 保存先パス
    - 出力：`Future<FileInfo>` - ダウンロードしたファイルの情報
    - 副作用：
    - ネットワーク通信を実行
    - ファイルシステムにファイルを書き込む
    - 失敗時に例外を投げる（インフラ層が実装する）
  - **チェックサムを計算できる(calculateChecksum)**
    - 入力：
    - `path`: `FilePath` - ファイルパス
    - 出力：`Future<Checksum>` - 計算されたチェックサム
    - 副作用：
    - ファイルを読み込む
    - 失敗時に例外を投げる（インフラ層が実装する）

---

### StorageQuotaService （ストレージ容量管理サービス／ドメインサービス契約）

- 目的：ストレージの容量制限と使用量を管理する。
- 責務：ダウンロード前に十分な容量があるかチェックし、容量上限（例：1GB）を超えないことを保証する。
- 振る舞い：
  - **使用量を取得できる(getCurrentUsage)**
    - 入力：なし
    - 出力：`int` - 使用中のバイト数
    - 副作用：なし（インフラ層が実装する）
  - **上限を取得できる(getQuotaLimit)**
    - 入力：なし
    - 出力：`int` - 上限バイト数（例：1GB = 1,073,741,824）
    - 副作用：なし（インフラ層が実装する）
  - **容量を予約できる(reserveSpace)**
    - 入力：
    - `job`: `CatalogDownloadJobIdentifier` - ジョブ識別子
    - `sizeBytes`: `int` - 予約するバイト数
    - 出力：なし
    - 副作用：
    - 容量が不足している場合に `StorageQuotaExceededError` 例外を投げる
    - 予約情報を記録（インフラ層が実装する）
  - **容量を解放できる(releaseSpace)**
    - 入力：
    - `job`: `CatalogDownloadJobIdentifier` - ジョブ識別子
    - 出力：なし
    - 副作用：予約情報を削除（インフラ層が実装する）

---

### LicenseFileWriter （ライセンスファイル書き込みサービス／ドメインサービス契約）

- 目的：ライセンステキストをファイルに書き込む。
- 責務：ライセンスファイルの配置規約（`licenses/<trackIdentifier>_LICENSE.txt`）を保証する。
- 振る舞い：
  - **ライセンステキストを書き込める(write)**
    - 入力：
    - `track`: `CatalogTrackIdentifier` - トラック識別子
    - `licenseText`: `String` - ライセンステキスト
    - 出力：`FilePath` - 書き込まれたファイルのパス（`licenses/<trackIdentifier>_LICENSE.txt`）
    - 副作用：
    - ファイルシステムにファイルを書き込む
    - ディレクトリが存在しない場合は作成
    - 失敗時に例外を投げる（インフラ層が実装する）
