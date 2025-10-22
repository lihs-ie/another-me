# avatar パッケージ モデル

相棒キャラクターと衣装スケジューリングに関するドメイン。要件の「相棒キャラ体験」「アセット仕様」を満たすため、30fps アニメーションと時間帯別衣装切替を集約で保証する。

## モデル方針

- キャラクターデータは AssetCatalog/AnimationSpec の参照を保持し、仕様違反のアセットを拒否する。
- 時間帯による衣装切替（朝/昼/夜）は `WardrobeMap` 値オブジェクトで定義し、ユーザーが直接編集できない。
- 再生中のアニメーションは library.animation の `AnimationBindingManifest` を `CharacterAnimationBinding` で参照し、typing/coffee の必須モーションの整合性を保つ。
- タイムラインやアトラスの詳細は library パッケージが単一の真実として保持し、avatar では `animationBindingIdentifier` の識別子参照に留める。
- イベントサブスクライバが時間帯変化・ライセンス/課金状態の更新に応じて装備可能キャラクターを制御する。

## Character 集約

### character サブパッケージ

#### CharacterIdentifier （キャラクター識別子／値オブジェクト）

- 目的：キャラクター集約を一意に識別する。
- フィールド：
  - `value`: ULID 文字列（26 文字）
- 不変条件：
  - `value` は ULID フォーマット（`[0-7][0-9A-HJKMNP-TV-Z]{25}`）に一致する。
- 振る舞い：
  - **新規生成できる(generate)**
    - 入力：なし
    - 出力：`CharacterIdentifier`
    - 副作用：なし（ULID を生成して返す）

#### Character （キャラクター／集約）

- 目的：必須アニメーションと衣装セットを備えたキャラクターを管理する。
- フィールド：
  - `identifier`: `CharacterIdentifier`
  - `displayName`: 表示名（文字列）
  - `bindings`: `CharacterAnimationBinding` のリスト
  - `wardrobes`: `WardrobeMap`
  - `palette`: `ColorPalette`
  - `status`: `CharacterStatus`
- 不変条件：
  - `bindings` リストに `tag=typing` と `tag=coffee` のバインディングが必須で含まれている。
  - `bindings` の各 `playbackOrder` はリスト内で一意である。
  - `wardrobes` の `morning`, `noon`, `night` がすべて設定されている。
  - `palette.colors.size <= 24`。
- 備考：
  - `bindings` が参照する `AnimationBindingManifest` の存在や仕様（30fps 等）の検証は、Application 層で行う。
  - `wardrobes` 内の `OutfitVariant` と外部リソースとの整合性検証も、Application 層で行う。
- 振る舞い：
  - **衣装マップを更新できる(updateWardrobe)**
    - 入力：検証済みの `WardrobeMap`
    - 出力：なし
    - 副作用：
      - `wardrobes` を新しい `WardrobeMap` で置き換える
      - `CharacterUpdated` を発火する
    - 備考：
      - 呼び出し側（Application 層）で `WardrobeMap` の整合性検証が完了していることを前提とする
      - 検証には外部リソース（`AnimationBindingManifest` と `SpriteAtlasDefinition`）との整合性チェックが含まれる
  - **キャラクターを廃止できる(deprecate)**
    - 入力：理由（文字列）
    - 出力：なし
    - 副作用：`status` を `Deprecated` に変更し、`CharacterDeprecated` を発火する
  - **キャラクターを解放できる(unlock)**
    - 入力：解放ソース（文字列）
    - 出力：なし
    - 副作用：`status` を `Active` に更新し、`CharacterUnlocked` を発火する

#### CharacterStatus （キャラクターステータス／値オブジェクト：列挙）

- フィールド：列挙（`Active` / `Deprecated` / `Locked`）
- 不変条件：列挙値以外は許容しない。

#### ColorPalette （カラーパレット／値オブジェクト）

- フィールド：
  - `colors`: `Color` のセット
- 不変条件：
  - `colors.size <= 24`。
  - セット特性により、同一 RGBA の `Color` が重複登録されない。

#### Color （カラー／値オブジェクト）

- フィールド：
  - `red`: 赤成分（数値 0〜255）
  - `green`: 緑成分（数値 0〜255）
  - `blue`: 青成分（数値 0〜255）
  - `alpha`: 透過率（数値 0〜255、任意。未指定時は 255）
