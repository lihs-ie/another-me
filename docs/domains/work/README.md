# work パッケージ モデル

このパッケージはポモドーロタイマーのリアルタイム制御と履歴管理を担い、要件定義書の「ポモドーロタイマー」および「状態遷移」セクションに準拠する。

## モデル方針
- 設定スナップショットは profile パッケージの `PomodoroPolicy` 値オブジェクトから受け取り、セッション内で改変しない。
- タイマー精度（±1 秒）、無効遷移の禁止、スキップ/一時停止/再開の順序維持を集約内の不変条件で保証する。
- セッション完了後は履歴（SessionLog）に確定値として永続化し、Append-only を守る。

## PomodoroSession 集約

#### PomodoroSessionIdentifier （ポモドーロセッション識別子／値オブジェクト）
- 目的：進行中または履歴のポモドーロセッションを一意に識別する。
- フィールド：
  - `value`: ULID 文字列（26 文字）
- 不変条件：
  - `value` は ULID フォーマット（`[0-7][0-9A-HJKMNP-TV-Z]{25}`）に一致する。
- 振る舞い：
  - **新規生成できる(generate)**
    - 入力：なし
    - 出力：`PomodoroSessionIdentifier`
    - 副作用：なし

#### PomodoroSessionStatus （セッション状態／値オブジェクト：列挙）
- フィールド：`Idle` / `Running` / `Paused` / `Completed`（列挙）
- 不変条件：列挙値以外は許容しない。

#### PomodoroSession （ポモドーロセッション／集約）
- 目的：作業/休憩/長休憩フェーズの状態遷移と残時間を一貫して管理する。
- フィールド：
  - `identifier`: `PomodoroSessionIdentifier`
  - `status`: `PomodoroSessionStatus`（セッション状態）
  - `phase`: `SessionPhase`（現在のフェーズ）
  - `remainingTime`: `RemainingTime`（現在フェーズの残り時間）
  - `elapsedCycles`: `int`（完了済み作業フェーズ数）
  - `policySnapshot`: `PomodoroPolicySnapshot`
  - `phaseHistory`: `List<PhaseHistory>`（フェーズ履歴リスト）
  - `lastTickAt`: `DateTime`（前回 tick 実行時刻）
- 不変条件：
  - `policySnapshot` 内の時間は 1〜120 分、`longBreakEvery >= 1` または `longBreakEnabled` が false。
  - `status` と `phase` の組み合わせは定義済み遷移に従う（無効遷移禁止）。
  - `remainingTime.ms >= 0` かつ フェーズ持ち時間以内。
  - `elapsedCycles >= 0` であり、作業フェーズ完了数と一致する。
  - `lastTickAt` と現在時刻の差が 2 秒を超える場合はスリープ復帰と判定し、差分を補正する（負値にならない）。
  - `phaseHistory` は Append-only で、過去のフェーズ記録は変更しない。
