# library パッケージ モデル

アセット・カタログとアニメーション仕様の整合を担う。要件の「アセット仕様」「アトラス構成」「制作パイプライン」に加え、公式配布楽曲のメタデータとライセンス情報も管理する。

## モデル方針

- AssetCatalog 集約はキャラクター・背景・公式楽曲などのリリースパッケージを表し、互換性バージョンと最小アプリ要件を保持する（**本番アプリでは読み取り専用**）。
- AnimationSpec 集約はアニメーション定義（fps, frame, pivot, next）のスキーマを厳密に検証する。
- avatar / scene パッケージが利用するタイムラインやアトラスの定義は animation サブパッケージで一元管理し、他ドメインは `AnimationBindingManifest` の識別子参照のみを許可する。
- カタログ同期時は関連パッケージ（avatar, scene, media）へイベントを発行し、整合性を再チェックさせる。
- 公式楽曲も AssetCatalog に統合して管理する。現時点ではキャラクター/背景と同じリリースサイクル・配信インフラを想定しており、バージョン管理や配布パイプラインを一元化できるメリットがあるためである。
- 将来、楽曲だけ更新頻度が高まる・配信インフラが分かれる・第三者提供のカタログと連携するなどの条件が揃った場合は、MusicCatalog として分離する判断が可能。その際に移行しやすいよう、楽曲メタ（TrackCatalogMetadata）を独立した値オブジェクトとして定義し、他アセットへの依存を避ける。
- **Checksum および ChecksumCalculator** は複数パッケージで利用される汎用概念のため、`common/storage` パッケージに定義されている。library パッケージでは AssetPackage や FileResource の整合性検証に使用する。

> **注意**: AssetCatalog の構築（パッケージ追加・検証・公開）は、本番アプリではなく **開発者ツール（@docs/tooling/asset-catalog-builder.md）** で行う。本番アプリは公式サーバーから配信された catalog.json を受信・参照するのみ。

## asset サブパッケージ

### AssetCatalog 集約

#### CatalogIdentifier （カタログ識別子／値オブジェクト）

- 目的：AssetCatalog のバージョンを一意に識別する。
- フィールド：
  - `value`: ULID 文字列（26 文字）
- 不変条件：
  - `value` は ULID フォーマット（`[0-7][0-9A-HJKMNP-TV-Z]{25}`）に一致する。
- 振る舞い：
  - **新規生成できる(generate)**
    - 入力：なし
    - 出力：`CatalogIdentifier`
    - 副作用：なし

#### AssetCatalog （アセットカタログ／集約）

- 目的：公式アセット（キャラ/背景/楽曲）のバージョンと依存関係を管理する。
- フィールド：
  - `identifier`: `CatalogIdentifier`
  - `version`: セマンティックバージョン（文字列）
  - `minAppVersion`: 最小対応アプリバージョン（文字列）
  - `packages`: `AssetPackage` のリスト
  - `publishedAt`: 公開日時
  - `status`: `CatalogStatus`（`Draft` / `Published` / `Deprecated`）
- 不変条件：
  - `version` はセマンティックバージョン形式。
  - `packages` の依存に循環がない。
  - `minAppVersion` は現行アプリバージョン以下。
- 振る舞い（本番アプリ用・読み取り専用）：
  - **パッケージを取得できる(getPackage)**
    - 入力：`identifier: AssetPackageIdentifier`
    - 出力：`AssetPackage`（存在しない場合は例外）
    - 副作用：なし
  - **パッケージ一覧を取得できる(listPackages)**
    - 入力：`type: AssetPackageType`（任意）
    - 出力：`List<AssetPackage>`
    - 副作用：なし
  - **カタログ情報を取得できる(getAttributes)**
    - 入力：なし
    - 出力：`identifier`, `version`, `publishedAt`
    - 副作用：なし

> **開発者ツール専用の振る舞い**（`addPackage`, `release`, `deprecate`）は `@docs/tooling/asset-catalog-builder.md` を参照。

#### AssetPackageIdentifier （アセットパッケージ識別子／値オブジェクト）

- 目的：AssetCatalog 内の各パッケージを一意に識別する。
- フィールド：
  - `value`: ULID 文字列（26 文字）
- 不変条件：
  - `value` は ULID フォーマットに一致する。
- 振る舞い：
  - **新規生成できる(generate)**
    - 入力：なし
    - 出力：`AssetPackageIdentifier`
    - 副作用：なし