- 不変条件：
  - 各成分は 0〜255 の自然数（0 を含む）である。
  - `red`, `green`, `blue` のいずれかが同一でも `alpha` が異なる場合は別色として扱うが、完全に同一の RGBA の組が複数存在しない（`ColorPalette.colors` がセットで保持するため重複登録不可）。
- 振る舞い：
  - **RAW 16 進数に変換できる(toRawHex)**
    - 入力：なし
    - 出力：RAW16 進数表記文字列（`#RRGGBBAA`）
    - 副作用：なし
  - **RAW 16 進数表記から自身を生成できる(fromRawHex)**
    - 入力：RAW16 進数表記文字列
    - 出力：自身
    - 副作用：文字列が不正な形式の場合は例外を発する

### animation サブパッケージ

#### CharacterAnimationBindingIdentifier （キャラクターアニメーションバインディング識別子／値オブジェクト）

- 目的：library.animation の `AnimationBindingManifest` を参照するときに使用する識別子。
- フィールド：
  - `value`: ULID 文字列（26 文字）
- 不変条件：
  - `value` は ULID フォーマットに一致する。
- 振る舞い：
  - **新規生成できる(generate)**
    - 入力：なし
    - 出力：`CharacterAnimationBindingIdentifier`
    - 副作用：なし

#### CharacterAnimationBinding （キャラクターアニメーションバインディング／値オブジェクト）

- 目的：library.animation の `AnimationBindingManifest` を参照し、キャラクター固有のメタ情報を紐付ける。
- フィールド：
  - `binding`: `CharacterAnimationBindingIdentifier`
  - `tag`: 利用タグ（列挙：`typing` / `coffee` / `idle` / `preview`）
  - `playbackOrder`: 優先度（数値）
- 不変条件：
  - `binding` は library.animation の `AnimationBindingManifest` に存在する。
  - `tag = typing` の場合、参照先マニフェストは 30fps ループ仕様（library 側で保証）。
  - `tag = coffee` の場合、参照先マニフェストは 30fps 単発かつ `defaultNext = typing`（library 側で保証）。
  - `playbackOrder` はユニークで、低い値ほど優先的に再生される。
- 備考：
  - 詳細なタイムライン・アトラス情報は `AnimationBindingManifest.extractMetadata()` を通じて library ドメインから取得する。

#### CharacterAnimationTag （キャラクターアニメーションタグ／値オブジェクト：列挙）

- フィールド：列挙（`Typing` / `Coffee` / `Idle` / `Preview`）
- 不変条件：列挙値以外は許容しない。

### wardrobe サブパッケージ

#### PaletteIdentifier （パレット識別子／値オブジェクト）

- 目的：キャラクターが参照するカラーパレットを一意に識別する。
- フィールド：
  - `value`: ULID 文字列（26 文字）
- 不変条件：
  - `value` は ULID フォーマットに一致する。
- 振る舞い：
  - **新規生成できる(generate)**
    - 入力：なし
    - 出力：`PaletteIdentifier`
    - 副作用：なし

#### WardrobeMap （衣装マップ／値オブジェクト）

- フィールド：
  - `morning`: `OutfitVariant`
  - `noon`: `OutfitVariant`
  - `night`: `OutfitVariant`
- 不変条件：なし
- 備考：
  - `OutfitVariant` と `AnimationBindingManifest`、`SpriteAtlasDefinition` との整合性検証は、`Character` 集約の `updateWardrobe` メソッドで実施される。
  - `WardrobeMap` 自体は純粋な値オブジェクトであり、外部リソースへの参照の妥当性は検証しない。
- 振る舞い：
  - **時間帯に応じた衣装を取得できる(resolveForPeriod)**
    - 入力：`DayPeriod`
    - 出力：`OutfitVariant`
    - 副作用：なし（該当衣装が存在しない場合は例外を発する）

#### AtlasFrameName （アトラスフレーム名／値オブジェクト）

- 目的：スプライトアトラス内のフレーム名を表現し、命名規則を強制する。
- フィールド：
  - `value`: 文字列（フレーム名）
- 不変条件：
  - `value` は空文字でない。
  - `value` は 1〜100 文字である。
  - `value` はスネークケース形式（`^[a-z][a-z0-9_]*$`）に一致する。
