# インフラストラクチャ層ガイド

ドメイン層で定義した各集約/リポジトリを、macOS を起点とした将来的な iOS/Windows/Android クロスプラットフォーム対応を考慮しつつ実装するための方針をまとめる。

## 基本方針

- 永続化は OS ごとのアプリ固有ディレクトリ（macOS/iOS: Application Support, Windows: %APPDATA%, Android: app-specific storage）を利用する。
- データストアの選定
  - **SQLite**：構造化データでクエリ/集計が必要な集約（例：Track, Playlist, SessionLog）。
  - **JSON ファイル**：設定や単一レコードを扱うもの（UserProfile, NotificationRule, AssetCatalog、MusicCatalogメタなど）。
  - **Firebase Storage**：公式楽曲とライセンスファイルの配信元。ACL アダプタを介してダウンロードを行う。
- 外部 API / ストレージは ACL（Anti-Corruption Layer）を設け、インフラ層のリポジトリは ACL 経由でアクセスする。

## パッケージ別設計

各パッケージごとのリポジトリ／保存形式／主要プロパティのマッピングを記述する。詳細は各 README を参照。

- `work`: `docs/infrastructures/work/README.md`
- `media`: `docs/infrastructures/media/README.md`
- `avatar`: `docs/infrastructures/avatar/README.md`
- `scene`: `docs/infrastructures/scene/README.md`
- `library`: `docs/infrastructures/library/README.md`
- `licensing`: `docs/infrastructures/licensing/README.md`
- `profile`: `docs/infrastructures/profile/README.md`
- `billing`: `docs/infrastructures/billing/README.md`
- `import`: `docs/infrastructures/import/README.md`
- `telemetry`: `docs/infrastructures/telemetry/README.md`
- `notification`: `docs/infrastructures/notification/README.md`

