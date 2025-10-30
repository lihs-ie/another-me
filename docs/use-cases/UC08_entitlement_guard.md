# ユースケース UC08: 権利上限チェックと自動調整（システム）

## 外部設計

### 目的
- プラン変更や利用状況の更新に応じて、楽曲数・キャラクター数の上限を自動検証し、超過リソースを安全に制御する。

### アクター
- メインアクター：Billing 境界（Entitlement 集約および EntitlementService）
- サポートアクター：Media 境界、Avatar 境界、Profile 境界、Notification 境界

### 事前条件
- `Subscription` が直近の検証結果（`status`, `expiresAt`, `offlineGracePeriod`）で同期済み。
- `Entitlement` が現在のプラン（`PlanLimit`）と使用数（`EntitlementUsage`）を保持している。

### トリガー
- ユーザーがプランをアップグレード / ダウングレードする、またはサブスクリプションが期限切れになる。
- `TrackRegistered` / `TrackDeprecated` / `CharacterUnlocked` / `CharacterDeprecated` など、使用数に影響するドメインイベントが発生する。

### 基本フロー
1. `PlanUpdated` または `SubscriptionStatusChanged` イベントが発火すると、ユースケース層が `EntitlementRepository.find` で該当 `Entitlement` を取得し、`Entitlement.syncWithPlan(planIdentifier, planLimit)` を呼び出す。結果として `EntitlementUpdated` が発火し、`version` がインクリメントされる。
2. 利用状況イベントを受けた `MediaUsageSubscriber` / `AvatarUsageSubscriber` が `Entitlement.adjustUsage(tracksDelta, charactersDelta, sequenceNumber)` を実行し、使用数を更新する。`sequenceNumber` はイベントストアが単調増加で付与し、再送を無視できるようにする。
3. `adjustUsage` の結果、上限を超過した場合は `EntitlementRestricted` が発火し、超過種別（`OverLimitType`）と現在の使用数が通知される。同時に `status` が `Restricted` に遷移する。
4. `EntitlementRestricted` を受けた Profile 境界が、超過分を解消するための候補（プレイリストから削除、キャラクターをロック）を生成し、ユーザーに選択肢を提示する。ユーザーが確定した内容をもとに Media / Avatar 境界がリソースの削除・無効化を行う。
5. 調整後、Profile 境界が結果を通知（Notification 境界経由）し、再度 `Entitlement.adjustUsage` を呼び出して実際の使用数と一致させる。問題が解消されると `EntitlementUpdated` が発火し、`status` が `Active` に戻る。

### 代替フロー
- **オフライン猶予内の利用**: `Subscription.canUseOffline(now)` が `true` の場合は `Entitlement.syncWithPlan` で `PlanLimit` を維持し、`EntitlementService` からは従来通りの上限値が返る。猶予切れ（`false`）になった時点で無料プラン相当に再計算される。
- **上限緩和**: アップグレードで上限が増えた場合、`Entitlement.syncWithPlan` が `PlanLimit` を更新するだけで `EntitlementRestricted` は発火しない。Profile 境界は通知で「制限が解除されました」を案内する。
- **読み込み遅延**: Media/Avatar 境界が使用数を即座に取得できない場合、UI 上に「権利確認中...」を表示しつつ `EntitlementService.getTrackLimit()` / `getCharacterLimit()` で暫定情報を表示する。

### 例外フロー
- **使用数再計算エラー**: プレイリスト/キャラクターの実数取得に失敗した場合、最大 3 回リトライし、それでも失敗した場合は `EntitlementQuotaAdjusted` とともに警告通知を行う。`Entitlement` の状態は `Restricted` のままとし、ユーザーに後で再試行を促す。
- **sequenceNumber 競合**: 過去のイベントが遅延して到着した場合、`sequenceNumber <= lastProcessedSequenceNumber` と判定され無視される。イベントハンドラは監査ログに「遅延・破棄」を記録する。
- **権利情報取得不可**: `EntitlementRepository.find` が失敗した場合、ユースケース層が `AggregateNotFoundError` を通知し、利用不可状態として UI をロックする。

### 事後条件
- `Entitlement` と `EntitlementUsage` が上限以内に収まり、状態が `Active` または `Restricted` のいずれかで正しく反映される。
- Profile / Media / Avatar 境界が調整結果を反映し、ユーザー通知に履歴が残る。

## 内部設計

### 関連ドメインモデル

#### Entitlement（billing）
- 概要：利用可能な上限（`limits`）と実際の使用数（`usage`）を管理する集約。
- 使用振る舞い：
  - `syncWithPlan(planIdentifier, planLimit)`：プラン変更に合わせて上限を再計算し、`EntitlementUpdated` を発火。
  - `adjustUsage(tracksDelta, charactersDelta, sequenceNumber)`：イベントに基づいて使用数を更新し、超過時に `EntitlementRestricted` を発火。
- 注意点：`sequenceNumber` をトラック用・キャラクター用に分けて保持し、冪等性を保証する。

#### EntitlementService（billing）
- 概要：他境界（media / avatar）がリソース追加前に上限可否を照会するためのインターフェース。
- 役割：ユーザー操作時は `canAddTrack` / `canUseCharacter` で事前チェックを行い、超過時は `EntitlementLimitExceededError` を返す。

#### Subscription（billing）
- 概要：購読状態とオフライン猶予を管理し、`SubscriptionStatusChanged` を通じて Entitlement に影響を与える。
- 使用箇所：猶予期間の判定、`Plan` と `Entitlement` の同期トリガー。

#### MediaUsageSubscriber / AvatarUsageSubscriber（billing）
- 概要：`TrackRegistered` / `CharacterUnlocked` 等を受信し、`Entitlement.adjustUsage` を呼び出す。
- 留意点：各イベントに付与された `sequenceNumber` を使用し、遅延イベントを安全にスキップする。

#### ProfileAdjustmentUseCase（profile）
- 概要：`EntitlementRestricted` を受け取り、ユーザーが削除・退避する候補を提示する。
- フロー：候補確定後に Media / Avatar のリポジトリを操作し、結果を Notification 境界へ送る。

### データフロー
1. プラン変更イベント → `Entitlement.syncWithPlan` → `EntitlementUpdated` / `EntitlementQuotaAdjusted`。
2. リソース利用イベント → `Entitlement.adjustUsage` → （必要に応じて）`EntitlementRestricted`。
3. `EntitlementRestricted` → Profile 境界で調整 → Media / Avatar で削除/ロック → `Entitlement.adjustUsage` の再計測。
4. 最終的に `EntitlementUpdated` が発火し、UI と `EntitlementService` が最新状態を参照できるようになる。
