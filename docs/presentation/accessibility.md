# アクセシビリティ設計

## 概要

要件 [NFR-A11Y-01]（requirements.md:84）に基づき、VoiceOver/TalkBack をはじめとするスクリーンリーダー対応とコントラスト調整、通知の読み上げ方針を定義する。

## スクリーンリーダー対応

### Semantics ラベル

| コンポーネント             | ラベル例                                       | 備考                                      |
|----------------------------|-----------------------------------------------|-------------------------------------------|
| `PomodoroStatusIndicator`  | "残り時間 {minutes}分{seconds}秒、{phase}フェーズ" | Ring 表示の代替として音声で状況を伝える      |
| `TrackInfoTile`            | "再生中：{title}、{artist}"                    | 曲タイトル・アーティストを読み上げ          |
| `DownloadProgressBadge`    | "ダウンロード進行中：{count}件、合計 {percent}%" | 進捗状況をリアルタイムで報告                |
| `ControlPanel` ボタン      | "音楽設定を開く" / "ポモドーロ設定を開く" など     | ボタンの役割を明確化                        |
| `NotificationToggle`       | "通知オン" / "通知オフ"                         | 状態を読み上げつつ切り替え可能であることを明示 |

### フォーカス順序

1. 残り時間表示（ポモドーロステータス）
2. 再生中トラック情報
3. コントロールボタン群（左から右へ）
4. ダウンロードバッジ（表示時）
5. 背景アニメーション領域（必要に応じて読み上げをスキップ可）

### 読み上げタイミング

- ポモドーロタイマー：30 秒ごとに残り時間を読み上げ（設定で ON/OFF 切替可能）。
- フェーズ切替：`PomodoroPhaseStarted` イベント受信時にフェーズ名を読み上げ。
- ダウンロード完了：`CatalogDownloadCompleted` 受信時に曲名と完了を通知。

## コントラストと文字サイズ

- HUD テキストのコントラスト比は 4.5:1 以上を保証（WCAG 2.1 AA 準拠）。
- 文字サイズは OS のアクセシビリティ設定（ContentSizeCategory）に追従し、Flutter の `MediaQuery.textScaleFactor` を利用。
- ボタンサイズは最小 44dp 四方を確保。

## 通知の読み上げ

- macOS：`NSUserNotificationCenter`（または `UNUserNotificationCenter`）で `sound` と `informativeText` を設定し VoiceOver 読み上げに対応。
- iOS/Android：`flutter_local_notifications` 等を経由し、音声読み上げが有効な通知カテゴリを利用。
- Windows：Toast Notification でアクセシビリティテキストを設定。

## モーダルのアクセシビリティ

- モーダル表示時は背面要素を読み上げ対象から除外（`ModalBarrier` + `Semantics` の `excludeSemantics: true`）。
- フォーカス移動はモーダル内に閉じ込め、閉じた際にボタンへフォーカスを戻す。

## テスト観点

- VoiceOver/TalkBack を ON にした状態での操作テスト。
- コントラスト検査ツール（Lighthouse, WCAG Color Contrast Analyzer）による確認。
- 文字スケール 200% で UI が崩れないかの確認。
