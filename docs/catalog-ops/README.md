# 公式カタログ運用ガイド

公式カタログ（AssetCatalog）の作成・更新・配信・ロールバックの手順をまとめる。キャラクター/背景アセットおよび公式楽曲を一元管理し、アプリで同期できる状態を維持する。

## 更新フロー概要

1. ステージング環境で新規アセットを制作・検証。
2. catalog.json（AssetCatalog）を生成し、チェックサムを付与。
3. Firebase Storage にアセットファイルをアップロード。
4. catalog.json を CDN へ配置、バージョンをインクリメント。
5. カタログ同期ユースケース（UC14）で動作確認。
6. 問題なければ本番環境へ反映。

## フォルダ構成（例）

```
catalog/
  staging/
    v1.2.0/
      catalog.json
      characters/
      scenes/
      tracks/
  production/
    current -> v1.1.0/
    v1.1.0/
      catalog.json
      ...
```

## バージョニングポリシー

- セマンティックバージョン（例：1.2.0）。
- 変更種別
  - MAJOR：互換性のない変更（アセット削除など）
  - MINOR：楽曲・アセットの追加
  - PATCH：メタデータ修正・チェックサム更新
- catalog.json の `version` と `catalogIdentifier` を一致させる。

## チェックサム生成

```
shasum -a 256 tracks/track_lofi_001.m4a > tracks/track_lofi_001.m4a.sha256
```

- catalog.json の `trackCatalogMetadata.audioChecksum` に出力を格納。
- ライセンスファイルも同様に checksum を記録。

## アップロード手順

1. Firebase CLI または gsutil を使用して Storage にアップロード。
   - 例：`gsutil cp tracks/track_lofi_001.m4a gs://another-me-prod/tracks/`
2. catalog.json を CDN へ配置し、`catalogEndpoint`（configuration.md 参照）を更新。
3. キャッシュクリアが必要な場合は CDN 側で Invalidate を実行。

## 検証チェックリスト

- `TrackCatalogMetadata` にタイトル/長さ/チェックサムが正しく入っているか。
- ライセンス情報（licenseName, attributionText, allowOffline）が最新か。
- キャラクター/背景のアセットが 16px グリッド・安全余白を満たすか。
- catalog.json をダウンロードし、`TrackCatalogUpdated` イベントがトリガーされるか。

## ロールバック手順

1. 旧バージョン (`production/v1.1.0/`) の catalog.json を `current` に戻す。
2. CDN キャッシュをクリアし、アプリ側の UC14 で再同期。
3. 必要に応じて、テレメトリでロールバック通知を確認。

## ドキュメント・ツール

- `scripts/catalog/generate_catalog.dart`：catalog.json を生成するスクリプト（バックログ項目）。
- チェックサム生成・アップロードを自動化するタスクランナー（makefile or npm scripts）を検討。