- 振る舞い：
  - **文字列から生成できる(fromString)**
    - 入力：`name: String`
    - 出力：`AtlasFrameName`
    - 副作用：無効な形式の場合は例外を発する
  - **文字列表現を取得できる(toString)**
    - 入力：なし
    - 出力：`String`
    - 副作用：なし
- 利用例：`Accessory.atlasFrame`, `OutfitVariant.atlasFrame`, スプライトアトラスのフレーム参照

#### AccessorySlot （アクセサリースロット／値オブジェクト：列挙）

- 目的：キャラクターに装着可能なアクセサリーのスロットを定義する。
- フィールド：
  - （列挙型） `Glasses` / `Hat` / `Scarf` / `Earrings` / `Necklace` / `Watch`
- 不変条件：列挙値以外は許容しない。
- 備考：
  - 将来的にスロットを追加する場合は、この列挙を拡張する。
  - 各スロットは同時に 1 つのアクセサリーのみ装着可能（スロットごとに排他的）。

#### Accessory （アクセサリー／値オブジェクト）

- 目的：衣装に付随するアクセサリーアイテムを表現する。
- フィールド：
  - `slot`: `AccessorySlot`（装着スロット）
  - `atlasFrame`: `AtlasFrameName`（アトラスフレーム名）
  - `displayName`: 表示名（文字列）
- 不変条件：
  - `atlasFrame` は参照元 `AnimationBindingManifest` のアトラス内に存在するフレーム名である。
  - `displayName` は 1〜50 文字である。
- 振る舞い：
  - **等価性を判定できる(equals)**
    - 入力：`other: Accessory`
    - 出力：`bool`
    - 副作用：なし（`slot`, `atlasFrame`, `displayName` が全て一致する場合に true）

#### OutfitVariant （衣装バリエーション／値オブジェクト）

- フィールド：
  - `binding`: `CharacterAnimationBindingIdentifier`
  - `atlasFrame`: `AtlasFrameName`（アトラスフレーム名）
  - `palette`: `PaletteIdentifier`
  - `accessories`: アクセサリーマップ（`Map<AccessorySlot, Accessory>`、任意）
- 不変条件：
  - `accessories` のキー（`AccessorySlot`）と値（`Accessory.slot`）が一致する。
- 振る舞い：
  - **アクセサリーを取得できる(getAccessory)**
    - 入力：`slot: AccessorySlot`
    - 出力：`Accessory?`
    - 副作用：なし（指定スロットにアクセサリーがない場合は null）
  - **アクセサリーを装着できる(putOn)**
    - 入力：`accessory: Accessory`
    - 出力：新しい `OutfitVariant`
    - 副作用：なし（不変オブジェクトのため、新しいインスタンスを返す）
    - 備考：同じスロットに既存のアクセサリーがある場合は置き換える
  - **アクセサリーを外せる(takeOff)**
    - 入力：`slot: AccessorySlot`
    - 出力：新しい `OutfitVariant`
    - 副作用：なし（指定スロットのアクセサリーを除いた新しいインスタンスを返す）
    - 備考：指定スロットにアクセサリーがない場合は、自身をそのまま返す

#### OutfitMode （衣装モード／値オブジェクト：列挙）

- 目的：衣装の切替方法（自動/手動）を制御し、DayPeriod 変化時の振る舞いを決定する。
- フィールド：
  - （列挙型） `auto` / `manual`
- 不変条件：
  - 列挙値以外は許容しない。
- 利用例：
  - `UserProfile.outfitMode`（profile パッケージから参照）
  - `DayPeriodChangedSubscriber` での自動切替判定（`mode == OutfitMode.auto` で判定）
  - UC06（時間帯による自動衣装切り替え）での前提条件確認

#### ドメインイベント

- `CharacterRegistered`
  - 役割：新しいキャラクターがカタログから登録されたことを通知する。
  - フィールド：
    - `character: CharacterIdentifier`
    - `bindings: List<CharacterAnimationBindingIdentifier>`
    - `palettes: List<PaletteIdentifier>`
    - `status: CharacterStatus`
- `CharacterUpdated`
  - 役割：既存キャラクターのアニメーション/衣装が更新されたことを通知する。
  - フィールド：
    - `character: CharacterIdentifier`
    - `updatedBindings: List<CharacterAnimationBindingIdentifier>`
    - `updatedPalettes: List<PaletteIdentifier>`
