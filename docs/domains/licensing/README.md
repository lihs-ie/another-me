# licensing パッケージ モデル

楽曲および素材のライセンス情報を管理し、再配布可否やクレジット生成を保証する。要件の「ライセンス/素材ポリシー」「ライセンス保存」を満たす。

## モデル方針
- 曲ごとの必須メタデータ（license_name, license_url, attribution_text, allow_offline, commercial_use_allowed, license_memo, credit_requirement）を `LicenseRecord` 集約で保持する。
- ライセンス情報は `LicensePolicy` 値オブジェクトにまとめ、不変条件を VO 内で保証する。
- 永続化フォーマットは `LicenseSnapshot` 値オブジェクトで定義し、JSON-ready な形式を保証する。
- import ドメインからは `LicenseRegistrationRequest` を通じて境界を越えた情報を渡し、licensing 側で変換する。
- クレジット生成ロジックは `AttributionBook` 集約が担当し、アプリ内表示に必要な文言を組み立てる。
- `AttributionBook` はライセンスが Active であることを検証し、失効時には該当エントリを無効化する。
- ライセンス失効・更新時は media パッケージへイベントを通知し、トラックを無効化させる。
- イベントサブスクライバが取り込みフローやユーザー通知を制御する。
- ライセンス確認 UI は閲覧のみで、すべての変更はドメイン経由で行われる。

## LicenseRecord 集約

#### LicenseIdentifier （ライセンス識別子／値オブジェクト）
- 目的：ライセンス記録を一意に識別する。
- フィールド：
  - `value`: ULID 文字列（26 文字）
- 不変条件：
  - `value` は ULID フォーマット（`[0-7][0-9A-HJKMNP-TV-Z]{25}`）に一致する。
- 振る舞い：
  - **新規生成できる(generate)**
    - 入力：なし
    - 出力：`LicenseIdentifier`
    - 副作用：なし

#### LicensePolicy （ライセンスポリシー／値オブジェクト）
- 目的：ライセンスの利用条件と制約を一括で保持し、不変条件を VO 内で保証する。
- フィールド：
  - `commercialUseAllowed`: 真偽値（商用利用可否）
  - `redistributionAllowed`: 真偽値（再配布可否）
  - `creditRequirement`: 文字列（クレジット条件、例: "Required", "Optional", "Not Required"）
  - `memo`: 文字列（任意、ライセンスメモ）
- 不変条件：
  - `creditRequirement` は 1 文字以上 100 文字以内
  - `memo` は設定される場合 1 文字以上 1000 文字以内
  - `commercialUseAllowed = false` かつ `redistributionAllowed = true` の組み合わせは禁止（再配布可能なのに商用不可は矛盾）
- 振る舞い：
  - **ポリシーを生成できる(create)**
    - 入力：`commercialUseAllowed`, `redistributionAllowed`, `creditRequirement`, `memo?`
    - 出力：`LicensePolicy`
    - 副作用：不変条件違反時は例外を発する

#### LicenseRegistrationRequest （ライセンス登録リクエスト／値オブジェクト）
- 目的：import ドメインから licensing ドメインへライセンス情報を境界を越えて渡す際の翻訳層。
- フィールド：
  - `trackTitle`: 文字列
  - `licenseName`: 文字列
  - `licenseURL`: `URL`（common/url パッケージ）
  - `attributionText`: 文字列
  - `licenseText`: 文字列（LICENSE ファイルの内容）
  - `policy`: `LicensePolicy`
  - `sourceURL`: `URL`（common/url パッケージ）
- 不変条件：
  - `trackTitle`, `licenseName`, `licenseURL`, `attributionText`, `licenseText`, `sourceURL` は必須
  - `licenseURL` および `sourceURL` は HTTP または HTTPS のみ許容（URL 型の不変条件により保証）
- 振る舞い：
  - **リクエストを生成できる(create)**
    - 入力：各フィールド
    - 出力：`LicenseRegistrationRequest`
    - 副作用：不変条件違反時は例外を発する

#### LicenseSnapshot （ライセンススナップショット／値オブジェクト）
- 目的：ライセンス記録を JSON-ready な形式で永続化するためのデータ構造。
- フィールド：
  - `identifier`: `LicenseIdentifier`
  - `track`: `TrackIdentifier`（media ドメインの Track 識別子）
  - `trackTitle`: 文字列
  - `licenseName`: 文字列
  - `licenseURL`: `URL`（common/url パッケージ）
  - `attributionText`: 文字列
  - `policy`: `LicensePolicy`
  - `sourceURL`: `URL`（common/url パッケージ）
  - `statusHistory`: `LicenseStatusEntry` のリスト
  - `licenseFilePath`: FilePath（任意）
  - `licenseFileChecksum`: `Checksum`（任意）
