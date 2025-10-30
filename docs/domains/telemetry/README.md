# telemetry パッケージ モデル

開発者向けのパフォーマンス監視と、ユーザーの明示的オプトインによる利用統計を管理する。要件の「テレメトリ/ログ（任意オプトイン）」に基づく。

## モデル方針

- パフォーマンス監視（performance）と利用統計（usage）を明確に分離する。
- performance: ユーザーとは無関係に常時動作し、リアルタイム最適化のために使用。
- usage: ユーザーの明示的なオプトインがある場合のみデータを記録し、匿名化して送信。

## performance サブパッケージ

開発者がアプリケーションのパフォーマンスを監視し、リアルタイムで最適化するためのドメイン。ユーザーとは完全に隔絶されており、オプトインは不要。

### PerformanceMonitorIdentifier （パフォーマンス監視識別子／値オブジェクト）

- 目的：PerformanceMonitor を一意に識別する。
- フィールド：
  - `value`: ULID 文字列（26 文字）
- 不変条件：
  - `value` は ULID フォーマット（`[0-7][0-9A-HJKMNP-TV-Z]{25}`）に一致する。
- 振る舞い：
  - **新規生成できる(generate)**
    - 入力：なし
    - 出力：`PerformanceMonitorIdentifier`
    - 副作用：なし

### PerformanceSnapshot （パフォーマンス統計／値オブジェクト）

- 目的：特定時点でのアプリケーションのパフォーマンス指標を表す。
- フィールド：
  - `averageCPU`: 浮動小数点（%）
  - `averageMemory`: 浮動小数点（MB）
  - `characterFPS`: `FramesPerSecond`（キャラクター描画の FPS、common/frame-rate）
  - `backgroundFPS`: `FramesPerSecond`（背景レンダリングの FPS、common/frame-rate）
  - `capturedAt`: 日時
- 不変条件：
  - `averageCPU >= 0.0 && averageCPU <= 100.0`
  - `averageMemory >= 0.0`
  - `characterFPS` と `backgroundFPS` は `FramesPerSecond` の不変条件に従う
- 振る舞い：
  - なし

### PerformanceMetricType （パフォーマンスメトリック種別／値オブジェクト：列挙）

- 目的：監視対象のパフォーマンス指標の種類を型安全に表現する。
- バリアント：
  - `CPU`: CPU 使用率
  - `Memory`: メモリ使用量
  - `CharacterFPS`: キャラクター描画の FPS
  - `BackgroundFPS`: 背景レンダリングの FPS
- 不変条件：列挙値のみを使用する。
- 振る舞い：
  - なし

### PerformanceThresholds （パフォーマンス閾値／値オブジェクト）

- 目的：パフォーマンス超過を判定するための閾値を定義する。
- フィールド：
  - `cpu`: 浮動小数点（%、デフォルト: 12.0）
  - `memory`: 浮動小数点（MB、デフォルト: 400.0）
  - `character`: `FramesPerSecond`（デフォルト: 30fps、common/frame-rate）
  - `background`: `FramesPerSecond`（デフォルト: 24fps、common/frame-rate）
- 不変条件：
  - `cpu > 0.0 && cpu <= 100.0`
  - `memory > 0.0`
  - `character` と `background` は `FramesPerSecond` の不変条件に従う
- 振る舞い：
  - **デフォルト閾値を生成できる(default)**
    - 入力：なし
    - 出力：`PerformanceThresholds`（CPU: 12.0%, Memory: 400.0MB, Character FPS: FramesPerSecond(30), Background FPS: FramesPerSecond(24)）
    - 副作用：なし
- 備考：
  - characterFpsThreshold FramesPerSecond(30) は FR-CHR-01（キャラクタ描画 30fps 必須）に基づく
  - backgroundFpsThreshold FramesPerSecond(24) は FR-BG-01（背景レンダリング 24fps）に基づく
  - キャラクターと背景で異なる FPS 要件を正しく反映

### PerformanceMonitor （パフォーマンス監視／集約）

