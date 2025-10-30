# ユースケース UC09: テレメトリウィンドウのローテーション（システム）

## 目的
- オプトインユーザーの利用統計を一定期間でローテーションし、匿名性とパフォーマンス基準を保つ。

## アクター
- メインアクター：UsageMetrics 集約
- サポートアクター：TelemetryWindowRotatedSubscriber、BatchUploader、PerformanceMonitor

## 事前条件
- ユーザーがテレメトリ送信にオプトインしている（optIn=true）。
- 現在の収集ウィンドウ（MetricsWindow.start〜end）が満了に近い。

## トリガー
- スケジューラが 24 時間ごとにウィンドウ満了をチェックし、`rotateWindow(now)` を呼び出す。

## 基本フロー
1. `UsageMetrics.rotateWindow(now)` が新しい `MetricsWindow` を作成し、旧ウィンドウのイベントを `TelemetryWindowRotated` イベントとして書き出す。
2. BatchUploader がイベントを受信し、匿名化済みデータをバックエンド（あるいはローカルファイル）へバッチ送信する。
3. 送信成功時に UsageMetrics の `events` をクリアし、保存期間が上限（30 日）を超えないようにする。
4. PerformanceMonitor が直近の `PerformanceSnapshot` を確認し、CPU/メモリが基準を超えていれば `PerformanceBudgetExceeded` を発火して UI に警告する。

## 代替フロー
- **オプトアウト**: `optIn=false` の場合、rotateWindow はイベント送信を行わず、既存データを即座に破棄する。
- **遅延送信**: ネットワーク不通の際はローカルに一時保存し、次回ローテーション時にまとめて送信する。

## 例外フロー
- **送信失敗**: バッチ送信が失敗した場合、最大 3 回再試行。それでも失敗する場合は UsageMetrics にリトライフラグを付け、次回ローテーションまで保持する。
- **データ破損**: 送信前の JSON が破損している場合、破損データを破棄してログに記録し、新しいウィンドウを開始する。

## 事後条件
- UsageMetrics のイベントがクリアされ、保存期間を守った状態で次のウィンドウが開始される。
- UI や QA チームは PerformanceBudgetExceeded イベントによりリソース状況を把握できる。

## 内部設計（ユースケース層）

### TelemetryBatchUploadService （ユースケース）

- 目的：集計ウィンドウのローテーション時にバッチ送信を行う。
- トリガー：定期タイマー（例：毎日 0 時）
- 処理内容：
  1. `UsageMetricsRepository.current()` で現在のメトリクスを取得
  2. `metrics.optIn == false` の場合は何もしない
  3. 新しい `MetricsWindow` を `metrics.window.next()` で生成
  4. `oldEvents = metrics.rotateWindow(newWindow)` を呼び出し、古いデータを除外して取得
  5. `oldEvents` が空でない場合、`TelemetryBatchUploader`（インフラ層）に渡して送信
  6. `UsageMetricsRepository.persist(metrics)` で永続化
  7. 発火されたイベント（`TelemetryWindowRotated`）を EventBroker に publish

### TelemetryMaintenanceService （ユースケース）

- 目的：30 日以上古いイベントを定期的に削除する。
- トリガー：定期タイマー（例：毎日 0 時）
- 処理内容：
  1. `UsageMetricsRepository.current()` で現在のメトリクスを取得
  2. `purgeThreshold = DateTime.now() - 30日` を計算
  3. `metrics.purgeOldEvents(purgeThreshold)` を呼び出し
  4. `UsageMetricsRepository.persist(metrics)` で永続化
  5. 発火されたイベント（`EventsPurged`）を EventBroker に publish

### PerformanceBudgetExceeded 発生時の Scene パララックス調整
- `PerformanceBudgetExceeded` イベントが発火された際、`PerformanceBudgetSubscriber`（scene パッケージ）が以下の処理を実行する：
  1. `SceneRepository.search(SceneSearchCriteria(statuses: {Active}))` で全てのアクティブな Scene を取得
  2. 各 Scene に対して以下の操作を順次実行：
     - `scene.removeFastestParallaxLayer()`: 最も速い `speedRatio` を持つパララックスレイヤーを削除（`SceneUpdated` イベント発火）
     - `scene.reduceParallaxSpeed(reductionRatio: 0.5)`: 残りの全パララックスレイヤーの速度を 50% に減速（`SceneUpdated` イベント発火）
  3. 各 Scene を `SceneRepository.persist(scene)` で永続化
