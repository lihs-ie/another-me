# scene パッケージ モデル

背景シーンのアセット仕様と演出制御を担当する。要件の「背景シーン」「アセット仕様」「夜間ダークニング」に従い、24fps ループやパララックス整合を保障する。

## モデル方針

- シーンは library.animation の `AnimationBindingManifest` を識別子参照して 24fps のスプライトループと演出設定を持つ単一集約で表現し、自然数スケール・16px グリッドの整合を担保する。
- 背景ごとのシーン固有演出やパララックス要素を `SceneEffects` 値オブジェクトで記録する。
- シーンの明度調整や夜間ダークニングは profile からのテーマ変更イベントで制御する。
- イベントサブスクライバがアセット更新や描画パフォーマンス計測に応じてシーン設定を調整する。

## Scene 集約

#### SceneIdentifier （シーン識別子／値オブジェクト）

- 目的：背景シーン集約を一意に識別する。
- フィールド：
  - `value`: ULID 文字列（26 文字）
- 不変条件：
  - `value` は ULID フォーマット（`[0-7][0-9A-HJKMNP-TV-Z]{25}`）に一致する。
- 振る舞い：
  - **新規生成できる(generate)**
    - 入力：なし
    - 出力：`SceneIdentifier`
    - 副作用：なし

#### Scene （シーン／集約）

- 目的：背景アニメーション、パララックス、照明などシーン表示に必要なメタデータを管理する。
- フィールド：
  - `identifier`: `SceneIdentifier`
  - `name`: 表示名（文字列）
  - `type`: `SceneType`
  - `animationBinding`: `SceneAnimationBinding`
  - `parallaxLayers`: `ParallaxLayer` のリスト
  - `characterAnchor`: `SceneAnchor`
  - `effects`: `SceneEffectElement`のセット
  - `lightingProfile`: `LightingProfile`
  - `status`: `SceneStatus`（`Active` / `Deprecated`）
- 不変条件：
  - `parallaxLayers` 内の各 `ParallaxLayer.identifier` は一意である。
  - `parallaxLayers` 内の各 `speedRatio` は正の有理数である（各 `ParallaxLayer` で保証）。
  - `characterAnchor` の制約は `SceneAnchor` 値オブジェクトで保証される。
  - `lightingProfile` の制約は `LightingProfile` 値オブジェクトで保証される。
- 生成時の事前条件（SceneFactory で検証）：
  - `animationBinding.binding` が参照する `AnimationBindingManifest` の `timeline` は 24fps ループ仕様である。
  - `animationBinding.binding` が参照する `AnimationBindingManifest` は `tags=ambient` を含む。
  - `animationBinding.binding` が参照する `TimelineDefinition` の `frameCount` は定義済みループ長（24 / 48 / 96 / 192）のいずれかである（要件のアセット仕様に準拠）。
- 振る舞い：
  - **照明を更新できる(changeLighting)**
    - 入力：`LightingProfile`
    - 出力：なし
    - 副作用：照明プロファイルを更新し `SceneLightingChanged` を発火する
  - **パララックスレイヤーの速度を減速できる(reduceParallaxSpeed)**
    - 入力：`reductionRatio: double`（0.0〜1.0、例: 0.5 で 50% に減速）
    - 出力：なし
    - 副作用：全 `parallaxLayers` の `speedRatio` を `reductionRatio` 倍に更新し、`SceneUpdated` を発火する
    - 例外：`reductionRatio` が 0.0〜1.0 の範囲外の場合は例外を発する
  - **特定のパララックスレイヤーを削除できる(removeParallaxLayer)**
    - 入力：`identifier: ParallaxLayerIdentifier`
    - 出力：なし
    - 副作用：指定された `identifier` を持つレイヤーを `parallaxLayers` から削除し、`SceneUpdated` を発火する
    - 例外：`identifier` が存在しない場合は例外を発する
  - **最も速いパララックスレイヤーを削除できる(removeFastestParallaxLayer)**
    - 入力：なし
    - 出力：削除された `ParallaxLayerIdentifier`
    - 副作用：`parallaxLayers` から最大の `speedRatio` を持つレイヤーを削除し、`SceneUpdated` を発火する
    - 例外：`parallaxLayers` が空の場合は例外を発する