- 振る舞い：
  - **セッションを開始する(start)**
    - 入力：`policySnapshot: PomodoroPolicySnapshot`, `startedAt: DateTime`
    - 処理：セッションを開始し、Work フェーズに遷移する
    - 出力：なし
    - 副作用：
      - `status` を `Running` に設定
      - `phase` を `Work` に設定
      - `remainingTime` を `policySnapshot.workMinutes` から計算（ms 単位）
      - `lastTickAt` を `startedAt` に設定
      - `elapsedCycles` を 0 に初期化
      - `PomodoroPhaseStarted` イベントを発行
    - 不変条件検証：
      - `status` が `Idle` であることを確認（二重開始の防止）
      - `policySnapshot` の各値が範囲内（1-120分、longBreakEnabled による条件）
  - **セッションを一時停止する(pause)**
    - 入力：`pausedAt: DateTime`
    - 処理：セッションを一時停止する
    - 出力：なし
    - 副作用：
      - `status` を `Paused` に設定
      - `lastTickAt` を `pausedAt` に更新（再開時の補正基準）
    - 不変条件検証：
      - `status` が `Running` であることを確認
      - `phase` が `Work` / `Break` / `LongBreak` のいずれかであることを確認（`Idle` / `Completed` からは不可）
  - **セッションを再開する(resume)**
    - 入力：`resumedAt: DateTime`
    - 処理：一時停止中のセッションを再開する
    - 出力：なし
    - 副作用：
      - `status` を `Running` に設定
      - `lastTickAt` を `resumedAt` に更新
    - 不変条件検証：
      - `status` が `Paused` であることを確認
  - **現在フェーズをスキップする(skip)**
    - 入力：`skippedAt: DateTime`
    - 処理：現在のフェーズをスキップし、次フェーズに遷移する
    - 出力：なし
    - 副作用：
      - `phaseHistory` に現在フェーズを記録（`skipped: true`）
      - `PomodoroPhaseCompleted` イベント（`skipped: true`）を発行
      - `completePhase` と同じロジックで次フェーズに遷移
      - `PomodoroPhaseStarted` イベントを発行
    - 不変条件検証：
      - `status` が `Running` であることを確認
  - **タイマーを進行させる(tick)**
    - 入力：`currentTime: DateTime`
    - 処理：タイマーを進行させ、フェーズ完了を検出する
    - 出力：フェーズが完了した場合 `true`、継続中は `false`
    - 副作用：
      - `currentTime - lastTickAt` の差分（`elapsedMs`）を計算
      - `elapsedMs` が 2000ms を超える場合はスリープ復帰と判定
      - `remainingTime.subtract(elapsedMs)` で残り時間を減算
      - `lastTickAt` を `currentTime` に更新
      - `remainingTime.isExpired()` が `true` の場合、`completePhase` を呼び出す
    - 不変条件検証：
      - `status` が `Running` であることを確認
      - `remainingTime` が負値にならないよう 0 にクランプ（`RemainingTime.subtract` 内で実施）
  - **フェーズを完了する(completePhase)**
    - 入力：`completedAt: DateTime`
    - 処理：現在のフェーズを完了し、次フェーズに遷移する
    - 出力：なし
    - 副作用：
      - `phaseHistory` に現在フェーズを記録（`skipped: false`）
      - `phase` が `Work` の場合、`elapsedCycles` を +1
      - 次フェーズを決定：
        - `policySnapshot.longBreakEnabled` が `true` かつ `elapsedCycles % longBreakEvery == 0` の場合、`LongBreak` へ
        - それ以外は `Work` → `Break` → `Work` のサイクルを継続
      - `PomodoroPhaseCompleted` イベントを発行
      - 次フェーズが存在する場合、`PomodoroPhaseStarted` イベントを発行
      - 全サイクル完了の場合、`status` を `Completed` に設定し、`PomodoroSessionCompleted` イベントを発行
    - 不変条件検証：
      - `status` が `Running` であることを確認
      - `remainingTime.isExpired()` が `true` であることを確認

#### SessionPhase （フェーズ区分／値オブジェクト：列挙）
- フィールド：`Work` / `Break` / `LongBreak` / `Idle`（列挙）
- 不変条件：列挙値以外は許容しない。次フェーズ決定ロジックを提供。

#### PomodoroPolicySnapshot （ポリシー参照／値オブジェクト）
- フィールド：
  - `workMinutes`: `int`（1〜120）
  - `breakMinutes`: `int`（1〜120）
  - `longBreakMinutes`: `int`（1〜120）
  - `longBreakEvery`: `int`（1 以上）
  - `longBreakEnabled`: `bool`
- 不変条件：
  - `workMinutes`、`breakMinutes`、`longBreakMinutes` は 1〜120 の範囲内。
  - `longBreakEvery >= 1`。
  - `longBreakEnabled` が `false` の場合、`longBreakEvery` と `longBreakMinutes` は無視される。
  - いずれの値もセッション中に変更しない。

#### PhaseDuration （フェーズ所要時間／値オブジェクト）
- フィールド：
  - `phase`: `SessionPhase`
  - `totalMs`: `int`（フェーズに応じたミリ秒）
- 不変条件：`totalMs` は `policySnapshot` から導出され、任意の値を入れない。

#### RemainingTime （残り時間／値オブジェクト）
- フィールド：
  - `ms`: `int`（ミリ秒）
