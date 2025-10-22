# billing パッケージ モデル

将来対応の課金・利用制限ドメイン。要件の「課金・利用制限」セクションに基づき、プラン・サブスクリプション・権利・使用数を管理する。

## モデル方針
- プラン設定（無料/有料）は `Plan` 集約で管理し、上限値を明示する。
- 購読状態（有効期限・領収書）は `Subscription` 集約で保持し、検証結果とステータス遷移を管理する。
- 実効的な権利集合は `Entitlement` 集約で計算し、使用数カウンタ（`EntitlementUsage` 値オブジェクト）を同一取引で更新する。
- イベントサブスクライバがメディア/アバター/プロフィールの利用状況を監視し、上限超過時に自動調整する。

## Plan 集約

#### Price （価格／値オブジェクト）
- 目的：プランの価格を表現し、負の値や不正な値を防ぐ。
- フィールド：
  - `amount`: 浮動小数点（0 以上）
- 不変条件：
  - `amount >= 0`（負の価格は許容しない）
- 振る舞い：
  - **価格を生成できる(create)**
    - 入力：`amount`（浮動小数点）
    - 出力：`Price`
    - 副作用：不変条件違反時（負の値）は例外を発する
  - **無料価格を生成できる(free)**
    - 入力：なし
    - 出力：`Price`（amount = 0）
    - 副作用：なし

#### Currency （通貨／値オブジェクト）
- 目的：ISO 4217 準拠の通貨コードを表現し、不正な通貨コードを防ぐ。
- フィールド：
  - `code`: 文字列（3 文字の ISO 4217 コード）
- 不変条件：
  - `code` は 3 文字である
  - `code` は大文字のアルファベットのみで構成される（例：USD, JPY, EUR）
- 振る舞い：
  - **通貨を生成できる(create)**
    - 入力：`code`（文字列）
    - 出力：`Currency`
    - 副作用：不変条件違反時は例外を発する
  - **文字列表現を取得できる(toString)**
    - 入力：なし
    - 出力：`String`
    - 副作用：なし

#### PlanIdentifier （プラン識別子／値オブジェクト）
- 目的：課金プランを一意に識別する。
- フィールド：
  - `value`: ULID 文字列（26 文字）
- 不変条件：
  - `value` は ULID フォーマットに一致する。
- 振る舞い：
  - **新規生成できる(generate)**
    - 入力：なし
    - 出力：`PlanIdentifier`
    - 副作用：なし

#### Limit （上限値／値オブジェクト）

- **何を表したドメインモデルなのか**
  - 概要：リソース（楽曲数、キャラクター数）の上限値を表現し、無制限と具体的な数値を型安全に区別する
  - 役割：上限チェックのロジックを一箇所に集約し、`null`による無制限表現の曖昧さを排除する

- **フィールド**
  - `_value`: `int?`（プライベート）
    - `null`の場合は無制限を意味する
    - 0以上の整数の場合は具体的な上限値

- **不変条件**
  - `_value`が指定される場合は0以上である
  - 無制限を表現する場合は必ず`Limit.unlimited()`ファクトリメソッドを使用する

- **振る舞い**
  - **制限値付きの上限を生成できる(limited)**
    - 処理の内容：指定された整数値で上限を設定する
    - 入力：`value`（整数、0以上）
    - 出力：`Limit`
    - 副作用：`value`が負の場合は`InvariantViolationError`を投げる

  - **無制限の上限を生成できる(unlimited)**
    - 処理の内容：上限なし（無制限）を表現するLimitを生成する
    - 入力：なし
    - 出力：`Limit`（内部的には`_value`が`null`）
    - 副作用：なし

  - **無制限かどうかを判定できる(isUnlimited)**
    - 処理の内容：このLimitが無制限かどうかを返す
    - 入力：なし
    - 出力：`bool`（無制限の場合は`true`）
    - 副作用：なし

  - **現在の使用数が上限内かを判定できる(allows)**
    - 処理の内容：指定された使用数が上限を超えていないかをチェックする
    - 入力：`current`（現在の使用数）
    - 出力：`bool`（上限内であれば`true`、無制限の場合も`true`）
    - 副作用：なし

  - **上限値を取得できる(value)**
    - 処理の内容：上限値を取得する（無制限の場合は`null`）
    - 入力：なし
    - 出力：`int?`
    - 副作用：なし