#### LightingHint （照明ヒント／値オブジェクト：列挙）

- 目的：シーンアニメーションに推奨される照明モードを示す。
- 列挙：`Day` / `Night` / `Auto`
  - `Day`: 昼間の明るい照明を推奨
  - `Night`: 夜間の暗い照明を推奨（ダークニング適用）
  - `Auto`: 自動判定（プロフィール設定やシステム時刻に応じて切り替え）
- 不変条件：列挙値以外は許容しない。

#### SceneAnimationBinding （シーンアニメーションバインディング／値オブジェクト）

- 目的：library.animation の `AnimationBindingManifest` を参照し、シーン固有の演出メタデータを付与する。
- フィールド：
  - `binding`: `AnimationBindingIdentifier`
  - `lighting`: `LightingHint`
- 不変条件：
  - `binding` は `AnimationBindingManifest.tags` に `ambient` を含むエントリを指す。
- 備考：
  - アトラス座標やピボット、ループ時間などの詳細情報は `AnimationBindingManifest.extractMetadata()` を通じて library ドメインから取得する。
  - ループ時間（loopDurationMs）は `AnimationBindingManifest` の `frameCount / FramesPerSecond.value * 1000` から計算可能な導出値。
  - `lighting` と `LightingProfile.darkeningFactor` の整合性は、Scene 集約の不変条件で保証される。

#### ParallaxLayerIdentifier （パララックス層識別子／値オブジェクト）

- 目的：パララックス層を一意に識別する。
- フィールド：
  - `value`: ULID 文字列（26 文字）
- 不変条件：
  - `value` は ULID フォーマットに一致する。
- 振る舞い：
  - **新規生成できる(generate)**
    - 入力：なし
    - 出力：`ParallaxLayerIdentifier`
    - 副作用：なし

#### ParallaxLayer （パララックス層／エンティティ）

- フィールド：
  - `identifier`: `ParallaxLayerIdentifier`
  - `binding`: `AnimationBindingIdentifier`
  - `speedRatio`: `Rational`（有理数）
  - `assetFrameRange`: `Range<int>`（フレーム範囲）
- 不変条件：
  - `speedRatio` は正の有理数である（`speedRatio > 0`）。
  - `assetFrameRange` は参照マニフェストのフレーム数以内。
- 振る舞い：
  - **速度比を更新できる(updateSpeedRatio)**
    - 入力：`newSpeedRatio: Rational`
    - 出力：なし
    - 副作用：`newSpeedRatio` が正の値でない場合は例外を発する。新しい速度比を反映する。

#### SceneEffectElement （シーン演出要素／値オブジェクト：列挙）

- 目的：シーン固有の演出要素の種類を表す。
- 列挙：`Pedestrians` / `Steam` / `Clouds` / `PrinterActivity`
  - `Pedestrians`: 通行人（カフェなど）
  - `Steam`: 湯気（カフェなど）
  - `Clouds`: 窓外の雲流れ（部屋など）
  - `PrinterActivity`: プリンタ稼働（オフィスなど）
- 不変条件：列挙値以外は許容しない。

#### SceneAnchor （キャラクターアンカー／値オブジェクト）

- 目的：シーン内のキャラクター配置位置を相対座標と 16px グリッド整合されたオフセットで表現する。
- フィールド：
  - `relativeX`: 浮動小数点（0.0〜1.0）
  - `relativeY`: 浮動小数点（0.0〜1.0）
  - `offsetX`: 数値（ピクセル）
  - `offsetY`: 数値（ピクセル）
- 不変条件：
  - `0.0 <= relativeX <= 1.0`
  - `0.0 <= relativeY <= 1.0`
  - `offsetX % 16 == 0`（16px グリッド整合）
  - `offsetY % 16 == 0`（16px グリッド整合）
- 振る舞い：
  - **絶対座標を計算できる(toAbsolute)**
    - 入力：シーンサイズ（幅・高さ）
    - 出力：`(int absoluteX, int absoluteY)`
    - 副作用：なし