- 不変条件：`ms >= 0`。減算時は 0 にクランプして負値にならないようにする。
- 振る舞い：
  - **残り時間を減算する(subtract)**
    - 入力：`elapsedMs: int`
    - 処理：経過時間を減算し、0 未満の場合は 0 にクランプする
    - 出力：`RemainingTime`
    - 副作用：なし
  - **残り時間が切れたか判定する(isExpired)**
    - 入力：なし
    - 処理：`ms == 0` の場合 `true`、それ以外は `false` を返す
    - 出力：`bool`
    - 副作用：なし
  - **残り時間を分単位に変換する(toMinutes)**
    - 入力：なし
    - 処理：`ms` を分単位に変換する（切り上げ）
    - 出力：`int`
    - 副作用：なし

#### PhaseHistory （フェーズ履歴／値オブジェクト）
- フィールド：
  - `phase`: `SessionPhase`
  - `startedAt`: `DateTime`
  - `endedAt`: `DateTime`
  - `skipped`: `bool`
- 不変条件：`startedAt < endedAt`。Append-only で記録。

#### ドメインイベント
- `PomodoroPhaseStarted`
  - 役割：ポモドーロセッションの新しいフェーズが開始したことを通知する。
  - フィールド：`identifier: PomodoroSessionIdentifier`, `phase: SessionPhase`, `startedAt: DateTime`, `remainingTime: RemainingTime`
- `PomodoroPhaseCompleted`
  - 役割：フェーズが完了したことを通知する。
  - フィールド：`identifier: PomodoroSessionIdentifier`, `phase: SessionPhase`, `actualDuration: Duration`, `skipped: bool`
- `PomodoroSessionCompleted`
  - 役割：セッション全体が完了したことを通知する。
  - フィールド：`identifier: PomodoroSessionIdentifier`, `totalWorkMs: int`, `totalBreakMs: int`, `cycles: int`, `completedAt: DateTime`

#### PomodoroSessionSearchCriteria （ポモドーロセッション検索条件／値オブジェクト）
- 目的：プロフィール単位でアクティブセッションを特定する条件を明示する。
- フィールド：
  - `profile`: `ProfileIdentifier`
  - `status`: `PomodoroSessionStatus`（デフォルト `Running`）
- 不変条件：
  - `profile` は必須
- 振る舞い：
  - **検索条件を生成できる(create)**
    - 入力：`profile`, `status?`
    - 出力：`PomodoroSessionSearchCriteria`
    - 副作用：なし

#### リポジトリ契約
- `PomodoroSessionRepository`
  - `search(criteria: PomodoroSessionSearchCriteria): PomodoroSession`
    - 検索条件に一致するセッションが見つからない場合は `AggregateNotFoundError` を投げる
  - `persist(session: PomodoroSession): void`
  - `terminate(identifier: PomodoroSessionIdentifier): void`

## SessionLog 集約

### 目的
- 完了済みセッションの監査ログと統計用データソースを提供する。
- Append-only ポリシーを守り、後追い修正を禁止する。

#### SessionLogIdentifier （セッションログ識別子／値オブジェクト）
- 目的：完了済みセッションログを一意に識別する。
- フィールド：
  - `value`: ULID 文字列（26 文字）
- 不変条件：
  - `value` は ULID フォーマット（`[0-7][0-9A-HJKMNP-TV-Z]{25}`）に一致する。
- 振る舞い：
  - **新規生成できる(generate)**
    - 入力：なし
    - 出力：`SessionLogIdentifier`
    - 副作用：なし

#### SessionLog （セッションログ／集約）
- 目的：完了済みセッションの監査ログを保持し、統計に利用する。
- フィールド：
  - `identifier`: `SessionLogIdentifier`
  - `session`: `PomodoroSessionIdentifier`
  - `profile`: `ProfileIdentifier`
  - `startedAt`: `DateTime`
  - `endedAt`: `DateTime`
  - `totalWorkMs`: `int`（ミリ秒）
  - `totalBreakMs`: `int`（ミリ秒）
  - `cycleCount`: `int`
  - `phaseSummaries`: `List<PhaseSummary>`
- 不変条件：
  - `startedAt < endedAt`
  - `totalWorkMs` と `totalBreakMs` は `phaseSummaries` の合計と一致する。
  - `cycleCount` は Work フェーズ完了数と一致する。
  - ログは Append-only（後から書き換えない）。
  - `profile` はログの所有者を示し、必須。

