# Lo-Fi Workmate — ドメインモデリング（集約ルート洗い出し）

## common パッケージ

- **Shared Value Objects / Events**
  - `Language`, `ThemeMode`, `DayPeriod`, `LoopMode`, `FadeDuration`, `VolumeLevel`, `QuietHours` など、複数パッケージで再利用する概念を定義。
  - 共通イベント契約：`ThemeChanged`, `DayPeriodChanged`, `SystemDndStateChanged`。
  - 不変条件（だれでも理解できる説明）：共通の値（Language など）やイベント定義を `common` で一元管理し、各パッケージはそれらをそのまま使います。重複定義による食い違いを防ぐためです。

## work パッケージ

- **PomodoroSession 集約**
  - 作業/休憩/長休憩の状態遷移と残時間・サイクル数の一貫性保持。スリープ復帰補正とコーヒーモーションのスケジューリングを行う。
  - 不変条件（だれでも理解できる説明）：タイマー状態（status）とフェーズ（phase）は決められた順序で進行し、残り時間（remainingTime）は常に 0 以上でフェーズ時間内に収まります。スリープ復帰時は `lastTickAt` の差分から時間を補正し、次のコーヒーモーション時刻（nextCoffeeAt）は 90〜150 秒の範囲で再設定されます。
- **SessionLog 集約**
  - 確定したセッション結果の監査ログ（Append-only）。
  - 不変条件（だれでも理解できる説明）：記録済みログ（SessionLog）は追記のみで、既存データを書き換えません。開始時刻（startedAt）と終了時刻（endedAt）の順序や、作業時間の合計（totalWorkMs）が必ず整合します。

## media パッケージ

- **Track 集約**
  - 曲の同一性・再生メタ（タイトル/長さ/ループポイント/ライセンス Identifier）。LoopPoint は `trackDurationMs` を保持して `start < end <= duration` を保証する。
  - 不変条件（だれでも理解できる説明）：曲名（title）やライセンス識別子（licenseIdentifier）などの必須情報はすべて埋め、対応するライセンス記録が存在することを保証します。
- **Playlist 集約**
  - 順序付きトラック集合（並び替え/追加/削除）。
  - 不変条件（だれでも理解できる説明）：プレイリストが参照する曲識別子（trackIdentifier）は必ず存在し、重複禁止設定（allowDuplicates）が false の場合は同じ曲を重ねて登録できません。

> 補足：ループ/フェード/出力デバイス等の再生方針は profile パッケージの UserProfile 集約が保持する PlaybackSettings 値オブジェクトで管理する。

## avatar パッケージ

- **Character 集約**
  - library.animation の `AnimationBindingManifest` を識別子で参照し、typing / coffee 等の必須アニメーションを揃えつつ時間帯別衣装マッピング（WardrobeMap 値オブジェクト）を内包。
  - 不変条件（だれでも理解できる説明）：必要なアニメーションバインディング（animationBindings.tags=typing / coffee）は 30fps 仕様を満たすマニフェストへリンクし、衣装（wardrobeMap.morning など）はカタログで承認されたバインディング識別子（animationBindingIdentifier）を参照します。詳しいタイムラインやアトラス情報は library ドメインが単一の真実として保持し、avatar は識別子参照のみに留めます。

## scene パッケージ

- **Scene 集約**
  - library.animation の `AnimationBindingManifest` を識別子参照し、24fps ループと露出範囲を `loopDurationMs` で整合させる。
  - 不変条件（だれでも理解できる説明）：背景アニメのバインディング識別子（animationBinding.animationBindingIdentifier）は 24fps 仕様に従い、パララックス層（parallaxLayers）は自然数比の速度とマニフェストで定義されたフレーム範囲内を利用します。窓の演出周期（windowView.cycleMs）も継ぎ目なくループし、キャラクターアンカー（characterAnchor）は 16px グリッドに沿って配置されるためレイアウトが崩れません。

## library パッケージ（アセット・カタログ）

- **AssetCatalog 集約**
  - 配布可能アセット（キャラ/背景/小物）のバージョン・互換性管理。
  - 不変条件（だれでも理解できる説明）：カタログの依存関係（packages[].dependencies）が循環せず、要求バージョン（minAppVersion）が現在のアプリでも利用できるかを確認します。
