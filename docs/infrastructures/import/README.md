# import パッケージ（CatalogDownloadJob）

## 永続化戦略

| データ                | ストア                   | 保存形式                      |
|-----------------------|--------------------------|-------------------------------|
| CatalogDownloadJob     | SQLite (`import.db`)       | テーブル `catalog_download_job` |

## 保存形式

### catalog_download_job
- `job_identifier` TEXT PRIMARY KEY
- `catalog_track_identifier` TEXT
- `status` TEXT (`Pending`|`Downloading`|`Verifying`|`Registering`|`Completed`|`Failed`)
- `download_url` TEXT
- `target_path` TEXT
- `track_metadata_json` TEXT （`CatalogTrackMetadata` の JSON シリアライズ）
- `license_metadata_json` TEXT
- `retry_count` INTEGER
- `failure_reason_code` TEXT NULL
- `failure_reason_message` TEXT NULL
- `created_at` INTEGER
- `updated_at` INTEGER

## リポジトリ実装

- `CatalogDownloadJobRepository`
  - `find(jobIdentifier)` → `SELECT * FROM catalog_download_job`
  - `persist(job)` → UPSERT（metadata_json を文字列として保存）
  - `findPending()` → `SELECT ... WHERE status IN ('Pending','Failed')`

## Firebase Storage ACL

- `FirebaseStorageClient`
  - `downloadFile(downloadUrl, targetPath)` → HTTPS経由でダウンロード
  - `verifyChecksum(targetPath, expectedChecksum)`
- `CatalogDownloadJobService`
  - job と ACL を結び付けて処理。ダウンロード→検証→登録の間でリポジトリを更新。

## 追加メモ

- `track_metadata_json` と `license_metadata_json` はドメインオブジェクトへの復元に使用（JSON → 値オブジェクト）。
- ダウンロード先は `tracks/{trackIdentifier}.m4a`、ライセンスは `tracks/licenses/{trackIdentifier}_LICENSE.txt`。
- 進捗表示（UI 用）は job のステータスを監視して実装。

## トランザクション境界

- `CatalogDownloadJobRepository.persist` は job レコード更新を単一トランザクションで実行。
- `CatalogDownloadJobService` では以下を保証：
  1. licensing.db でライセンス登録 → 成功時にコミット
  2. media.db でトラック登録 → 成功時にコミット
  3. いずれか失敗時は job を `Failed` とし、`retry_count` をインクリメント

## マイグレーション

- `import.db` に `schema_version` テーブルを追加し、SQL マイグレーションを適用。
