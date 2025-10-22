# notification パッケージ モデル

ポモドーロフェーズや再生状態に応じた通知・メニューバー更新を制御する。要件の「通知/ステータス」セクション（FR-NOT-01, FR-NOT-02）を満たす。

## モデル方針

- 通知設定は `NotificationRule` 集約で管理し、Do Not Disturb や静音時間を尊重する
- テンプレートエンジンにより動的データ（残り時間、楽曲名など）を通知内容に埋め込む
- 型安全な `NotificationEventType` により境界間の依存を最小化する
- スパム防止機能により同一イベントの連続通知を抑制する
- notification ドメインは通知可否判定とイベント発行のみを担当し、UI更新は presentation 層に委譲する

## 責務分担

### notification ドメイン（本パッケージ）の責務
1. 通知可否判定（DND、QuietHours、スパム防止）
2. 通知内容生成（テンプレート + コンテキスト）
3. `NotificationRequested` イベント発行

### presentation 層の責務
1. メニューバー UI の実装（macOS/Windows 固有API）
2. デスクトップ通知の表示
3. サウンド再生

### application 層の責務
1. ドメインイベント購読
2. presentation 層のサービス呼び出し
3. クイック操作のコマンド実行（ポモドーロ開始/停止）

この分担により、notification ドメインはプラットフォーム固有の実装に依存せず、DDD原則の「ドメイン層は技術的詳細から独立」を保つ。

## 値オブジェクト

### TemplatePlaceholder （テンプレートプレースホルダー／値オブジェクト：列挙）

- **何を表したドメインモデルなのか**
  - 概要：通知テンプレート内で使用可能なプレースホルダーを定義する
  - 役割：型安全にテンプレート変数を管理し、誤ったプレースホルダー指定を防ぐ
- **フィールド**
  - `name`: String（プレースホルダー名）
- **不変条件**
  - `name` は空文字列不可
- **列挙値**
  - `remainingMinutes`: 残り時間（分）
  - `remainingSeconds`: 残り時間（秒）
  - `phaseName`: フェーズ名（「作業時間」「短い休憩」など）
  - `trackTitle`: 楽曲タイトル
  - `artistName`: アーティスト名

### NotificationTemplate （通知テンプレート／値オブジェクト）

- **何を表したドメインモデルなのか**
  - 概要：プレースホルダーを含む通知メッセージのテンプレート
  - 役割：動的データを埋め込み可能な通知メッセージを表現する
- **フィールド**
  - `template`: String（テンプレート文字列、例：「{{phaseName}}が開始しました。残り{{remainingMinutes}}分です。」）
  - `requiredPlaceholders`: Set<TemplatePlaceholder>（必須プレースホルダー）
- **不変条件**
  - `template` は 1〜200 文字
  - `requiredPlaceholders` に指定されたプレースホルダーが全て `template` 内に存在する
- **振る舞い**
  - **テンプレートを生成できる(create)**
    - 処理の内容：テンプレート文字列と必須プレースホルダーを検証してインスタンスを生成する
    - 入力：`template`（String）、`requiredPlaceholders`（Set<TemplatePlaceholder>）
    - 出力：`NotificationTemplate`
    - 副作用：不変条件違反時は `InvariantViolationError` を投げる
  - **コンテキストを適用してメッセージを生成できる(render)**
    - 処理の内容：`NotificationContext` の値をプレースホルダーに埋め込み、最終的な通知メッセージを生成する
    - 入力：`context`（NotificationContext）
    - 出力：String（レンダリングされたメッセージ）
    - 副作用：必須プレースホルダーの値が context に存在しない場合は `ArgumentError` を投げる

### NotificationContext （通知コンテキスト／値オブジェクト）

- **何を表したドメインモデルなのか**
  - 概要：テンプレートに埋め込む動的データを保持する
  - 役割：イベントごとに異なるデータをテンプレートに渡す
- **フィールド**
  - `values`: Map<String, String>（プレースホルダー名 → 値のマッピング）
- **不変条件**
  - なし（空のコンテキストも許容）
