# ユースケース UC14: パフォーマンスモニタリング（システム）

## 目的
- アプリケーションのパフォーマンス（CPU、メモリ、FPS）を定期的に監視し、閾値超過時に他ドメインに通知する。

## アクター
- メインアクター：PerformanceMonitor 集約
- サポートアクター：PerformanceMetricsCollector、PerformanceBudgetSubscriber

## 事前条件
- アプリケーションが起動している。
- PerformanceMonitor がデフォルトの閾値で初期化されている。

## トリガー
- 定期タイマー（例：5 秒ごと）が PerformanceMonitorService を呼び出す。

## 基本フロー
1. `PerformanceMetricsCollector.collect()` でパフォーマンスデータ（CPU、メモリ、キャラクターFPS、背景FPS）を取得する。
2. `PerformanceMonitorRepository.current()` で現在のモニターを取得する。
3. `monitor.recordSnapshot(snapshot)` を呼び出し、スナップショットを記録する。
4. 閾値超過が検出された場合、`PerformanceBudgetExceeded` イベントが発火される。
5. `PerformanceMonitorRepository.persist(monitor)` で永続化する。
6. 発火されたイベント（`PerformanceBudgetExceeded`）を EventBroker に publish する。

## 代替フロー
- **閾値カスタマイズ**: ユーザーまたは開発者が設定画面で閾値を変更した場合、`monitor.updateThresholds(newThresholds)` を呼び出す。

## 例外フロー
- **メトリクス収集失敗**: `PerformanceMetricsCollector.collect()` が失敗した場合、エラーをログに記録し、次回の収集まで待機する。
- **永続化失敗**: `PerformanceMonitorRepository.persist(monitor)` が失敗した場合、エラーをログに記録するが、次回の収集には影響しない。

## 事後条件
- パフォーマンススナップショットが記録される。
- 閾値超過時には `PerformanceBudgetExceeded` イベントが発火され、scene パッケージの `PerformanceBudgetSubscriber` が反応する。

## 内部設計（ユースケース層）

### PerformanceMonitorService （ユースケース）

- 目的：定期的にパフォーマンスメトリクスを収集して telemetry/performance に記録する。
- トリガー：定期タイマー（例：5 秒ごと）
- 処理内容：
  1. `PerformanceMetricsCollector.collect()` でパフォーマンスデータを取得
  2. `PerformanceMonitorRepository.current()` で現在のモニターを取得
  3. `monitor.recordSnapshot(snapshot)` を呼び出し
  4. `PerformanceMonitorRepository.persist(monitor)` で永続化
  5. 発火されたイベント（`PerformanceBudgetExceeded` など）を EventBroker に publish
# ユースケース UC14: パフォーマンスモニタリング（システム）

## 外部設計

### 目的
- アプリのパフォーマンス（CPU、メモリ、FPS）を定期監視し、閾値超過時に他境界へ通知して対策を促す。

### アクター
- メインアクター：PerformanceMonitor 集約
- サポートアクター：PerformanceMetricsCollector、PerformanceBudgetSubscriber

### 事前条件
- アプリが起動し、`PerformanceMonitor` がデフォルト閾値で初期化されている。

### トリガー
- 定期タイマー（例：5 秒ごと）が `PerformanceMonitorService` を起動する。

### 基本フロー
1. `PerformanceMetricsCollector.collect()` が CPU/メモリ/キャラクターFPS/背景FPS を取得する。
2. `PerformanceMonitorRepository.current()` で現在のモニターを取得し、`monitor.recordSnapshot(snapshot)` を実行する。
3. 閾値超過を検出した場合、`PerformanceBudgetExceeded` が発火し、scene や avatar 境界へ通知される。
4. スナップショットが記録された `monitor` を `PerformanceMonitorRepository.persist` で永続化する。
5. Telemetry 境界がメトリクスを UsageMetrics へ転送し、後日の分析に備える。

### 代替フロー
- **閾値カスタマイズ**：ユーザー/開発者が設定画面で閾値を変更すると、`monitor.updateThresholds(newThresholds)` を呼び出して次回から新閾値を使用する。

### 例外フロー
- **メトリクス収集失敗**：`collect()` が失敗した場合、エラーログを残して次回収集まで待機する。
- **永続化失敗**：`PerformanceMonitorRepository.persist` が失敗した場合、エラーログを残しつつプロセスは継続する。

### 事後条件
- パフォーマンススナップショットが記録され、閾値超過時は `PerformanceBudgetExceeded` が発火する。
- Scene/Avatar 境界の `PerformanceBudgetSubscriber` がイベントを受け、演出抑制などの対策を実施する。

## 内部設計

### 関連ドメインモデル

#### PerformanceMonitor（telemetry）
- 概要：パフォーマンス閾値とスナップショット履歴を保持する集約。
- 主な振る舞い：
  - `recordSnapshot(snapshot)`：新しいメトリクスを記録し、閾値超過を判定。
  - `updateThresholds(thresholds)`：監視閾値を変更。

#### PerformanceSnapshot（telemetry）
- 概要：計測結果（CPU/メモリ/FPS）を表す値オブジェクト。

#### PerformanceMetricsCollector（telemetry）
- 概要：OS/API から最新のメトリクスを取得するサービス。

#### PerformanceMonitorRepository
- 概要：モニターの取得・保存を担当。

#### PerformanceBudgetSubscriber（scene/avatar）
- 概要：`PerformanceBudgetExceeded` を購読し、パララックス抑制や衣装軽量化などの対策を行う。

### データフロー
1. タイマーが `PerformanceMonitorService.execute()` を呼び出す。
2. `collect()` → `recordSnapshot()` → `persist()` の順に処理し、必要に応じて `PerformanceBudgetExceeded` を発火。
3. イベントを受けた Scene/Avatar 境界が演出調整を実施し、結果を `SceneRepository.persist` 等で保存する。
