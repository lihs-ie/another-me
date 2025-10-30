# profile パッケージ モデル

ユーザー設定と嗜好（キャラクター/シーン/テーマ/音量/ポモドーロ規則）を管理する。要件の「設定・永続化」「UI/UX」セクションに準拠し、整合性を UserProfile 集約で保証する。

## モデル方針

- 設定は `UserProfile` 集約に集約し、外部集約への参照は Identifier のみに限定する。
- 選択中のキャラクター・シーンは、avatar パッケージの `CharacterIdentifier`、scene パッケージの `SceneIdentifier` を直接参照する（重複定義を避けるため）。
- 再生方針（フェード、ループモード、出力デバイス）は `PlaybackSettings` 値オブジェクトで一元管理し、media パッケージは参照するだけにする。
- ポモドーロ規則は `PomodoroPolicy` 値オブジェクトで保持し、work パッケージへスナップショットを提供する。
- イベントサブスクライバが 他パッケージからの変更（キャラ/シーン廃止、権利更新）を受けて設定を補正する。

## UserProfile 集約

#### ProfileIdentifier （プロフィール識別子／値オブジェクト）

- 目的：ユーザープロファイルを一意に識別する。
- フィールド：
  - `value`: ULID 文字列（26 文字）
- 不変条件：
  - `value` は ULID フォーマット（`[0-7][0-9A-HJKMNP-TV-Z]{25}`）に一致する。
- 振る舞い：
  - **新規生成できる(generate)**
    - 入力：なし
    - 出力：`ProfileIdentifier`
    - 副作用：なし

#### OutputDeviceIdentifier （出力デバイス識別子／値オブジェクト）

- 目的：ユーザーが選択したオーディオ出力デバイスを一意に識別する（設定画面で利用）。
- フィールド：
  - `value`: ULID 文字列（26 文字）
- 不変条件：
  - `value` は ULID フォーマットに一致する。
- 振る舞い：
  - **新規生成できる(generate)**
    - 入力：なし
    - 出力：`OutputDeviceIdentifier`
    - 副作用：なし

#### AppearanceSettings （外観設定／値オブジェクト）

- 目的：アプリケーションの視覚的な外観を構成する要素（キャラクター、シーン、テーマ、衣装モード）を一元管理する。
- フィールド：
  - `character`: `CharacterIdentifier`
  - `scene`: `SceneIdentifier`
  - `theme`: `ThemeMode`
  - `outfit`: `OutfitMode`（avatar パッケージで定義）
- 不変条件：
  - `character` は実在する有効なキャラクターを指す。
  - `scene` は実在する有効なシーンを指す。
  - `outfit` が `OutfitMode.manual` の場合、ユーザーが選択した衣装はライセンス状態で利用可能なもののみである。
- 振る舞い：
  - **キャラクターを変更できる(changeCharacter)**
    - 入力：`character`（`CharacterIdentifier`）
    - 出力：新しい `AppearanceSettings`
    - 副作用：不変条件違反時は例外を発する
  - **シーンを変更できる(changeScene)**
    - 入力：`scene`（`SceneIdentifier`）
    - 出力：新しい `AppearanceSettings`
    - 副作用：不変条件違反時は例外を発する
  - **テーマを変更できる(changeTheme)**
    - 入力：`theme`（`ThemeMode`）
    - 出力：新しい `AppearanceSettings`
    - 副作用：なし
  - **衣装モードを変更できる(changeOutfit)**
    - 入力：`outfit`（`OutfitMode`）
    - 出力：新しい `AppearanceSettings`
    - 副作用：なし

#### UserProfile （ユーザープロファイル／集約）

- 目的：ユーザー固有の見た目・タイマー・音量設定を一貫して管理し、アプリ起動時に復元する。
- フィールド：
  - `identifier`: `ProfileIdentifier`
  - `isDefault`: 真偽値
  - `appearance`: `AppearanceSettings`
  - `language`: `Language`
  - `playback`: `PlaybackSettings`
  - `pomodoro`: `PomodoroPolicy`
  - `restoreOnLaunch`: 真偽値
  - `notification`: `NotificationPreference`
- 不変条件：
  - `appearance` の不変条件は `AppearanceSettings` で保証される。
  - `pomodoro` の各値は 1〜120 分、`longBreakEvery >= 1`。
  - `playbackSettings` の不変条件は `PlaybackSettings` で保証される。
  - `isDefault` はデフォルトプロファイルかどうかを示す（シングルユーザーアプリでは常に `true`）。
