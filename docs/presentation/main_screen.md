# メイン画面設計

## レイアウト概要

```
┌───────────────────────────────┐
│    ① 背景キャンバス（Scene）               │
│   ┌─────────────────────────┐ │
│   │ キャラクター（Character）             │ │
│   └─────────────────────────┘ │
│                                   │
│                                   │
│                                   │
│                                   │
│───────────────────────────────────│
│ ② HUD オーバーレイ（半透明）              │
│   ├─ 現在時刻表示                        │
│   ├─ 再生中トラック情報（タイトル/アーティスト/進捗） │
│   ├─ ポモドーロ残り時間/フェーズ表示          │
│   └─ コントロールボタン群                   │
└───────────────────────────────┘

コントロールボタン群（右下 or 右上にまとめて配置）：
- 🎵 音楽コントロールボタン（Music）
- ⏱ ポモドーロコントロールボタン（Focus）
- ⚙️ 設定ボタン（Settings）
- 🔔 通知設定ボタン（Notification）
- 📥 ダウンロード進捗バッジ（必要時のみ表示）
```

## コンポーネント詳細

| コンポーネント              | 役割                                                                 | Riverpod Provider                     |
|-----------------------------|----------------------------------------------------------------------|---------------------------------------|
| BackgroundCanvas            | Scene のアニメーションを描画。`Scene.characterAnchor` でキャラ位置調整。| `characterSceneController`            |
| CharacterSprite             | Character のアニメーション。WardrobeMap に応じて衣装を切替。            | `characterSceneController`            |
| TimeDisplay                 | 現在時刻を表示。タイムゾーンは OS に従う。                            | `timeProvider`                        |
| TrackInfoTile               | 再生中の曲タイトル、アーティスト、進捗バー。                           | `trackPlaybackController`             |
| PomodoroStatusIndicator     | 残り時間とフェーズのラベル、進行リング。                              | `pomodoroSessionController`           |
| ControlPanel (button row)   | 各種モーダルを開くボタンを配置。                                      | `uiOverlayController`（UI ローカル状態） |
| DownloadProgressBadge       | CatalogDownloadJob の進行状況。複数ジョブがある場合はバッジ表示。        | `catalogDownloadController`           |

## インタラクション

| ボタン/ジェスチャ | 動作                                         | 開く UI                | 関連ユースケース |
|-------------------|----------------------------------------------|------------------------|-------------------|
| 🎵 音楽ボタン      | 再生キュー／公式カタログを操作               | Music モーダル         | UC02, UC03, UC14  |
| ⏱ ポモボタン       | セッション開始/停止、フェーズスキップ        | Pomodoro モーダル      | UC01              |
| ⚙️ 設定ボタン      | キャラ・背景・復元設定などを操作             | Settings モーダル      | UC04, UC13        |
| 🔔 通知ボタン      | 通知チャネル・静音時間帯を操作               | Notification モーダル  | UC12              |
| 📥 バッジ          | 未完了のダウンロードジョブ一覧を表示         | Download モーダル      | UC02, UC14        |

## 状態遷移 (サマリ)

### Pomodoro セッション
1. `PomodoroSessionController.start()` → `pomodoro_session` ユースケース（UC01）を実行。
2. 背 景／キャラ → `phase` に応じたアニメーション更新。
3. フェーズ終了 → NotificationDispatcher 経由で通知。

### 楽曲ダウンロード
1. 🎵 モーダルで曲を選択 → `CatalogDownloadController.enqueue()`。
2. HUD のバッジで進捗表示、完了時に `TrackPlaybackController` がライブラリを更新。

### 設定変更
1. ⚙️ からキャラ/背景を変更 → `CharacterSceneController` と `UserProfileRepository` を更新。
2. 服装モードが Auto の場合は DayPeriod イベントを購読し自動切替。

## レイアウト適応

- macOS/Windows：横幅の広いレイアウト。HUD は下部オーバーレイ。
- iOS/Android：縦長レイアウト。HUD は下部カードまたはスライドアップパネルに変更。
- 16:9 から 4:3 などアスペクト比変化に応じて BackgroundCanvas を整数スケールで描画し、HUD 要素は `SafeArea` で調整。
## レスポンシブ対応

| デバイス               | ブレークポイント例 | HUD 配置                      | コントロールボタン配置               |
|------------------------|--------------------|-------------------------------|-------------------------------------|
| デスクトップ (macOS/Win)| 幅 ≥ 1200px         | 画面下部の横長オーバーレイ        | 右下に横並び（アイコン＋ラベル）        |
| タブレット (iPad)       | 800px ≤ 幅 < 1200px | 下部カード（高さを抑えたオーバーレイ）| 右下にコンパクト表示（アイコンのみ）    |
| モバイル (iOS/Android)  | 幅 < 800px          | スライドアップ式のボトムシート     | 右上に FAB スタック（縦並び）         |

- アスペクト比が 16:9 より縦長の場合は HUD をボトムシート風にし、タップで展開。
- BackgroundCanvas は `FittedBox` + 整数スケールで描画、余白は両端（レターボックス）に配置。
- キャラクター位置は `Scene.characterAnchor` の relative 値で調整し、HUD に重ならないよう補正。

## 追加メモ（パフォーマンス最適化）

- Scene / Character レイヤを `RepaintBoundary` で分離し、HUD との再描画を最小限に抑える。
- アプリがバックグラウンドになった際は `characterSceneController` で FPS を 30→15（キャラ）、24→12（背景）に落として CPU 使用率を抑制する。
- HUD のタイマーや進捗バーは `AnimatedBuilder` / `ValueListenableBuilder` で局所的に更新し、全体の `setState` を避ける。

## メニューバー UI（macOS / Windows）

- システムのメニューバー（ステータスバー）に常駐アイコンを表示し、クリックでクイックパネルを開く。
- 表示項目
  - 残り時間（`PomodoroSessionController` から取得）
  - 再生中の曲タイトル（`TrackPlaybackController` から取得）
  - 状態アイコン（作業中＝🟢、休憩中＝🟡、停止＝⚪️）
- クイック操作
  - セッションの一時停止／再開
  - 次の曲へスキップ
  - 設定モーダルを開くショートカット
- 実装：macOS は `NSStatusBar`、Windows はシステムトレイ API（将来対応予定）。Flutter ではプラットフォームチャネル経由で実装する。
