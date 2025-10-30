# モーダル／ポップアップ設計

メイン画面からアクセスする各モーダルの UI 構成と状態管理をまとめる。

## 共通仕様

- Flutter の `showModalBottomSheet`（モバイル）と `Dialog`（デスクトップ）を使い分ける。
- 背面の Scene/Character は半透明化し、モーダル閉鎖後は元の描画に復帰。
- モーダル内の操作は Riverpod Provider を介してユースケースを実行する。

## 1. Music モーダル（🎵）

### セクション
1. **Now Playing**：現在再生中の曲・タイムライン。
2. **Playlist**：UC03 のプレイリスト一覧。ドラッグ＆ドロップで並び替え。
3. **Official Catalog**：UC02/UC14。検索バー／フィルタ／タグ。
4. **Download Queue**：進行中のジョブ一覧。進捗バー・再試行・キャンセル操作。

### 主要操作
- 曲の再生/一時停止/スキップ。
- プレイリストへの追加・削除（`PlaylistRepository` 経由）。
- カタログ曲のダウンロード開始（`CatalogDownloadController.enqueue`）。

### 状態管理
- `trackPlaybackController`（再生状態）
- `playlistController`（プレイリスト編集）
- `catalogDownloadController`（ダウンロード進捗）

## 2. Pomodoro モーダル（⏱）

### セクション
1. **Session Controls**：開始/一時停止/スキップ/リセット。
2. **Timer Config**：PomodoroPolicy の編集（範囲 1–120 分）。
3. **History**：最近の SessionLog（UC01, UC13）を表示。

### 状態管理
- `pomodoroSessionController`
- `sessionLogProvider`（最新ログを SQL から取得）

### インタラクション
- 作業／休憩時間の調整 → 即座に `UserProfileRepository` に保存。
- 実行中セッションの変更は confirm ダイアログで確認。

## 3. Settings モーダル（⚙️）

### タブ構成
1. **Appearance**：キャラ選択、背景選択、服装モード。
2. **Audio**：ボリューム、出力デバイス、フェード設定。
3. **General**：言語、テーマモード、起動時復元、キャッシュクリア。

### 状態管理
- `characterSceneController`
- `userProfileController`

### 特記事項
- キャラ／背景変更時はプレビューを即時反映。
- キャッシュ削除は Firebase Storage への再ダウンロードを促す。（トラックファイル、背景アセットの削除）

## 4. Notification モーダル（🔔）

### セクション
1. **Channels**：イベント別の通知チャネル（Desktop/MenuBar/Sound）。
2. **Quiet Hours**：静音時間帯の設定。
3. **System Integration**：OS の Do Not Disturb 同期。

### 状態管理
- `notificationSettingsController`

### 機能
- チャンネルの ON/OFF で `NotificationRuleRepository.persist`。
- テスト通知ボタンで `NotificationDispatcher` をトリガー。

## 5. Download モーダル（📥）

### 概要
- 進行中／失敗した CatalogDownloadJob の一覧。
- 各ジョブの再試行・キャンセル・失敗理由表示。

### 状態管理
- `catalogDownloadController`

### エラーハンドリング
- ネットワーク不通 → 再試行ボタンで `retry_count` をリセット。
- チェックサム不一致 → 失敗理由を表示し、再ダウンロードを推奨。
