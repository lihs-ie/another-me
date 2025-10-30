# ユースケース UC01: ポモドーロセッションを開始・完了する

## 外部設計

### 目的
- ユーザーが 25 分作業 / 5 分休憩（またはカスタム設定）で集中サイクルを実行し、その結果を履歴に残す。

### アクター
- メインアクター：ユーザー
- サポートアクター：アプリ（タイマー・通知・アニメーション制御）

### 事前条件
- アプリが起動している。
- `UserProfile` にポモドーロ設定（作業時間/休憩時間/長休憩周期/長休憩有効フラグ）が保存済み。

### トリガー
- ユーザーがメイン画面またはメニューバーパネルで「セッション開始」を選択する。

### 基本フロー
1. アプリが `PomodoroPolicy` を読み出し、`PomodoroPolicySnapshot` を生成して `PomodoroSessionRepository.persist`（状態 `Idle`）に保存する。
2. ユーザー操作により `PomodoroSession.start` が呼ばれ、`PomodoroSessionStatus.Running` / `SessionPhase.Work` でカウントダウンが開始される。キャラクターとシーンは `PomodoroPhaseStarted` イベントで演出を切り替える（コーヒーモーションの挿入間隔は avatar 境界が制御）。
3. 作業フェーズが終了すると `PomodoroPhaseCompleted` が発火し、通知パッケージがデスクトップ通知とメニューバー更新を行う。`PomodoroSession.tick` は `lastTickAt` と現在時刻の差分を補正し、スリープ復帰後も±1秒以内の精度を維持する。
4. 休憩フェーズ完了後、`PomodoroSession` は `longBreakEnabled` が `true` かつ `elapsedCycles % longBreakEvery == 0` の場合のみ `SessionPhase.LongBreak` へ、それ以外は再度 `SessionPhase.Work` へ遷移する。
5. すべての作業フェーズが完了するか、ユーザーが「セッション完了」を選択すると `PomodoroSessionStatus.Completed` となり、`SessionLog.record` によりプロフィール別の履歴が Append される。

### 代替フロー
- **一時停止**: ユーザーが「一時停止」を選択すると `PomodoroSession.pause` が呼ばれ、`status=Paused` のまま残り時間が保持される。再開時は `PomodoroSession.resume` により `status=Running` が復元される。
- **フェーズスキップ**: 休憩が不要な場合、ユーザーが「スキップ」を選択すると `PomodoroSession.skip` が現在フェーズを `PhaseHistory.skipped=true` として記録し、次のフェーズへ即遷移する。

### 例外フロー
- **システムスリープ**: スリープ復帰後 `tick` が呼ばれると、経過時間が 2000ms を超えていても補正をかけて残り時間を 0 未満にしない。補正不能なほど差が大きい場合はセッションを完了扱いにして通知する。
- **強制終了**: アプリが異常終了した場合、`SessionLog` に確定済みの履歴のみが残り、未完了の `PomodoroSession` は次回起動時に `PomodoroSessionRepository.search` で `status=Running` を確認し、ユーザーに再開可否を問い合わせる。

### 事後条件
- `SessionLog` に作業時間・休憩時間・サイクル数がプロフィール単位で保存される。
- キャラクターとシーン演出が `Idle` に戻り、通知キューがクリアされる。

## 内部設計

### 関連ドメインモデル

#### PomodoroSession（work）
- 概要：作業/休憩/長休憩フェーズを管理し、`start` / `pause` / `resume` / `skip` / `tick` / `completePhase` の振る舞いで不変条件（時間範囲、状態遷移）を保証する。
- 入出力：
  - `start(policySnapshot, startedAt)`：`status` と `phase` を初期化し `PomodoroPhaseStarted` を発火。
  - `tick(currentTime)`：差分時間を減算し、フェーズ完了時に `PomodoroPhaseCompleted` / `PomodoroPhaseStarted` を連鎖させる。
  - `skip(skippedAt)`：`PhaseHistory` へスキップ記録を追加し、`PomodoroPhaseCompleted(skipped=true)` を発火。
- 留意点：`longBreakEnabled=false` の場合は常に `Work` ↔ `Break` のみを繰り返す。

#### PomodoroSessionRepository（work）
- 概要：進行中セッションの読み書きを担当するリポジトリ。
- 使用箇所：セッション生成時の初期永続化、一時停止からの再開判定、異常終了後の復旧。

#### SessionLog（work）
- 概要：完了済みセッションを Append-only で蓄積し、`SessionLogRecorded` を発火する。
- 使用箇所：`PomodoroSession` が `Completed` になった際の結果保存。
- 注意事項：`profile: ProfileIdentifier` を必須フィールドとして保持し、計測値が `PhaseSummary` と一致することを検証する。

#### NotificationSubscriber / MediaSubscriber（notification, media, avatar）
- 概要：`PomodoroPhaseStarted` / `PomodoroPhaseCompleted` / `PomodoroSessionCompleted` を購読し、通知や演出を更新する。
- 留意点：コーヒーモーションのスケジュールは avatar 境界が独自に管理し、work 境界はタイミングを保持しない。

### データフロー
1. `UserProfile` から `PomodoroPolicy` を取得し、ユースケース層で `PomodoroPolicySnapshot` に変換する。
2. `PomodoroSession` の状態変更に応じてイベントが発火し、通知・メディア・アバター境界がそれぞれのアクションを実施。
3. セッション完了時に `SessionLog.record` で履歴を永続化し、統計画面が `SessionLogRepository.findRange` を通じて利用する。
