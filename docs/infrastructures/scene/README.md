# scene パッケージ（Scene）

## 永続化戦略

| データ        | ストア                        | 保存形式                                      |
|---------------|-------------------------------|-----------------------------------------------|
| シーンメタ     | JSON (`scenes.json`)           | AssetCatalog から生成したキャッシュ           |
| 背景アセット   | Firebase Storage / ローカルFS | `assets/scenes/{sceneIdentifier}/...`          |


## JSON 保存構造（scenes.json）

```json
{
  "version": "1.2.0",
  "scenes": [
    {
      "sceneIdentifier": "room",
      "name": "My Room",
      "animation": {"fps": 24, "frameCount": 96, "loopDurationMs": 4000},
      "atlasRef": {"pngPath": "assets/scenes/room/atlas.png", "jsonPath": "assets/scenes/room/atlas.json", "gridSize": 16},
      "parallaxLayers": [
        {"layerId": "background", "speedRatio": "1", "assetFrameRange": [0,95]},
        {"layerId": "foreground", "speedRatio": "1/2", "assetFrameRange": [0,95]}
      ],
      "characterAnchor": {"relativeX": 0.5, "relativeY": 0.8, "offsetX": 0, "offsetY": -16},
      "windowView": {"elements": ["Clouds"], "cycleMs": 4000},
      "lightingProfile": {"mode": "Auto", "darkeningFactor": 0.3},
      "status": "Active",
      "updatedAt": 1730000000000
    }
  ]
}
```

## リポジトリ実装

- `SceneRepository`
  - `find(sceneIdentifier)` → JSON から読み込み
  - `findActive()` → `status == Active`
  - `persist(scene)` → AssetCatalog 更新時に JSON 再生成
  - `all()` → 全シーン

## アセット管理

- Firebase Storage 上の背景アセットを library パッケージの共通ダウンロードロジックで取得し、ローカルに展開。
- `characterAnchor` 等のメタ情報は JSON に保持し、描画時に Scene 集約へ読み込む。

## 追加メモ

- 背景アセットの展開先：`Application Support/another-me/assets/scenes/{sceneIdentifier}`。
- night/day の照明調整は `lightingProfile` を参照し、UI 側で適用する。