#### Plan （プラン／集約）
- 目的：無料/有料プランの上限値と料金を管理する。
- フィールド：
  - `identifier`: `PlanIdentifier`
  - `name`: 文字列
  - `limits`: `PlanLimit`
  - `price`: `Price`
  - `currency`: `Currency`
  - `status`: `PlanStatus`（`Active` / `Deprecated`）
- 不変条件：
  - 無料プランの場合、`price.amount` は 0 である。
  - `limits` は有効な `PlanLimit` である。

#### PlanLimit （プラン上限／値オブジェクト）

- **何を表したドメインモデルなのか**
  - 概要：プランごとの楽曲数・キャラクター数の上限を一つの単位として表現する
  - 役割：複数のリソース種別の上限を統一的に管理し、プラン全体の制約を表現する

- **フィールド**
  - `tracks`: `Limit`
    - 楽曲数の上限
  - `characters`: `Limit`
    - キャラクター数の上限

- **不変条件**
  - `tracks`と`characters`は両方とも有効な`Limit`である

- **振る舞い**
  - **プラン上限を生成できる（コンストラクタ）**
    - 処理の内容：楽曲数とキャラクター数の上限を持つPlanLimitを生成する
    - 入力：`tracks`（`Limit`）, `characters`（`Limit`）
    - 出力：`PlanLimit`
    - 副作用：なし

- **使用例**：
  ```dart
  final freeLimit = PlanLimit(
    tracks: Limit.limited(3),
    characters: Limit.limited(2),
  );

  final paidLimit = PlanLimit(
    tracks: Limit.unlimited(),
    characters: Limit.unlimited(),
  );

  if (!freeLimit.tracks.allows(currentTracks)) {
    throw EntitlementLimitExceededError('Track limit reached');
  }
  ```

#### ドメインイベント
- `PlanUpdated`
  - 役割：プランの上限値や状態が更新されたことを通知する。
  - フィールド：
    - `plan: PlanIdentifier`
    - `limits: PlanLimit`

## Subscription 集約

#### SubscriptionIdentifier （サブスクリプション識別子／値オブジェクト）
- 目的：ユーザーの購読契約を一意に識別する。
- フィールド：
  - `value`: ULID 文字列（26 文字）
- 不変条件：
  - `value` は ULID フォーマットに一致する。
- 振る舞い：
  - **新規生成できる(generate)**
    - 入力：なし
    - 出力：`SubscriptionIdentifier`
    - 副作用：なし

#### Subscription （サブスクリプション／集約）
- 目的：購読状態・有効期限・領収書を管理する。
- フィールド：
  - `identifier`: `SubscriptionIdentifier`
  - `plan`: `PlanIdentifier`
  - `status`: `SubscriptionStatus`（`Active` / `Expired` / `Grace` / `Canceled`）
  - `expiresAt`: 日時
  - `gracePeriodEndsAt`: 日時（任意）
  - `offlineGracePeriod`: OfflineGracePeriod
  - `receipt`: `PurchaseReceipt`
  - `lastSyncedAt`: 日時
- 不変条件：
  - `expiresAt` は登録日時以降。
  - `gracePeriodEndsAt` は `expiresAt` 以降。
  - `offlineGracePeriod` 内では `lastSyncedAt` からの経過時間でオフライン利用可否を判定。

#### PurchaseReceipt （購入領収書／値オブジェクト）
- 目的：決済プロバイダから発行される購入証跡を保持し、サブスクリプション検証に利用する。
- フィールド：
  - `provider`: 文字列（決済プロバイダ名、例：`AppStore`, `GooglePlay`, `Stripe`）
  - `transactionIdentifier`: `TransactionIdentifier`
  - `signature`: 文字列（検証用署名）
