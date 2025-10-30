# telemetry パッケージ

## 概要

telemetry パッケージは、パフォーマンス監視（performance サブパッケージ）と利用統計（usage サブパッケージ）の2つのサブパッケージに分かれています。

- **performance**: パフォーマンス指標（CPU、メモリ、FPS）をリアルタイムで監視し、閾値超過時に他ドメインに通知します。ユーザーのオプトインは不要です。
- **usage**: ユーザーの利用イベントを記録し、オプトイン時にのみバッチ送信します。個人情報は含まず、匿名化されたデータのみを扱います。

## 永続化戦略

| データ                     | ストア                       | 保存形式                                  |
|----------------------------|------------------------------|-------------------------------------------|
| PerformanceMonitor         | SQLite (`telemetry.db`)      | テーブル `performance_monitor`            |
| PerformanceSnapshot        | メモリのみ（最新のみ保持）   | -                                         |
| TelemetryConsent           | SQLite (`telemetry.db`)      | テーブル `telemetry_consent`              |
| UsageMetrics               | SQLite (`telemetry.db`)      | テーブル `usage_metrics`                  |
| UsageEvent                 | SQLite (`telemetry.db`)      | テーブル `usage_event`                    |

- オプトイン状態が false の場合は UsageEvent を保存しない。
- PerformanceSnapshot は最新のスナップショットのみをメモリに保持し、永続化は行わない（リアルタイム監視のため）。

## 保存形式

### performance_monitor

- `monitor_identifier` TEXT PRIMARY KEY
- `cpu_threshold` REAL
- `memory_threshold` REAL
- `character_fps_threshold` INTEGER
- `background_fps_threshold` INTEGER
- `updated_at` INTEGER

### telemetry_consent

- `consent_identifier` TEXT PRIMARY KEY (ProfileIdentifier の値)
- `status` TEXT ('opted_in' または 'opted_out')
- `updated_at` INTEGER

### usage_metrics

- `metrics_identifier` TEXT PRIMARY KEY
- `window_start` INTEGER
- `window_end` INTEGER
- `opt_in` INTEGER (0/1)
- `updated_at` INTEGER

### usage_event

- `id` INTEGER PRIMARY KEY AUTOINCREMENT
- `metrics_identifier` TEXT
- `event_type` TEXT (UsageEventType の文字列表現、例: 'session_started')
- `payload_json` TEXT（匿名化済み、EventPayload の JSON）
- `occurred_at` INTEGER
- FOREIGN KEY(metrics_identifier) REFERENCES usage_metrics(metrics_identifier)

## リポジトリ実装

### PerformanceMonitorRepository

- `current(): PerformanceMonitor`
  - SQLite から `SELECT * FROM performance_monitor LIMIT 1` で取得
  - 存在しない場合はデフォルトの閾値で新規作成
- `persist(monitor: PerformanceMonitor): void`
  - `INSERT OR REPLACE INTO performance_monitor` で保存
  - PerformanceSnapshot はメモリに保持するのみで永続化しない

### TelemetryConsentRepository

- `find(identifier: ProfileIdentifier): TelemetryConsent`
  - SQLite から `SELECT * FROM telemetry_consent WHERE consent_identifier = ?` で取得
  - 存在しない場合は `AggregateNotFoundError` を投げる
- `persist(consent: TelemetryConsent): void`
  - `INSERT OR REPLACE INTO telemetry_consent` で保存

### UsageMetricsRepository

- `current(): UsageMetrics`
  - SQLite から `SELECT * FROM usage_metrics ORDER BY window_end DESC LIMIT 1` で取得
  - 存在しない場合はデフォルト値（optIn: false）で新規作成
  - UsageEvent を `SELECT * FROM usage_event WHERE metrics_identifier = ? ORDER BY occurred_at ASC` で取得して復元
- `persist(metrics: UsageMetrics): void`
  - `INSERT OR REPLACE INTO usage_metrics` でメトリクス本体を保存
  - `DELETE FROM usage_event WHERE metrics_identifier = ?` で既存イベントを削除
  - `INSERT INTO usage_event` で全イベントを再挿入（時系列順を保証）

## インフラストラクチャ層の責務

### PerformanceMetricsCollector （ドメインサービス実装）

- 目的：レンダリング層からパフォーマンスメトリクスを収集する。
- 実装：
  - Flutter の `SchedulerBinding.instance.currentFrameTimestamp` や `dart:io` の `ProcessInfo` を使用
  - CPU 使用率：プロセスのユーザー時間 + システム時間を計算
  - メモリ使用量：プロセスの物理メモリ使用量を取得
  - キャラクター FPS：キャラクターアニメーションレイヤーのフレームレートを取得
  - 背景 FPS：背景レンダリングレイヤーのフレームレートを取得
- 返却値：`PerformanceSnapshot`（FramesPerSecond 値オブジェクトを使用）

### TelemetryBatchUploader （インフラストラクチャ）

- 目的：UsageEvent のバッチを外部サーバーに送信する。
- 責務：
  1. **JSON シリアライズ**
     - `UsageEvent` のリストを JSON 形式にシリアライズ
     - `EventPayload.toJson()` を使用してペイロードデータを取得
  2. **バッチ送信**
     - 匿名化済みのイベントバッチを外部テレメトリサーバーに HTTP POST
     - リトライ・タイムアウト・エラーハンドリングを実装
- 備考：
  - ペイロードの型検証とサイズ検証は EventPayload 値オブジェクトで完結しているため、インフラ層では実施不要
  - ドメイン層は HTTP 通信の詳細を知らないため、これらの技術的な責務はインフラ層が担う

## 追加メモ

- **データ保持期間**：UsageEvent は 30 日の期限を設け、`TelemetryMaintenanceService` が定期的に古いイベントを削除する。
- **オプトアウト時のデータ削除**：`UsageMetrics.changeOptIn(false)` が呼ばれると、`DELETE FROM usage_event WHERE metrics_identifier = ?` で全イベントを削除する。
- **スキーマバージョン管理**：`telemetry.db` に `schema_version` テーブルを配置し、マイグレーションファイル（例：`migrations/telemetry/001_initial.sql`）を管理する。
- **パフォーマンスデータの取り扱い**：PerformanceSnapshot はリアルタイム監視用のため永続化せず、最新のスナップショットのみをメモリに保持する。