- 目的：アプリケーションのパフォーマンスをリアルタイムで監視し、閾値超過時に他ドメインに通知する。
- フィールド：
  - `identifier`: `PerformanceMonitorIdentifier`
  - `currentSnapshot`: `PerformanceSnapshot?`（最新のスナップショット）
  - `thresholds`: `PerformanceThresholds`
- 不変条件：なし
- 振る舞い：
  - **パフォーマンスを記録できる(recordSnapshot)**
    - 入力：`snapshot: PerformanceSnapshot`
    - 出力：なし
    - 副作用：
      - `currentSnapshot` を更新
      - `snapshot.averageCPU` が `thresholds.cpu` を超過している場合、`PerformanceBudgetExceeded` イベントを発火（metric: PerformanceMetricType.CPU, value: snapshot.averageCPU, threshold: thresholds.cpu）
      - `snapshot.averageMemory` が `thresholds.memory` を超過している場合、`PerformanceBudgetExceeded` イベントを発火（metric: PerformanceMetricType.Memory, value: snapshot.averageMemory, threshold: thresholds.memory）
      - `snapshot.characterFPS.value` が `thresholds.character.value` を下回っている場合、`PerformanceBudgetExceeded` イベントを発火（metric: PerformanceMetricType.CharacterFPS, value: snapshot.characterFPS.value, threshold: thresholds.character.value）
      - `snapshot.backgroundFPS.value` が `thresholds.background.value` を下回っている場合、`PerformanceBudgetExceeded` イベントを発火（metric: PerformanceMetricType.BackgroundFPS, value: snapshot.backgroundFPS.value, threshold: thresholds.background.value）
  - **閾値を更新できる(updateThresholds)**
    - 入力：`thresholds: PerformanceThresholds`
    - 出力：なし
    - 副作用：
      - `thresholds` を更新
      - `PerformanceThresholdsUpdated` イベントを発火

### PerformanceMetricsCollector （パフォーマンスメトリクス収集器／ドメインサービス契約）

- 目的：レンダリング層からパフォーマンスメトリクスを収集する。
- 責務：IO 操作をカプセル化し、ドメインモデルが直接レンダリング層に依存しないようにする。
- 振る舞い：
  - **現在のパフォーマンスを取得できる(collect)**
    - 入力：なし
    - 出力：`PerformanceSnapshot`
    - 副作用：なし（インフラ層が実装する）

### ドメインイベント

- `PerformanceBudgetExceeded`
  - 役割：パフォーマンス指標が閾値を超過したことを通知する。
  - フィールド：
    - `monitor: PerformanceMonitorIdentifier`
    - `metric: PerformanceMetricType`
    - `value: double`
    - `threshold: double`
    - `snapshot: PerformanceSnapshot`
- `PerformanceThresholdsUpdated`
  - 役割：パフォーマンス閾値が更新されたことを通知する。
  - フィールド：
    - `monitor: PerformanceMonitorIdentifier`
    - `thresholds: PerformanceThresholds`

### リポジトリ契約

- `PerformanceMonitorRepository`
  - `current(): PerformanceMonitor`（現在のモニターを取得、存在しない場合はデフォルト値を返す）
  - `persist(monitor: PerformanceMonitor): void`
- 備考：
  - シングルトンパターン。常に 1 つの PerformanceMonitor のみ存在
  - `current()` は初回起動時にデフォルトの PerformanceMonitor を生成して返す

## usage サブパッケージ

ユーザーの明示的なオプトインによる利用統計を収集し、開発者が分析するためのドメイン。

### UsageMetricsIdentifier （利用メトリクス識別子／値オブジェクト）

- 目的：利用統計集約を一意に識別する。
- フィールド：
  - `value`: ULID 文字列（26 文字）
- 不変条件：
  - `value` は ULID フォーマット（`[0-7][0-9A-HJKMNP-TV-Z]{25}`）に一致する。
- 振る舞い：
  - **新規生成できる(generate)**
    - 入力：なし
    - 出力：`UsageMetricsIdentifier`
    - 副作用：なし

### EventPayload （イベントペイロード／値オブジェクト）

- 目的：UsageEvent のペイロードデータを型安全に扱い、サイズ制限と型制約を保証する。
- フィールド：
  - `data`: `Map<String, Object>`（プリミティブ型またはそのリストのみ許可、空も許容）