#### LightingProfile （照明プロファイル／値オブジェクト）

- 目的：シーンの照明モードと暗化係数を管理する。
- フィールド：
  - `mode`: ThemeMode（`Day` / `Night` / `Auto`）
  - `darkeningFactor`: 浮動小数点（0〜1）
- 不変条件：
  - `0 <= darkeningFactor <= 1`
  - `mode == Night` の場合、`darkeningFactor >= 0.4`
- 振る舞い：
  - **ThemeMode から生成できる(fromThemeMode)**
    - 入力：`mode: ThemeMode`
    - 出力：`LightingProfile`
    - 処理：
      - `mode == Day`: `darkeningFactor = 0.0`
      - `mode == Night`: `darkeningFactor = 0.5`（デフォルト値）
      - `mode == Auto`: `darkeningFactor = 0.0`（Auto は実行時に Day/Night を判定するため、初期値は Day 相当）
    - 副作用：なし

#### SceneStatus （シーン状態／値オブジェクト：列挙）

- 列挙：`Active` / `Deprecated`
- 不変条件：列挙値以外は許容しない。

#### SceneType （シーン種別／値オブジェクト：列挙）

- 目的：シーンの種類を表す。
- 列挙：`Room` / `Office` / `Cafe`
  - `Room`: 自室
  - `Office`: 会社・オフィス
  - `Cafe`: カフェ
- 不変条件：列挙値以外は許容しない。

## ドメインサービス

#### SceneFactory （シーンファクトリ）

- 目的：Scene 集約の生成時に library.animation パッケージの AnimationBindingManifest と TimelineDefinition を検証し、整合性を保証する。
- 責務：
  - AnimationBindingManifest と TimelineDefinition が Scene に適した仕様（24fps、ambient タグ、自然数秒ループ）を満たすか検証する
  - 検証に成功した場合のみ Scene 集約を生成する
- 振る舞い：
  - **Scene を生成できる(create)**
    - 入力：
      - `identifier: SceneIdentifier`
      - `name: String`
      - `type: SceneType`
      - `animationBinding: SceneAnimationBinding`
      - `parallaxLayers: List<ParallaxLayer>`
      - `characterAnchor: SceneAnchor`
      - `effects: SceneEffectElementのセット`
      - `lightingProfile: LightingProfile`
      - `animationBindingManifestRepository: AnimationBindingManifestRepository`（library パッケージ）
      - `timelineDefinitionRepository: TimelineDefinitionRepository`（library パッケージ）
    - 出力：`Scene`
    - 処理内容：
      1. `animationBindingManifestRepository.find(animationBinding.binding)` で `AnimationBindingManifest` を取得
      2. `timelineDefinitionRepository.find(manifest.timeline)` で `TimelineDefinition` を取得
      3. `timeline.fps == FramesPerSecond(24)` を検証
      4. `manifest.tags` に `ambient` が含まれるか検証
      5. `timeline.frameCount` が定義済みループ長（24 / 48 / 96 / 192）のいずれかであることを検証
      6. すべての検証に成功した場合、Scene を生成して返す
    - 例外：
      - AnimationBindingManifest が見つからない場合は例外を発する
      - TimelineDefinition が見つからない場合は例外を発する
      - 24fps でない場合は例外を発する
      - `ambient` タグがない場合は例外を発する
      - `frameCount` が定義済みループ長でない場合は例外を発する

#### ドメインイベント

- `SceneRegistered`
  - 役割：新しい背景シーンが登録されたことを通知する。
  - フィールド：`identifier: SceneIdentifier`, `type: SceneType`, `binding: AnimationBindingIdentifier`, `effects: Set<SceneEffectElement>`
- `SceneUpdated`
  - 役割：既存シーンの設定（照明やパララックスなど）が更新されたことを通知する。
  - フィールド：`identifier: SceneIdentifier`, `binding: AnimationBindingIdentifier`, `lightingProfile: LightingProfile`, `parallaxLayers: List<ParallaxLayer>`
