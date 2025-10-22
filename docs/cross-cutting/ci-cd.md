# CI/CD パイプライン設計

## ワークフロー構成（例：GitHub Actions）

### Pull Request 時
1. `flutter analyze`
2. `flutter test`（ユニット＋ウィジェット＋ゴールデン差分）
3. マイグレーションテスト（空 DB / 既存 DB）
4. lint/format チェック

### main ブランチマージ後
1. E2E テスト（Firebase Storage モック）
2. ベンチマークテスト（CPU/メモリ計測）
3. DMG 生成 → 署名／公証 → リリースページへアップロード

## 環境変数例

- `FIREBASE_PROJECT_ID_DEV` / `FIREBASE_PROJECT_ID_PROD`
- `CI_APPLE_CERTIFICATE_P12`（署名）
- `CI_NOTARIZATION_USERNAME` / `CI_NOTARIZATION_PASSWORD`
- `APP_ENV`

## 成果物

- macOS 用 DMG（署名/公証済み）
- テストレポート（JUnit / coverage）
- ベンチマーク結果ログ

## サンプル GitHub Actions YAML（抜粋）

```yaml
name: CI

on:
  pull_request:
  push:
    branches: [main]

jobs:
  build:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
      - name: Install dependencies
        run: flutter pub get
      - name: Analyze
        run: flutter analyze
      - name: Unit & Widget Tests
        run: flutter test
      - name: Golden Tests
        run: flutter test --update-goldens
      - name: Migration Tests
        run: dart run tool/migration_test.dart
      - name: Benchmark (main branch only)
        if: github.ref == 'refs/heads/main'
        run: flutter drive --profile --target=test_driver/benchmark.dart
```
