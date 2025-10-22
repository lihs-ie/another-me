# media パッケージ モデル

本パッケージは lo-fi 楽曲とプレイリスト、再生方針に関わるドメインを扱う。要件定義書の「音楽再生」「ライセンス/素材ポリシー」「課金・利用制限」と整合するようモデリングする。

## モデル方針
- 楽曲取り込みは import パッケージの `CatalogDownloadJob` 集約からのイベントを受けて `Track` 集約が確定登録する。
- ライセンス整合性は licensing パッケージの `LicenseRecord` との Identifier 参照で保証し、欠落時は集約内で拒否する。
- プレイリスト操作は順序付きリストの再構築に限定し、重複許否ポリシーを明示する。
- 出力デバイスやフェードなど再生設定は profile パッケージに移譲し、本パッケージは再生対象と順序に責務を集中する。
- ドメインイベントを Publish/Subscribe で扱い、常駐型サブスクライバが集約の副作用処理（取り込み完了、ライセンス失効、権利更新）を担う。

## Track 集約

#### TrackIdentifier （楽曲識別子／値オブジェクト）
- 目的：Track 集約を一意に識別する。
- フィールド：
  - `value`: ULID 文字列（26 文字）
- 不変条件：
  - `value` は ULID フォーマット（`[0-7][0-9A-HJKMNP-TV-Z]{25}`）に一致する。
- 振る舞い：
  - **新規生成できる(generate)**
    - 入力：なし
    - 出力：`TrackIdentifier`
    - 副作用：なし

#### TrackRegistrationRequest （楽曲登録リクエスト／値オブジェクト）
- 目的：media 境界専用の楽曲登録情報を表す。import 境界の型への依存を排除する。
- フィールド：
  - `identifier`: `TrackIdentifier`（media 境界で生成）
  - `title`: 曲名（文字列）
  - `artist`: アーティスト名（文字列）
  - `durationMs`: 再生時間（ミリ秒）
  - `audioFormat`: 文字列（`aac` / `mp3` / `wav`）
  - `localPath`: `FilePath`
  - `fileChecksum`: `Checksum`
  - `loopPoint`: `LoopPoint`
  - `lufsTarget`: `LufsValue`
  - `license`: `LicenseIdentifier`（licensing 境界への識別子参照）
  - `catalogTrackID`: 文字列（カタログ上の楽曲ID）
- 不変条件：
  - すべてのフィールドが非 null。
  - `durationMs > 0`。
  - `loopPoint.startMs < loopPoint.endMs <= durationMs`。
  - `lufsTarget` は要件内（-14dB ± 許容範囲）に収める。
- 備考：
  - **変換責務**：import 境界の型（`CatalogTrackMetadata` 等）から `TrackRegistrationRequest` への変換は、アプリケーション層（ユースケース）で実施する。
  - これにより media 境界は import 境界の内部実装に依存しない。

#### TrackStatus （楽曲ステータス／列挙型）
- 目的：Track の現在の状態を表す。
- 値：
  - `active`：通常の再生可能状態
  - `deprecated`：ライセンス失効等で非推奨
- 状態遷移：
  - `[作成] → active`
  - `active → deprecated`（ライセンス失効時）
  - `deprecated → (削除不可、履歴として保持)`

#### Track （楽曲／集約）
- 目的：楽曲メタデータ、ローカルファイル参照、ライセンスとの紐付けを一貫して管理する。
- フィールド：
  - `identifier`: `TrackIdentifier`
  - `title`: 曲名（文字列）
  - `artist`: アーティスト名（文字列）
  - `durationMs`: 再生時間（ミリ秒）
  - `audioFormat`: 文字列（`aac` / `mp3` / `wav`）
  - `localPath`: ファイルパス（`FilePath`）
  - `fileChecksum`: `Checksum`
  - `loopPoint`: `LoopPoint`
  - `lufsTarget`: `LufsValue`
  - `license`: `LicenseIdentifier`（識別子参照のみ、ライセンス情報の実体は licensing 境界が管理）
  - `catalogSource`: `CatalogSource`
  - `status`: `TrackStatus`
- 不変条件：
  - `title`, `artist`, `localPath`, `license` は必須。
  - `durationMs > 0`。
  - `loopPoint.startMs < loopPoint.endMs <= durationMs`。
  - `lufsTarget` は要件内（例：-14dB ± 許容範囲）に収める。
  - `status == deprecated` の Track は新規 Playlist に追加不可。
