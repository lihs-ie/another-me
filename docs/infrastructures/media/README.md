# media パッケージ（Track / Playlist）

## 永続化戦略

| 集約/データ | ストア             | 保存形式                       |
|--------------|--------------------|--------------------------------|
| Track        | SQLite (`media.db`) | テーブル `track`               |
| Playlist     | SQLite (`media.db`) | テーブル `playlist`            |
| PlaylistEntry| SQLite (`media.db`) | テーブル `playlist_entry`      |

補助ファイル：楽曲ファイルは Firebase Storage からダウンロードし、アプリ固有ディレクトリの `tracks/{trackIdentifier}.m4a` へ保存。ライセンスファイルは `tracks/licenses/{trackIdentifier}_LICENSE.txt`。

## 保存形式

### track
- `track_identifier` TEXT PRIMARY KEY
- `title`, `artist` TEXT
- `duration_ms` INTEGER
- `audio_format` TEXT (`aac`/`mp3`/`wav`)
- `local_path` TEXT
- `loop_start_ms` INTEGER NULL
- `loop_end_ms` INTEGER NULL
- `license_identifier` TEXT
- `allow_offline` INTEGER (0/1)
- `lufs_target` REAL
- `catalog_track_identifier` TEXT (公式カタログ ID)
- `download_url` TEXT
- `audio_checksum` TEXT
- `license_file_path` TEXT
- `downloaded_at` INTEGER
- FOREIGN KEY(license_identifier) REFERENCES license_record(license_identifier)

### playlist
- `playlist_identifier` TEXT PRIMARY KEY
- `name` TEXT
- `allow_duplicates` INTEGER (0/1)
- `created_at` INTEGER
- `updated_at` INTEGER

### playlist_entry
- `entry_identifier` TEXT PRIMARY KEY
- `playlist_identifier` TEXT
- `track_identifier` TEXT
- `order_index` INTEGER
- `added_at` INTEGER
- FOREIGN KEY(playlist_identifier) REFERENCES playlist(playlist_identifier)
- FOREIGN KEY(track_identifier) REFERENCES track(track_identifier)

## リポジトリ実装

- `TrackRepository`
  - `find(trackIdentifier)` → `SELECT * FROM track WHERE track_identifier = ?`
  - `persist(track)` → UPSERT（カタログメタを含む）
  - `terminate(trackIdentifier)` → レコード削除 & 音源/ライセンスファイル削除

- `PlaylistRepository`
  - `find(playlistIdentifier)` → `SELECT` + entry JOIN
  - `persist(playlist)` → playlist & entries をトランザクションで更新（orderIndex を再計算）
  - `terminate(playlistIdentifier)` → 関連エントリ含め削除

## Firebase Storage ACL アダプタ

- `FirebaseStorageClient`
  - `downloadFile(downloadUrl, targetPath, expectedChecksum)`
    - Firebase Storage の HTTPS URL を取得（署名付き URL またはパブリック URL）
    - ダウンロード後に SHA-256 チェックサムを比較
  - `deleteFile(storagePath)`（将来のクリーンアップ用）

`CatalogDownloadJobRepository` は ACL アダプタ (`FirebaseStorageClient`) を利用して音源・ライセンスを取得後、SQLite への永続化を行う。

## 追加メモ

- 楽曲ファイルの保存先はプラットフォームごとに Application Support 相当を利用（macOS/iOS: `Library/Application Support/another-me/tracks`、Windows: `%APPDATA%\another-me\tracks` など）。
- ダウンロード状況は `downloaded_at` と存在チェック（ファイル有無）で判定。欠落時は再ダウンロードを促す。

## トランザクション境界とロールバック戦略

- `CatalogDownloadCompleted` 処理時は以下の順でコミットする：
  1. **licensing.db トランザクション**：`LicenseRecord.registerFromCatalog` を実行し、ライセンステキストを保存。コミット成功後に進む。
  2. **media.db トランザクション**：`Track.registerFromCatalog` を実行し、`license_identifier` を参照してレコードを作成。成功したらコミットし、`TrackRegistered` イベントを発火。
- media.db のコミットで失敗した場合：
  - 既に登録済みの `LicenseRecord` を `status='Pending'` に更新し、再試行キューへ追加する。
  - 失敗が続く場合はユーザーへ通知して手動再ダウンロードを促す。
- `TrackRepository.persist()` は `LicenseRecordRepository.find()` を呼び出し、ライセンスレコードが存在しない場合はエラー扱いにして整合性を確保する。

## マイグレーション・スキーマバージョン

- `media.db` に `schema_version` テーブルを作成：
  ```sql
  CREATE TABLE IF NOT EXISTS schema_version (
    version INTEGER PRIMARY KEY,
    applied_at INTEGER NOT NULL
  );
  ```
- マイグレーションファイル例
  - `migrations/media/001_initial.sql`
  - `migrations/media/002_add_catalog_columns.sql`
- アプリ起動時に未適用のマイグレーションを順次実行し、エラー時はロールバック。