- 不変条件：
  - `data` の各値はプリミティブ型（String, int, double, bool）または `List<プリミティブ型>` のみ
  - リスト型の場合、要素数は 1000 個以内
  - プラットフォーム標準の JSON エンコーディングで測定したバイト数が 5KB（5120 バイト）以内
- 振る舞い：
  - **空のペイロードを生成できる(empty)**
    - 入力：なし
    - 出力：`EventPayload`（data: {}）
    - 副作用：なし
  - **データを取得できる(data getter)**
    - 入力：なし
    - 出力：`Map<String, Object>`（不変）
    - 副作用：なし
- 備考：
  - 実装上は `Map<String, V>` などのジェネリクス型で型安全性を確保すること
  - 起動回数など追加情報を持たないイベントは `empty()` を使用
  - JSON シリアライゼーションはドメイン層の責務ではない。永続化が必要な場合はインフラストラクチャ層で Mapper を実装する

### UsageEventType （利用イベント種別／値オブジェクト：列挙）

- 目的：記録対象のユーザーアクションの種類を型安全に表現する。
- バリアント：
  - `PomodoroSessionStarted`: ポモドーロセッション開始
  - `PomodoroSessionCompleted`: ポモドーロセッション完了
  - `PomorodoSessionPaused`: ポモドーロセッション一時停止
  - `PomodoroPhaseChanged`: フェーズ変更（Work → Break など）
  - `CharacterSelected`: キャラクター選択
  - `SceneSelected`: シーン選択
  - `WardrobeSwitched`: ワードローブ切り替え
  - `MediaPlayed`: メディア再生開始
  - `MediaPaused`: メディア一時停止
  - `PlaylistCreated`: プレイリスト作成
  - `FocusModeActivated`: フォーカスモード有効化
  - `SleepModeActivated`: スリープモード有効化
- 不変条件：列挙値のみを使用する。
- 振る舞い:
  - なし
- 備考：
  - 各バリアントは対応する文字列値を持つ（例: `SessionStarted` → `"session_started"`）
  - 将来的に新しいユーザーアクションが追加される場合は、バリアントを追加する

### UsageEvent （利用イベント／値オブジェクト）

- 目的：ユーザーの利用イベントを匿名化して記録する。
- フィールド：
  - `type`: `UsageEventType`（イベント種別）
  - `payload`: `EventPayload`（匿名化済みデータ）
  - `occurredAt`: 日時
- 不変条件：
  - 個人情報を含めない（実装者の責務）
- 振る舞い：
  - なし

### TelemetryConsentIdentifier （テレメトリ同意識別子／値オブジェクト）

- 目的：テレメトリ同意集約を一意に識別する。
- フィールド：
  - `value`: ULID 文字列（26 文字）
- 不変条件：
  - `value` は ULID フォーマット（`[0-7][0-9A-HJKMNP-TV-Z]{25}`）に一致する。
- 振る舞い：
  - **新規生成できる(generate)**
    - 入力：なし
    - 出力：`TelemetryConsentIdentifier`
    - 副作用：なし

### TelemetryConsentStatus （テレメトリ同意状態／値オブジェクト：列挙）

- 目的：同意状態を表現する。
- バリアント：`optedIn`, `optedOut`
- 不変条件：列挙値のみを使用する。
- 振る舞い：
  - **状態を反転できる(toggle)**
    - 入力：なし
    - 出力：`TelemetryConsentStatus`
    - 副作用：なし
  - **オプトイン判定ができる(isOptedIn)**
    - 入力：なし
    - 出力：真偽値（`optedIn` の場合は `true`、`optedOut` の場合は `false`）
    - 副作用：なし

### TelemetryConsent （テレメトリ同意／集約）

- 目的：プロフィール単位のテレメトリ同意を管理する。
- フィールド：
  - `identifier`: `TelemetryConsentIdentifier`
  - `profile`: `ProfileIdentifier`
  - `status`: `TelemetryConsentStatus`
  - `updatedAt`: 日時
- 不変条件：
  - `updatedAt` は過去または現在の時刻である。
