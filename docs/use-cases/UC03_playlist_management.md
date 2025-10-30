# ユースケース UC03: プレイリストを作成・管理する

## 外部設計

### 目的
- ユーザーが作業用のプレイリストを作成し、曲の順番や重複可否を安全に管理する。

### アクター
- メインアクター：ユーザー
- サポートアクター：アプリ（Playlist 集約、EntitlementService、メディアプレイヤー）

### 事前条件
- ライブラリに 1 曲以上の `Track` が登録済み。
- 対象プロフィールが `EntitlementService` から楽曲上限情報を取得できる状態。

### トリガー
- メイン画面のプレイリストパネルで「新規プレイリスト」を選択する。

### 基本フロー
1. ユーザーがプレイリスト名を入力し、`Playlist.create` が呼ばれてプレイリストが下書き状態（`PlaylistRepository.persist`）で保存される。
2. 曲一覧から追加候補を選択すると、ユースケース層が `EntitlementService.canAddTrack(currentTrackCount)` を呼び出し、上限内であることを確認する。
3. チェックが `true` の場合のみ `Playlist.addTrack(trackIdentifier)` が実行され、`allowDuplicates` 設定に従ってリストへ追加される。`false` の場合は追加を中断し、上限超過のダイアログを表示する。
4. ユーザーはドラッグ＆ドロップで `Playlist.reorder(orderIndex)` を操作し、希望の再生順に並べ替える。
5. 保存操作で `Playlist.finalize` が実行され、`PlaylistUpdated` イベントが発火し UI／プレイヤーキューに反映される。

### 代替フロー
- **既存プレイリストの編集**: 既存プレイリストを開くと格納済みトラック数から `canAddTrack` を再評価し、上限を超える場合は削除または長いプレイリストへの移動を促す。
- **エンタイトルメント更新**: 有料プランへアップグレードすると `EntitlementUpdated` イベントが届き、再読み込み時に `EntitlementService.getTrackLimit()` を用いて最新の上限値を表示する。

### 例外フロー
- **権利超過**: `canAddTrack` が `false` を返した場合、`EntitlementLimitExceededError` を捕捉し、ダイアログで上限値と現在数を提示する。
- **重複禁止違反**: `allowDuplicates=false` のプレイリストで同じ曲を追加しようとすると `Playlist.addTrack` が例外を投げ、ガイダンスメッセージを表示する。
- **永続化エラー**: `PlaylistRepository.persist` に失敗した場合はトランザクションをロールバックし、「保存できませんでした」と通知する。

### 事後条件
- プレイリスト構成が保存され、ナビゲーション / クイック再生メニューから呼び出し可能になる。
- `PlaylistUpdated` イベントが発火し、プレイヤー・通知・ウィジェットが同期される。

## 内部設計

### 関連ドメインモデル

#### Playlist（media）
- 概要：プレイリストのトラック集合と順序を管理する集約。
- 使用振る舞い：
  - `create(name, allowDuplicates)`：初期状態のプレイリストを生成。
  - `addTrack(trackIdentifier)`：`allowDuplicates` と上限チェックを満たす場合のみ追加。
  - `reorder(orderIndexMap)`：順序を更新し、不変条件として 0 以上の連番を保証。
  - `removeTrack(trackIdentifier)`：削除時に順序を詰め直す。

#### EntitlementService（billing）
- 概要：現在のプランに基づく曲数上限を照会する境界インターフェース。
- 使用箇所：トラック追加前に `canAddTrack` を呼び出し、`false` の場合はユースケース層でユーザー操作をブロック。
- 関連イベント：`EntitlementUpdated` / `EntitlementRestricted` を購読して UI 表示上限を更新。

#### PlaylistRepository（media）
- 概要：プレイリスト永続化（検索/保存/削除）を担当。
- 留意点：保存時はトランザクション内で `Playlist` の整合性を検証し、`PlaylistUpdated` を発火する。

#### Track（media）
- 概要：プレイリストに追加される個々の楽曲。`TrackIdentifier` と `LicenseRecord` を参照する。
- 役割：`Playlist.addTrack` 時に存在確認と利用可能状態（廃止されていないか）を保証する。

### データフロー
1. ユースケース層が `PlaylistRepository` から対象プレイリストを取得し、ユーザー操作を適用。
2. 各追加操作ごとに `EntitlementService.canAddTrack` を呼び出し、上限を超える場合は処理を中断。
3. 保存時に `PlaylistRepository.persist` が呼ばれ、成功後に `PlaylistUpdated` イベントが通知境界およびプレイヤーへ拡散される。