#### AssetPackage （アセットパッケージ／エンティティ）

- フィールド：
  - `identifier`: `AssetPackageIdentifier`
  - `type`: `AssetPackageType`
  - `files`: `FileResource` のリスト
  - `checksum`: `Checksum`
  - `animationSpecVersion`: 文字列（任意）
  - `trackCatalogMetadata`: `TrackCatalogMetadata`（Track の場合必須）
- 不変条件：
  - 画像系パッケージは PNG + JSON アトラス、余白 2〜4px。
  - Track パッケージは `trackCatalogMetadata` を必ず保持し、チェックサムと一致する。
- 振る舞い：
  - **ファイル整合性を検証できる(validateFiles)**
    - 入力：なし
    - 出力：なし
    - 副作用：`files` の `verifyIntegrity()` を順に実行し、失敗時は例外を発する
  - **トラックメタを取得できる(extractTrackSeed)**
    - 入力：なし
    - 出力：`TrackCatalogMetadata`（Track タイプの場合）
    - 副作用：`type` が `Track` のときのみ利用可能、それ以外は例外

#### SemanticVersion （セマンティックバージョン／値オブジェクト）

- 目的：カタログやアプリのバージョンをセマンティックバージョニング形式で管理する。
- フィールド：
  - `major`: メジャーバージョン（自然数）
  - `minor`: マイナーバージョン（自然数）
  - `patch`: パッチバージョン（自然数）
- 不変条件：
  - `major`, `minor`, `patch` は全て 0 以上の自然数である。
- 振る舞い：
  - **文字列から生成できる(fromString)**
    - 入力：`version: String`（例：`"1.2.3"`）
    - 出力：`SemanticVersion`
    - 副作用：無効な形式の場合は例外を発する
  - **文字列表現を取得できる(toString)**
    - 入力：なし
    - 出力：`String`（例：`"1.2.3"`）
    - 副作用：なし
  - **比較できる(compareTo)**
    - 入力：`other: SemanticVersion`
    - 出力：`int`（-1: 小さい、0: 等しい、1: 大きい）
    - 副作用：なし
  - **互換性を判定できる(isCompatibleWith)**
    - 入力：`other: SemanticVersion`
    - 出力：`bool`（メジャーバージョンが同じ場合にtrue）
    - 副作用：なし
- 利用例：AssetCatalog.version、AssetCatalog.minAppVersion

#### FileResource （ファイルリソース／値オブジェクト）

- 目的：AssetPackage に含まれる単一ファイルの参照とメタ情報を保持する。
- フィールド：
  - `path`: ファイルパス（FilePath）
  - `sizeBytes`: サイズ（数値、バイト）
  - `checksum`: `Checksum`
- 不変条件：
  - `sizeBytes > 0` かつ 制作ガイドライン最大値（例：200MB）以下。
  - `path` は OS 別ルールに従い、PNG/JSON 等の拡張子が期待通りである。
  - `checksum` と実ファイルのハッシュが一致する。
- 振る舞い：
  - **整合性を検証できる(verifyIntegrity)**
    - 入力：`ChecksumCalculator`
    - 出力：真偽値
    - 副作用：計算サービスを通じてファイルを読み込み `checksum` と比較し、一致しなければ例外を発する

#### TrackCatalogMetadata （トラックカタログメタ／値オブジェクト）

- 目的：公式楽曲のメタ情報とライセンス参照を一元化し、Track 集約生成時の材料を提供する。
- フィールド：
  - `track`: `CatalogTrackIdentifier`（import パッケージで定義）
  - `downloadUrl`: ダウンロード URL（文字列、HTTPS 必須）
  - `audioChecksum`: 音源ファイルの `Checksum`
  - `licenseMetadata`: `CatalogLicenseMetadata`（licensing パッケージ準拠）
- 不変条件：
  - `downloadUrl` は HTTPS で始まり、署名付き URL の有効期限を持つ。
  - `audioChecksum` は音源ファイルと一致する。
  - `licenseMetadata` は licensing パッケージの期待スキーマに合致する。
- 振る舞い：
  - **Track 生成用の入力を構築できる(toTrackSeed)**
    - 入力：なし
    - 出力：`Track` 登録用 DTO（識別子・URL・チェックサム）
    - 副作用：なし（検証失敗時は例外）

#### CatalogStatus （カタログ状態／値オブジェクト：列挙）

- 列挙：`Draft` / `Published` / `Deprecated`

#### ドメインイベント

