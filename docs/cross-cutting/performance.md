# パフォーマンスモニタリング戦略

## 収集メトリクス

- CPU 使用率：Flutter DevTools の Timeline を用いて 1080p / 60 秒稼働時に計測（NFR-PERF-01）。
- メモリ使用量：Dart VM Heap のプロファイル（NFR-PERF-02 の 400MB 以下を目標）。
- FPS：キャラクター 30fps、背景 24fps を維持できているか確認。

## テレメトリ連携

- 使用許諾を得たユーザーのみ `UsageMetrics`（docs/infrastructures/telemetry/README.md）へ `PerformanceSnapshot` を保存。
- 週次で集計し、閾値を超えていないかモニタリング。

## CI ベンチマーク

- `flutter drive --profile` 等を用いてシナリオベースのベンチマークを実行。
- CPU/メモリが閾値を超えた場合は CI を失敗させ、パフォーマンス退行を防止。

## 最適化施策

- バックグラウンド時は FPS を下げる（presentation/main_screen.md 参照）。
- RepaintBoundary や `AnimatedBuilder` を活用し、再描画領域を最小限に保つ。
