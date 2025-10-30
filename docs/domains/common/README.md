# common パッケージ モデル

複数パッケージで共通利用する値オブジェクト・列挙・イベント契約を集約し、整合性と命名規約を統一する。要件定義書の全体要件（言語切替、昼夜演出、フェード/音量制御等）に紐づく基礎概念をここで管理する。

## モデル方針

- 共有概念は `common` で定義し、各パッケージ側では再定義せず参照のみを行う。
- 値オブジェクトは不変・検証ロジックを内包し、生成時に必ず制約を満たす。
- 列挙はアプリ全体で利用する選択肢の源泉とし、追加・変更は `common` に対して行う。
- クロスパッケージで購読されるイベントは `common` でスキーマを定義し、発火元パッケージはこれに準拠する。

## 値オブジェクト / 列挙

以下の概念はさらにサブパッケージへ分割して管理する。

### identifier パッケージ

#### ProfileIdentifier （プロフィール識別子／値オブジェクト）

- 目的：ユーザープロファイルや関連イベントを一意に識別する。
- フィールド：
  - `value`: ULID 文字列（26 文字）
- 不変条件：
  - `value` は ULID フォーマット（`[0-7][0-9A-HJKMNP-TV-Z]{25}`）に一致する。
- 振る舞い：
  - **新規生成できる(generate)**
    - 入力：なし
    - 出力：`ProfileIdentifier`
    - 副作用：なし

#### GenericIdentifier 指針（値オブジェクト設計ポリシー／ガイドライン）

- 目的：全集約で `xxxIdentifier` 命名を統一し、ULID で一意性を担保する。
- フィールド：
  - `value`: ULID 文字列（26 文字）
- 不変条件：
  - 任意の `xxxIdentifier` は ULID フォーマットを満たす。
- 備考：
  - 各ドメインごとに固有の `FooIdentifier` を定義し、本指針に基づいて生成・検証を行う。

### locale パッケージ

#### Language （言語／値オブジェクト：列挙）

- 目的：UI/コンテンツの言語切替を統一する。
- フィールド：
  - （列挙型） `ja` / `en`
- 不変条件：
  - 列挙値のみを使用する。
  - 将来追加の場合は locale パッケージで拡張する。

### theme パッケージ

#### ThemeMode （テーマモード／値オブジェクト：列挙）

- 目的：昼/夜/自動テーマを横断的に共有。
- フィールド：
  - （列挙型） `Day` / `Night` / `Auto`
- 不変条件：列挙値以外は許容しない。

### date パッケージ

#### DayPeriod （時間帯／値オブジェクト：列挙）

- 目的：朝/昼/夜に応じた衣装変更や演出制御。
- フィールド：
  - （列挙型） `Morning` / `Noon` / `Night`
- 不変条件：
  - `Morning` は 04:00–11:59（含む）を表す。
  - `Noon` は 12:00–17:59。
  - `Night` は 18:00–03:59。

#### OfflineGracePeriod （オフライン猶予期間／値オブジェクト）

- 目的：サブスクリプションのオフライン猶予時間を表現する。
- フィールド：
  - `minutes`: 自然数（1 以上）
- 不変条件：
  - `minutes > 0`
  - 0 以下は許容しない。必要なら別の DurationValue を導入して再利用。

#### Timeline （タイムライン／値オブジェクト）

- 目的：集約のライフサイクルにおける時刻情報（作成・更新）を管理する汎用的な値オブジェクト。
- フィールド：
  - `createdAt`: `DateTime` - 作成日時
  - `updatedAt`: `DateTime` - 更新日時
- 不変条件：
  - `createdAt <= updatedAt`
  - `createdAt` は未来の日時ではない（検証時の `DateTime.now()` と比較）
  - `updatedAt` は未来の日時ではない（検証時の `DateTime.now()` と比較）
- 振る舞い：
  - **経過時間を取得できる(age)**
    - 入力：
      - `now`: `DateTime` - 現在時刻
    - 出力：`Duration` - `createdAt` から `now` までの経過時間
    - 副作用：なし
  - **最終更新からの経過時間を取得できる(lastUpdateAge)**
    - 入力：
      - `now`: `DateTime` - 現在時刻
    - 出力：`Duration` - `updatedAt` から `now` までの経過時間
    - 副作用：なし
- 利用例：CatalogDownloadJob（import）、AssetCatalog（library）、PerformanceMonitor（telemetry）等の集約での時刻管理

