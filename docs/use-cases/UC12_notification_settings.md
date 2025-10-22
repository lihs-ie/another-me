# ユースケース UC12: 通知ルールと静音時間を設定する

## 目的
- ユーザーがポモドーロ通知や楽曲イベント通知のチャネル・静音時間帯を調整し、作業スタイルに合わせたアラート制御を行う。

## アクター
- メインアクター：ユーザー
- サポートアクター：アプリ（NotificationRule 集約、UserProfile）

## 事前条件
- 通知機能が macOS 上で許可されている。
- `NotificationRule` が初期値（Desktop 通知オン、QuietHours 未設定）で存在する。

## トリガー
- 設定画面の「通知」セクションを開き、静音時間帯や通知チャネルを編集する。

## 基本フロー
1. アプリが現行の `NotificationRule` を読み込み、イベントタイプ（ポモドーロ開始/終了、トラック無効化など）ごとのチャネル設定を表示する。
2. ユーザーが静音時間帯（quietHours.start / quietHours.end）を設定し、「22:00〜07:00 は通知しない」などのルールを決める。
3. 必要に応じて、デスクトップ通知（Desktop）、メニューバー更新（MenuBar）、サウンド通知（Sound）のオン/オフを個別に切り替える。
4. 保存ボタンを押すと `NotificationRuleUpdated` イベントが発火し、`NotificationRuleRepository.persist` により変更が反映される。
5. テスト通知を送信し、新しい設定が正しく動作するか確認できる。

## 代替フロー
- **DND 同期**: 「macOS のおやすみモードと同期」チェックを入れると、`SystemDndStateChanged` イベントを購読して自動的に通知を停止する。
- **プロファイル連動**: プロファイル切替に応じて異なる NotificationRule を適用する（例：ワーク用 / プライベート用）。

## 例外フロー
- **時間帯不整合**: 終了時刻（quietHours.end）が開始時刻（quietHours.start）より前に設定された場合、UI がエラー表示し保存をブロックする。
- **テンプレート欠落**: 通知テンプレート（NotificationChannelSetting.template）が空欄の場合、保存を許可せず注意メッセージを表示する。

## 事後条件
- `NotificationRule` に更新内容が保存され、今後の通知発生時に新しい設定が適用される。
- 変更履歴が UsageMetrics やログに記録され、サポート対応時に参照できる。
# ユースケース UC12: 通知ルールと静音時間を設定する

## 外部設計

### 目的
- ユーザーがポモドーロ通知や楽曲イベント通知のチャネル、静音時間帯を調整し、作業スタイルに合わせたアラート制御を行う。

### アクター
- メインアクター：ユーザー
- サポートアクター：アプリ（NotificationRule 集約、UserProfile）

### 事前条件
- macOS 上で通知権限が許可されている。
- `NotificationRule` が初期値（Desktop 通知オン、静音時間未設定）で存在する。

### トリガー
- 設定画面の「通知」セクションを開き、静音時間帯や通知チャネルを編集する。

### 基本フロー
1. アプリが `NotificationRuleRepository.find(profileIdentifier)` を呼び出し、イベントタイプ別（ポモドーロ開始/終了、トラック無効化など）のチャネル設定を表示する。
2. ユーザーが静音時間帯（`QuietHours.start` / `QuietHours.end`）を編集し、「22:00〜07:00 は通知しない」などのルールを設定する。
3. デスクトップ通知（Desktop）、メニューバー更新（MenuBar）、サウンド通知（Sound）を個別にオン/オフ切り替え、必要に応じてテンプレート文言を編集する。
4. 保存操作で `NotificationRule.update(settings)` が実行され、`NotificationRuleUpdated` イベントが発火する。ユースケース層は `NotificationRuleRepository.persist` を呼び出し永続化する。
5. ユーザーはテスト通知を送信し、新しい設定が反映されていることを確認できる。

### 代替フロー
- **DND 同期**：macOS のおやすみモードと同期する設定を有効にすると、`SystemDndStateChanged` を購読して自動的に通知を抑制する。
- **プロファイル連動**：プロファイル切替に応じて異なる `NotificationRule` を適用する（ワーク用／プライベート用）。

### 例外フロー
- **時間帯不整合**：`QuietHours.end` が `start` より前に設定された場合、UI がエラーを表示して保存をブロックする（翌日扱いを許可する場合は別 UI で案内）。
- **テンプレート欠落**：通知テンプレートが空の場合、保存を許可せず警告を出す。
- **権限拒否**：通知権限が取り消された場合、設定保存後に再許可を促すモーダルを表示する。

### 事後条件
- `NotificationRule` に更新内容が保存され、今後の通知発生時に新しい設定が適用される。
- 変更履歴が UsageMetrics やログに記録され、サポート対応時に参照できる。

## 内部設計

### 関連ドメインモデル

#### NotificationRule（notification）
- 概要：通知チャネル設定と静音時間を管理する集約。
- 主な振る舞い：
  - `updateChannels(channelSettings)`：イベント種別ごとのチャネル設定を更新。
  - `updateQuietHours(quietHours)`：静音時間帯を設定・検証。
  - `enableSystemDndSync(enabled)`：OS の DND と同期するかを切り替え。

#### QuietHours（common.notification）
- 概要：静音時間帯を表す値オブジェクト。`start` と `end` が 0:00〜23:59 の範囲であることを保証する。

#### NotificationRuleRepository
- 概要：`NotificationRule` の取得・保存を担当。
- 留意点：プロファイルごとに独立したルールを保持し、変更時に `NotificationRuleUpdated` を発火する。

### データフロー
1. 設定画面が開かれると `NotificationRuleRepository.find` で現在のルールを取得。
2. ユーザー入力を `NotificationRule.update*` メソッドへ適用し、ユースケース層が検証エラーを UI に返す。
3. 保存成功後、`NotificationRuleRepository.persist` が更新を永続化し、`NotificationRuleUpdated` を発火。
4. Notification サービスが最新設定をキャッシュし、以後の通知発生時に適切なチャネル・静音判定を行う。