- 不変条件：
  - `provider` は空文字でない。
  - `provider` は 1〜50 文字以内。
  - `signature` は空文字でない。
- 振る舞い：
  - **購入領収書を生成できる(create)**
    - 入力：`provider`（文字列）, `transactionIdentifier`（`TransactionIdentifier`）, `signature`（文字列）
    - 出力：`PurchaseReceipt`
    - 副作用：不変条件違反時は例外を発する

#### TransactionIdentifier （取引識別子／値オブジェクト）
- 目的：決済プロバイダのトランザクションを一意に識別する。
- フィールド：
  - `value`: ULID 文字列（26 文字）
- 不変条件：
  - `value` は ULID フォーマットに一致する。
- 振る舞い：
  - **新規生成できる(generate)**
    - 入力：なし
    - 出力：`TransactionIdentifier`
    - 副作用：なし

- フィールド更新：
  - `transactionIdentifier`: `TransactionIdentifier`
- 不変条件：空文字不可。

#### SubscriptionStatus （サブスクリプションステータス／値オブジェクト：列挙）
- 目的：サブスクリプションのライフサイクル状態を明確に区別し、有効期限・猶予期間・解約の管理を支援する。
- フィールド：
  - 列挙（`Active` / `Expired` / `Grace` / `Canceled`）
- 不変条件：
  - 列挙値以外は許容しない。
- 状態の意味：
  - `Active`：サブスクリプションが有効で、すべての機能が利用可能。
  - `Expired`：有効期限（`expiresAt`）を過ぎ、猶予期間も終了している状態。
  - `Grace`：有効期限を過ぎたが、猶予期間（`gracePeriodEndsAt`）内にあり、限定的な利用が可能。
  - `Canceled`：ユーザーまたはシステムにより明示的に解約された状態。

#### OfflineGracePeriod （オフライン猶予期間／値オブジェクト）
- 目的：オフライン環境でのサブスクリプション利用可否を判定するための猶予時間を表現する。
- フィールド：
  - `days` または `minutes`（自然数、例：1〜30 日）
- 不変条件：
  - 指定された期間は自然数である。
  - 日数指定の場合は 1〜30 日の範囲内。

#### ドメインイベント
- `SubscriptionActivated`
  - 役割：利用者のサブスクリプションが有効化されたことを通知する。
  - フィールド：
    - `subscription: SubscriptionIdentifier`
    - `plan: PlanIdentifier`
    - `expiresAt: DateTime`
- `SubscriptionExpired`
  - 役割：サブスクリプションが期限切れになったことを通知する。
  - フィールド：
    - `subscription: SubscriptionIdentifier`
- `SubscriptionGraceEntered`
  - 役割：サブスクリプションが猶予期間に入ったことを通知する。
  - フィールド：
    - `subscription: SubscriptionIdentifier`
    - `gracePeriodEndsAt: DateTime`

#### Subscription 状態遷移図

```
[初期] → Active → Expired → Canceled
              ↓      ↑
            Grace ──┘

遷移ルール：
- Active → Grace: expiresAtを過ぎたが、gracePeriodEndsAt以内
- Grace → Active: サブスクリプション更新成功
- Grace → Expired: gracePeriodEndsAtを過ぎた
- Active/Grace/Expired → Canceled: ユーザーまたはシステムによる明示的な解約
- Canceled → Active: 不可（新規サブスクリプションが必要）
```

#### オフライン検証の仕組み

- **オンライン時**：
  - サブスクリプション検証APIを呼び出し
  - `lastSyncedAt`を現在時刻に更新
  - 検証結果に基づいて`status`を更新

- **オフライン時**：
  - `lastSyncedAt`からの経過時間を計算
  - `offlineGracePeriod`（例：7日）以内であれば、キャッシュされた状態を信頼
  - 超過した場合は、次回オンライン時に再検証を強制