- 振る舞い：
  - **同意状態を変更できる(changeStatus)**
    - 入力：`status: TelemetryConsentStatus`, `changedAt: DateTime`
    - 出力：なし
    - 副作用：
      - `status` と `updatedAt` を更新
      - `TelemetryConsentChanged` イベントを発火（identifier, profile, status, changedAt）

### MetricsWindow （集計期間／値オブジェクト）

- 目的：バッチ送信の単位となる集計期間を識別する。
- フィールド：
  - `range: 日時範囲`
- 不変条件：
  - 期間は最大 7 日以内（1 つのバッチ送信の単位）
- 振る舞い：
  - **期間内判定ができる(includes)**
    - 入力：`timestamp: DateTime`
    - 出力：真偽値
    - 副作用：なし
  - **次のウィンドウを生成できる(next)**
    - 入力：なし
    - 出力：`MetricsWindow`（start から end の差分の新しいウィンドウ）
    - 副作用：なし

### UsageMetrics （利用メトリクス／集約）

- 目的：利用イベントを一定期間で集計し、オプトイン設定を管理する。
- フィールド：
  - `identifier`: `UsageMetricsIdentifier`
  - `window`: `MetricsWindow`
  - `events`: `List<UsageEvent>`（時系列順）
  - `optIn`: 真偽値
- 不変条件：
  - `optIn = false` の場合は `events` は空である。
  - `events` 内のイベントは保持期間（30 日）を超えたデータを含まない。
  - `events` 内のイベントは `occurredAt` の昇順でソートされている。
  - `events` 内のイベントは全て `window` の範囲内（`window.contains(event.occurredAt) == true`）である。
- 振る舞い：
  - **イベントを記録できる(recordEvent)**
    - 入力：`event: UsageEvent`
    - 出力：なし
    - 副作用：
      - `optIn = false` の場合は何もしない
      - `optIn = true` の場合：
        1. `event.occurredAt` が既存イベントの最後の `occurredAt` より前の場合は例外を発する（時系列順を保証）
        2. `window.contains(event.occurredAt)` が false の場合は例外を発する（集計ウィンドウとの整合性を保証）
        3. 保持期間（30 日）を超えた古いイベントを `events` から自動除外
        4. `event` を `events` に追加
        5. `UsageEventRecorded` を発火する
  - **オプトイン設定を変更できる(changeOptIn)**
    - 入力：`status: TelemetryConsentStatus`
    - 出力：なし
    - 副作用：
      - `optIn` を `status.isOptedIn()` に基づいて更新
      - `status` が `TelemetryConsentStatus.optedOut` の場合、`events` をクリア
      - `UsageOptInChanged` イベントを発火（status を添付）
  - **集計ウィンドウを回転できる(rotateWindow)**
    - 入力：`nextWindow: MetricsWindow`
    - 出力：`List<UsageEvent>`（除外された古いイベント）
    - 副作用：
      - `window` を更新
      - 新しいウィンドウの範囲外のイベントを `events` から除外
      - 除外されたイベントのリストを返す
      - `TelemetryWindowRotated` を発火する
  - **古いイベントを削除できる(purgeOldEvents)**
    - 入力：`olderThan: DateTime`
    - 出力：なし
    - 副作用：
      - `olderThan` より古い `events` を削除
      - 削除されたイベント数を含む `EventsPurged` イベントを発火

### ドメインイベント

- `UsageEventRecorded`
  - 役割：利用イベントが記録されたことを通知する。
  - フィールド：
    - `metrics: UsageMetricsIdentifier`
    - `type: UsageEventType`
    - `occurredAt: DateTime`
- `UsageOptInChanged`
  - 役割：オプトイン設定が変更されたことを通知する。
  - フィールド：
    - `metrics: UsageMetricsIdentifier`
    - `status: TelemetryConsentStatus`
- `TelemetryConsentChanged`
  - 役割：テレメトリ同意が更新されたことを通知する。
  - フィールド：
    - `consent: TelemetryConsentIdentifier`
    - `profile: ProfileIdentifier`
    - `status: TelemetryConsentStatus`
    - `changedAt: DateTime`