- 振る舞い：
  - **キャラクターを変更できる(changeCharacter)**
    - 入力：`character`（`CharacterIdentifier`）
    - 出力：なし
    - 副作用：
      - `appearance.changeCharacter(character)` を呼び出して新しい `AppearanceSettings` を生成
      - 内部の `appearance` フィールドを更新
      - 不変条件違反時は例外を発する
  - **シーンを変更できる(changeScene)**
    - 入力：`scene`（`SceneIdentifier`）
    - 出力：なし
    - 副作用：
      - `appearance.changeScene(scene)` を呼び出して新しい `AppearanceSettings` を生成
      - 内部の `appearance` フィールドを更新
      - 不変条件違反時は例外を発する
  - **テーマを変更できる(changeTheme)**
    - 入力：`theme`（`ThemeMode`）
    - 出力：なし
    - 副作用：
      - `appearance.changeTheme(theme)` を呼び出して新しい `AppearanceSettings` を生成
      - 内部の `appearance` フィールドを更新
  - **衣装モードを変更できる(changeOutfit)**
    - 入力：`outfit`（`OutfitMode`）
    - 出力：なし
    - 副作用：
      - `appearance.changeOutfit(outfit)` を呼び出して新しい `AppearanceSettings` を生成
      - 内部の `appearance` フィールドを更新

#### PlaybackSettings （再生設定／値オブジェクト）

- フィールド：
  - `loopMode`: LoopMode
  - `fade`: FadeDuration
  - `volume`: VolumeLevel
  - `mute`: 真偽値
  - `outputDevice`: `OutputDeviceIdentifier`（任意）
- 不変条件：
  - `fade.milliseconds >= 0`
  - `volume.value` が範囲内。

#### PomodoroPolicy （ポモドーロ設定／値オブジェクト）

- フィールド：
  - `workMinutes`: 数値（1〜120）
  - `breakMinutes`: 数値（1〜120）
  - `longBreakMinutes`: 数値（1〜120）
  - `longBreakEvery`: 数値（1 以上）
- 不変条件：各値が範囲内になり、相互に矛盾しない。

#### NotificationPreference （通知設定／値オブジェクト）

- フィールド：
  - `enableDesktop`: 真偽値
  - `enableMenuBar`: 真偽値
  - `quietHours`: QuietHours
- 不変条件：`quietHours` が妥当な時間帯を指す。

#### ドメインイベント

- `UserProfileUpdated`
  - 役割：プロフィールの主要項目が更新されたことを通知する。
  - フィールド：`identifier: ProfileIdentifier`
- `PomodoroPolicyChanged`
  - 役割：ポモドーロ設定が変更されたことを通知する。
  - フィールド：`profile: ProfileIdentifier`, `policy: PomodoroPolicy`
- `PlaybackSettingsChanged`
  - 役割：再生設定が変更されたことを通知する。
  - フィールド：`profile: ProfileIdentifier`, `settings: PlaybackSettings`
- `ThemeChanged`
  - 役割：テーマ設定が変更されたことを通知する。
  - フィールド：`profile: ProfileIdentifier`, `mode: ThemeMode`
- `DayPeriodChanged`
  - 役割：ユーザープロファイルに紐づく時間帯が変更されたことを通知する。
  - フィールド：`profile: ProfileIdentifier`, `period: DayPeriod`
- `ProfileQuotaAdjusted`
  - 役割：Entitlement による制限変更に合わせてプロファイルの選択済みリソースを調整したことを通知する。
  - フィールド：`profile: ProfileIdentifier`, `adjustments: Map<String, Object>`

#### グローバル不変条件

- **デフォルトプロファイルのユニーク性**
  - システム全体で `isDefault = true` を持つプロファイルは1つのみ存在する。
  - この制約はインフラストラクチャ層のリポジトリ実装で保証される。

#### リポジトリ契約

- `UserProfileRepository`
  - `getDefault(): UserProfile`
    - 目的：デフォルトのユーザープロファイルを取得する。
    - 仕様：
      - `isDefault = true` を持つプロファイルを返す（シングルユーザー前提）。
      - システム全体で `isDefault = true` のプロファイルは1つのみ存在する（グローバル不変条件）。
      - プロファイルが存在しない場合は初期データを生成して返す。
      - 初期データ生成時は、以下の設定を適用する：
        - `identifier`: インフラストラクチャ層で決定される識別子
        - `isDefault`: `true`
        - `character`: システムで利用可能な最初のアクティブなキャラクター
        - `scene`: システムで利用可能な最初のアクティブなシーン
        - `language`: システムロケールから判定（デフォルトは日本語）
        - `theme`: `ThemeMode.auto`
        - `outfitMode`: `OutfitMode.auto`
        - `pomodoro`: 25分作業/5分休憩/15分長休憩/4セット毎
        - `volume`: 0.7（70%）、ミュートなし
        - `fade`: 500ms
        - `loopMode`: `LoopMode.single`
        - `notification`: デスクトップ・メニューバー共に有効、quietHours は 22:00-07:00
        - `restoreOnLaunch`: `true`
    - 備考：インフラストラクチャ層では `user_profile.json` からの読み込みで実装される。識別子の具体的な値はインフラ層で管理される。
  - `persist(profile: UserProfile): void`
    - 目的：プロファイルを永続化する。
    - 仕様：指定されたプロファイルを保存する。
    - 備考：インフラストラクチャ層では `user_profile.json` への書き込みで実装される。
  - `observe(identifier: ProfileIdentifier): Stream<UserProfile>`
    - 目的：プロファイルの変更を監視する。
    - 仕様：指定された識別子のプロファイルが更新されるたびに新しい値を通知する。
    - 備考：ファイル監視などで実装される（将来拡張）。

