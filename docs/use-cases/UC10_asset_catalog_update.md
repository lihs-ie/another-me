# ユースケース UC10: アセットカタログ更新の検証と展開（開発者ツール）

## 目的
- 制作チームが追加・修正したアセットパッケージを自動検証し、catalog.json を構築・公開する。

## アクター
- メインアクター：開発者ツール（AssetCatalogBuilder）
- サポートアクター：CI/CD、PipelineSubmissionSubscriber

## 事前条件
- 新しいアセットバンドルが制作パイプラインから提出されている。
- バンドルには PNG / JSON アトラス、チェックサムなどのメタファイルが含まれている。

## トリガー
- `PipelineBundleSubmitted` イベントが投稿される、または CI/CD がアセットの ZIP を配置する。

## 基本フロー
1. PipelineSubmissionSubscriber がバンドルのファイル構成とチェックサムを検証する。
2. 検証に合格した場合、`AssetCatalogBuilder.addPackage` を呼び出し、該当パッケージを新バージョンのカタログに組み込む。
3. `AssetCatalogBuilder.validateAll()` がすべてのパッケージの整合性を検証する（AnimationSpec との互換性チェック、Track パッケージの音源ハッシュ・ライセンスメタ検証など）。
4. 検証成功時、`AssetCatalogBuilder.publish()` が実行され、`AssetCatalogPublished` イベントが発火する。
5. `AssetCatalogBuilder.uploadToStorage()` が catalog.json を Firebase Storage へアップロードする。
6. 本番アプリが公式サーバーから catalog.json をダウンロードし、Avatar / Scene / Media パッケージが新アセットを利用可能にする。

## 代替フロー
- **差分更新**: 一部ファイルのみ更新された場合でも、catalog.json 全体を再構築して配信する（本番アプリ側で差分を判断）。
- **ロールバック**: 不具合が見つかった場合、前バージョンの catalog.json を Firebase Storage へ再アップロードする。

## 例外フロー
- **検証失敗**: PNG サイズが規定外、または JSON スキーマが不正な場合、`PipelineBundleRejected` を返却して制作チームへ差し戻す。
- **互換性エラー**: 新アニメーションの fps や frameCount がルール外だった場合、`AssetCatalogBuilder.validateAll()` が例外を発し、公開を中止する。

## 事後条件
- catalog.json が Firebase Storage へ公開され、本番アプリがダウンロード可能になる。
- 検証結果がログに記録され、次回更新時のレビューに活用できる。

## 内部設計（アプリケーション層）

### AssetCatalogUpdated イベント購読時の Scene 検証
- 本番アプリが新しい catalog.json をダウンロードした後、`AssetCatalogUpdated` イベントが発火される。
- `AssetCatalogUpdatedSubscriber`（scene パッケージ）が以下の処理を実行：
  1. `SceneRepository.all()` で全ての Scene を取得
  2. 各 Scene の `animationBinding.binding` が新しい `AssetCatalog` に存在するか確認
  3. 存在する場合：
     - `AnimationBindingRepository.find(animationBinding.binding)` で最新の `AnimationBindingManifest` を取得
     - `SceneFactory.create()` と同様の検証（24fps、ambient タグ、validFrames）を実施
     - 検証成功: `SceneUpdated` イベントを発火（必要に応じて）
     - 検証失敗: `scene.status` を `Deprecated` に変更し、`SceneDeprecated` イベントを発火
  4. 存在しない場合:
     - `scene.status` を `Deprecated` に変更し、`SceneDeprecated` イベントを発火
  5. 変更された Scene を `SceneRepository.persist(scene)` で永続化
- この処理により、アセット更新後も Scene の整合性が保たれる。

### Scene の再登録
- 新しい `AssetCatalog` に新しいシーン用の `AnimationBindingManifest` が追加された場合：
  1. `SceneFactory.create()` を使用して新しい Scene を生成・検証
  2. 検証成功時: `SceneRepository.persist(scene)` で永続化し、`SceneRegistered` イベントを発火
  3. 検証失敗時: Scene の生成を中止し、ログに記録

## 関連ドキュメント
- 開発者ツール設計：`@docs/tooling/asset-catalog-builder.md`
- 本番アプリのドメインモデル：`@docs/domains/library/README.md`
- Scene ドメインモデル：`@docs/domains/scene/README.md`
# ユースケース UC10: アセットカタログ更新の検証と展開（開発者ツール）

