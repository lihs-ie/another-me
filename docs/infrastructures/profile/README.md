# profile パッケージ（UserProfile）

## 永続化戦略

| データ          | ストア                    | 保存形式                            |
|-----------------|---------------------------|-------------------------------------|
| UserProfile      | JSON (`user_profile.json`) | 単一レコード                         |
| 最近のセッション | SQLite (`work.db`) ※参照    | SessionLog から読み取る（読み専） |

- JSON を選択した理由：設定項目が Key-Value であり、単一レコードの読み書きが主用途のため。

## 保存形式（user_profile.json）

```json
{
  "profileIdentifier": "01ARZ3NDEKTSV4RRFFQ69G5FAV",
  "isDefault": true,
  "language": "ja",
  "themeMode": "Auto",
  "outfitMode": "Auto",
  "selectedCharacterIdentifier": "01EXAMPLE1CHARACTERID0000",
  "selectedSceneIdentifier": "01EXAMPLE1SCENEID00000000",
  "playbackSettings": {
    "loopMode": "Single",
    "fade": {"milliseconds": 500},
    "volume": {"value": 0.7, "isMuted": false},
    "outputDeviceIdentifier": null
  },
  "pomodoroPolicy": {"workMinutes": 25, "breakMinutes": 5, "longBreakMinutes": 15, "longBreakEvery": 4},
  "notificationPreferences": {
    "enableDesktop": true,
    "enableMenuBar": true,
    "quietHours": {"start": "22:00", "end": "07:00"}
  },
  "restoreOnLaunch": true,
  "updatedAt": 1730000000000
}
```

**注意事項**:
- `isDefault`: デフォルトプロファイルかどうかを示す真偽値（シングルユーザーアプリでは常に `true`）
- `profileIdentifier` は固定ULID `01ARZ3NDEKTSV4RRFFQ69G5FAV` を使用（インフラ層の実装詳細）
- `selectedCharacterIdentifier` と `selectedSceneIdentifier` は実際のULID値を保存
- すべての識別子はULID形式（26文字）で統一
- デフォルトプロファイルかどうかの判定は `isDefault` フィールドのみで行う

**制約**:
- `isDefault = true` を持つプロファイルは**システム全体で1つのみ**存在できる（ユニーク制約）
- 現在の実装（単一ファイル `user_profile.json`）では、この制約は自然に保証される
- 将来的に複数プロファイル対応（`profiles/{id}.json`）する場合は、リポジトリ層で明示的に検証が必要

## リポジトリ実装

- `UserProfileRepository`
  - `getDefault()` → user_profile.json を読み込み、存在しなければ初期データを生成
    - 初期データの `profileIdentifier` は固定ULID `01ARZ3NDEKTSV4RRFFQ69G5FAV` を使用
    - 初期データの `isDefault` は `true` を設定
    - キャラクター・シーンはアクティブな最初のものを選択
    - その他はドメイン層で定義されたデフォルト値を適用
  - `persist(profile)` → JSON を上書き
    - すべての識別子はULID文字列（26文字）として保存
    - `isDefault` フィールドも保存
    - **重要**: `isDefault = true` で保存する場合、他のプロファイルの `isDefault` を `false` に更新する必要がある（将来の複数プロファイル対応時）
  - `observe(profileIdentifier)` → ファイル監視などで変更通知（将来拡張）

**将来の複数プロファイル対応時の追加実装**:
- `setDefault(profileIdentifier)` → 指定されたプロファイルをデフォルトに設定
  1. 既存のデフォルトプロファイル（`isDefault = true`）を検索
  2. 既存のデフォルトプロファイルの `isDefault` を `false` に更新
  3. 指定されたプロファイルの `isDefault` を `true` に更新
  4. これらの操作をトランザクション内で実行し、ユニーク制約を保証

## 追加メモ

- プラットフォーム共通ディレクトリ：`Application Support/another-me/user_profile.json`
- 複数プロファイルに対応する場合はファイルを分割（`profiles/{id}.json`）
- 再起動時の復元は UC13 に従い、JSON を読み込んだ後にアセット存在チェックを行う。