- 不変条件：
  - すべてのフィールドは `LicenseRecord` の不変条件を満たす
- 振る舞い：
  - **スナップショットを生成できる(fromRecord)**
    - 入力：`LicenseRecord`
    - 出力：`LicenseSnapshot`
    - 副作用：なし
  - **記録を復元できる(toRecord)**
    - 入力：なし
    - 出力：`LicenseRecord`
    - 副作用：なし
- 備考：
  - JSON シリアライゼーションはドメイン層の責務ではない
  - 永続化が必要な場合は、インフラストラクチャ層に `LicenseSnapshotMapper` を配置し、そこで JSON 変換を実装する

#### LicenseRecord （ライセンス記録／集約）
- 目的：楽曲のライセンス事実と証跡を保持し、更新・撤回を履歴化する。
- フィールド：
  - `identifier`: `LicenseIdentifier`
  - `track`: `TrackIdentifier`（media ドメインの Track 識別子）
  - `trackTitle`: 文字列
  - `licenseName`: 文字列
  - `licenseURL`: `URL`（common/url パッケージ）
  - `attributionText`: `AttributionText`
  - `policy`: `LicensePolicy`
  - `sourceURL`: `URL`（common/url パッケージ）
  - `statusHistory`: `LicenseStatusEntry` のリスト
  - `licenseFilePath`: FilePath（任意）
  - `licenseFileChecksum`: `Checksum`（任意）
- 不変条件：
  - `track`, `licenseName`, `licenseURL`, `attributionText`, `policy`, `sourceURL` は必須。
  - `statusHistory` は古い順 → 新しい順に並ぶ。
  - 最新ステータスが `Revoked` の場合、`policy.redistributionAllowed = false` かつ Track はオフライン再生不可。
  - `licenseFilePath` が設定されていれば実ファイルが存在し、`licenseFileChecksum` と一致する。
  - `statusHistory` の状態遷移は以下のみ許容：`Pending → Active`, `Active → Revoked`。
- 振る舞い：
  - **ライセンスを登録できる(register)**
    - 入力：`LicenseRegistrationRequest`, `TrackIdentifier`, `FilePath`, `Checksum`
    - 出力：`LicenseRecord`
    - 副作用：リクエストを検証し、LICENSE ファイルを指定パスに保存後、`LicenseRecordRegistered` を発火する。検証失敗時は例外を発する。
  - **ステータスを更新できる(updateStatus)**
    - 入力：`LicenseStatusEntry`
    - 出力：なし
    - 副作用：
      - 前提条件：現在のステータスから遷移可能であることを検証（`Pending → Active`, `Active → Revoked` のみ許容）
      - `statusHistory` を追記
      - ステータスが `Revoked` に変更された場合、`policy.redistributionAllowed` を `false` に自動設定
      - `LicenseRecordStatusChanged` を発火
  - **ポリシーを更新できる(updatePolicy)**
    - 入力：`LicensePolicy`
    - 出力：なし
    - 副作用：
      - 前提条件：現在のステータスが `Active` であることを検証
      - `policy` を更新
      - `LicensePolicyUpdated` を発火
  - **ライセンスを失効できる(revoke)**
    - 入力：理由（文字列）
    - 出力：なし
    - 副作用：
      - 前提条件：現在のステータスが `Active` であることを検証
      - 最新ステータスを `Revoked` へ追加
      - `policy.redistributionAllowed` を `false` に自動設定
      - `LicenseRecordRevoked` を発火
  - **スナップショットを取得できる(snapshot)**
    - 入力：なし
    - 出力：`LicenseSnapshot`
    - 副作用：なし

#### LicenseStatusEntry （ステータス履歴／値オブジェクト）
- フィールド：
  - `status`: 列挙（`Active` / `Revoked` / `Pending`）
  - `changedAt`: 日時
  - `reason`: 文字列
- 不変条件：履歴全体で昇順に並ぶ。

#### AttributionText （帰属文／値オブジェクト）
- 目的：ライセンスの帰属表示文を検証済みの形式で保持する。
- フィールド：
  - `text`: 文字列
- 不変条件：
  - `text` は 1 文字以上 500 文字以内
  - 空文字・null は許容しない
  - 改行は `\n` に正規化される
