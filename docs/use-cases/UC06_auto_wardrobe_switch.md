# ユースケース UC06: 時間帯による自動衣装切り替え（システム）

## 目的
- アプリが DayPeriod（朝/昼/夜）の変化を検知し、ユーザー操作なしでキャラクターの衣装と背景の光量を切り替える。

## アクター
- メインアクター：システムクロックサービス
- サポートアクター：アプリ（DayPeriodChangedSubscriber, Character/Scene 集約）

## 事前条件
- `UserProfile.outfitMode` が `Auto` に設定されている。
- 選択中キャラクターの `WardrobeMap` が朝・昼・夜すべて定義済み。

## トリガー
- システムクロックが DayPeriod の境界（04:00 / 12:00 / 18:00）を跨ぐ。

## 基本フロー
1. クロックサービスが `DayPeriodChanged` イベント（period を Morning/Noon/Night）として発火する。
2. Avatar パッケージのサブスクライバがイベントを受け取り、`Character` 集約から該当衣装の `animationBindingIdentifier` を取得し、library のマニフェストから描画に必要なフレーム情報を読み込む。
3. UserProfile の `applyOutfit(period)` が呼ばれ、`selectedCharacterIdentifier` の衣装情報が更新される。
4. Scene サブスクライバが同イベントを受け、`SceneAnimationBinding` の識別子を通じてマニフェストを再参照し、必要に応じて照明プロファイル（LightingProfile）を夜間モードへ遷移させる。
5. UI レイヤが `CharacterOutfitApplied` / `SceneLightingChanged` を購読しており、描画を即座に更新する。

## 代替フロー
- **Manual モード**: `outfitMode=Manual` の場合、DayPeriodChanged イベントを受けても衣装は切り替わらず、通知バナーで「現在は手動モードです」と表示する。

## 例外フロー
- **Wardrobe 欠落**: 該当時間帯の衣装が未定義だった場合、デフォルト衣装（morning）にフォールバックし、UsageMetrics に警告を送る。
- **Asset 読み込み失敗**: スプライトが読み込めなかった場合は、直前の衣装を継続し、ログにエラー記録する。

## 事後条件
- `UserProfile` とレンダリングレイヤが新しい衣装・照明設定で同期される。
- イベントが通知パネルに履歴として残り、ユーザーは手動切替に切り替えることもできる。
# ユースケース UC06: 時間帯による自動衣装切り替え（システム）

## 外部設計

### 目的
- DayPeriod（朝/昼/夜）の変化を検知し、ユーザー操作なしでキャラクター衣装と照明演出を自動切り替えする。

### アクター
- メインアクター：システムクロックサービス
- サポートアクター：アプリ（Avatar・Scene・Profile 境界）

### 事前条件
- `UserProfile.outfitMode == OutfitMode.auto`。
- 選択中キャラクターの `WardrobeMap`（morning/noon/night）が定義済み。
- シーンが DayPeriod に応じた `LightingProfile` を提供できる。

### トリガー
- システムクロックが DayPeriod の境界（04:00 / 12:00 / 18:00）を跨ぐ。

### 基本フロー
1. クロックサービスが `DayPeriodChanged(period)` を発火する。通知には `profileIdentifier` と当該 DayPeriod が含まれる。
2. Avatar 境界のサブスクライバがイベントを受け取り、`Character.applyWardrobe(period)` を実行して該当衣装の `CharacterAnimationBinding` を取得し、library 境界のマニフェストを再読込する。
3. Profile 境界の `UserProfile.applyOutfit(period)` が呼び出され、`appearance.outfit` に反映される。変更結果は `UserProfileUpdated` として発火する。
4. Scene 境界のサブスクライバが同イベントを処理し、`Scene.adjustLighting(period)` により `LightingProfile` を適用して夜間の明度・彩度を調整する。
5. プレゼンテーション層が `CharacterOutfitApplied` / `SceneLightingChanged` を購読し、描画を即時更新する。

### 代替フロー
- **Manual モード**：`outfitMode == Manual` の場合は衣装変更をスキップし、通知で「現在は手動モードです」を表示する。
- **過去時刻補正**：スリープ復帰後に複数の DayPeriod を跨いでいた場合、クロックサービスが最新 DayPeriod のみを通知し、Avatar 境界が一括で最新衣装に切り替える。

### 例外フロー
- **Wardrobe 未定義**：対象 DayPeriod の衣装が存在しない場合、`Character.applyWardrobe` がデフォルト（morning）へフォールバックし、Telemetry 境界の `UsageMetricsCollector` に警告を記録する。
- **アセット読み込み失敗**：マニフェストが読み込めなかった場合、直前の衣装を継続し、再試行スケジュールを登録する。

### 事後条件
- `UserProfile`・Avatar・Scene の状態が新しい DayPeriod に同期する。
- イベント履歴に切り替え結果が残り、ユーザーは任意タイミングで手動モードへ切り替え可能。

## 内部設計

### 関連ドメインモデル

#### DayPeriod（common）
- 概要：朝/昼/夜を表す値オブジェクト。クロックサービスが境界判定に利用。

#### UserProfile（profile）
- 概要：外観設定を保持。`applyOutfit(period)` で `AppearanceSettings` を更新し、`UserProfileUpdated` を発火。

#### Character（avatar）
- 概要：`WardrobeMap` を基に `applyWardrobe(period)` を提供し、衣装切替に必要な `CharacterAnimationBinding` を返す。

#### Scene（scene）
- 概要：`LightingProfile` や `SceneLayout` を保持し、`adjustLighting(period)` で昼夜演出を切り替える。

#### DayPeriodChangedSubscriber（avatar/scene アプリケーション層）
- 概要：イベント購読クラス。Avatar と Scene の両境界で DayPeriod 連携を担う。

### データフロー
1. システムクロックが DayPeriod を判定し、イベントバスへ `DayPeriodChanged` を送信。
2. Avatar 境界が衣装切替を行い、Profile 境界を介して `UserProfile` に反映。
3. Scene 境界が `LightingProfile` を切り替え、描画設定を更新。
4. UI 層がイベントを受け、キャラクター／背景描画を最新状態へ更新。