### playback パッケージ

#### LoopMode （ループモード／値オブジェクト：列挙）

- 目的：音楽再生のループ挙動に一貫性を持たせる。
- フィールド：
  - （列挙型） `Single` / `Playlist`
- 不変条件：列挙値以外は許容しない。

#### FadeDuration （フェード時間／値オブジェクト）

- 目的：フェードイン/アウト時間の検証（ms 単位）。
- フィールド：
  - `milliseconds`: 自然数（0 を含む）
- 不変条件：
  - `milliseconds >= 0`
  - 推奨値は 500ms だが、ビジネスルールに応じて調整可。

#### VolumeLevel （音量レベル／値オブジェクト）

- 目的：音量設定(0.0–1.0)の検証。
- フィールド：
  - `value`: 浮動小数点（0.0 〜 1.0）
  - `isMuted`: 真偽値
- 不変条件：
  - `0.0 <= value <= 1.0`
  - ミュート時でも値は保持する。

### notification パッケージ

#### QuietHours （静音時間帯／値オブジェクト）

- 目的：通知のサイレント時間帯を共通管理。
- フィールド：
  - `start`: LocalTime（ローカル時刻）
  - `end`: LocalTime（ローカル時刻）
- 不変条件：
  - `start` と `end` は 0:00〜23:59 の間。
  - 基本は `end` が `start` より後（翌日跨ぎの場合は拡張時にルール追加）。

##### LocalTime （ローカル時刻／値オブジェクト）

- フィールド：
  - `hour`: 数値（0〜23）
  - `minute`: 数値（0〜59）
- 不変条件：
  - `0 <= hour < 24`
  - `0 <= minute < 60`

### storage パッケージ

#### FilePath （ファイルパス／値オブジェクト）

- 目的：ローカルファイルパスの妥当性を検証。
- フィールド：
  - `operatingSystem`: OperatingSystem（OS 列挙）
  - `path`: 文字列