#### PhaseSummary （フェーズ実績／値オブジェクト）
- フィールド：
  - `phase`: `SessionPhase`
  - `actualDurationMs`: `int`
  - `skipped`: `bool`
  - `startedAt`: `DateTime`
  - `endedAt`: `DateTime`
- 不変条件：`startedAt < endedAt`。`actualDurationMs` は期間に一致。

#### WorkBreakRatio （作業休憩比率／値オブジェクト）
- フィールド：
  - `workMs`: `int`
  - `breakMs`: `int`
- 不変条件：いずれも 0 以上。表示用の派生値として扱う。

#### ドメインイベント
- `SessionLogRecorded`
  - 役割：完了済みセッションのログが記録されたことを通知する。
  - フィールド：`identifier: SessionLogIdentifier`, `session: PomodoroSessionIdentifier`, `cycleCount: int`, `totalWorkMs: int`, `totalBreakMs: int`

#### リポジトリ契約
- `SessionLogRepository`
  - `append(log: SessionLog): void`
  - `findRange(profile: ProfileIdentifier, byDateRange: DateRange): List<SessionLog>`
  - `findLatest(profile: ProfileIdentifier, limit: int): List<SessionLog>`

## パッケージ間コラボレーション

### profile パッケージ
- **責務**: ポモドーロタイマーのポリシー設定を work パッケージに提供する。
- **コラボレーション**:
  - `PomodoroPolicy` 値オブジェクト（profile パッケージ）を `PomodoroPolicySnapshot` 値オブジェクト（work パッケージ）に変換してセッション開始時に供給。
  - 変換はアプリケーション層で実行し、work パッケージは profile パッケージに依存しない（Anti-Corruption Layer）。
  - `ProfileIdentifier` は work パッケージが直接参照可能。

### notification パッケージ
- **責務**: ポモドーロセッションのイベントを受信し、通知ルールに従ってデスクトップ通知とメニューバー更新を実行する。
- **コラボレーション**:
  - `PomodoroPhaseStarted` イベントをサブスクライブし、フェーズ開始通知を送信。
    - イベントフィールド: `identifier`, `phase`, `startedAt`, `remainingTime`
    - 通知テンプレートに `{{phaseName}}`, `{{remainingMinutes}}` を埋め込む。
  - `PomodoroPhaseCompleted` イベントをサブスクライブし、フェーズ完了通知を送信。
    - イベントフィールド: `identifier`, `phase`, `actualDuration`, `skipped`
  - `PomodoroSessionCompleted` イベントをサブスクライブし、セッション完了通知を送信。
    - イベントフィールド: `identifier`, `totalWorkMs`, `totalBreakMs`, `cycles`, `completedAt`

### media パッケージ
- **責務**: ポモドーロフェーズ遷移時に楽曲を再生・停止し、フェードイン/アウトを制御する。
- **コラボレーション**:
  - `PomodoroPhaseStarted` イベントをサブスクライブし、フェーズに応じた楽曲を再生開始。
    - フェードイン時間は楽曲メタデータまたは設定から取得（work パッケージは関与しない）。
  - `PomodoroPhaseCompleted` イベントをサブスクライブし、楽曲をフェードアウトして停止。
    - フェードアウト時間は楽曲メタデータまたは設定から取得（work パッケージは関与しない）。
  - フェーズスキップ時（`skipped: true`）は即座に停止し、次フェーズの再生を開始。

### scene パッケージ
- **責務**: ポモドーロフェーズ遷移時にシーンアニメーションを制御する。
- **コラボレーション**:
  - `PomodoroPhaseStarted` イベントをサブスクライブし、フェーズに応じたシーンアニメーションを開始。

### avatar パッケージ
- **責務**: ポモドーロフェーズ遷移時にキャラクターアニメーションを制御する。
- **コラボレーション**:
  - `PomodoroPhaseStarted` イベントをサブスクライブし、フェーズに応じたキャラクターアニメーションを開始。
  - コーヒーモーション挿入タイミングは avatar パッケージまたはプレゼンテーション層で制御する（work パッケージは関与しない）。