- **AnimationSpec 集約**
  - アニメ仕様（fps/frames/next/pivot/安全余白）スキーマの厳密化。
  - 不変条件（だれでも理解できる説明）：アニメーション仕様ではフレーム数（frames）・再生速度（fps）・原点（pivot）・安全余白（safetyMargin）などの必須フィールドが制作ルールに適合するよう検査されます。

## licensing パッケージ

- **LicenseRecord 集約**
  - 各曲のライセンス事実（名称/URL/帰属文/再配布可否/オフライン可否）。
  - 不変条件（だれでも理解できる説明）：ライセンス名（licenseName）・URL（licenseUrl）・帰属文（attributionText）を必ず保存し、取り消し時は履歴（statusHistory）に追記します。ライセンステキストファイル（licenseFilePath）が存在する場合はチェックサム（licenseFileChecksum）と一致することを確認します。
- **AttributionBook 集約**
  - アプリ内クレジット表示の生成根拠（素材 → 帰属文対応表）。
  - 不変条件（だれでも理解できる説明）：素材識別子（resourceIdentifier）ごとに一意のエントリを持ち、クレジット帳票（entries）は追記のみで編集しません。

## profile パッケージ

- **UserProfile 集約**
  - 選択中キャラ/シーン/言語/テーマ/服装モードに加え、再生方針（PlaybackSettings 値オブジェクト）とポモドーロ規則（PomodoroPolicy 値オブジェクト）を一括管理。
  - 不変条件（だれでも理解できる説明）：選択中キャラクター（selectedCharacterIdentifier）や背景（selectedSceneIdentifier）は実在し、ポモドーロ設定（pomodoroPolicy）や再生設定（playbackSettings）が許容範囲を満たしていることをまとめて検証します。

## billing パッケージ

- **Plan 集約**
  - free/paid と各リソース制限（曲数/キャラ数）。
  - 不変条件（だれでも理解できる説明）：プランの曲上限（trackLimit）やキャラ上限（characterLimit）は、無料プランでは 3 曲・2 キャラ、有料プランでは無制限など、定めた条件をそのまま表現します。
- **Subscription 集約**
  - 購読状態（active/expired）、有効期限・領収書検証結果。
  - 不変条件（だれでも理解できる説明）：購読状態（status）は、開始→有効→期限切れ→猶予など決められた流れで推移し、有効期限（expiresAt）や猶予終了（gracePeriodEndsAt）の順序が矛盾しないようにします。オフライン猶予期間（offlineGracePeriod）内であれば最後の同期から一定期間オフラインでも利用可能です。
- **Entitlement 集約**
  - 実効的な権利集合（tracks/characters の上限）と現在使用数（EntitlementUsage 値オブジェクト）を同一取引で管理。
  - 不変条件（だれでも理解できる説明）：権利上限（limits）と実際の利用数（usage）が常に整合し、無制限は `null` 表記に統一、使用数は負の値にならないようにします。また、更新ごとにリビジョン（version）をインクリメントし、使用数イベントには単調増加する `sequenceNumber` を付与して競合や二重適用を防ぎます。日次の再計算（reconcileUsage）で実データと usage のズレも補正します。

## import パッケージ

- **CatalogDownloadJob 集約**
  - 公式カタログから楽曲をダウンロードし、検証後に Track/LicenseRecord を登録する。
  - 不変条件（だれでも理解できる説明）：ダウンロード→検証→登録の順序を守り、提供メタデータ（trackMetadata / licenseMetadata）と照合したうえで登録します。再試行回数にも上限を設けます。

## telemetry パッケージ（任意）

- **UsageMetrics 集約**
  - 匿名の利用統計の集約・保持。
  - 不変条件（だれでも理解できる説明）：個人を特定できる情報は一切扱わず、イベント保存期間（events）を上限内に収めます。

## notification パッケージ（任意）

- **NotificationRule 集約**
  - 各 Phase での通知チャネル設定。
  - 不変条件（だれでも理解できる説明）：通知ルールはサイレント時間帯（quietHours）やおやすみモード（System DND）を守り、テンプレート（NotificationChannelSetting.template）が空にならないようにします。

---

## 参照・整合の基本方針

- 参照は Identifier のみ：Playlist → TrackIdentifier、UserProfile → CharacterIdentifier/SceneIdentifier、Track → LicenseRecordIdentifier。
- 整合はドメインイベントで伝播（PomodoroSessionCompleted、TrackImported、SubscriptionChanged など）。
- 双方向参照は禁止。