- **状態とEntitlementの関係**：
  - `Active`: Entitlement.limitsはPlan.limitsと同期
  - `Grace`: Entitlement.limitsは維持（猶予期間中は継続利用可）
  - `Expired`: EntitlementQuotaAdjustedイベントを発火、Freeプランの制限に戻す
  - `Canceled`: 即座にFreeプランの制限に戻す

## EntitlementService インターフェース

#### EntitlementService （権利チェックサービス／インターフェース）

- **何を表したドメインモデルなのか**
  - 概要：現在のユーザーの利用権限（Entitlement）に基づいて、リソース追加の可否を判定するサービスインターフェース
  - 役割：billing境界の内部実装（Plan、Entitlement）を隠蔽し、他境界（media、avatar）に対して上限チェック機能を提供する

- **振る舞い**
  - **楽曲追加可能かチェックできる(canAddTrack)**
    - 処理の内容：現在の楽曲数が上限内かどうかを判定する
    - 入力：`currentTrackCount`（現在の楽曲数）
    - 出力：`Future<bool>`（追加可能であれば`true`）
    - 副作用：なし（読み取り専用）

  - **キャラクター使用可能かチェックできる(canUseCharacter)**
    - 処理の内容：現在のキャラクター数が上限内かどうかを判定する
    - 入力：`currentCharacterCount`（現在のキャラクター数）
    - 出力：`Future<bool>`（使用可能であれば`true`）
    - 副作用：なし（読み取り専用）

  - **楽曲数上限を取得できる(getTrackLimit)**
    - 処理の内容：現在適用されているプランの楽曲数上限を取得する
    - 入力：なし
    - 出力：`Future<int>`（無制限の場合は十分に大きな値、例：`int.maxValue`）
    - 副作用：なし（読み取り専用）

  - **キャラクター数上限を取得できる(getCharacterLimit)**
    - 処理の内容：現在適用されているプランのキャラクター数上限を取得する
    - 入力：なし
    - 出力：`Future<int>`（無制限の場合は十分に大きな値、例：`int.maxValue`）
    - 副作用：なし（読み取り専用）

- **実装の責務**
  - billing境界で実装を提供する
  - `Entitlement`集約から現在の上限（`limits`）と使用数（`usage`）を取得
  - `Limit.allows()`メソッドを使用して判定

- **依存関係**
  - media境界：`Playlist.addTrack`呼び出し前にこのインターフェースを使用
  - avatar境界：キャラクター解放前にこのインターフェースを使用
  - 依存性逆転の原則により、media/avatar境界はインターフェースのみに依存
  - ユースケース層でDIコンテナを使って実装を注入

- **ユースケースとの連携**
  - 詳細は`docs/use-cases/UC_XX_add_track_to_playlist.md`を参照
  - ハッピーパス：`canAddTrack() == true` → `Playlist.addTrack()` → 成功
  - エラーパス：`canAddTrack() == false` → `EntitlementLimitExceededError` → ユーザーに通知

- **イベント駆動と事前チェックの役割分担**
  - **通常フロー（ユーザー操作）**：
    - `Playlist.addTrack`呼び出し前に`EntitlementService.canAddTrack`でチェック
    - 上限に達している場合は`EntitlementLimitExceededError`を投げて追加を拒否
    - これにより事前にユーザーに通知でき、UXが向上
  - **例外フロー（プラン変更・同期）**：
    - `PlanUpdated`イベントでプランが変更された場合（例：Paid→Free）
    - `SubscriptionExpired`イベントでサブスクリプションが期限切れになった場合
    - `EntitlementQuotaAdjusted`イベントを発火し、profile境界が自動削減を実行
    - この場合のみ`EntitlementRestricted`を使用し、ユーザーに「プラン変更により削減されました」と通知
  - **整合性保証（リカバリ）**：
    - `MediaUsageSubscriber`は使用数を追跡するが、上限チェックは行わない
    - 整合性の再計算（実リソース数との照合）はユースケース層で定期的に実行
    - 不整合が検出された場合のみ補正を行う