- **振る舞い**
  - **ポモドーロフェーズ用コンテキストを生成できる(forPomodoroPhase)**
    - 処理の内容：ポモドーロフェーズの通知に必要なデータを含むコンテキストを生成する
    - 入力：`remainingMinutes`（int）、`remainingSeconds`（int）、`phaseName`（String）
    - 出力：`NotificationContext`
    - 副作用：なし
  - **楽曲登録用コンテキストを生成できる(forTrackRegistered)**
    - 処理の内容：楽曲登録通知に必要なデータを含むコンテキストを生成する
    - 入力：`trackTitle`（String）、`artistName`（String）
    - 出力：`NotificationContext`
    - 副作用：なし
  - **プレースホルダーの値を取得できる(getValue)**
    - 処理の内容：指定されたプレースホルダーに対応する値を取得する
    - 入力：`placeholder`（TemplatePlaceholder）
    - 出力：String
    - 副作用：プレースホルダーの値が存在しない場合は `ArgumentError` を投げる

### NotificationEventType （通知イベント種別／値オブジェクト）

- **何を表したドメインモデルなのか**
  - 概要：通知対象となるドメインイベントの種別を型安全に表現する
  - 役割：境界間で文字列を共有せず、型による制約を保証する
- **フィールド（抽象）**
  - `name`: String（イベント種別名）
  - `requiredPlaceholders`: Set<TemplatePlaceholder>（このイベントで必要なプレースホルダー）
- **不変条件**
  - `name` は空文字列不可
- **具体クラス**
  - **PomodoroPhaseStartedEvent**
    - `name`: 'PomodoroPhaseStarted'
    - `requiredPlaceholders`: {`phaseName`, `remainingMinutes`, `remainingSeconds`}
  - **PomodoroSessionCompletedEvent**
    - `name`: 'PomodoroSessionCompleted'
    - `requiredPlaceholders`: {`phaseName`}
  - **TrackRegisteredEvent**
    - `name`: 'TrackRegistered'
    - `requiredPlaceholders`: {`trackTitle`, `artistName`}
  - **TrackDeprecatedEvent**
    - `name`: 'TrackDeprecated'
    - `requiredPlaceholders`: {`trackTitle`}
  - **DayPeriodChangedEvent**
    - `name`: 'DayPeriodChanged'
    - `requiredPlaceholders`: {} (空)

### NotificationChannel （通知チャネル／値オブジェクト：列挙）

- **何を表したドメインモデルなのか**
  - 概要：通知の送信先チャネルを表現する
  - 役割：デスクトップ通知、メニューバー、サウンドなど複数の通知手段を管理する
- **列挙値**
  - `desktop`: デスクトップ通知
  - `menuBar`: メニューバー（ステータスバー）表示
  - `sound`: サウンド再生

### QuietHours （静音時間／値オブジェクト）

- **何を表したドメインモデルなのか**
  - 概要：通知を抑制する時間帯を表現する
  - 役割：開始時刻と終了時刻を保持し、現在時刻が静音時間内かを判定する
- **フィールド**
  - `startTime`: TimeOfDay（開始時刻）
  - `endTime`: TimeOfDay（終了時刻）
  - `spansMidnight`: bool（翌日跨ぎフラグ、自動計算）
- **不変条件**
  - `startTime` と `endTime` が同じ時刻でない
- **振る舞い**
  - **静音時間を生成できる(create)**
    - 処理の内容：開始時刻と終了時刻を検証し、翌日跨ぎフラグを自動計算してインスタンスを生成する
    - 入力：`startTime`（TimeOfDay）、`endTime`（TimeOfDay）
    - 出力：`QuietHours`
    - 副作用：不変条件違反時は `InvariantViolationError` を投げる
  - **現在時刻が静音時間内かを判定できる(isQuietTime)**
    - 処理の内容：現在時刻が静音時間の範囲内かを判定する。翌日跨ぎの場合も正しく処理する。
    - 入力：`now`（DateTime）
    - 出力：bool
    - 副作用：なし

