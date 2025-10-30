# ユースケース UC04: キャラクターと背景を選択する

## 目的
- ユーザーが作業中の相棒キャラクターと背景シーンを切り替え、時間帯に応じた衣装や演出を楽しむ。

## アクター
- メインアクター：ユーザー
- サポートアクター：アプリ（Character ・Scene 集約、UserProfile）

## 事前条件
- アセットカタログに最低 1 体のキャラクターと 1 つの背景が利用可能な状態で登録されている。
- 無料プランの場合は使用可能なキャラクター数に制限がある。

## トリガー
- 設定画面またはメニューバーパネルでキャラクター/背景を選択する操作を行う。

## 基本フロー
1. アプリが一覧から利用可能なキャラクター（Character.status=Active）と背景（Scene.status=Active）を表示する。表示用のタイムラインやアトラス詳細は、選択時に library の `AnimationBindingManifest.extractMetadata()` から取得する。
2. ユーザーがキャラクターを選択すると、`UserProfile.selectedCharacterIdentifier` が更新される。
3. 同様に背景を選択すると、`UserProfile.selectedSceneIdentifier` が更新される。ウィンドウサイズに応じて `Scene.characterAnchor` と整数スケールが再計算され、キャラクター位置が自然に保たれる。
4. DayPeriod に連動して `WardrobeMap` が参照する `animationBindingIdentifier` のマニフェストを取得し、キャラクター衣装とアトラス差分を適用する。
5. 設定が保存され、次回起動時も同じ組み合わせで復元される。

## 代替フロー
- **手動衣装切替**: ユーザーが outfitMode を Manual に設定した場合、朝/昼/夜それぞれの衣装を手動で選択できる。
- **無料枠制限**: 無料プランで利用できるキャラ数（2 体）を超える場合、アップグレード案内を表示する。

## 例外フロー
- **アセット更新**: AssetCatalog が更新され、選択中のキャラクターが Deprecated になった場合、フォールバック用の別キャラクターに自動切り替える。
- **依存ファイル欠落**: 必要なアニメーションファイルが読み込めない場合、デフォルトキャラクターに戻し、ユーザーへエラーメッセージを表示する。

## 事後条件
- `UserProfile` に選択結果が保存され、メイン画面の表示とアニメーションに即時反映される。
- `CharacterUpdated` / `SceneUpdated` イベントを購読する UI が自動アップデートする。

## 内部設計（アプリケーション層）

### Scene の生成と検証
- Scene の初期登録時（アセットカタログからの読み込み時など）は、`SceneFactory.create()` を使用して生成する。
- `SceneFactory` は以下の検証を行う：
  1. `AnimationBindingRepository.find(animationBinding.binding)` で `AnimationBindingManifest` を取得
  2. manifest が 24fps ループ仕様であるか検証
  3. manifest が `tags=ambient` を含むか検証
  4. manifest の `validFrames` が 96 / 192 など定義済み倍数であるか検証
- 検証に失敗した場合は例外を発し、Scene の生成を中止する（該当 Scene は利用不可とマークされる）。

### Scene 選択時の処理
- ユーザーが背景を選択する際は、`SceneRepository.search(criteria)` で `Scene.status=Active` のシーンのみを表示する。
- Scene の表示用メタデータ（プレビュー画像、アトラス座標など）は `AnimationBindingManifest.extractMetadata()` を通じて library ドメインから取得する。
# ユースケース UC04: キャラクターと背景を選択する

## 外部設計

### 目的
- ユーザーが相棒キャラクターと背景シーンを切り替え、時間帯や衣装モードに応じた演出を体験できるようにする。

### アクター
- メインアクター：ユーザー
- サポートアクター：アプリ（Avatar・Scene・Profile 境界、Billing 境界の権利チェック）

### 事前条件
- アセットカタログに `Character.status=Active` のキャラクターと `Scene.status=Active` の背景が少なくとも 1 つずつ存在する。
- プロファイルが有効（`UserProfile.isDefault=true`）で、`EntitlementService` が現在のキャラクター上限を提供できる。

### トリガー
- 設定画面またはメニューバーパネルでキャラクター／背景切替操作を行う。