- `AssetCatalogPublished`
  - 役割：AssetCatalog の新バージョンが公開されたことを通知する。
  - フィールド：`identifier: CatalogIdentifier`, `version: String`, `packages: List<AssetPackage>`
- `AssetCatalogUpdated`
  - 役割：既存カタログが更新されたことを通知する。
  - フィールド：
    - `catalog: CatalogIdentifier`
    - `updatedPackages: List<AssetPackage>`
- `AssetCatalogDeprecated`
  - 役割：カタログが利用不可になったことを通知する。
  - フィールド：`identifier: CatalogIdentifier`, `reason: String`
- `TrackCatalogUpdated`
  - 役割：公式トラックカタログの差分を通知する。
  - フィールド：`catalog: CatalogIdentifier`, `addedTracks: List<CatalogTrackIdentifier>`, `removedTracks: List<CatalogTrackIdentifier>`, `updatedTracks: List<CatalogTrackIdentifier>`

#### リポジトリ契約

- `AssetCatalogRepository`
  - `findLatest(): AssetCatalog`
    - 副作用：カタログが見つからない場合は`AggregateNotFoundError`を投げる
  - `find(identifier: CatalogIdentifier): AssetCatalog`
    - 副作用：識別子に対応するカタログが見つからない場合は`AggregateNotFoundError`を投げる
  - `persist(catalog: AssetCatalog): void`

#### イベントサブスクライバ

- **CatalogPublishSubscriber**
  - 目的：AssetCatalog 公開後に他ドメインへ新バージョンを通知する。
  - 購読イベント：`AssetCatalogPublished`（library）。
  - 処理内容：
    1. イベントから `identifier`, `version`, `packages` を取得
    2. パッケージをタイプ別に分類（`Character`, `Scene`, `Track`）
    3. 各タイプのパッケージリストを含む `AssetCatalogUpdated` イベントを発火
    4. avatar・scene パッケージの `AssetCatalogUpdatedSubscriber` がこのイベントを購読し、それぞれ必要なアセット整合性チェックを実行
  - 発火イベント：`AssetCatalogUpdated`

## animation サブパッケージ

animation サブパッケージは以下のサブパッケージで構成されます:

- **animation/spec** - アニメーション仕様（AnimationSpec）
- **animation/timeline** - タイムライン定義（TimelineDefinition）
- **animation/atlas** - スプライトアトラス定義（SpriteAtlasDefinition）
- **animation/binding** - タイムラインとアトラスの結合（AnimationBindingManifest）
- **animation/common** - アニメーション共通値オブジェクト（GridSize, Pivot, Hitbox, FrameSequence）

### animation/spec サブパッケージ

#### AnimationSpec 集約

#### AnimationSpecIdentifier （アニメーション仕様識別子／値オブジェクト）

- 目的：AnimationSpec を一意に識別する。
- フィールド：
  - `value`: ULID 文字列（26 文字）
- 不変条件：
  - `value` は ULID フォーマットに一致する。
- 振る舞い：
  - **新規生成できる(generate)**
    - 入力：なし
    - 出力：`AnimationSpecIdentifier`
    - 副作用：なし

#### AnimationSpec （アニメーション仕様／集約）

- 目的：アセットが遵守すべきアニメーション定義を保持する。
- フィールド：
  - `identifier`: `AnimationSpecIdentifier`
  - `name`: 文字列
  - `fps`: FramesPerSecond（common.frame-rate）
  - `frames`: 数値
  - `next`: 次に遷移するアニメーション名（文字列）
  - `pivot`: `Pivot`
  - `hitboxes`: `Hitbox` のリスト
  - `safetyMargin`: 数値（px）
- 不変条件：
  - `fps` と `frames` は事前定義の倍数（12 / 24 / 30 / 48 / 60 / 96 / 120）。
  - `pivot` はアトラス範囲内の自然数座標。
  - `safetyMargin >= 8`。
- 振る舞い：
  - **アニメーション仕様を登録できる(register)**
    - 入力：なし
    - 出力：なし
    - 副作用：値検証に成功した場合にのみ内部状態を確定し、`AnimationSpecRegistered` を発火する
  - **廃止できる(deprecate)**
    - 入力：理由（文字列）
    - 出力：なし
    - 副作用：`AnimationSpecDeprecated` を発火し、依存するバインディングへ通知する

#### ドメインイベント