- 振る舞い：
  - **カタログから登録できる(registerFromCatalog)**
    - 入力：`TrackRegistrationRequest`
    - 出力：`Track`
    - 副作用：メタ情報とファイル整合性を検証し、成功時に Track を生成して `TrackRegistered` を発火する。失敗時は例外を投げる。
  - **メタデータを更新できる(updateMetadata)**
    - 入力：変更差分（タイトル・アーティストなど）
    - 出力：なし
    - 副作用：差分を反映し、更新結果を `TrackMetadataUpdated` として発火する。
  - **廃止できる(markDeprecated)**
    - 入力：理由（文字列）
    - 出力：なし
    - 副作用：`status` を `deprecated` に変更し、`TrackDeprecated` を発火する。冪等性を保証（既に deprecated なら何もしない）。
- 備考：
  - **ライセンス情報の参照**：`allowOffline` や `attributionText` などのライセンス情報は Track には保持しない。これらは licensing 境界の `LicenseRecord` がソース・オブ・トゥルースとして管理する。
  - **UI での参照方法**：再生可否やクレジット表示が必要な場合、アプリケーション層またはプレゼンテーション層で `LicenseRepository.find(track.license)` により取得する。
  - **syncLicense の削除**：ライセンス情報を Track に保持しないため、`syncLicense` メソッドは不要。ライセンス失効時は `LicenseRecordSyncSubscriber` が `Track.markDeprecated` を呼び出す。

#### LoopPoint （ループポイント／値オブジェクト）
- フィールド：
  - `startMs`: 自然数（ミリ秒）
  - `endMs`: 自然数（ミリ秒）
  - `trackDurationMs`: 自然数（ミリ秒）
- 不変条件：`0 <= startMs < endMs <= trackDurationMs`。
- 振る舞い：
  - **ループポイントを生成できる(create)**
    - 入力：`startMs`, `endMs`, `trackDurationMs`
    - 出力：`LoopPoint`
    - 副作用：入力値が不変条件を満たさない場合は例外を発する

#### LufsValue （音量正規化値／値オブジェクト）
- フィールド：
  - `value`: 浮動小数点（-30〜0）
- 不変条件：-30 以下や 0 より大きい値は許容しない。

#### CatalogSource （カタログ情報／値オブジェクト）
- 目的：公式カタログ上の元データを参照する。
- フィールド：
  - `catalogTrackID`: 文字列（カタログ上の楽曲ID）
  - `downloadURL`: 文字列（HTTPS URL）
- 不変条件：
  - `catalogTrackID` は空文字不可。
  - `downloadURL` は HTTPS スキームのみ許容。
- 備考：
  - import 境界の `CatalogTrackIdentifier` 型を直接参照せず、文字列 ID で保持することで境界の独立性を保つ。

#### ドメインイベント
- `TrackRegistered`
  - 役割：楽曲の取り込みが完了し、ライブラリに登録されたことを通知する。
  - フィールド：`identifier: TrackIdentifier`, `license: LicenseIdentifier`, `durationMs: int`
  - 備考：`allowOffline` は licensing 境界が管理するため、このイベントには含めない。
- `TrackMetadataUpdated`
  - 役割：楽曲メタデータ（タイトル等）が更新されたことを通知する。
  - フィールド：変更されたフィールドとその値
- `TrackDeprecated`
  - 役割：楽曲が利用不可になったことを通知する。
  - フィールド：`identifier: TrackIdentifier`, `reason: String`
- `TrackRegistrationFailed`
  - 役割：楽曲登録に失敗したことを通知する。
  - フィールド：`catalogTrackID: String`, `reason: String`, `occurredAt: DateTime`
  - 備考：media 境界独自の失敗イベント。import 境界の `CatalogDownloadFailed` とは分離して管理する。

#### リポジトリ契約
- `TrackRepository`
  - `find(identifier: TrackIdentifier): Track`
    - 識別子に一致するトラックが見つからない場合は `AggregateNotFoundError` を投げる
  - `all(): List<Track>`
  - `persist(track: Track): void`
  - `terminate(identifier: TrackIdentifier): void`

## Playlist 集約

### 目的
- ユーザーが定義する楽曲順序付き集合を管理し、ループ・シャッフル等の政策を profile パッケージと連携して適用する。
- 曲の追加・削除・並び替え操作を整合性を持って提供する。

## Playlist 集約

#### PlaylistIdentifier （プレイリスト識別子／値オブジェクト）
- 目的：ユーザーのプレイリストを一意に識別する。
- フィールド：
  - `value`: ULID 文字列（26 文字）
- 不変条件：
  - `value` は ULID フォーマットに一致する。
- 振る舞い：
  - **新規生成できる(generate)**
    - 入力：なし
    - 出力：`PlaylistIdentifier`
    - 副作用：なし