## Entitlement 集約

#### EntitlementIdentifier （権利識別子／値オブジェクト）
- 目的：利用権利エンティティを一意に識別する。
- フィールド：
  - `value`: ULID 文字列（26 文字）
- 不変条件：
  - `value` は ULID フォーマットに一致する。
- 振る舞い：
  - **新規生成できる(generate)**
    - 入力：なし
    - 出力：`EntitlementIdentifier`
    - 副作用：なし

#### Entitlement （権利情報／集約）
- 目的：プラン・サブスクリプションから実効的な上限値を算出し、使用数を追跡する。
- フィールド：
  - `identifier`: `EntitlementIdentifier`
  - `plan`: `PlanIdentifier`
  - `subscription`: `SubscriptionIdentifier`（任意）
  - `version`: 自然数（0 を含む）
  - `lastProcessedSequenceNumber`: 自然数（0 を含む、初期値 0）
  - `limits`: PlanLimit
  - `usage`: `EntitlementUsage`
  - `status`: `EntitlementStatus`（`Active` / `Restricted`）
- 不変条件：
  - `usage.tracks <= limits.tracks`（制限ありの場合）。
  - `usage.characters <= limits.characters`。
  - `version` は更新ごとにインクリメントされ、過去バージョンとの整合性を検証する。
  - 使用数更新イベントには単調増加する `sequenceNumber` を付与し、`lastProcessedSequenceNumber` より大きい値のみ処理する。
- 振る舞い：
  - **プラン情報と同期できる(syncWithPlan)**
    - 入力：`planIdentifier`（`PlanIdentifier`）、`limits`（`PlanLimit`）
    - 出力：なし
    - 副作用：`limits` と `status` を再計算し、`version` をインクリメントして `EntitlementUpdated` を発火する
  - **使用数を増減できる(adjustUsage)**
    - 入力：`tracksDelta`（整数）、`charactersDelta`（整数）、`sequenceNumber`（自然数）
    - 出力：なし
    - 副作用：`usage` を更新し、`version` をインクリメント。上限制約を超えた場合は `EntitlementRestricted` を発火し、処理した `sequenceNumber` を `lastProcessedSequenceNumber` として記録する

注記：使用数の整合性再計算（実リソース数との照合）はリポジトリアクセスが必要なため、ユースケース層で実施する。ユースケース層でMediaリポジトリ・Avatarリポジトリから実在リソース数を取得し、Entitlementの `usage` と比較して差分があれば `adjustUsage` を呼び出して補正する。

#### Entitlement の sequenceNumber 管理

- **sequenceNumber の粒度と生成方式**：
  - **推奨アプローチ：プロファイル単位のグローバルシーケンス**
    - 各プロファイルごとに単調増加するグローバルシーケンス番号を管理
    - すべてのドメインイベント（TrackRegistered、CharacterUnlocked等）が同一のシーケンス空間を共有
    - EventBrokerまたはイベントストアがプロファイル単位でシーケンス番号を採番
    - これにより、Track/Character間のイベント順序も保証される

  - **代替アプローチ：リソース種別ごとの独立シーケンス**
    - Track用とCharacter用で独立した`lastProcessedSequenceNumber`を保持
    - `Entitlement`フィールド：`lastProcessedTrackSequence: int`, `lastProcessedCharacterSequence: int`
    - メリット：リソース種別ごとの独立性が高い
    - デメリット：整合性チェックが複雑化（両方のシーケンスを確認する必要）

  - **全イベント共通のグローバルシーケンス（非推奨）**
    - システム全体で単一のシーケンスを使用
    - マルチプロファイル環境では競合が発生しやすく、スケールしない

- **冪等性の保証（プロファイル単位グローバルシーケンスの場合）**：
  - `Entitlement.adjustUsage(sequenceNumber)`は以下のロジックで処理：
    ```dart
    if (sequenceNumber <= lastProcessedSequenceNumber) {
      return;
    }

    usage = usage.adjust(tracksDelta, charactersDelta);
    lastProcessedSequenceNumber = sequenceNumber;
    version++;
    ```