- `AnimationSpecRegistered`
  - 役割：新しいアニメーション仕様が登録されたことを通知する。
  - フィールド：`specIdentifier: AnimationSpecIdentifier`, `name: String`, `fps: FramesPerSecond`, `frames: int`
- `AnimationSpecDeprecated`
  - 役割：アニメーション仕様が廃止されたことを通知する。
  - フィールド：`specIdentifier: AnimationSpecIdentifier`

#### リポジトリ契約

- `AnimationSpecRepository`
  - `findByName(name: String): AnimationSpec`
    - 副作用：名前に対応するスペックが見つからない場合は`AggregateNotFoundError`を投げる
  - `persist(spec: AnimationSpec): void`
  - `all(): List<AnimationSpec>`

#### イベントサブスクライバ

- **SpecComplianceSubscriber**
  - 目的：AnimationSpec 変更時に依存アセットの整合性を担保する。
  - 購読イベント：`AnimationSpecRegistered`（library）。
  - 処理内容：
    1. イベントから新規登録された `AnimationSpec` の `name`, `fps`, `frames`, `pivot`, `safetyMargin` を取得
    2. `AssetCatalogRepository.findLatest()` から最新のカタログを取得
    3. カタログ内の全 `AssetPackage` のうち、`animationSpecVersion` が新規 `AnimationSpec.name` と一致するものを抽出
    4. 各 AssetPackage について以下を検証：
       - JSON アトラスの `fps` が `AnimationSpec.fps` と一致するか
       - JSON アトラスの総フレーム数が `AnimationSpec.frames` と一致するか
       - JSON アトラスの `pivot` 座標が `AnimationSpec.pivot` と一致するか
       - PNG 画像の余白が `AnimationSpec.safetyMargin` 以上確保されているか
    5. 検証に失敗した AssetPackage が存在する場合、`AssetCatalog.deprecate(reason: "AnimationSpec不整合")` を呼び出し、`AssetCatalogDeprecated` イベントを発火
    6. `AssetCatalogRepository` で永続化
  - 発火イベント：`AssetCatalogDeprecated`（AssetCatalog の振る舞いから）
  - 備考：検証には JSON パース処理と PNG メタデータ読み取りが必要。これらはインフラ層のサービスに委譲する。

### animation/common サブパッケージ

#### GridSize (グリッドサイズ/値オブジェクト)

- 目的：グリッドサイズを表す
- フィールド：
  - `value`: 数値
- 不変条件
  - `value`は 8, 16, 32 のいずれかの数値
- 振る舞い：
  - **グリッドサイズを生成できる(create)**
    - 入力：`value`（数値）
    - 出力：`GridSize`
    - 副作用：不変条件違反時は例外を発する

#### Pivot （ピボット／値オブジェクト）

- 目的：スプライト座標系の原点位置を表し、avatar/scene で一致を保証する。
- フィールド：
  - `x`: 自然数（ピクセル）
  - `y`: 自然数（ピクセル）
  - `gridSize`: GridSize
- 不変条件：
  - `x`, `y` はアトラスの範囲内。
  - `x` と `y` は `gridSize.value` の倍数。
- 振る舞い：
  - **ピボットを生成できる(create)**
    - 入力：`x`, `y`, `gridSize`
    - 出力：`Pivot`
    - 副作用：不変条件違反時は例外を発する
  - **正規化座標へ変換できる(toNormalized)**
    - 入力：アトラスサイズ（幅・高さ）
    - 出力：`(double normalizedX, double normalizedY)`
    - 副作用：なし（範囲外なら例外）

#### Hitbox （ヒットボックス／値オブジェクト）

- 目的：アニメーションの当たり判定やインタラクション領域を定義する。
- フィールド：
  - `originX`: エリア左上 X 座標（自然数）
  - `originY`: エリア左上 Y 座標（自然数）
  - `width`: 幅（自然数）
  - `height`: 高さ（自然数）
  - `purpose`: `HitboxPurpose`
- 不変条件：
  - `width > 0`, `height > 0`。
  - 矩形がフレーム内に収まる。
  - `purpose` は定義済みカテゴリに含まれる。
- 振る舞い：
  - **矩形内判定ができる(contains)**
    - 入力：座標 `(x, y)`
    - 出力：真偽値
    - 副作用：なし

#### HitboxPurpose （ヒットボックス用途／値オブジェクト：列挙）