- 振る舞い：
  - **文字列を生成できる(create)**
    - 入力：`text`（文字列）
    - 出力：`AttributionText`
    - 副作用：不変条件違反時は例外を発する
  - **テキストを取得できる(value)**
    - 入力：なし
    - 出力：文字列
    - 副作用：なし

#### LicenseRecordSearchCriteria （ライセンス検索条件／値オブジェクト）
- 目的：リポジトリ検索時に必要な条件を型安全に表現する。
- フィールド：
  - `statuses`: `LicenseStatus` の集合（任意）
  - `allowOfflineOnly`: 真偽値（デフォルト `false`）
- 不変条件：
  - `statuses` を指定する場合は空集合不可
- 振る舞い：
  - **検索条件を生成できる(create)**
    - 入力：`statuses?`, `allowOfflineOnly?`
    - 出力：`LicenseRecordSearchCriteria`
    - 副作用：なし

#### ドメインイベント
- `LicenseRecordRegistered`
  - 役割：新しいライセンス記録が登録されたことを通知する。
  - フィールド：`identifier: LicenseIdentifier`, `track: TrackIdentifier`, `trackTitle: String`, `policy: LicensePolicy`
- `LicenseRecordStatusChanged`
  - 役割：ライセンス記録のステータスが変更されたことを通知する。
  - フィールド：`identifier: LicenseIdentifier`, `oldStatus: LicenseStatus`, `newStatus: LicenseStatus`, `changedAt: DateTime`
- `LicensePolicyUpdated`
  - 役割：ライセンスポリシーが更新されたことを通知する。
  - フィールド：`identifier: LicenseIdentifier`, `oldPolicy: LicensePolicy`, `newPolicy: LicensePolicy`
- `LicenseRecordRevoked`
  - 役割：ライセンスが失効したことを通知する。
  - フィールド：`identifier: LicenseIdentifier`, `track: TrackIdentifier`, `reason: String`

#### リポジトリ契約
- `LicenseRecordRepository`
  - `find(identifier: LicenseIdentifier): LicenseRecord`
    - 副作用：識別子に対応するライセンス記録が見つからない場合は`AggregateNotFoundError`を投げる
  - `persist(record: LicenseRecord): void`
  - `search(criteria: LicenseRecordSearchCriteria): List<LicenseRecord>`

## AttributionBook 集約

#### AttributionBookIdentifier （クレジット帳識別子／値オブジェクト）
- 目的：アトリビューション帳票を一意に識別する。
- フィールド：
  - `value`: ULID 文字列（26 文字）
- 不変条件：
  - `value` は ULID フォーマットに一致する。
- 振る舞い：
  - **新規生成できる(generate)**
    - 入力：なし
    - 出力：`AttributionBookIdentifier`
    - 副作用：なし

#### AttributionBook （クレジット帳／集約）
- 目的：素材と帰属文のペアを append-only で保管し、クレジット表示に利用する。
- フィールド：
  - `identifier`: `AttributionBookIdentifier`
  - `entries`: `AttributionEntry` のリスト
  - `publishedVersion`: 数値
- 不変条件：
  - `entries` はカテゴリ・素材名で整然と並ぶ。
  - `resource` の重複を禁止。
  - Append-only（削除・上書き不可）。
  - すべてのエントリが参照するライセンスは `Active` ステータスである。
- 振る舞い：
  - **エントリを追加できる(appendEntry)**
    - 入力：`AttributionEntry`, `LicenseRecordRepository`
    - 出力：なし
    - 副作用：
      - 前提条件：参照する `LicenseRecord` が存在し、ステータスが `Active` であることを検証
      - 重複検証に成功した場合のみ `entries` に追記
      - `AttributionEntryAppended` を発火
      - 検証失敗時は例外を発する
  - **ライセンス失効時にエントリを無効化できる(invalidateEntriesByLicense)**
    - 入力：`LicenseIdentifier`
    - 出力：なし
    - 副作用：
      - 該当ライセンスを参照するすべてのエントリを無効マークする（論理削除）
      - `AttributionEntriesInvalidated` を発火
  - **クレジット帳を公開できる(publish)**
    - 入力：バージョン番号（数値）
    - 出力：なし
    - 副作用：`publishedVersion` を更新し、`AttributionBookPublished` を発火する

#### AttributionResourceIdentifier （クレジット資源識別子／値オブジェクト）
- 目的：クレジット表示対象となる素材を一意に識別する。
- フィールド：
  - `value`: ULID 文字列（26 文字）