- **順序逆転の扱い**：
  - EventBrokerが順序通りの配信を保証することを前提とする
  - 順序逆転が発生した場合（古いsequenceNumberが後から到着）は無視
  - 警告ログを出力し、モニタリングで検知可能にする
  - 長期的な不整合は定期的な整合性チェック（後述）で補正

- **整合性チェック手順（リソース種別ごとの独立シーケンスを使用する場合）**：
  1. MediaリポジトリからアクティブなTrack数を取得
  2. AvatarリポジトリからアンロックされたCharacter数を取得
  3. Entitlementの`usage.tracks`および`usage.characters`と比較
  4. 差分がある場合：
     - 最新のsequenceNumberを取得（各リソース種別ごと）
     - `adjustUsage`を呼び出して補正
     - `EntitlementUsageReconciled`イベントを発火（監査用）
  5. 定期実行：アプリケーション起動時、プラン変更時、または1日1回のバッチ処理

- **EventBrokerへの要求仕様**：
  - プロファイル単位でイベントキューを分離
  - 各キュー内でsequenceNumberの単調増加を保証
  - イベント永続化時にsequenceNumberを記録
  - 実装はインフラ層で行い、詳細は`docs/cross-cutting/event-broker.md`を参照

#### EntitlementUsage （使用数／値オブジェクト）
- フィールド：
  - `tracks`: 数値（0 以上）
  - `characters`: 数値（0 以上）
- 不変条件：負値禁止。

#### EntitlementStatus （状態／値オブジェクト：列挙）
- 列挙：`Active` / `Restricted`

#### OverLimitType （制限超過種別／列挙型）

- **何を表したドメインモデルなのか**
  - 概要：どのリソースが上限を超えたかを型安全に表現する
  - 役割：EntitlementRestrictedイベントで超過したリソース種別を明確に伝達する

- **列挙値**：
  - `tracks`: 楽曲数が上限超過
  - `characters`: キャラクター数が上限超過

#### ドメインイベント
- `EntitlementUpdated`
  - 役割：利用権限の上限・使用数が更新されたことを通知する。
  - フィールド：
    - `entitlement: EntitlementIdentifier`
    - `limits: PlanLimit`
    - `usage: EntitlementUsage`
    - `status: EntitlementStatus`
- `EntitlementRestricted`
  - 役割：使用数が上限を超え、制限状態になったことを通知する。
  - フィールド：
    - `entitlement: EntitlementIdentifier`
    - `overLimitType: OverLimitType`（列挙型）
    - `currentUsage: EntitlementUsage`
    - `limits: PlanLimit`
    - `occurredAt: DateTime`
- `EntitlementQuotaAdjusted`
  - 役割：プラン変更などで Entitlement の上限を再計算したことを他ドメインへ伝える。
  - フィールド：
    - `entitlement: EntitlementIdentifier`
    - `limits: PlanLimit`

### リポジトリ契約
- `PlanRepository`
  - `find(identifier: PlanIdentifier): Plan`
    - 副作用：識別子に対応するプランが見つからない場合は`AggregateNotFoundError`を投げる
  - `all(): List<Plan>`
  - `persist(plan: Plan): void`
- `SubscriptionRepository`
  - `find(identifier: SubscriptionIdentifier): Subscription`
    - 副作用：識別子に対応するサブスクリプションが見つからない場合は`AggregateNotFoundError`を投げる
  - `persist(subscription: Subscription): void`
- `EntitlementRepository`
  - `find(identifier: EntitlementIdentifier): Entitlement`
    - 副作用：識別子に対応するエンタイトルメントが見つからない場合は`AggregateNotFoundError`を投げる
  - `persist(entitlement: Entitlement): void`

## デフォルトプラン定義

システム起動時に以下のデフォルトプランを登録：