### 基本フロー
1. アプリが `CharacterRepository.search(criteria)` と `SceneRepository.search(criteria)` を通じて有効な候補を取得し、一覧に表示する。キャラクター一覧には `Character.status`, `WardrobeMap` 情報、時間帯別プレビューを含める。
2. ユーザーがキャラクターを選択すると、ユースケース層が `EntitlementService.canUseCharacter(currentActiveCount)` を呼び出し、上限内であることを確認する。許可された場合のみ `UserProfile.changeCharacter(characterIdentifier)` を実行する。
3. 背景を選択すると `UserProfile.changeScene(sceneIdentifier)` が呼ばれ、Scene 境界から取得した `SceneLayout` に基づきウィンドウスケール・アンカーが再計算される。
4. `PomodoroPhaseStarted` / DayPeriod 変更のタイミングで avatar 境界が `WardrobeMap` を参照し、時間帯に合った衣装へ自動切替する。ユーザーが outfitMode を Manual に設定している場合は、選択中の衣装を維持する。
5. 設定完了後、`UserProfileRepository.persist` が新しい `AppearanceSettings` を保存し、次回起動時にも復元される。UI は `UserProfileUpdated` / `ThemeChanged` イベントを受けて即時反映する。

### 代替フロー
- **手動衣装切替**：ユーザーが outfitMode を Manual に変更すると、朝・昼・夜の衣装スロットが解放され、各スロットで `Character.changeWardrobe` の検証を通過した衣装のみ選択可能になる。
- **無料枠制限**：無料プランで上限（例：2 体）に達している場合、`canUseCharacter` が `false` を返し、アップグレード案内モーダルを表示する。
- **Scene モバイル互換表示**：将来モバイル向け UI でビューが切り替わった場合、Scene 境界が `SceneProjection` を提供し、ユースケース層が適切なレイアウトへ切り替える。

### 例外フロー
- **アセット廃止**：`CharacterDeprecated` または `SceneDeprecated` が発火した場合、`UserProfile` が自動的にフォールバック候補（`Character.fallbackIdentifier` 等）へ切替える。
- **依存ファイル欠落**：必要なアトラス/アニメーションが読み込めない場合、Avatar 境界が `CharacterLocked` 状態に遷移し、デフォルトキャラクターへ置換した上でエラーメッセージを表示する。
- **権利確認失敗**：`EntitlementService` から上限値が取得できない場合はキャラクターリストを非表示にし、「権利情報を確認できませんでした」と通知する。

### 事後条件
- `UserProfile.appearance` が更新され、メイン画面のキャラクター／背景表示に即反映される。
- `UserProfileUpdated`, `ThemeChanged`, `WardrobeChanged` などのイベントを購読する UI・シーン・アバターサブシステムが最新状態に同期する。

## 内部設計

### 関連ドメインモデル

#### UserProfile（profile）
- 概要：ユーザーの外観設定・言語・再生ポリシーを保持する集約。
- 使用振る舞い：
  - `changeCharacter(characterIdentifier)`
  - `changeScene(sceneIdentifier)`
  - `changeOutfit(outfitMode)`
- 不変条件：選択先のキャラクター／シーンが `Active` であり、ライセンス・権利上使用可能であること。

#### Character（avatar）
- 概要：必須アニメーションと時間帯別衣装マップを管理する集約。
- 使用箇所：キャラクター一覧表示、衣装切替、フォールバック判定。
- 重要フィールド：`wardrobes: WardrobeMap`, `bindings: CharacterAnimationBinding`, `status: CharacterStatus`。

#### Scene（scene）
- 概要：背景アニメーション、整数スケール、キャラクターアンカーを保持する集約。
- 使用箇所：背景一覧表示、画面サイズ変化時のレイアウト計算。

#### EntitlementService（billing）
- 概要：現在のキャラクター上限を照会するサービス。
- ユースケース利用箇所：キャラクター選択前の上限確認、UI 表示用の残り利用枠の提示。

#### ProfileRepository / CharacterRepository / SceneRepository
- 概要：各集約の永続化と検索を担うリポジトリ。
- 留意点：`CharacterRepository.search` は `status=Active` のみを返し、Deprecated を除外する。

### データフロー
1. ユーザー操作によりユースケース層が `CharacterRepository.search` / `SceneRepository.search` を呼び出し、候補一覧を取得。
2. キャラクター選択時に `EntitlementService.canUseCharacter` を呼んで上限判定。`true` の場合は `UserProfile.changeCharacter` → `ProfileRepository.persist` を実行。
3. Scene 選択時は `UserProfile.changeScene` を呼び、Scene 境界から `SceneLayout` を取得して表示を更新。
4. 変更完了後、`UserProfileUpdated` と必要な avatar/scene イベントが発火し、UI・アニメーションが最新状態に同期する。
