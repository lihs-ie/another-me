# プレゼンテーション層設計ガイド

本ガイドは Flutter を用いた UI レイヤーの設計方針をまとめる。クロスプラットフォーム（macOS/iOS/Windows/Android）を前提とし、ドメイン・ユースケースで定義された機能をどのように画面・状態に落とし込むかを整理する。

## 状態管理

- **Riverpod**（`flutter_riverpod`）を採用し、アプリケーション全体の依存性注入と状態管理を統一する。
- 主要な Provider
  - `PomodoroSessionController`：UC01 に基づき、セッション状態／残り時間／フェーズを管理。
  - `TrackPlaybackController`：UC02, UC03 を担当し、現在再生中のトラック、再生キュー、ダウンロード状況を提供。
  - `CharacterSceneController`：UC04, UC06 を担当し、選択キャラクター・背景・DayPeriod に応じた衣装・アンカー調整を行う。
  - `CatalogDownloadController`：UC02, UC14 を担当し、ダウンロードジョブの進行状況・エラー・再試行を管理。
  - `NotificationSettingsController`：UC12 を担当。
- Provider のライフサイクルは `ProviderScope` で管理し、画面間共有が必要なものは `StateNotifierProvider`/`AsyncNotifierProvider` を使用。

## フォルダ構成（推奨）

```
lib/
  presentation/
    main_screen/
      main_screen.dart
      hud_overlay.dart
      control_panel.dart
    modals/
      pomodoro_modal.dart
      music_modal.dart
      settings_modal.dart
      notification_modal.dart
    widgets/
      track_info_tile.dart
      time_display.dart
      download_progress_badge.dart
    themes/
      app_theme.dart
```

詳細は以下のドキュメントを参照：

- `docs/presentation/main_screen.md`
- `docs/presentation/modals.md`
- `docs/presentation/state_flow.md`
- `docs/presentation/accessibility.md`
- `docs/presentation/error_handling.md`
- `docs/presentation/i18n.md`
