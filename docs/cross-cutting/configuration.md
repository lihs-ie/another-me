# 設定管理方針

## 環境別設定

- `lib/config/app_config.dart` でアプリケーション設定のモデルを定義。
- 環境別に JSON / YAML で設定を用意：
  - `config/app_config_dev.json`
  - `config/app_config_prod.json`
- 主な項目
- `firebaseProjectId`
- `storageBucket`
- `catalogEndpoint`（catalog.json の取得 URL）
- `logLevel`
- すべての `catalogEndpoint` は HTTPS (TLS) エンドポイントである必要がある。HTTP を指定した場合は設定検証でエラーとし、通信は行わない。

## 読み込み手順

1. アプリ起動時に環境変数（`--dart-define=APP_ENV=dev`）を参照。
2. 該当 JSON を読み込んで `AppConfig` として Provider へ注入。
3. テスト時はデフォルトのモック設定を使用。

## 設定の反映先

- Firebase Storage 接続情報 → `FirebaseStorageClient`
- イベントバスログレベル → Logging 設定
- カタログ取得 URL → Catalog Sync ユースケース

## スキーマ例

```json
{
  "firebaseProjectId": "another-me-dev",
  "storageBucket": "another-me-dev.appspot.com",
  "catalogEndpoint": "https://cdn.example.com/catalog.json",
  "logLevel": "INFO",
  "features": {
    "enableTelemetry": true,
    "enableNotifications": true
  }
}
```

## 秘匿情報

- API キーや認証情報は `.env`（Flutter Dotenv など）で管理し、Git 管理外とする。

## 更新手順

- 設定変更時は Pull Request でレビューし、CI が lint/format チェックを行う。