- 不変条件：
  - `value` は ULID フォーマットに一致する。
- 振る舞い：
  - **新規生成できる(generate)**
    - 入力：なし
    - 出力：`AttributionResourceIdentifier`
    - 副作用：なし

#### AttributionEntry （帰属エントリ／値オブジェクト）
- フィールド：
  - `resource`: `AttributionResourceIdentifier`
  - `displayName`: 文字列
  - `attributionText`: `AttributionText`
  - `license`: `LicenseIdentifier`
  - `isValid`: 真偽値（デフォルト `true`、ライセンス失効時に `false` になる）
- 不変条件：
  - 参照する `LicenseRecord` が存在する。
  - `isValid = true` の場合、参照するライセンスは `Active` ステータスである。

#### ドメインイベント
- `AttributionEntryAppended`
  - 役割：クレジット帳に新しいエントリが追加されたことを通知する。
  - フィールド：`resource: AttributionResourceIdentifier`, `license: LicenseIdentifier`
- `AttributionEntriesInvalidated`
  - 役割：ライセンス失効により、該当ライセンスを参照するエントリが無効化されたことを通知する。
  - フィールド：`license: LicenseIdentifier`, `affectedResources: List<AttributionResourceIdentifier>`
- `AttributionBookPublished`
  - 役割：クレジット帳が公開バージョンとして確定されたことを通知する。
  - フィールド：`identifier: AttributionBookIdentifier`, `version: int`

#### リポジトリ契約
- `AttributionBookRepository`
  - `current(): AttributionBook`
  - `persist(book: AttributionBook): void`

## イベントサブスクライバ
- **CatalogLicenseRegistrationSubscriber**
  - 目的：import ドメインのダウンロード完了時にライセンス記録を生成する。
  - 購読イベント：`CatalogDownloadCompleted`（import）。
  - 処理内容：
    1. `CatalogDownloadJob` からメタデータを取得
    2. `LicensePolicy` を生成（commercialUseAllowed, redistributionAllowed, creditRequirement, memo）
    3. `LicenseRegistrationRequest` を生成
    4. media ドメインで Track を作成し、`TrackIdentifier` を取得
    5. `LicenseRecord.register(request, trackIdentifier, licenseFilePath, checksum)` を実行
    6. `LicenseRecordRepository` で永続化
    7. 成功時は `LicenseRecordRegistered` を発火、失敗時は `CatalogDownloadFailed` を発火
  - 発火イベント：`LicenseRecordRegistered` / `CatalogDownloadFailed`
- **LicenseRevocationSubscriber**
  - 目的：ライセンス失効を media/profile へ伝搬し、AttributionBook を更新する。
  - 購読イベント：`LicenseRecordRevoked`（licensing）。
  - 処理内容：
    1. `LicenseRecordRevoked` イベントから `TrackIdentifier` を取得
    2. `TrackRepository` から該当 Track を取得
    3. Track に対して `markDeprecated(reason: "ライセンス失効")` を呼び出し、`TrackDeprecated` イベントを発火
    4. `TrackRepository` で永続化
    5. `AttributionBookRepository` から現在の AttributionBook を取得
    6. `AttributionBook.invalidateEntriesByLicense(licenseIdentifier)` を呼び出し、`AttributionEntriesInvalidated` を発火
    7. `AttributionBookRepository` で永続化
    8. profile パッケージへ `LicenseRevocationWarning` イベントを発火（ユーザーへの通知を促す）
  - 発火イベント：`TrackDeprecated` / `AttributionEntriesInvalidated` / `LicenseRevocationWarning`
- **AttributionPublishSubscriber**
  - 目的：ライセンス登録時に AttributionBook を最新化する。
  - 購読イベント：`LicenseRecordRegistered`（licensing）。
  - 処理内容：
    1. `LicenseRecordRepository` から対象ライセンスを取得
    2. `AttributionBookRepository` から現在の AttributionBook を取得
    3. ライセンス情報から `AttributionEntry` を生成（resource, displayName, attributionText, license, isValid=true）
    4. `AttributionBook.appendEntry(entry, licenseRecordRepository)` を呼び出し、Active ライセンスチェック後に `AttributionEntryAppended` が発火
    5. エントリ数が閾値（例: 100件）に到達した場合、`AttributionBook.publish(version)` を呼び出し、`AttributionBookPublished` を発火
    6. AttributionBookRepository で永続化
  - 発火イベント：`AttributionEntryAppended` / `AttributionBookPublished`