- この処理により、レンダリング負荷を軽減し、パフォーマンス基準内に収める。
# ユースケース UC09: テレメトリウィンドウのローテーション（システム）

## 外部設計

### 目的
- オプトインしたユーザーの利用統計を一定期間でローテーションし、匿名性・保管期限・パフォーマンス基準を維持する。

### アクター
- メインアクター：Telemetry 境界（UsageMetrics 集約）
- サポートアクター：BatchUploader（インフラ層）、PerformanceMonitor、Notification 境界

### 事前条件
- `UsageMetrics.optIn == true`（テレメトリ送信が許可されている）。
- 現在の `MetricsWindow` が満了時刻に近い。

### トリガー
- スケジューラが 24 時間ごとに `TelemetryRotationJob` を起動し、`UsageMetrics.rotateWindow(now)` を呼び出す。

### 基本フロー
1. `UsageMetrics.rotateWindow(now)` が旧ウィンドウのイベントを抽出し、新しい `MetricsWindow` を開始する。結果として `TelemetryWindowRotated` イベントが発火する。
2. `TelemetryBatchUploadService` がイベントを受け取り、匿名化済みデータを `TelemetryBatchUploader`（インフラ層）へ渡してバックエンドまたはローカルファイルへ送信する。
3. 送信成功後、`UsageMetrics` が旧イベントをクリアし、保持期間（30 日）を超えないよう `purgeOldEvents` を実行する。
4. 直近の `PerformanceSnapshot` をチェックし、CPU/メモリが閾値を超えていれば `PerformanceBudgetExceeded` を発火して UI／Scene 境界へ警告する。

### 代替フロー
- **オプトアウト**：`optIn == false` の場合、`rotateWindow` は即座にイベントを破棄し、送信処理をスキップする。
- **遅延送信**：ネットワーク不通時はインフラ層がローカルに一時保存し、次回ローテーションで再送を試みる。

### 例外フロー
- **送信失敗**：バッチ送信が失敗した場合、最大 3 回再試行。すべて失敗したときは `UsageMetrics` にリトライフラグを付与し、次回ローテーションまで旧イベントを保持する。
- **データ破損**：送信前に JSON が破損している場合、破損データを破棄して新しいウィンドウを開始し、監査ログへ記録する。

### 事後条件
- `UsageMetrics` のイベントが整理され、保持期間ルールを満たした状態で新しいウィンドウが開始する。
- `PerformanceBudgetExceeded` により、UI や QA チームがリソース状況を把握できる。

## 内部設計

### 関連ドメインモデル

#### UsageMetrics（telemetry）
- 概要：ユーザーごとのテレメトリ設定・メトリクスを保持する集約。
- 主な振る舞い：
  - `rotateWindow(now)`：新しい `MetricsWindow` を生成し、旧イベントを戻り値として返す。
  - `purgeOldEvents(threshold)`：指定日時より古いイベントを破棄する。

#### MetricsWindow（telemetry）
- 概要：テレメトリ収集期間を表す値オブジェクト。
- 役割：開始・終了時刻を保持し、`next(now)` で次ウィンドウを生成する。

#### TelemetryBatchUploadService（ユースケース層）
- 概要：ローテーション結果をインフラ層へ送信し、成功時に `UsageMetricsRepository.persist` を行う。
- 連携：送信失敗時にリトライ戦略とローカルキャッシュを管理。

#### PerformanceMonitor（telemetry）
- 概要：`PerformanceSnapshot` を解析し、閾値超過時に `PerformanceBudgetExceeded` を発火するサービス。
- 連携：Scene 境界や Notification 境界がイベントを購読して演出抑制・警告表示を行う。

### データフロー
1. スケジューラが `UsageMetricsRepository.current()` を取得し、`rotateWindow(now)` を実行。
2. 旧イベントが `TelemetryWindowRotated` としてイベントバスへ送出され、`TelemetryBatchUploadService` が送信処理を実行。
3. 送信成功時に `UsageMetricsRepository.persist(metrics)` を呼び、`purgeOldEvents` で保持期間を調整。
4. `PerformanceMonitor` が `PerformanceSnapshot` を評価し、必要であれば `PerformanceBudgetExceeded` を発火して Scene/Notification 境界へ通知する。
