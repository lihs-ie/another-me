# クロスカッティング基盤設計ガイド

共通基盤（依存性注入、設定、ログ、エラー処理、マイグレーションなど）を整理し、ドメイン／ユースケース／プレゼンテーションを下支えする設計をまとめる。

## 目次

- `docs/cross-cutting/di.md` … 依存性注入（DI）方針
- `docs/cross-cutting/configuration.md` … 設定管理
- `docs/cross-cutting/logging.md` … ログ／モニタリング
- `docs/cross-cutting/error-handling.md` … システムエラーの共通処理（UI は presentation 側）
- `docs/cross-cutting/migration.md` … DB スキーママイグレーション戦略
- `docs/cross-cutting/testing.md` … テスト戦略の高位方針