```dart
final freePlan = Plan(
  identifier: PlanIdentifier.fromString('FREE_PLAN_V1'),
  name: 'Free',
  limits: PlanLimit(
    tracks: Limit.limited(3),
    characters: Limit.limited(2),
  ),
  price: Price.free(),
  currency: Currency.create('JPY'),
  status: PlanStatus.active,
);

final paidPlan = Plan(
  identifier: PlanIdentifier.fromString('PAID_PLAN_V1'),
  name: 'Premium',
  limits: PlanLimit(
    tracks: Limit.unlimited(),
    characters: Limit.unlimited(),
  ),
  price: Price.create(amount: 980.0),
  currency: Currency.create('JPY'),
  status: PlanStatus.active,
);
```

初期バージョンでは全ユーザーにFreeプランを割り当て、課金機能はフィーチャートグルで無効化。

## イベントサブスクライバ
- **SubscriptionSyncSubscriber**
  - 目的：Subscription の状態変化を Entitlement へ反映する。
  - 購読イベント：`SubscriptionActivated`, `SubscriptionExpired`（billing）。
  - 処理内容：
    1. `SubscriptionRepository` から `Subscription` を取得
    2. `PlanRepository` から `Plan` を取得し、`limits` を抽出
    3. `EntitlementRepository` から対象 `Entitlement` を取得
    4. `Entitlement.syncWithPlan(plan.identifier, plan.limits)` を呼び出し、usage/limits を最新化
    5. `EntitlementRepository` で永続化し、`EntitlementUpdated` を発火
  - 発火イベント：`EntitlementUpdated`
- **MediaUsageSubscriber**
  - 目的：Playlist/Track の使用状況を Entitlement に反映する。
  - 購読イベント：`PlaylistUpdated`, `TrackRegistered`, `TrackDeprecated`（media）。
  - 処理内容：
    1. `EntitlementRepository` から対象 `Entitlement` を取得
    2. `TrackRegistered` の場合：`Entitlement.adjustUsage(tracksDelta: +1, charactersDelta: 0, sequenceNumber: xxx)` を呼び出し
    3. `TrackDeprecated` の場合：`Entitlement.adjustUsage(tracksDelta: -1, charactersDelta: 0, sequenceNumber: xxx)` を呼び出し
    4. `adjustUsage` 内部で上限チェックが行われ、超過時に `EntitlementRestricted` が発火される
    5. `EntitlementRepository` で永続化し、`EntitlementUpdated` が発火される
  - 発火イベント：`EntitlementUpdated` / `EntitlementRestricted`（Entitlementの振る舞いから）
- **AvatarUsageSubscriber**
  - 目的：キャラクター利用状況を Entitlement に反映する。
  - 購読イベント：`CharacterUnlocked`, `CharacterDeprecated`（avatar）。
  - 処理内容：
    1. `EntitlementRepository` から対象 `Entitlement` を取得
    2. `CharacterUnlocked` の場合：`Entitlement.adjustUsage(tracksDelta: 0, charactersDelta: +1, sequenceNumber: xxx)` を呼び出し
    3. `CharacterDeprecated` の場合：`Entitlement.adjustUsage(tracksDelta: 0, charactersDelta: -1, sequenceNumber: xxx)` を呼び出し
    4. `adjustUsage` 内部で上限チェックが行われ、超過時に `EntitlementRestricted` が発火される
    5. `EntitlementRepository` で永続化し、`EntitlementUpdated` が発火される
  - 発火イベント：`EntitlementUpdated` / `EntitlementRestricted`（Entitlementの振る舞いから）
- **PlanManagementSubscriber**
  - 目的：プラン更新に伴い既存 Entitlement の上限を再計算する。
  - 購読イベント：`PlanUpdated`（billing）。
  - 処理内容：
    1. `PlanRepository.find(event.plan)` から更新された `Plan` を取得
    2. `EntitlementRepository.all()` で該当プランを参照するすべての `Entitlement` を取得
    3. 各 `Entitlement` に対して `syncWithPlan(plan.identifier, plan.limits)` を呼び出し、`Plan` の新しい上限値（`limits`）を反映
    4. `syncWithPlan` 内部で上限チェックが行われ、超過している場合は `EntitlementRestricted` が発火される
    5. 超過が検出された場合、`EntitlementQuotaAdjusted` イベントを発火（profile パッケージが購読）
    6. `EntitlementRepository` で永続化
  - 発火イベント：`EntitlementQuotaAdjusted` / `EntitlementRestricted`（Entitlementの振る舞いから）

