# avatar パッケージ（Character）

## 永続化戦略

| データ           | ストア              | 保存形式                     |
|------------------|---------------------|------------------------------|
| 利用可能キャラ情報 | JSON (`characters.json`) | アプリ固有ディレクトリ内の JSON |
| ダウンロード済みアセット | Firebase Storage / ローカルFS | `assets/characters/{id}/...`   |

- キャラクターメタ（アニメーションフレーム、WardrobeMap）は AssetCatalog から同期されるため、JSON ファイルでキャッシュ。
- 画像/アニメーションアセットは AssetCatalog のパッケージを展開した結果として管理。

## JSON 保存構造（characters.json）

```json
{
  "version": "1.2.0",
  "characters": [
    {
      "characterIdentifier": "char_a",
      "displayName": "Character A",
      "status": "Active",
      "animationSet": {
        "typing": {"fps": 30, "frameCount": 12, "durationMs": 400},
        "coffee": {"fps": 30, "frameCount": 24, "durationMs": 800}
      },
      "wardrobeMap": {
        "morning": {"atlasFrame": "typing_morning_01", "paletteIdentifier": "palette_main"},
        "noon": {...},
        "night": {...}
      },
      "atlasRef": {
        "pngPath": "assets/characters/char_a/atlas.png",
        "jsonPath": "assets/characters/char_a/atlas.json",
        "pivot": {"x": 64, "y": 112},
        "padding": 8
      },
      "palette": ["#123456", "#abcdef"],
      "updatedAt": 1730000000000
    }
  ]
}
```

## リポジトリ実装

- `CharacterRepository`
  - `find(characterIdentifier)` → JSON のキャッシュから検索
  - `findActive()` → `status == Active` の配列を返す
  - `persist(character)` → AssetCatalog 更新時に JSON を再生成
  - `all()` → 全件返却
- AssetCatalog 更新 (`TrackCatalogUpdated` / `AssetCatalogPublished`) を受けた際に JSON を再生成。

## Firebase Storage 利用

- キャラクターアセット（PNG/JSON）も AssetCatalog パッケージとして Firebase Storage に配置。
- ダウンロードは library パッケージ側で共通ハンドラを用意し、avatar はローカル展開済みファイルを参照。

## 追加メモ

- プラットフォーム共通ディレクトリ：`Application Support/another-me/assets/characters/{id}`。
- 衣装データ（WardrobeMap）は JSON からロードし、時間帯変更ごとに `Character` 集約へ反映。