## 外部設計

### 目的
- 制作チームが提出したアセットバンドルを自動検証し、公式 catalog.json を再構築・公開する。

### アクター
- メインアクター：開発者ツール（AssetCatalogBuilder）
- サポートアクター：CI/CD、PipelineSubmissionSubscriber、本番アプリ

### 事前条件
- 新しいアセットバンドルが制作パイプラインから提出されている（PNG・JSON アトラス、チェックサム、ライセンスメタを含む）。
- 検証用のリソース（AnimationSpec、License 定義、音源ファイル）が揃っている。

### トリガー
- `PipelineBundleSubmitted` イベント、または CI/CD がアセット ZIP を配置する。

### 基本フロー
1. `PipelineSubmissionSubscriber` がバンドルのファイル構成とチェックサムを検証する。失敗時は `PipelineBundleRejected` を返す。
2. 検証に合格した場合、`AssetCatalogBuilder.addPackage(bundle)` が呼ばれ、新バージョンのカタログにパッケージが組み込まれる。
3. `AssetCatalogBuilder.validateAll()` が AnimationSpec や Track メタとの整合性をチェックし、fps・frameCount・チェックサム・ライセンス一致を確認する。
4. 検証成功後、`AssetCatalogBuilder.publish()` が実行され、`AssetCatalogPublished` イベントが発火する。同時に catalog.json が生成される。
5. `AssetCatalogBuilder.uploadToStorage()` が catalog.json を Firebase Storage 等の配布先へアップロードする。
6. 本番アプリが catalog.json をダウンロードし、Avatar/Scene/Media 境界が新アセットを利用可能にする。整合性確認のため `AssetCatalogUpdated` が発火する。

### 代替フロー
- **差分更新**：一部ファイルのみ変更された場合でも catalog.json 全体を再構築し、本番アプリ側が差分適用を判断する。
- **ロールバック**：不具合が発覚したら旧バージョンの catalog.json を再アップロードし、`AssetCatalogRollbacked` を通知する。

### 例外フロー
- **検証失敗**：PNG サイズや JSON スキーマが規定外の場合、`PipelineBundleRejected` が返される。原因は開発チームへ通知。
- **互換性エラー**：AnimationSpec との互換性（fps・frameCount）が満たされない場合、`AssetCatalogBuilder.validateAll()` が例外を投げ、公開処理を中断する。

### 事後条件
- catalog.json が配布ストレージへ公開され、本番アプリが最新アセットを取得できる。
- 検証結果が CI/CD ログに保存され、次回更新時のレビューに活用できる。

## 内部設計

### 関連ドメインモデル

#### AssetCatalogBuilder（tooling）
- 概要：アセットカタログの組成・検証・公開を行うビルダー。
- 主な振る舞い：
  - `addPackage(bundle)`：提出バンドルを検証してカタログへ追加。
  - `validateAll()`：AnimationSpec、ライセンス、音源チェックサムを一括検証。
  - `publish()`：catalog.json を生成し、`AssetCatalogPublished` を発火。
  - `uploadToStorage()`：生成物を配布ストレージへアップロード。

#### PipelineSubmissionSubscriber（tooling）
- 概要：制作パイプラインからの提出を監視し、バンドルの構造・チェックサム検証を担当する。

#### AssetCatalog（library）
- 概要：アプリ本体が参照するアセットメタデータ集約。`AssetCatalogUpdated` を通じて境界へ通知。

#### SceneFactory / CharacterFactory（scene / avatar）
- 概要：新しいアニメーションバインディングを検証して Scene / Character を再生成する。
- 役割：`AssetCatalogUpdated` 後、アセットの整合性を再確認する。

### データフロー
1. 提出イベント → `PipelineSubmissionSubscriber` が構造・チェックサム検証。
2. 成功時、`AssetCatalogBuilder.addPackage` → `validateAll` → `publish` → `uploadToStorage`。
3. `AssetCatalogPublished` が CI/CD と監査ログへ通知される。
4. 本番アプリが catalog.json を取得し、`AssetCatalogUpdated` を発火。Scene/Avatar/Media 境界が新リソースを検証し、必要に応じて再登録または Deprecated 化する。