#### EntitlementService （権利チェックサービス／インターフェース）
- 目的：billing 境界の Entitlement 情報を抽象化し、Playlist が楽曲数制限をチェックできるようにする。
- 振る舞い：
  - **楽曲追加可能かチェックできる(canAddTrack)**
    - 入力：`currentTrackCount: int`
    - 出力：`bool`（追加可能なら `true`、制限超過なら `false`）
  - **楽曲数上限を取得できる(getTrackLimit)**
    - 入力：なし
    - 出力：`int`（Free プランなら 3、Pro プランなら無制限を表す大きな値）
- 備考：
  - 実装は billing 境界の `EntitlementPlan` から情報を取得する。
  - Playlist はこのインターフェースに依存することで、billing 境界の内部実装から独立する。

#### Playlist （プレイリスト／集約）
- 目的：ユーザーが定義する楽曲順序集合を管理する。
- フィールド：
  - `identifier`: `PlaylistIdentifier`
  - `name`: 文字列
  - `entries`: `PlaylistEntry` の順序付きリスト
  - `repeatPolicy`: `RepeatPolicy`
  - `allowDuplicates`: 真偽値
  - `createdAt`: 日時
  - `updatedAt`: 日時
- 不変条件：
  - `name` は空文字不可。
  - 各 `entries.track` は存在する `Track` を指す。
  - `allowDuplicates == false` の場合、同じ `track` を 1 度しか登録しない。
  - `entries.orderIndex` は 0 から連番（重複・欠番なし）。
  - 追加する Track の `status` が `active` であること（`deprecated` は追加不可）。
- 振る舞い：
  - **トラックを追加できる(addTrack)**
    - 入力：`track: TrackIdentifier`, `entitlement: EntitlementService`
    - 出力：なし
    - 副作用：
      1. `entitlement.canAddTrack(currentTrackCount: entries.length)` で事前チェック
      2. 制限超過の場合は `EntitlementLimitExceededError` を投げる
      3. `track.status == deprecated` の場合は `InvariantViolationError` を投げる
      4. `allowDuplicates == false` かつ既存エントリに同じ track がある場合は `InvariantViolationError` を投げる
      5. 制約を満たす場合にエントリを末尾へ追加し、`PlaylistEntryAdded` を発火する
    - 備考：エラー時は即座に例外を投げ、ユーザーに明確なフィードバックを提供（UX 向上）
  - **トラックを並び替えできる(reorder)**
    - 入力：`entry: PlaylistEntryIdentifier`, `newIndex: int`
    - 出力：なし
    - 副作用：
      1. `newIndex` が範囲外（`< 0` または `>= entries.length`）の場合は `ArgumentError` を投げる
      2. 対象エントリを現在位置から削除
      3. `newIndex` の位置に挿入
      4. 全エントリの `orderIndex` を 0 から連番に再計算
      5. `PlaylistReordered` を発火する
    - 備考：FR-AUD-03（並び替え操作）を満たす
  - **トラックを削除できる(removeTrack)**
    - 入力：`entry: PlaylistEntryIdentifier`
    - 出力：なし
    - 副作用：該当エントリを除去し、残りの `orderIndex` を 0..n-1 の連番に再調整する。`PlaylistEntryRemoved` を発火する。

#### PlaylistEntryIdentifier （プレイリスト項目識別子／値オブジェクト）
- 目的：プレイリスト内の各エントリを一意に識別する。
- フィールド：
  - `value`: ULID 文字列（26 文字）
- 不変条件：
  - `value` は ULID フォーマットに一致する。
- 振る舞い：
  - **新規生成できる(generate)**
    - 入力：なし
    - 出力：`PlaylistEntryIdentifier`
    - 副作用：なし

#### PlaylistEntry （プレイリスト項目／エンティティ）
- フィールド：
  - `identifier`: `PlaylistEntryIdentifier`
  - `track`: `TrackIdentifier`
  - `orderIndex`: 数値（0 からの連番）
  - `addedAt`: 日時
- 不変条件：`orderIndex` は並び替え後も 0..n-1 を維持。

#### RepeatPolicy （リピート方針／値オブジェクト）
- フィールド：
  - `mode`: LoopMode（`Single` / `Playlist` / `None` 想定）
- 不変条件：`LoopMode.Single` の場合は単曲再生となるよう profile 設定と整合。

#### PlaylistStats / DuplicatePolicy / PlaylistPhaseBinding
- それぞれ集計値・重複許否・フェーズ紐付けを表す補助値オブジェクト。必要に応じて拡張。

