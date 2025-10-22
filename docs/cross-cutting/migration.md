# マイグレーション戦略

## スキーマバージョン管理

- 各 SQLite DB（work.db, media.db, licensing.db, billing.db, import.db, telemetry.db）に `schema_version` テーブルを持つ。
  ```sql
  CREATE TABLE IF NOT EXISTS schema_version (
    version INTEGER PRIMARY KEY,
    applied_at INTEGER NOT NULL
  );
  ```
- マイグレーションファイルは `lib/infrastructure/migrations/{db}/` に番号付きで配置（例：`001_initial.sql`, `002_add_next_coffee_at.sql`）。

## 実行手順

1. アプリ起動時に各 DB を開き、`schema_version` を参照。
2. 未適用のマイグレーションを順番に実行。
3. 失敗した場合はロールバックし、`ERROR` ログを出力。ユーザーにはダイアログで再起動を案内。複数 DB 間のマイグレーションは依存順に実行し、途中失敗時は全 DB を前バージョンに戻す。

## テスト

- CI でマイグレーション適用テストを実行（空の DB と既存データを持つ DB の両方）。
- 意図的に失敗するマイグレーション（不正な SQL）を実行し、ロールバック動作を検証。
- バージョンダウンは原則サポートしないが、必要に応じてバックアップを取る運用を整備。