- 不変条件：
  - `path` は空文字でない。
  - `path` は最大長（例：2048 文字）以内。
  - OS ごとのパス形式（禁止文字など）に従う。
    - macOS: `/` 区切り、 `:` 禁止。例: 正規表現 `/^(\/([^\/:]+))*$/`
    - iOS: macOS と同じ POSIX パスを使用。
    - Windows: `\` 区切り、 `<>:"/\|?*` 禁止。例: 正規表現 `/^([A-Za-z]:\\)?([^\\/:*?"<>|]+\\)*([^\\/:*?"<>|]+)?$/`
    - Android: POSIX パスに準拠（macOS と同様）。
- 利用例：LicenseRecord.licenseFilePath、AssetCatalog 内のアセット参照。

#### OperatingSystem （OS 種別／値オブジェクト：列挙）

- 目的：`FilePath` や OS 固有処理で利用する対象 OS を明示する列挙。
- フィールド：
  - （列挙型） `macOS` / `iOS` / `windows` / `android`
- 不変条件：列挙値以外を許容しない。
- 利用例：`FilePath.operatingSystem`、設定管理（フォルダの配置場所）、プレゼンテーション層での UI 分岐。

#### Checksum （チェックサム／値オブジェクト）

- 目的：ファイルの完全性と改ざん検知を保証する汎用的なチェックサム値オブジェクト。
- フィールド：
  - `algorithm`: `String` - アルゴリズム名（例：`sha256` / `blake3`）
  - `value`: `String` - ハッシュ値（16 進表記）
- 不変条件：
  - `algorithm` はサポート対象（`sha256`, `blake3` など）のいずれか
  - `value` は空文字でなく、2 文字 × ビット長/8 の 16 進数で構成される
- 備考：
  - `Checksum` 自体は純粋な値オブジェクトであり、生成時点で不変
  - ファイルからのハッシュ計算は `ChecksumCalculator` ドメインサービスに委譲
  - ドメインモデルは IO を直接扱わず、計算結果を受け取って `Checksum` を生成
- 利用例：AssetPackage（library）、CatalogDownloadJob（import）、FileResource（library）での整合性検証

#### ChecksumCalculator （チェックサム計算器／ドメインサービス）

- 目的：ファイルからハッシュ値を計算し、`Checksum` 値オブジェクトの生成を支援する。
- 責務：
  - ファイルの内容を読み取り、指定されたアルゴリズムでハッシュ値を計算
  - IO 操作をカプセル化し、ドメインモデルが直接ファイルシステムに依存しないようにする
- 振る舞い：
  - **チェックサムを計算できる(calculate)**
    - 入力：
      - `filePath`: `FilePath` - 計算対象ファイルパス
      - `algorithm`: `ChecksumAlgorithm` - 使用するアルゴリズム（`sha256` / `blake3` など）
    - 出力：`Checksum` - 計算されたチェックサム
    - 副作用：
      - ファイルを読み取り、ハッシュ値を計算
      - ファイルが存在しない場合やアクセスエラーの場合は例外を投げる
- 利用例：AssetPackage の整合性検証、CatalogDownloadJob のダウンロードファイル検証、FileResource の検証

### Identifier 指針

- 目的：全集約で `xxxIdentifier` を用いる命名規約を文書化。
- 内容：UUID もしくは ULID を推奨、外部公開が必要な場合は human-readable スラッグを追加メタで保持。

## 共通ドメインイベント

| イベント名              | 発火元                    | 主な購読先                    | ペイロード                                                  |
| ----------------------- | ------------------------- | ----------------------------- | ----------------------------------------------------------- |
| `ThemeChanged`          | profile                   | scene / avatar / notification | `profileIdentifier: ProfileIdentifier`, `mode: ThemeMode`   |
| `DayPeriodChanged`      | profile or clock サービス | avatar / scene / notification | `profileIdentifier: ProfileIdentifier`, `period: DayPeriod` |
| `SystemDndStateChanged` | OS ブリッジ               | notification / profile        | `enabled: boolean`, `startsAt?`, `endsAt?`                  |

#### SystemDndStateChanged （システム DND 状態変更／外部イベント）

- 目的：OS のおやすみモード（Do Not Disturb）状態が変化したことを通知する。
- フィールド：
  - `enabled`: 真偽値
  - `startsAt?`: DateTime（任意）
  - `endsAt?`: DateTime（任意）
- 備考：OS ブリッジから発火され、notification / profile パッケージが購読する。

> 他パッケージ固有のイベント（例：`EntitlementUpdated`, `CatalogDownloadCompleted`）はそれぞれのパッケージで定義し、必要に応じて `common` テーブルに参照リンクを追加する。

## ユーティリティ

- `ClockService` インターフェース
  - 役割：現在時刻・タイムゾーン・DayPeriod 変換を提供。profile/notification/avatar が依存。
- `EventBusContract`
  - 役割：共通イベントのシリアライズ形式（JSON schema）を定義。

## パッケージング対応表

| 共通概念 / 値オブジェクト         | 所属サブパッケージ | 利用パッケージ                                         | 主な用途                                       |
| --------------------------------- | ------------------ | ------------------------------------------------------ | ---------------------------------------------- |
| `Language`                        | locale             | profile, presentation, i18n                            | UI 言語切り替え                                |
| `ThemeMode`                       | theme              | profile, scene, presentation                           | テーマ設定・照明制御                           |
| `DayPeriod`                       | date               | avatar, scene, profile                                 | 衣装自動切替・照明                             |
| `LoopMode`                        | playback           | profile, media                                         | 再生モード一貫性                               |
| `FadeDuration`                    | playback           | profile, media                                         | フェード時間検証                               |
| `VolumeLevel`                     | playback           | profile, presentation, notification                    | 音量・ミュート設定                             |
| `QuietHours`                      | notification       | notification, profile                                  | 通知静音時間帯                                 |
| `Duration` / `OfflineGracePeriod` | date               | billing, work                                          | サブスクリプション猶予・コーヒーモーション間隔 |
| `FilePath`                        | storage            | licensing, media, library                              | ライセンスファイル・アセットパスの検証         |
| `ThemeChanged` イベント           | events             | profile (発火), scene/avatar/notification (購読)       | テーマ変更通知                                 |
| `DayPeriodChanged` イベント       | events             | profile/clock (発火), avatar/scene/notification (購読) | 朝昼夜変更の伝播                               |
| `SystemDndStateChanged` イベント  | events             | OS ブリッジ (発火), notification/profile (購読)        | OS DND 状態と通知設定の同期                    |
| `URL`                             | url                | library, import                                        | リソース参照・外部 API エンドポイント          |
| `SignedURL`                       | url                | library, import                                        | 一時アクセス URL・プリサインド URL             |
| `Range<T>`                        | variant            | library (FrameRange), 全般                             | 範囲表現・境界値検証                           |
| `Rational`                        | variant            | scene (ParallaxLayer), library (アニメーション速度)    | 有理数・自然数比・速度比率                     |
| `ValueObject`                     | variant            | 全パッケージ                                           | 値オブジェクトの基底インターフェース           |
| `Invariant`                       | variant            | 全パッケージ                                           | 不変条件検証の統一的提供                       |
| `EventBroker`                     | event              | 全パッケージ                                           | イベント駆動アーキテクチャの基盤               |
| `Transaction`                     | transaction        | 全パッケージ（リポジトリ操作）                         | トランザクション管理・データ整合性保証         |

### frame-rate パッケージ

#### FramesPerSecond （フレーム毎秒／値オブジェクト）

- 目的：アニメーションやループに使用する FPS 値を統一し、許可されたセットを強制する。
- フィールド：
  - `value`: 自然数（例：12, 24, 30, 48, 60, 96, 120）
- 不変条件：
  - `value` はサポート対象の自然数集合 `{12, 24, 30, 48, 60, 96, 120}` のいずれか。
- 振る舞い：
  - **新規生成できる(fromInt)**
    - 入力：自然数 `fps`
    - 出力：`FramesPerSecond`
    - 副作用：`fps` が許可セットに含まれない場合は例外を発する
  - **1 フレームあたりの時間を取得できる(frameDurationMs)**
    - 入力：なし
    - 出力：`double`（ミリ秒、`1000 / value`）
    - 副作用：なし
  - **指定フレーム数の合計時間を計算できる(totalDurationMs)**
    - 入力：`frameCount: int`
    - 出力：`double`（ミリ秒、`frameCount * 1000 / value`）
    - 副作用：なし

### url パッケージ

#### URL （URL／値オブジェクト）

- 目的：HTTP/HTTPS URL の妥当性を検証し、安全な URL 文字列を保証する。
- フィールド：
  - `value`: 文字列（URL 形式）
- 不変条件：
  - `value` は空文字でない
  - `value` は有効な URL 形式である
  - プロトコルは HTTP または HTTPS である
- 振る舞い：
  - **文字列から生成できる(fromString)**
    - 入力：`url: String`
    - 出力：`URL`
    - 副作用：無効な URL 形式の場合は例外を発する
  - **文字列表現を取得できる(toString)**
    - 入力：なし
    - 出力：`String`
    - 副作用：なし
- 利用例：AssetManifest 内のリソース参照、外部 API エンドポイント

#### SignedURL （署名付き URL／値オブジェクト）

- 目的：一時的なアクセス権限を持つ署名付き URL を安全に扱う。
- フィールド：
  - `url`: URL（基底 URL）
  - `expiresAt`: DateTime（有効期限）
- 不変条件：
  - `url` は有効な URL 値オブジェクトである
  - `expiresAt` は未来の日時である
- 振る舞い：
  - **有効期限が切れているか判定できる(isExpired)**
    - 入力：`currentTime: DateTime`
    - 出力：`bool`
    - 副作用：なし
- 利用例：クラウドストレージからの一時ダウンロード URL、プリサインドアップロード URL

### variant パッケージ

#### Range<T> （範囲／値オブジェクト）

- 目的：数値や比較可能な値の範囲を表現し、境界値の検証を提供する。
- 型パラメータ：
  - `T`: Comparable<T>を実装する型
- フィールド：
  - `min`: T（最小値）
  - `max`: T（最大値）
- 不変条件：
  - `min <= max`
- 振る舞い：
  - **値が範囲内かを判定できる(contains)**
    - 入力：`value: T`
    - 出力：`bool`
    - 副作用：なし
  - **2 つの範囲が重なるかを判定できる(overlaps)**
    - 入力：`other: Range<T>`
    - 出力：`bool`
    - 副作用：なし
- 利用例：FrameRange（フレーム範囲）、数値の妥当性検証

#### Rational （有理数／値オブジェクト）

- 目的：分数（有理数）を正確に表現し、整数演算で精度を保証する。
- フィールド：
  - `numerator`: BigInt（分子）
  - `denominator`: BigInt（分母）
- 不変条件：
  - `denominator != 0`（分母はゼロでない）
  - 分数は常に既約分数（最大公約数で約分済み）
  - 負の値は分子に符号を持ち、分母は常に正
- 振る舞い：
  - **整数から生成できる(fromInt)**
    - 入力：`value: int`
    - 出力：`Rational`
    - 副作用：なし
  - **文字列から生成できる(parse)**
    - 入力：`value: String`（例：`"3/4"`, `"5"`）
    - 出力：`Rational`
    - 副作用：無効な形式の場合は例外を発する
  - **浮動小数点数から生成できる(fromDouble)**
    - 入力：`value: double`, `maxDenominator: int?`, `epsilon: double?`
    - 出力：`Rational`
    - 副作用：NaN または無限大の場合は例外を発する
  - **四則演算ができる(+, -, \*, /)**
    - 入力：`other: Rational`
    - 出力：`Rational`
    - 副作用：除算でゼロ除算の場合は例外を発する
  - **比較ができる(compareTo, <, >, <=, >=)**
    - 入力：`other: Rational`
    - 出力：`int` または `bool`
    - 副作用：なし
  - **浮動小数点数に変換できる(toDouble)**
    - 入力：なし
    - 出力：`double`
    - 副作用：なし
  - **逆数を取得できる(reciprocal)**
    - 入力：なし
    - 出力：`Rational`
    - 副作用：分子がゼロの場合は例外を発する
  - **床関数を適用できる(floor)**
    - 入力：なし
    - 出力：`BigInt`
    - 副作用：なし
- 利用例：ParallaxLayer の speedRatio（自然数比）、アニメーション速度比率

## アーキテクチャ基盤

### event パッケージ

#### EventBroker （イベント仲介者／インフラストラクチャサービス）

- 目的：ドメインイベントの発行と購読を管理し、疎結合なイベント駆動アーキテクチャを実現する。
- 責務：
  - イベントの発行（publish）
  - イベント購読者の登録（subscribe）
  - 購読者へのイベント配信
- 振る舞い：
  - **イベントを発行できる(publish)**
    - 入力：`event: BaseEvent`
    - 出力：`Future<void>`
    - 副作用：登録された購読者にイベントを配信する
  - **イベントを購読できる(subscribe)**
    - 入力：`eventType: Type`, `handler: Function`
    - 出力：`Subscription`
    - 副作用：購読者リストに登録する
- 利用例：集約間のイベント通知、ドメインイベントの発行と購読

#### Transaction （トランザクション／インフラストラクチャサービス）

- 目的：複数のリポジトリ操作をアトミックに実行し、データの整合性を保証する。
- 責務：
  - トランザクションの開始
  - トランザクションのコミット
  - トランザクションのロールバック
- 振る舞い：
  - **トランザクション内で処理を実行できる(execute)**
    - 入力：`operation: Future<T> Function()`
    - 出力：`Future<T>`
    - 副作用：操作が成功すればコミット、失敗すればロールバックする
- 利用例：複数集約の一貫性保証、複数リポジトリ操作の原子性確保

### variant パッケージ

#### ValueObject （値オブジェクト基底／抽象インターフェース）

- 目的：全ての値オブジェクトに共通する契約を定義する。
- 責務：
  - 等価性の定義（構造的等価性）
  - ハッシュコードの定義
- 振る舞い：
  - **等価性を判定できる(equals)**
    - 入力：`other: Object`
    - 出力：`bool`
    - 副作用：なし
  - **ハッシュコードを取得できる(hashCode)**
    - 入力：なし
    - 出力：`int`
    - 副作用：なし
- 利用例：全ての値オブジェクトの基底インターフェース

#### Invariant （不変条件検証／ユーティリティ）

- 目的：値オブジェクトの不変条件検証を統一的に提供する。
- 責務：
  - 範囲検証
  - 長さ検証
  - 非 null 検証
  - パターン検証
- 静的メソッド：
  - **範囲検証(range)**
    - 入力：`value: T`, `name: String`, `min: T`, `max: T?`
    - 出力：なし
    - 副作用：範囲外の場合は InvariantViolationError を発する
  - **長さ検証(length)**
    - 入力：`value: String`, `name: String`, `min: int`, `max: int?`
    - 出力：なし
    - 副作用：長さが範囲外の場合は例外を発する
  - **非 null 検証(notNull)**
    - 入力：`value: T?`, `name: String`
    - 出力：なし
    - 副作用：null の場合は例外を発する
  - **パターン検証(pattern)**
    - 入力：`value: String`, `name: String`, `pattern: RegExp`
    - 出力：なし
    - 副作用：パターンに一致しない場合は例外を発する
- 利用例：全ての値オブジェクトのコンストラクタでの検証