**翌日跨ぎの判定ロジック**：
- `startTime` が `endTime` より後の場合、翌日跨ぎとみなす（例：22:00〜07:00）
- 翌日跨ぎの場合：現在時刻が開始時刻以降 OR 終了時刻以前 で静音時間内
- 通常の場合：現在時刻が開始時刻以降 AND 終了時刻以前 で静音時間内

### NotificationChannelSetting （通知チャネル設定／値オブジェクト）

- **何を表したドメインモデルなのか**
  - 概要：イベント種別ごとの通知チャネルとテンプレートを保持する
  - 役割：どのイベントでどのチャネルを使い、どのメッセージを表示するかを定義する
- **フィールド**
  - `eventType`: NotificationEventType（イベント種別）
  - `channels`: Set<NotificationChannel>（通知チャネル）
  - `template`: NotificationTemplate（通知テンプレート）
- **不変条件**
  - `channels` は空集合不可
  - `template` の `requiredPlaceholders` が `eventType.requiredPlaceholders` を全て含む
- **振る舞い**
  - **設定を生成できる(create)**
    - 処理の内容：イベント種別、チャネル、テンプレートを検証してインスタンスを生成する
    - 入力：`eventType`（NotificationEventType）、`channels`（Set<NotificationChannel>）、`template`（NotificationTemplate）
    - 出力：`NotificationChannelSetting`
    - 副作用：不変条件違反時は `InvariantViolationError` を投げる

### NotificationHistory （通知履歴／値オブジェクト）

- **何を表したドメインモデルなのか**
  - 概要：イベントタイプごとの最終送信時刻を保持する
  - 役割：同一イベントの短時間での連続通知を防ぐ（スパム防止）
- **フィールド**
  - `lastSentTimes`: Map<NotificationEventType, DateTime>（イベント種別ごとの最終送信時刻）
- **不変条件**
  - `lastSentTimes` の DateTime は未来日時不可
- **振る舞い**
  - **空の履歴を生成できる(empty)**
    - 処理の内容：初期状態の空の履歴を生成する
    - 入力：なし
    - 出力：`NotificationHistory`
    - 副作用：なし
  - **通知を抑止すべきかを判定できる(shouldSuppress)**
    - 処理の内容：指定されたイベント種別の最終送信時刻から最小間隔が経過していない場合、抑止すべきと判定する
    - 入力：`eventType`（NotificationEventType）、`now`（DateTime）、`minimumInterval`（Duration）
    - 出力：bool
    - 副作用：なし
  - **送信記録を追加できる(recordSent)**
    - 処理の内容：指定されたイベント種別の送信時刻を記録した新しい履歴を生成する（イミュータブル）
    - 入力：`eventType`（NotificationEventType）、`sentAt`（DateTime）
    - 出力：`NotificationHistory`
    - 副作用：なし
  - **最終送信からの経過時間を取得できる(elapsedSince)**
    - 処理の内容：指定されたイベント種別の最終送信時刻からの経過時間を取得する
    - 入力：`eventType`（NotificationEventType）、`now`（DateTime）
    - 出力：Duration?（送信履歴がない場合は null）
    - 副作用：なし

## NotificationRule 集約

### NotificationRuleIdentifier （通知ルール識別子／値オブジェクト）

- **何を表したドメインモデルなのか**
  - 概要：通知ルールを一意に識別する
  - 役割：通知ルールのライフサイクル管理に使用される
- **フィールド**
  - `value`: Ulid（ULID値）
- **不変条件**
  - `value` は有効な ULID
- **振る舞い**
  - **新規生成できる(generate)**
    - 処理の内容：新しい ULID を生成して識別子を作成する
    - 入力：なし
    - 出力：`NotificationRuleIdentifier`
    - 副作用：なし

### NotificationRule （通知ルール／集約ルート）

- **何を表したドメインモデルなのか**
  - 概要：プロフィールごとの通知設定を管理し、通知可否を判定する
  - 役割：DND・静音時間・スパム防止を考慮した通知制御を担当する