- 目的：ヒットボックスの用途を限定し、誤ったカテゴリの混入を防ぐ。
- フィールド：列挙（`interaction`, `effect`, `boundingBox` など必要な用途）
- 不変条件：列挙値以外は許容しない。
- 振る舞い：
  - 必要に応じて用途ごとの補助メソッド（例：描画に影響するか等）を追加できる。

#### FrameSequence （フレームシーケンス／値オブジェクト）

- 目的：アニメーションの一連のフレーム数と再生時間を管理し、タイムラインの妥当性を検証する。
- フィールド：
  - `count`: フレーム数（自然数）
  - `durationMs`: 再生時間（数値、ミリ秒）
- 不変条件：
  - `count > 0`。
  - `durationMs` は `count / fps * 1000` と一致する（タイムライン側で検証）。
- 振る舞い：
  - **1 フレームあたりの時間を取得できる(frameDuration)**
    - 入力：なし
    - 出力：`double`（ミリ秒）
    - 副作用：なし

### animation/timeline サブパッケージ

#### TimelineIdentifier （タイムライン識別子／値オブジェクト）

- 目的：タイムライン定義を一意に識別する。
- フィールド：
  - `value`: ULID 文字列（26 文字）
- 不変条件：
  - `value` は ULID フォーマットに一致する。
- 振る舞い：
  - **新規生成できる(generate)**
    - 入力：なし
    - 出力：`TimelineIdentifier`
    - 副作用：なし

#### TimelineDefinition （タイムライン定義／エンティティ）

- 目的：アニメーションタイムラインの FPS・フレーム構成・遷移先を集中管理し、avatar/scene から参照できる識別子を付与する。
- フィールド：
  - `identifier`: `TimelineIdentifier`
  - `name`: タイムライン名（文字列）
  - `fps`: FramesPerSecond
  - `frameCount`: フレーム数（数値）
  - `loopMode`: ループ方式（列挙：`Loop` / `PingPong` / `Single`）
  - `defaultNext`: 既定遷移先タイムライン名（文字列）
- 不変条件：
  - `fps` は要件で定義されたセット（12 / 24 / 30 / 48 / 60 / 96 / 120）に含まれる。
  - `frameCount` は `fps` の倍数で、1 周するまでの時間が自然数ミリ秒になる。
  - `loopMode = Single` の場合、`defaultNext` は必須。
  - `identifier` は AssetCatalog 内で一意。

#### ドメインイベント

- `TimelineDefinitionRegistered`
  - 役割：新しいタイムライン定義が登録されたことを通知する。
  - フィールド：`identifier: TimelineIdentifier`, `fps: FramesPerSecond`, `frameCount: int`

#### リポジトリ契約

- `TimelineDefinitionRepository`
  - `find(identifier: TimelineIdentifier): TimelineDefinition`
    - 副作用：識別子に対応するタイムライン定義が見つからない場合は`AggregateNotFoundError`を投げる
  - `persist(timeline: TimelineDefinition): void`

### animation/atlas サブパッケージ

#### AtlasIdentifier （アトラス識別子／値オブジェクト）

- 目的：スプライトアトラス資源を一意に識別する。
- フィールド：
  - `value`: ULID 文字列（26 文字）
- 不変条件：
  - `value` は ULID フォーマットに一致する。
- 振る舞い：
  - **新規生成できる(generate)**
    - 入力：なし
    - 出力：`AtlasIdentifier`
    - 副作用：なし

#### SpriteAtlasDefinition （スプライトアトラス定義／エンティティ）

- 目的：PNG/JSON アトラスの構造とピボット情報を管理し、avatar/scene が同じアセットを再解釈しないようにする。
- フィールド：
  - `identifier`: `AtlasIdentifier`
  - `pngPath`: FilePath
  - `jsonPath`: FilePath
  - `gridSize`: GridSize
  - `pivot`: `Pivot`
- 不変条件：
  - `pngPath` と `jsonPath` は同一ディレクトリ直下に存在する。
  - `pivot.gridSize` と `gridSize` は一致する。
  - `identifier` は AssetCatalog の `identifier` と組み合わせて一意。
- 振る舞い：
  - **アトラス整合性を検証できる(validate)**
    - 入力：なし
    - 出力：なし
    - 副作用：PNG/JSON の存在・グリッド値・ピボット整合を確認し、違反時は例外を発する
- 備考：AnimationSpec との整合性検証は、両者を参照できる上位のコンテキスト（AssetPackage や AnimationBindingManifest）で行う。

#### ドメインイベント