## 永続化戦略

### Plan（プラン）

- **形式**：SQLite
- **理由**：システム定義のマスタデータであり、検索・フィルタリングが必要
- **テーブル**：`plans`
- **スキーマ**：
  ```sql
  CREATE TABLE plans (
    identifier TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    track_limit INTEGER,
    character_limit INTEGER,
    price_amount REAL NOT NULL,
    currency_code TEXT NOT NULL,
    status TEXT NOT NULL CHECK(status IN ('Active', 'Deprecated'))
  );
  ```
  注記：track_limit と character_limit は NULL が無制限を意味する。実装時は Limit 値オブジェクトと相互変換する Mapper を使用。

### Subscription（サブスクリプション）

- **形式**：JSON（暗号化）
- **理由**：ユーザーごとに1件のみ、領収書など機密情報を含む
- **パス**：`<profile_dir>/subscription.json.enc`
- **暗号化**：AES-256-GCM（プロファイルのマスターキーで暗号化）
- **構造例**：
  ```json
  {
    "identifier": "01HQXYZ...",
    "plan": "FREE_PLAN_V1",
    "status": "Active",
    "expiresAt": "2025-12-31T23:59:59Z",
    "receipt": {
      "provider": "AppStore",
      "transactionIdentifier": "01HQABC...",
      "signature": "base64encodedSignature=="
    },
    "lastSyncedAt": "2025-10-30T12:00:00Z"
  }
  ```

### Entitlement（権利情報）

- **形式**：JSON
- **理由**：ユーザーごとに1件のみ、頻繁に更新される
- **パス**：`<profile_dir>/entitlement.json`
- **構造例**：
  ```json
  {
    "identifier": "01HQXYZ...",
    "plan": "FREE_PLAN_V1",
    "version": 42,
    "lastProcessedSequenceNumber": 1234,
    "limits": {
      "tracks": 3,
      "characters": 2
    },
    "usage": {
      "tracks": 2,
      "characters": 1
    },
    "status": "Active"
  }
  ```

### セキュリティ考慮事項

#### 暗号鍵の保管

- プロファイルのマスターキーを使用（詳細は`docs/cross-cutting/security.md`を参照）
- マスターキーの保管方法：
  - iOS/macOS：Keychain Services
  - Windows：DPAPI (Data Protection API)
  - Linux：libsecret または gnome-keyring
- 実装はインフラ層の`SecureStoragePort`が担当

#### 暗号鍵のローテーション

- プロファイルのマスターキー更新時に`subscription.json.enc`を再暗号化
- ローテーション手順：
  1. 新しいマスターキーを生成
  2. 古いマスターキーで復号
  3. 新しいマスターキーで再暗号化
  4. アトミックに置き換え（tmp→rename）
- 詳細は`docs/cross-cutting/key-rotation.md`を参照

#### バックアップから復元時の再検証フロー

1. `subscription.json.enc`を復元
2. 復号して`Subscription`を読み込み
3. `lastSyncedAt`が古い場合（例：7日以上前）は、サブスクリプション検証APIを即座に呼び出し
4. 検証結果に基づいて`status`を更新
5. `Entitlement`も再計算（`syncWithPlan`を実行）
6. 整合性チェックを実行（実リソース数と`usage`を照合）
7. 詳細は`docs/cross-cutting/backup-restore.md`を参照

#### デバイス間の同期

- 同期は行わない（各デバイスで独立して検証）
- 理由：領収書の検証は決済プロバイダのAPIを使用するため、同期不要
- 各デバイスが独立してサブスクリプション状態を管理