- `TelemetryWindowRotated`
  - 役割：集計ウィンドウを回転させたことを通知する。
  - フィールド：
    - `metrics: UsageMetricsIdentifier`
    - `previous: MetricsWindow`
    - `current: MetricsWindow`
- `TelemetryEventsPurged`
  - 役割：古いイベントが削除されたことを通知する。
  - フィールド：
    - `metrics: UsageMetricsIdentifier`
    - `purgedCount: int`
    - `olderThan: DateTime`

### リポジトリ契約

- `UsageMetricsRepository`
  - `current(): UsageMetrics`（現在のメトリクスを取得、存在しない場合はデフォルト値を返す）
  - `persist(metrics: UsageMetrics): void`
- `TelemetryConsentRepository`
  - `find(TelemetryConsentIdentifier identifier): TelemetryConsent`
  - `findByProfile(ProfileIdentifier profile): TelemetryConsent`
  - `persist(TelemetryConsent consent): void`
- 備考：
  - UsageMetrics は opt-in 状態のキャッシュとして `optIn` フィールドを保持するが、真偽値のソースオブトゥルースは `TelemetryConsent`
  - `UsageMetricsRepository.current()` は初回起動時にデフォルトの UsageMetrics（optIn: false）を生成して返す

## イベントサブスクライバ

### performance サブパッケージ

- サブスクライバなし
- アプリケーション層の `PerformanceMonitorService` から定期的に `PerformanceMonitor.recordSnapshot` を呼び出す

### usage サブパッケージ

- **TelemetryConsentSubscriber**
  - 目的：`TelemetryConsentChanged` を受けて UsageMetrics の opt-in 状態を同期する。
  - 購読イベント：`TelemetryConsentChanged`（telemetry/usage）。
  - 処理内容：
    1. `TelemetryConsentRepository.find(event.consent)` で同意情報を取得し、イベントと整合しているか確認
    2. `UsageMetricsRepository.current()` を呼び出し、`event.profile` に対応するメトリクスを取得（存在しない場合は例外）
    3. `metrics.changeOptIn(event.status)` を呼び出し
    4. `UsageMetricsRepository.persist(metrics)` で永続化
    5. 発火されたイベント（`UsageOptInChanged`）を EventBroker に publish
  - 発火イベント：`UsageOptInChanged`（UsageMetrics の振る舞いから）
  - 備考：Profile 境界への依存は不要。プロファイル設定画面は `TelemetryConsentService` を介して同意を変更する

## 他パッケージへの影響

### profile パッケージへの変更提案

- なし。テレメトリ同意は telemetry ドメイン内の `TelemetryConsent` で完結させ、UserProfile には新たなフィールドを追加しない。

### scene パッケージへの変更提案

#### イベントサブスクライバ

- **PerformanceBudgetSubscriber**
  - 目的：telemetry/performance の FPS 超過イベントを受けてシーン負荷を調整する。
  - 購読イベント：`PerformanceBudgetExceeded`（telemetry/performance）。
  - 処理内容：
    1. イベントの `metric` フィールドを確認
    2. `metric` が "CharacterFPS" または "BackgroundFPS" でない場合は何もしない（CPU/Memory 超過にはシーン調整を適用しない）
    3. `metric` が "CharacterFPS" または "BackgroundFPS" の場合：
       - `SceneRepository.search(SceneSearchCriteria(statuses: {Active}))` からすべてのアクティブなシーンを取得
       - 各シーンについて：
         - パララックスレイヤーが存在する場合：
           - `removeFastestParallaxLayer()` を呼び出し、最も高い `speedRatio` を持つレイヤーを削除
           - 削除後もパララックスレイヤーが残っている場合、`reduceParallaxSpeed(reductionRatio: 0.5)` を呼び出し、残りのレイヤーの速度を 50% に減速
         - パララックスレイヤーが存在しない場合：何もしない
       - 各シーンを `SceneRepository.persist` で永続化
       - 発火されたイベント（`SceneUpdated`）を EventBroker に publish
  - 発火イベント：`SceneUpdated`（Scene の振る舞いから発火）
  - 備考：
    - CPU/Memory 超過の場合、シーン調整以外の対処（アプリケーション全体の最適化など）が必要
    - FPS 超過のみがシーン描画の負荷調整に該当する