- `SceneDeprecated`
  - 役割：シーンが利用不可になったことを通知する。
  - フィールド：`identifier: SceneIdentifier`, `reason: String`
- `SceneLightingChanged`
  - 役割：シーンの照明プロファイルが変更されたことを通知する。
  - フィールド：`identifier: SceneIdentifier`, `lightingProfile: LightingProfile`

#### SceneSearchCriteria （シーン検索条件／値オブジェクト）

- 目的：利用可能なシーンを状態や種類別に検索する。
- フィールド：
  - `statuses`: `Set<SceneStatus>`（任意）
  - `types`: `Set<SceneType>`（任意）
- 不変条件：
  - `statuses` を指定する場合は空集合不可
  - `types` を指定する場合は空集合不可
- 振る舞い：
  - **検索条件を生成できる(create)**
    - 入力：`statuses?`, `types?`
    - 出力：`SceneSearchCriteria`
    - 副作用：なし

#### リポジトリ契約

- `SceneRepository`
  - `find(identifier: SceneIdentifier): Scene`
  - `search(criteria: SceneSearchCriteria): List<Scene>`
  - `persist(scene: Scene): void`
  - `all(): List<Scene>`

## イベントサブスクライバ

- **ThemeChangedSubscriber**
  - 目的：プロフィールのテーマ変更に応じてすべてのアクティブなシーンの照明を更新する。
  - 購読イベント：`ThemeChanged`（profile/common）。
  - 処理内容：
    1. `SceneRepository.search(criteria: SceneSearchCriteria(statuses: {Active}))` ですべてのアクティブなシーンを取得
    2. `ThemeChanged` イベントの `mode` から `LightingProfile.fromThemeMode(mode)` で新しい `LightingProfile` を生成
    3. 各シーンの `changeLighting(lightingProfile)` を呼び出し、照明プロファイルを更新（`SceneLightingChanged` イベントは各振る舞いで発火済み）
    4. 各シーンを `SceneRepository.persist` で永続化
  - 発火イベント：`SceneLightingChanged`（Scene の振る舞いから発火）
- **AssetCatalogUpdatedSubscriber**
  - 目的：アセット更新に応じて該当するシーンのアニメーション整合を再検証する。
  - 購読イベント：`AssetCatalogUpdated`（library）。
  - 処理内容：
    1. `AssetCatalogUpdated` イベントの `updatedPackages` から `type` が `AssetPackageType.Scene` に該当するパッケージを抽出
    2. Scene タイプのパッケージが含まれている場合、`SceneRepository.all()` から全シーンを取得
    3. 各シーンについて：
       - `AnimationBindingManifestRepository.find(scene.animationBinding.binding)` と各 `parallaxLayer.binding` で最新のマニフェストを取得
       - `TimelineDefinitionRepository.find(manifest.timeline)` で最新のタイムライン定義を取得
       - シーンの事前条件（24fps、ambient タグ、定義済みループ長）を再検証
       - 検証成功：シーンを `SceneRepository.persist` で永続化し、`SceneUpdated` を発火
       - 検証失敗：シーンの `status` を `Deprecated` に変更し、`SceneDeprecated` を発火
    4. `SceneRepository` で永続化
  - 発火イベント：`SceneUpdated` / `SceneDeprecated`
- **PerformanceBudgetSubscriber**
  - 目的：telemetry のパフォーマンス超過イベントを受けてシーン負荷を調整する。
  - 購読イベント：`PerformanceBudgetExceeded`（telemetry）。
  - 処理内容：
    1. `SceneRepository` からすべてのアクティブなシーンを取得
    2. 各シーンの `removeFastestParallaxLayer()` を呼び出し、最も高い `speedRatio` を持つレイヤーを削除
    3. `Scene.reduceParallaxSpeed(reductionRatio: 0.5)` を呼び出し、残りのレイヤーの `speedRatio` を 50% に減速
    4. 各シーンを `SceneRepository.persist` で永続化（`SceneUpdated` イベントは各振る舞いで発火済み）
  - 発火イベント：`SceneUpdated`（Scene の振る舞いから発火）