#### ドメインイベント
- `PlaylistCreated`
  - 役割：新しいプレイリストが作成されたことを通知する。
  - フィールド：`identifier: PlaylistIdentifier`, `name: String`, `trackCount: int`
- `PlaylistEntryAdded`
  - 役割：プレイリストにトラックが追加されたことを通知する。
  - フィールド：`playlist: PlaylistIdentifier`, `entry: PlaylistEntryIdentifier`, `track: TrackIdentifier`
- `PlaylistEntryRemoved`
  - 役割：プレイリストからトラックが削除されたことを通知する。
  - フィールド：`playlist: PlaylistIdentifier`, `entry: PlaylistEntryIdentifier`
- `PlaylistReordered`
  - 役割：プレイリストの並び順が変更されたことを通知する。
  - フィールド：`playlist: PlaylistIdentifier`, `entry: PlaylistEntryIdentifier`, `newIndex: int`
- `PlaylistDeleted`
  - 役割：プレイリストが削除されたことを通知する。
  - フィールド：`identifier: PlaylistIdentifier`
- `PlaylistExceedsEntitlementLimit`
  - 役割：プランダウングレード時にプレイリストが楽曲数上限を超過したことを通知する。
  - フィールド：`playlist: PlaylistIdentifier`, `currentCount: int`, `limit: int`
  - 備考：UI 層でユーザーに通知し、どの楽曲を削除するか選択させる（自動削除はしない、UX 向上）

#### リポジトリ契約
- `PlaylistRepository`
  - `find(identifier: PlaylistIdentifier): Playlist`
    - 識別子に一致するプレイリストが見つからない場合は `AggregateNotFoundError` を投げる
  - `all(): List<Playlist>`
  - `persist(playlist: Playlist): void`
  - `terminate(identifier: PlaylistIdentifier): void`

## 再生設定の責務境界

本セクションでは、LoopPoint / LufsValue などの再生関連設定がどの境界に所属するかを明確化する。

| 項目 | 所属 | 理由 |
|-----|------|------|
| LoopPoint（楽曲固有） | Track (media) | 楽曲のメタデータとして保存。FR-AUD-04 に対応。 |
| フェード時間（500ms） | PlaybackSettings (profile) | ユーザー設定（要件32）。ユーザーごとに異なる可能性がある。 |
| LUFS正規化の有効/無効 | PlaybackSettings (profile) | ユーザー設定。正規化を使うかどうかはユーザーの選択。 |
| LUFS目標値（-14dB） | Playlist (media) | プレイリスト単位の設定。FR-AUD-06 に対応。 |
| 音量・ミュート | PlaybackSettings (profile) | ユーザー設定（要件32）。グローバルな音量制御。 |

**備考**：
- media 境界は「何を再生するか」（楽曲メタデータ、プレイリスト順序）に責務を集中。
- profile 境界は「どのように再生するか」（フェード、音量、ミュート）に責務を集中。
- この責務分担により、各境界の凝集度が高まり、変更影響を局所化できる。

## Cross-パッケージ連携
- licensing
  - `Track` は `LicenseIdentifier` で `LicenseRecord` を参照する（識別子参照のみ）。
  - ライセンス失効イベント（`LicenseRecordRevoked`）を受けた場合、`Track.markDeprecated` を発火する。
  - `allowOffline` や `attributionText` は licensing 境界が管理。media 境界は必要時に `LicenseRepository.find` で取得する。
- billing
  - `Playlist.addTrack` は `EntitlementService` を通じて楽曲数制限をチェックする。
  - プランダウングレード時（`PlanDowngraded` イベント）は `PlaylistExceedsEntitlementLimit` を発火し、UI 層でユーザーに通知。
- profile
  - `RepeatPolicy` や再生キュー設定、フェード時間、音量設定を管理。
  - `Playlist` 集約は順序管理に徹する。
- import
  - `CatalogDownloadCompleted` イベントを受けて `Track.registerFromCatalog` を実行。
  - 登録成功時は `TrackRegistered`、失敗時は `TrackRegistrationFailed` を発火（import の `CatalogDownloadFailed` とは分離）。

## イベントサブスクライバ

- **CatalogDownloadCompletedSubscriber**
  - 目的：import 境界のダウンロード完了を受け取り、Track を登録する。
  - 購読イベント：`CatalogDownloadCompleted`（import）。
  - 処理内容：
    1. import 境界の型（`CatalogTrackMetadata` 等）から `TrackRegistrationRequest` に変換（アプリケーション層で実施）
    2. `Track.registerFromCatalog(request)` を実行
    3. 成功時に `TrackRegistered` を発火
    4. 失敗時（例外キャッチ）は `TrackRegistrationFailed` を発火
  - 発火イベント：`TrackRegistered` / `TrackRegistrationFailed`
  - 備考：media 境界独自の `TrackRegistrationFailed` を発火し、import の `CatalogDownloadFailed` とは分離する（境界の独立性）。
