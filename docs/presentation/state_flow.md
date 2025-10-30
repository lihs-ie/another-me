# UI 状態遷移・イベントフロー

## 全体図

```
User Interaction
    ↓
Presentation Controller (Flutter Widget / Riverpod)
    ↓
Application / Use Case (docs/use-cases)
    ↓
Domain (Aggregates / Services)
    ↓
Infrastructure (Repositories / ACL)
    ↓
State update → Provider に反映 → UI 再描画
```

## 1. 楽曲ダウンロードフロー（UC02, UC14）

1. ユーザーが Music モーダルで「ダウンロード」を押下。
2. `CatalogDownloadController.enqueue(trackId)` が `CatalogDownloadJobRepository` にジョブ登録。
3. `CatalogDownloadJobService`（ユースケース層）が Firebase Storage 経由でダウンロード。
4. 成功時：`LicenseRecord.registerFromCatalog` → `Track.registerFromCatalog` → `TrackRegistered` イベント。
5. `TrackPlaybackController` がライブラリを再読み込みし、HUD に反映。
6. 失敗時：job のステータスを Failed にし、バッジ上に失敗アイコンを表示。

### UI 更新ポイント
- Download バッジ → プログレスバー／失敗時警告。
- Music モーダル → カタログリストの状態（ダウンロード済み／未済）を更新。

## 2. ポモドーロセッション（UC01）

1. HUD の ⏱ ボタン → Pomodoro モーダルで開始操作。
2. `PomodoroSessionController.start()` → `PomodoroSession` 集約を更新。
3. Provider が残り時間を `Stream` で配信。
4. 時間経過／フェーズ終了で `PomodoroPhaseStarted/Completed` イベントが発火。
5. Notification モーダルの設定に応じて `NotificationDispatcher` が OS 通知を送信。
6. セッション完了時は `SessionLogRepository.append` → History UI を更新。

### UI 更新ポイント
- HUD のリング表示／残り時間。
- 背景・キャラクターアニメーション（フェーズに応じて切替）。
- Pomodoro モーダルのログセクション。

## 3. キャラクター／背景切替（UC04, UC06）

1. Settings モーダルでキャラ／背景を選択。
2. `CharacterSceneController.updateSelection()` が `UserProfileRepository.persist`。
3. DayPeriod イベント（自動衣装切替）が発生すると、`CharacterSceneController` が WardrobeMap を更新。
4. メイン画面の BackgroundCanvas と CharacterSprite が再描画される。

### UI 更新ポイント
- 即時プレビュー（モーダル内のミニプレビュー）。
- HUD のキャラクター名表示（任意）。

## 4. 通知設定（UC12）

1. Notification モーダルでチャネルを変更。
2. `NotificationSettingsController.update()` が JSON を更新。
3. `NotificationDispatcher` が次回イベント発火時に新設定を使用。

### UI 更新ポイント
- トグルスイッチ／静音時間帯入力欄。
- テスト通知を送信し、結果（成功/失敗）を Snackbar で表示。

## エラーハンドリングの UI 表現

- ネットワークエラー：SnackBar + Download モーダルで詳細表示。
- チェックサム不一致：Music モーダルのリスト項目に警告アイコン。
- DB エラー：ダイアログで「再試行」オプションを提示し、詳細ログは Logging フレームワークへ送信。