- `CharacterDeprecated`
  - 役割：キャラクターが利用不可になったことを通知する。
  - フィールド：
    - `character: CharacterIdentifier`
    - `reason: String`
- `CharacterUnlocked`
  - 役割：課金や実績によりキャラクターが使用可能になったことを通知する。
  - フィールド：
    - `character: CharacterIdentifier`
    - `unlockSource: String`
- `CharacterOutfitApplied`
  - 役割：WardrobeMap に基づき特定時間帯の衣装が適用されたことを通知する。
  - フィールド：
    - `character: CharacterIdentifier`
    - `dayPeriod: DayPeriod`
    - `palette: PaletteIdentifier`

#### CharacterSearchCriteria （キャラクター検索条件／値オブジェクト）

- 目的：リポジトリ検索条件を明示し、状態やタグでのフィルタを統一する。
- フィールド：
  - `statuses`: `CharacterStatus` の集合（任意）
  - `tags`: セット（例：`typing`, `coffee`）
- 不変条件：
  - `statuses` を指定する場合は空集合不可

#### リポジトリ契約

- `CharacterRepository`
  - `find(identifier: CharacterIdentifier): Character?`
  - `search(criteria: CharacterSearchCriteria): List<Character>`
  - `persist(character: Character): void`
  - `all(): List<Character>`

## イベントサブスクライバ

- **DayPeriodChangedSubscriber**
  - 目的：共通時間帯イベントに応じて Wardrobe を自動切り替える。
  - 購読イベント：`DayPeriodChanged`（profile/common）。
  - 処理内容：`WardrobeMap` から該当衣装を選び、`CharacterOutfitApplied` を profile へ発火。
  - 発火イベント：`CharacterOutfitApplied`
- **AssetCatalogUpdatedSubscriber**
  - 目的：AssetCatalog 更新時にキャラクターのアトラス/アニメ整合を確認する。
  - 購読イベント：`AssetCatalogUpdated`（library）。
  - 処理内容：
    1. `AssetCatalogUpdated` イベントの `updatedPackages` から `type` が `AssetPackageType.Character` に該当するパッケージを抽出
    2. Character タイプのパッケージが含まれている場合、`CharacterRepository.all()` から全キャラクターを取得
    3. 各キャラクターについて：
       - `bindings` の各 `CharacterAnimationBinding.binding` と `wardrobes` 内の各 `OutfitVariant.binding` について `AnimationBindingManifestRepository.find()` で最新のマニフェストを取得
       - `TimelineDefinitionRepository.find(manifest.timeline)` で最新のタイムライン定義を取得
       - キャラクターの事前条件（30fps、typing/coffee タグの存在）を再検証
       - 検証成功：キャラクターを `CharacterRepository.persist` で永続化し、`CharacterUpdated` を発火
       - 検証失敗：キャラクターの `deprecate(reason: "アセット整合性違反")` を呼び出し、`CharacterDeprecated` を発火
    4. `CharacterRepository` で永続化
  - 発火イベント：`CharacterUpdated` / `CharacterDeprecated`
- **EntitlementChangedSubscriber**
  - 目的：Billing の権利変更に合わせてキャラクター解放状態を調整する。
  - 購読イベント：`EntitlementUpdated`（billing）。
  - 処理内容：
    1. `EntitlementRepository` から更新された `Entitlement` を取得
    2. `Entitlement.limits.characters` と現在解放済みのキャラクター数を比較
    3. 上限を超過している場合、`CharacterRepository.search(criteria: CharacterSearchCriteria(statuses: [Active]))` で解放済みキャラクターを取得
    4. 超過分のキャラクター（最近解放されたものから順）に対して `Character.deprecate(reason: "利用枠超過")` を呼び出し、`status` を `Locked` に変更
    5. 各キャラクターが `CharacterDeprecated` イベントを発火
    6. `CharacterRepository` で永続化
  - 発火イベント：`CharacterDeprecated`（Character の振る舞いから）

## ドメインサービス連携

- **CoffeeMotionScheduler（work パッケージ側に実装）**
  - `PomodoroPhaseStarted` イベントを購読し、90〜150 秒のランダム間隔で `Character` の `coffee` アニメーションを cue として発火する。
  - Character 集約はアニメーションメタデータを提供し、実際のスケジュール管理は `PomodoroSession` の `nextCoffeeAt` / `CoffeeCueSchedule` に委ねる。
