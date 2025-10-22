# licensing パッケージ（LicenseRecord / AttributionBook）

## 設計原則

- ドメイン層への依存は許容されるが、ドメイン層がインフラ層に依存してはならない（依存関係逆転の原則）
- 技術的詳細（JSON、データベース、ファイルシステムなど）はこの層に閉じ込める
- **ドメインモデルは `toJson`/`fromJson` メソッドを持たない**（AGENTS.mdのルールに従う）
- シリアライゼーションはインフラストラクチャ層の Mapper クラスで実装する

## Mapper

### LicenseSnapshotMapper

#### 目的

`LicenseSnapshot`（ドメインモデル）と JSON 形式の相互変換を担当する Mapper クラス。

#### 責務

- ドメインモデルからJSON形式への変換（toJson）
- JSON形式からドメインモデルへの復元（fromJson）
- 複合型（`URL`、`FilePath`、`Checksum`など）の適切な分解とシリアライズ

#### インターフェース

```dart
class LicenseSnapshotMapper {
  Map<String, dynamic> toJson(LicenseSnapshot snapshot);
  LicenseSnapshot fromJson(Map<String, dynamic> json);
}
```

#### 注意事項

- URL型は `value` と `scheme` を分けて保存する
- FilePath型は `value` と `os` を分けて保存する
- Checksum型は `algorithm` と `value` を分けて保存する
- DateTime型はISO8601形式の文字列として保存する
- Enum型は`name`プロパティを使用して文字列として保存する

## 永続化戦略

| データ                 | ストア                  | 保存形式                      |
|------------------------|-------------------------|-------------------------------|
| LicenseRecord           | SQLite (`licensing.db`) | テーブル `license_record`     |
| LicenseStatusHistory    | SQLite (`licensing.db`) | テーブル `license_status_history` |
| AttributionBook         | JSON (`attribution.json`)| Append-only 形式               |
| ライセンスファイル      | Firebase Storage / ローカルFS | `tracks/licenses/{trackIdentifier}_LICENSE.txt` |

## 保存形式

### license_record
- `license_identifier` TEXT PRIMARY KEY
- `track_title` TEXT
- `license_name` TEXT
- `license_url` TEXT
- `attribution_text` TEXT
- `allow_offline` INTEGER (0/1)
- `redistribution_allowed` INTEGER (0/1)
- `source_url` TEXT
- `license_file_path` TEXT
- `catalog_track_identifier` TEXT
- `created_at` INTEGER
- `updated_at` INTEGER

### license_status_history
- `id` INTEGER PRIMARY KEY AUTOINCREMENT
- `license_identifier` TEXT
- `status` TEXT (`Active`|`Revoked`|`Pending`)
- `changed_at` INTEGER
- `reason` TEXT
- FOREIGN KEY(license_identifier) REFERENCES license_record(license_identifier)

### attribution.json

```json
{
  "bookIdentifier": "default",
  "entries": [
    {
      "resourceIdentifier": "track_lofi_001",
      "displayName": "Rainy Day Study",
      "licenseIdentifier": "license_lofi_001",
      "attributionText": "Rainy Day Study by Lo-Fi Artist (CC BY 4.0)",
      "updatedAt": 1730000000000
    }
  ],
  "publishedVersion": 12
}
```

## リポジトリ実装

- `LicenseRecordRepository`
  - `find(licenseIdentifier)` → `SELECT * FROM license_record`
  - `persist(record)` → UPSERT + status_history を更新
  - `findActive()` → `SELECT ... WHERE status = 'Active'`

- `AttributionBookRepository`
  - `current()` → attribution.json を読み込み
  - `persist(book)` → JSON を Append-only 更新（追記）

## Firebase Storage ACL

- `FirebaseStorageClient`
  - `downloadLicenseFile(downloadUrl, targetPath, expectedChecksum)`
  - `deleteLicenseFile(path)`（撤回時のクリーンアップ用）

LicenseRecord.registerFromCatalog は ACL を介してライセンステキストを取得し、`license_file_path` に保存する。

## トランザクション境界とロールバック戦略

- `CatalogDownloadCompleted` 処理時：
  1. licensing.db トランザクション内で `LicenseRecord.registerFromCatalog` を実行し、`license_status_history` に履歴を追加してコミット。
  2. media.db で Track 登録が失敗した場合は、該当ライセンスを `status='Pending'` に更新し、再試行キューへ追加。これにより半端な登録状態を回避する。
- `LicenseRecordRepository.persist()` は履歴更新を含め 1 トランザクションで行い、エラー時はロールバックする。

## エラーハンドリング

- ライセンステキストのダウンロードに失敗した場合、`CatalogDownloadJob` を `Failed` にしてユーザーへ再試行を案内。
- 撤回時のファイル削除が失敗した場合はログに記録し、定期クリーンアップジョブで再実行する。

## マイグレーション・スキーマバージョン

- `licensing.db` に `schema_version` テーブルを追加し、マイグレーションを順次適用。
- 例：`migrations/licensing/001_initial.sql`, `002_add_license_file_path.sql`

## 追加メモ

- ライセンス撤回（LicenseRecordRevoked）時は media パッケージへ通知し、該当トラックを `TrackDeprecated` に移行。
- AttributionBook は append-only なので、UI 表示時は JSON を読み込み並び替えた結果を渡す。