## イベントサブスクライバ

- **CharacterLifecycleSubscriber**
  - 目的：Avatar ドメインでのキャラクター状態変化を UserProfile に反映する。
  - 購読イベント：`CharacterUpdated`, `CharacterDeprecated`, `CharacterUnlocked`（avatar）。
  - 処理内容：
    - **onCharacterUpdated**
      1. イベント内容をログ出力（レベル: debug）
      2. UserProfile への反映は不要（キャラクターの属性変更はプロフィール設定に影響しないため）
    - **onCharacterDeprecated**
      1. イベント内容をログ出力（レベル: info）
      2. `UserProfileRepository.getDefault()` から対象プロフィールを取得
      3. 現在の `appearance.character` が廃止されたキャラクター（`event.character`）と一致しない場合、ログ出力（レベル: debug、「廃止されたキャラクターは現在選択されていないため処理をスキップ」）して処理を終了
      4. `CharacterRepository.search(criteria: CharacterSearchCriteria(statuses: [Active]))` から最初の有効なキャラクターを取得
      5. `profile.changeCharacter(newCharacter)` でキャラクターを変更
      6. `UserProfileRepository.persist(profile)` で永続化
      7. `UserProfileUpdated` を発火
    - **onCharacterUnlocked**
      1. イベント内容をログ出力（レベル: info）
      2. 解放されたキャラクター情報（`event.character`）を記録
      3. UserProfile への自動反映は行わない（ユーザーの明示的な選択を待つ）
  - 発火イベント：`UserProfileUpdated`（onCharacterDeprecated のみ）
- **SceneLifecycleSubscriber**
  - 目的：Scene ドメインの変更（廃止・照明）をプロフィールへ反映する。
  - 購読イベント：`SceneDeprecated`, `SceneLightingChanged`（scene）。
  - 処理内容：
    - **onSceneDeprecated**
      1. イベント内容をログ出力（レベル: info）
      2. `UserProfileRepository.getDefault()` から対象プロフィールを取得
      3. 現在の `appearance.scene` が廃止されたシーン（`event.identifier`）と一致しない場合、ログ出力（レベル: debug、「廃止されたシーンは現在選択されていないため処理をスキップ」）して処理を終了
      4. `SceneRepository.search(criteria: SceneSearchCriteria(statuses: [Active]))` から最初の有効なシーンを取得
      5. `profile.changeScene(newScene)` でシーンを変更
      6. `UserProfileRepository.persist(profile)` で永続化
      7. `UserProfileUpdated` を発火
    - **onSceneLightingChanged**
      1. イベント内容をログ出力（レベル: info）
      2. `UserProfileRepository.getDefault()` から対象プロフィールを取得
      3. `appearance.theme` が Auto でない場合、ログ出力（レベル: debug、「テーマが Auto でないため照明変更を反映しない」）して処理を終了
      4. 照明の変更（`event.mode`）に合わせて `profile.changeTheme(event.mode)` でテーマを変更
      5. `UserProfileRepository.persist(profile)` で永続化
      6. `UserProfileUpdated` を発火
  - 発火イベント：`UserProfileUpdated`
- **EntitlementPolicySubscriber**
  - 目的：Billing の権利制限に応じてプロフィール設定を調整する。
  - 購読イベント：`EntitlementUpdated`（billing）。
  - 処理内容：
    - **onEntitlementUpdated**
      1. イベント内容をログ出力（レベル: info）
      2. `EntitlementRepository.find(event.entitlement)` から更新された Entitlement を取得
      3. `UserProfileRepository.getDefault()` から対象プロフィールを取得
      4. `CharacterRepository.all()` からユーザーが利用中のキャラクター数を取得し、`Entitlement.limits.characters` と比較
      5. 超過している場合、選択中のキャラクターを制限内に収まるように調整（最も最近追加されたものから削除）
      6. 調整内容を `adjustments: Map<String, Object>` にまとめて `ProfileQuotaAdjusted` を発火
      7. `UserProfileRepository.persist(profile)` で永続化
  - 発火イベント：`ProfileQuotaAdjusted`
- **PomodoroSessionSubscriber**
  - 目的：work ドメインのセッション完了情報をプロフィールに蓄積する。
  - 購読イベント：`PomodoroSessionCompleted`（work）。
  - 処理内容：
    - **onPomodoroSessionCompleted**
      1. イベント内容をログ出力（レベル: info）
      2. `UserProfileRepository.getDefault()` から対象プロフィールを取得
      3. `UserProfile.lastCompletedSession` を `event.identifier` に更新し、`sessionCompletionCount` をインクリメント
      4. 必要に応じて `UserProfile.pomodoro` のデフォルトフェーズ設定を更新
      5. `UserProfileUpdated` を発火
      6. `UserProfileRepository.persist(profile)` で永続化
  - 発火イベント：`UserProfileUpdated`
  - 備考：UserProfile 集約に `lastCompletedSession: PomodoroSessionIdentifier` フィールドと `sessionCompletionCount: int` フィールドの追加が必要（設計変更の提案として記載）