- **フィールド**
  - `identifier`: NotificationRuleIdentifier（識別子）
  - `profile`: ProfileIdentifier（対象プロフィール）
  - `channelSettings`: Map<NotificationEventType, NotificationChannelSetting>（イベント種別ごとのチャネル設定）
  - `quietHours`: QuietHours（静音時間）
  - `dndEnabled`: bool（Do Not Disturb 有効フラグ）
  - `history`: NotificationHistory（通知履歴）
  - `minimumNotificationInterval`: Duration（最小通知間隔、デフォルト5分）
- **不変条件**
  - `channelSettings` の各 `NotificationChannelSetting` が対応する `NotificationEventType` をキーとして保持される
  - `minimumNotificationInterval` は 1秒 以上
- **振る舞い**
  - **通知ルールを生成できる(create)**
    - 処理の内容：新しい通知ルールを生成する
    - 入力：`profile`（ProfileIdentifier）、`channelSettings`（Map<NotificationEventType, NotificationChannelSetting>）、`quietHours`（QuietHours）
    - 出力：`NotificationRule`
    - 副作用：`NotificationRuleCreated` イベントを発行する
  - **通知を評価できる(evaluateNotification)**
    - 処理の内容：DND、静音時間、スパム防止をチェックし、通知可否を判定する。可能な場合は通知内容を生成し、`NotificationRequested` イベントを発行する。不可の場合は `NotificationSuppressed` イベントを発行する。
    - 入力：`eventType`（NotificationEventType）、`context`（NotificationContext）、`now`（DateTime）
    - 出力：NotificationResult（送信/抑止の結果）
    - 副作用：
      - 通知可能な場合：`NotificationRequested` イベントを発行し、履歴を更新する
      - 通知抑止の場合：`NotificationSuppressed` イベントを発行する
  - **DND 状態を切り替えられる(toggleDnd)**
    - 処理の内容：Do Not Disturb の有効/無効を切り替える
    - 入力：`enabled`（bool）
    - 出力：なし
    - 副作用：`NotificationRuleUpdated` イベントを発行する
  - **静音時間を更新できる(updateQuietHours)**
    - 処理の内容：静音時間の設定を更新する
    - 入力：`quietHours`（QuietHours）
    - 出力：なし
    - 副作用：`NotificationRuleUpdated` イベントを発行する
  - **チャネル設定を更新できる(updateChannelSetting)**
    - 処理の内容：特定のイベント種別のチャネル設定を更新する
    - 入力：`eventType`（NotificationEventType）、`setting`（NotificationChannelSetting）
    - 出力：なし
    - 副作用：`NotificationRuleUpdated` イベントを発行する

## ドメインイベント

### NotificationEvent （通知イベント／抽象イベント）

- **役割**：notification 境界内の全てのイベントの基底クラス
- **フィールド**：`occurredAt`（DateTime）

### NotificationRuleCreated

- **役割**：新しい通知ルールが作成されたことを通知する
- **フィールド**
  - `identifier`: NotificationRuleIdentifier
  - `profile`: ProfileIdentifier
  - `occurredAt`: DateTime

### NotificationRuleUpdated

- **役割**：通知ルールの設定内容が更新されたことを通知する
- **フィールド**
  - `identifier`: NotificationRuleIdentifier
  - `profile`: ProfileIdentifier
  - `dndEnabled`: bool
  - `occurredAt`: DateTime

### NotificationRequested

- **役割**：通知が承認され、送信準備が整ったことを通知する（application 層が購読し、presentation 層のサービスを呼び出す）
- **フィールド**
  - `identifier`: NotificationRuleIdentifier
  - `eventType`: NotificationEventType
  - `context`: NotificationContext
  - `channels`: Set<NotificationChannel>
  - `renderedMessage`: String（レンダリング済みメッセージ）
  - `occurredAt`: DateTime

### NotificationSuppressed

- **役割**：通知がサプレッション（DND・静音・スパム防止）により抑止されたことを記録する
- **フィールド**
  - `identifier`: NotificationRuleIdentifier
  - `eventType`: NotificationEventType
  - `reason`: String（抑止理由：'DND is enabled', 'Quiet hours active', 'Sent too recently' など）
  - `occurredAt`: DateTime