- **LicenseRecordSyncSubscriber**
  - 目的：ライセンス失効を Track 集約へ反映する。
  - 購読イベント：`LicenseRecordRevoked`（licensing）。
  - 処理内容：対象 `Track` を取得し、`Track.markDeprecated(reason: "License revoked")` を実行。
  - 発火イベント：`TrackDeprecated`
  - 備考：`LicenseRecordUpdated` は購読しない（Track はライセンス情報を保持しないため、更新イベントに反応する必要がない）。
- **TrackDeprecationSubscriber**
  - 目的：Track の廃止に連動してプレイリストを整合させる。
  - 購読イベント：`TrackDeprecated`（media）。
  - 処理内容：関連 `Playlist` からトラックを削除せず、そのまま保持する（ユーザーが削除を判断）。UI 層で deprecated トラックを表示する際にグレーアウト等で示す。
  - 発火イベント：なし
  - 備考：自動削除はせず、履歴として保持する方針。
- **PlanDowngradedSubscriber**
  - 目的：プランダウングレード時にプレイリストが楽曲数上限を超過している場合、ユーザーに通知する。
  - 購読イベント：`PlanDowngraded`（billing）。
  - 処理内容：
    1. `PlaylistRepository.all()` からすべての Playlist を取得
    2. `EntitlementService.getTrackLimit()` で現在の上限を取得
    3. 各 Playlist の `entries.length` が上限を超過している場合、`PlaylistExceedsEntitlementLimit` を発火
    4. **自動削除はしない**（ユーザーが削除する楽曲を選択する、UX 向上）
  - 発火イベント：`PlaylistExceedsEntitlementLimit`
  - 備考：要件28（プランダウングレード時の制約）に対応。

## 永続化方針

本セクションでは、Track と Playlist の永続化フォーマットと責務境界を明確化する（FR-SET-02 対応）。

### Track
- **形式**：SQLite
- **理由**：楽曲数が多く（数百〜数千曲）、検索・フィルタリング（アーティスト名、タイトル等）が必要なため、RDBMS が適切。
- **テーブル設計**：
  - `tracks` テーブル：identifier, title, artist, durationMs, audioFormat, localPath, fileChecksum, loopPoint, lufsTarget, license, catalogSource, status
  - インデックス：`license`（ライセンスIDでの検索）、`status`（active/deprecated のフィルタリング）
- **実装場所**：`infrastructures/media/track_repository_sqlite.dart`

### Playlist
- **形式**：JSON（ファイル）
- **理由**：プレイリスト数は少なく（ユーザーあたり数個〜数十個）、全件読み込みで十分。SQLite のオーバーヘッドを避ける。
- **ファイルパス**：`<profile_dir>/playlists/<playlist_id>.json`
  - 例：`/Users/alice/.another-me/profiles/01ARZ3NDEKTSV4RRFFQ69G5FAV/playlists/01HXZ3NDEKTSV4RRFFQ69G5FAV.json`
- **責務境界**：
  - **media 境界**：Playlist 集約のドメインロジック（並び替え、追加、削除）
  - **profile 境界**：プレイリストファイルの保存先ディレクトリ（`<profile_dir>`）の管理
  - **infrastructures/media**：JSON シリアライゼーション（Mapper パターン）
- **JSON 構造例**：
  ```json
  {
    "identifier": "01HXZ3NDEKTSV4RRFFQ69G5FAV",
    "name": "作業用BGM",
    "entries": [
      {
        "identifier": "01HXZ3NDEKTSV4RRFFQ69G5FAV",
        "track": "01ARZ3NDEKTSV4RRFFQ69G5FAV",
        "orderIndex": 0,
        "addedAt": "2025-10-30T10:00:00Z"
      }
    ],
    "repeatPolicy": {"mode": "Playlist"},
    "allowDuplicates": false,
    "createdAt": "2025-10-30T09:00:00Z",
    "updatedAt": "2025-10-30T10:00:00Z"
  }
  ```
- **実装場所**：`infrastructures/media/playlist_repository_json.dart`, `infrastructures/media/playlist_mapper.dart`

**備考**：
- ドメインモデルは `toJson`/`fromJson` を持たない（AGENTS.md のルールに従う）。
- シリアライゼーションは infrastructures 層の Mapper で実装する。
