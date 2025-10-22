# notification パッケージ（NotificationRule）

## 永続化戦略

| データ           | ストア                    | 保存形式                          |
|------------------|---------------------------|-----------------------------------|
| NotificationRule | JSON (`notification_rule.json`) | 単一レコード                       |

- JSON を選択した理由：通知設定は Key-Value で、頻繁なアップデートが想定されないため。

## 保存形式

```json
{
  "ruleIdentifier": "default",
  "profileIdentifier": "default",
  "channels": [
    {"eventType": "PomodoroPhaseStarted", "channels": ["Desktop", "MenuBar"], "template": "Phase ${phase} started"},
    {"eventType": "TrackDeprecated", "channels": ["Desktop"], "template": "Track ${title} is unavailable."}
  ],
  "quietHours": {"start": "22:00", "end": "07:00"},
  "dndEnabled": false,
  "lastNotified": [
    {"eventType": "PomodoroPhaseStarted", "lastSentAt": 1730000000000}
  ],
  "updatedAt": 1730000000000
}
```

## リポジトリ実装

- `NotificationRuleRepository`
  - `find(profileIdentifier)` → JSON を読み込み
  - `persist(rule)` → 上書き保存

## 追加メモ

- macOS/iOS では `UNUserNotificationCenter`、Windows では Toast Notifications、Android では NotificationManager など OS ネイティブの API を使用。ACL アダプタとして `NotificationDispatcher` を実装し、アプリ固有フォーマットから OS API へ変換。
- JSON ファイルの保存先：`Application Support/another-me/notification_rule.json`