## リポジトリ契約

### NotificationRuleRepository

- **責務**：通知ルールの永続化と取得
- **振る舞い**
  - **find(identifier: ProfileIdentifier): NotificationRule**
    - 処理の内容：プロフィール識別子に対応する通知ルールを取得する
    - 副作用：識別子に対応するルールが見つからない場合は `AggregateNotFoundError` を投げる
    - 注記：プロフィールごとに1つの通知ルールを保持する設計（MVP仕様）
  - **persist(rule: NotificationRule): void**
    - 処理の内容：通知ルールを永続化する
    - 副作用：なし

**設計方針**：
- MVP では 1プロフィール = 1通知ルール の単純な設計
- 将来的に複数ルール対応が必要な場合は以下を検討：
  - `findAll(profile: ProfileIdentifier): List<NotificationRule>`
  - ルールの優先度フィールド追加
  - ルール名/説明フィールド追加（「仕事用」「プライベート用」等）

## イベントサブスクライバ

### PomodoroNotificationSubscriber

- **目的**：Pomodoro のフェーズ変化に基づき通知を評価する
- **購読イベント**：`PomodoroPhaseStarted`（work）、`PomodoroSessionCompleted`（work）
- **処理内容**：
  1. `NotificationRuleRepository` から対象プロフィールのルールを取得
  2. `NotificationEventTypeFactory` で work 境界のイベントを notification 境界の型に変換
  3. `NotificationContext.forPomodoroPhase` でコンテキストを生成
  4. `NotificationRule.evaluateNotification` で通知を評価
  5. 履歴が更新された場合は `NotificationRuleRepository` で永続化
- **発火イベント**：なし（NotificationRule が発行する）

### MediaNotificationSubscriber

- **目的**：メディア関連のイベントに連動して通知を制御する
- **購読イベント**：`TrackRegistered`（media）、`TrackDeprecated`（media）
- **処理内容**：
  1. `NotificationRuleRepository` から対象プロフィールのルールを取得
  2. `NotificationEventTypeFactory` で media 境界のイベントを notification 境界の型に変換
  3. `NotificationContext.forTrackRegistered` 等でコンテキストを生成
  4. `NotificationRule.evaluateNotification` で通知を評価
  5. 履歴が更新された場合は `NotificationRuleRepository` で永続化
- **発火イベント**：なし（NotificationRule が発行する）

### DayPeriodNotificationSubscriber

- **目的**：時間帯変化に基づき通知を評価する
- **購読イベント**：`DayPeriodChanged`（profile/common）
- **処理内容**：
  1. `NotificationRuleRepository` から対象プロフィールのルールを取得
  2. `NotificationEventTypeFactory` で profile 境界のイベントを notification 境界の型に変換
  3. 空のコンテキストを生成（DayPeriodChanged はプレースホルダー不要）
  4. `NotificationRule.evaluateNotification` で通知を評価
  5. 履歴が更新された場合は `NotificationRuleRepository` で永続化
- **発火イベント**：なし（NotificationRule が発行する）

### NotificationDisplaySubscriber

- **目的**：`NotificationRequested` イベントを購読し、presentation 層のサービスを呼び出す
- **購読イベント**：`NotificationRequested`（notification）
- **処理内容**：
  1. イベントの `channels` をチェック
  2. `menuBar` が含まれる場合は `MenuBarService.updateStatus` を呼び出し
  3. `desktop` が含まれる場合は `DesktopNotificationService.show` を呼び出し
  4. `sound` が含まれる場合は `SoundService.playNotificationSound` を呼び出し
- **発火イベント**：なし
- **注記**：このサブスクライバは application 層に配置され、presentation 層のサービスに依存する

### SystemDndSubscriber

- **目的**：OS の DND 状態を NotificationRule に反映する
- **購読イベント**：`SystemDndStateChanged`（common）
- **処理内容**：
  1. 全プロフィールの `NotificationRule` を取得
  2. 各ルールに対して `toggleDnd` を呼び出し
  3. 更新されたルールを永続化
- **発火イベント**：なし（NotificationRule が発行する）