- `SpriteAtlasDefinitionRegistered`
  - 役割：新しいスプライトアトラス定義が登録されたことを通知する。
  - フィールド：`identifier: AtlasIdentifier`, `gridSize: GridSize`, `pivot: Pivot`

#### リポジトリ契約

- `SpriteAtlasDefinitionRepository`
  - `find(identifier: AtlasIdentifier): SpriteAtlasDefinition`
    - 副作用：識別子に対応するアトラス定義が見つからない場合は`AggregateNotFoundError`を投げる
  - `persist(atlas: SpriteAtlasDefinition): void`

### animation/binding サブパッケージ

#### AnimationBindingIdentifier （アニメーションバインディング識別子／値オブジェクト）

- 目的：タイムラインとアトラスの組み合わせ定義を一意に識別する。
- フィールド：
  - `value`: ULID 文字列（26 文字）
- 不変条件：
  - `value` は ULID フォーマットに一致する。
- 振る舞い：
  - **新規生成できる(generate)**
    - 入力：なし
    - 出力：`AnimationBindingIdentifier`
    - 副作用：なし

#### AnimationBindingManifest （アニメーションバインディング仕様／エンティティ）

- 目的：タイムラインとアトラスの関連付け、利用可能フレーム、用途タグを管理し、他ドメインが表示フレームを特定できるようにする。
- フィールド：
  - `identifier`: `AnimationBindingIdentifier`
  - `timeline`: `TimelineIdentifier`
  - `atlas`: `AtlasIdentifier`
  - `frameCount`: 自然数（フレーム総数）
  - `frameRange`: 使用可能フレーム範囲（数値レンジ）
  - `tags`: 利用タグ（例：`typing` / `coffee` / `ambient` / `wardrobe`）
- 不変条件：
  - `timeline` と `atlas` は同じ AssetPackage に含まれている。
  - `frameCount` は参照する `TimelineDefinition` の値と一致する。
  - `frameRange` は `0 <= start <= end < frameCount` を満たす。
  - `tags` は定義済み用途一覧に含まれる。
- 振る舞い：
  - **タイムラインとアトラスを関連付けできる(bind)**
    - 入力：`TimelineIdentifier`, `AtlasIdentifier`
    - 出力：なし
    - 副作用：対応する AssetPackage を検証し、成功時にバインディングを確定する
  - **外部向けメタデータを提供できる(extractMetadata)**
    - 入力：なし
    - 出力：`TimelineIdentifier`, `AtlasIdentifier`, `frameCount`, `frameRange`
    - 副作用：なし（avatar / scene など呼び出し側は識別子のみ保持し、詳細情報はこの振る舞い経由で取得）

#### AnimationBindingSearchCriteria （アニメーションバインディング検索条件／値オブジェクト）

- 目的：用途タグやフレームレートでバインディングを検索する条件を型で表現する。
- フィールド：
  - `tags`: セット（任意）
  - `frameRate`: `FramesPerSecond`（任意）
- 不変条件：
  - `tags` を指定する場合は空集合不可
- 振る舞い：
  - **検索条件を生成できる(create)**
    - 入力：`tags?`, `frameRate?`
    - 出力：`AnimationBindingSearchCriteria`
    - 副作用：なし

#### ドメインイベント

- `AnimationBindingManifestUpdated`
  - 役割：アニメーションバインディング仕様が更新されたことを通知する。
  - フィールド：`binding: AnimationBindingIdentifier`, `timeline: TimelineIdentifier`, `atlas: AtlasIdentifier`, `tags: Set<String>`

#### リポジトリ契約

- `AnimationBindingManifestRepository`
  - `find(identifier: AnimationBindingIdentifier): AnimationBindingManifest`
    - 副作用：識別子に対応するマニフェストが見つからない場合は`AggregateNotFoundError`を投げる
  - `search(criteria: AnimationBindingSearchCriteria): List<AnimationBindingManifest>`
  - `persist(binding: AnimationBindingManifest): void`

## その他の共通値オブジェクト

#### AssetPackageType （アセットパッケージ種別／値オブジェクト：列挙）

- 目的：AssetPackage が扱うリソースの種類を明示し、検証分岐を簡潔にする。
- フィールド：列挙（`Character` / `Scene` / `UI` / `SFX` / `Track`）
- 不変条件：列挙値以外は許容しない。
- 振る舞い：
  - **トラック系か判定できる(isTrack)**
    - 入力：なし
    - 出力：真偽値
    - 副作用：なし
