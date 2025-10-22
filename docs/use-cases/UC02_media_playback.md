# ユースケース UC02: 公式カタログ楽曲をダウンロード・再生する

## 目的
- ユーザーがアプリ提供者が用意した lo-fi 楽曲カタログから曲を選び、ライセンスを自動登録した上で BGM として再生する。

## アクター
- メインアクター：ユーザー
- サポートアクター：アプリ（CatalogDownloadJob、Track、LicenseRecord、Player）

## 事前条件
- アプリが起動し、ネットワーク接続が利用可能。
- AssetCatalog に少なくとも 1 曲以上の公式楽曲が公開されている。

## トリガー
- ユーザーが「公式カタログ」画面で楽曲を選択し、「ダウンロード」ボタンを押す。

## 基本フロー
1. アプリが選択した曲の `CatalogTrackMetadata` を取得し、`CatalogDownloadJob` を `Pending` 状態で作成する。
2. `CatalogDownloadStarted` イベントが発火し、ダウンロードエグゼキュータが CDN から音源ファイルと LICENSE テキストを取得する。
3. ダウンロード終了後、`CatalogDownloadVerifying` でチェックサムが検証され、一致すれば `Registering` 状態へ進む。
4. `CatalogDownloadCompleted` が発火し、`LicenseRecord.registerFromCatalog` がライセンス本文と `licenseFileChecksum` を保存した後、`Track.registerFromCatalog` が音源メタとローカルパスを確定する。
5. 登録済み曲がライブラリへ追加され、再生キューに挿入される。プレイヤーがフェード付きで再生を開始し、ライセンス情報は `Track.syncLicense` により常に最新状態に保たれる。

### トランザクション順序
1. `LicenseRecord.registerFromCatalog` を licensing.db で Pending 状態としてコミット。
2. `Track.registerFromCatalog` を media.db でコミットし、ライセンス ID を参照。
3. 両方成功した場合のみ `TrackRegistered` イベントを発火し、HUD／モーダルを更新。
4. 途中で失敗した場合はライセンスを Pending に戻し、Download モーダルから再試行できるようにする。

## 代替フロー
- **事前ダウンロード済み**: 既にローカルに存在する曲を選択した場合、ダウンロードはスキップされ即時再生される。
- **バックグラウンドダウンロード**: ユーザーが複数曲をキューに入れた場合、CatalogDownloadJob がキューで順次処理され、完了通知のみトーストで表示する。

## 例外フロー
- **チェックサム不一致**: ファイルの整合性検証に失敗すると `CatalogDownloadFailed` が発火し、ユーザーへ「再試行」オプションを提示する。
- **ネットワークエラー**: 再試行回数（最大 3 回）を超えて失敗した場合、ジョブを `Failed` としてログに残し、ユーザーに後で再実行を促す。
- **ストレージ不足**: ダウンロード先の空き容量が不足している場合、適切なエラーメッセージを表示し、不要な曲の削除を案内する。

## 事後条件
- `Track` と `LicenseRecord` が永続化され、公式カタログのメタデータと一致した状態で保存される。
- ダウンロード済み曲はオフラインでも再生できる（licenseMetadata.allowOffline が true の場合）。
# ユースケース UC02: 公式カタログ楽曲をダウンロード・再生する

## 外部設計

### 目的
- ユーザーが公式カタログから楽曲を選択し、ライセンス登録とローカル保存を経て BGM として再生できるようにする。

### アクター
- メインアクター：ユーザー
- サポートアクター：アプリ（Import・Licensing・Media 境界、Notification 境界）

### 事前条件
- アプリがオンラインで動作中。
- `AssetCatalog` に少なくとも 1 曲の公開トラックが存在する。
- ユーザープロファイルにダウンロード先と再生設定が構成済み。

### トリガー
- ユーザーが「公式カタログ」画面で曲を選択し、「ダウンロード」を押下する。

### 基本フロー
1. アプリが選択した曲の `CatalogTrackMetadata` を取得し、`CatalogDownloadService.start(jobId)` が `CatalogDownloadJob` を `Pending` → `Queued` 状態で永続化する。
2. Import 境界のダウンロード実行キューが `CatalogDownloadStarted` を発火し、エグゼキュータが CDN から音源・LICENSE ファイルを取得する。進捗は Notification 境界が HUD/トーストで表示する。
3. 取得完了後、`CatalogDownloadJob.markVerifying` により `CatalogDownloadVerifying` が発火。チェックサムが一致すれば `CatalogDownloadVerified` が発行され、`CatalogDownloadJob.startRegistration` が `Registering` へ遷移する。
4. `CatalogDownloadCompleted` が発火し、Licensing 境界の `LicenseRegistrationSubscriber` が `LicenseRecord.registerFromCatalog` を実行してライセンスを保存する。ライセンス登録が成功すると `LicenseRecordRegistered` が発火する。
5. Media 境界の `TrackRegistrationSubscriber` が `LicenseRecordRegistered` と `CatalogDownloadCompleted` を受け、`Track.registerFromCatalog` で楽曲メタデータとローカルファイルパスを確定する。成功時に `TrackRegistered` が発火し、プレイヤーがフェードインで再生を開始する。
6. ダウンロード完了通知が表示され、曲はライブラリおよびプレイリストに追加される。ユーザーは即座に再生・ループ設定を操作できる。

### 代替フロー
- **事前ダウンロード済み**：ローカルに同一トラックが存在する場合、`CatalogDownloadService` が既存ファイルを検証し、手順 2〜5 をスキップして即再生する。
- **バックグラウンドキュー**：複数曲を連続キューすると、Import 境界が FIFO で処理し、完了ごとにトースト通知のみ表示する。
- **ライセンスのみ再取得**：音源は最新のままでライセンス条項のみ変更された場合、Licensing 境界が `LicenseRecord.updateFromCatalog` を実行し、`Track` は再ダウンロードせずにメタデータを同期する。

### 例外フロー
- **チェックサム不一致**：`CatalogDownloadVerified` で整合性が取れない場合、`CatalogDownloadJob.markFailed` が `CatalogDownloadFailed` を発火。ユーザーに再試行オプションを提示し、リトライ上限を超えると失敗ログを残す。
- **ネットワークエラー**：ダウンロード中にエラーが発生した場合、リトライポリシー（既定 3 回）に従い再試行。すべて失敗すると `CatalogDownloadFailed` が通知され、ユーザーへ後日再実行を促す。
- **ストレージ不足**：保存先の空き容量が閾値未満の場合、Import 境界が `CatalogDownloadJob.markFailed(StorageLow)` を実行し、不要曲の削除案内を表示する。
- **ライセンス登録失敗**：`LicenseRecord.registerFromCatalog` が失敗した場合、Licensing 境界が `CatalogDownloadFailed` を再発火し、Import 境界がジョブを `Failed` としてログに記録する。音源はクリーンアップされる。

### 事後条件
- `Track` と `LicenseRecord` が永続化され、音源・LICENSE ファイルがローカルに保存される。
- `TrackRegistered` によりプレイリスト・プレイヤーが更新され、オフライン再生が許可されている場合はオフラインでも利用可能となる。

## 内部設計

### 関連ドメインモデル

#### CatalogDownloadJob（import）
- 概要：公式カタログダウンロードの状態遷移・再試行・チェックサム検証を管理する集約。
- 主な振る舞い：
  - `queue(metadata)`：ジョブの初期化とキュー投入。
  - `startDownload(paths)`：ダウンロード開始・イベント発火。
  - `markVerifying(actualChecksum)`：チェックサム検証へ遷移。
  - `completeRegistration(licensePath)`：登録完了と `CatalogDownloadCompleted` の発火。
  - `markFailed(reason)`：失敗理由を保持し、再試行ポリシーを適用。

#### CatalogDownloadJobRepository（import）
- 概要：ジョブの永続化・検索・状態更新を担う。
- ユースケース利用箇所：キュー投入、ダウンロード実行時のジョブ取得、検証・登録完了時の更新。

#### LicenseRecord（licensing）
- 概要：外部ライセンス本文・署名を保持し、`LicenseRecordRegistered` を発火する集約。
- ユースケース利用箇所：`registerFromCatalog` により DLC ライセンスを保存し、メディア境界へ通知する。

#### Track（media）
- 概要：楽曲メタデータ・ローカルパス・ライセンス参照を持つ集約。
- ユースケース利用箇所：`registerFromCatalog` によりトラックを登録し、`TrackRegistered` を通じて再生系へ通知する。

#### TrackRepository / LicenseRecordRepository（media / licensing）
- 概要：各集約の永続化を担当するリポジトリ。
- 備考：二重コミットを避けるため、ユースケース層でトランザクション境界を管理する。

#### Player / PlaybackController（media）
- 概要：`TrackRegistered` イベントを購読し、新規トラックを再生キューに追加するアプリケーションサービス。

### データフロー
1. ユースケース層が `CatalogDownloadService.queueFromCatalog(trackIdentifier)` を呼び出し、`CatalogDownloadJob` を生成して Import 境界に保存。
2. ダウンロード実行時に Import 境界が CDN から資産を取得しつつ、イベント（`CatalogDownloadStarted`→`CatalogDownloadVerifying`→`CatalogDownloadCompleted`）を発火。
3. `CatalogDownloadCompleted` を受けた Licensing 境界がライセンスを登録し、`LicenseRecordRegistered` を発火。
4. Media 境界が `Track.registerFromCatalog` を実行して `TrackRegistered` を発火、プレイヤー・通知・プロフィール設定が更新される。
5. エラー時は `CatalogDownloadFailed` または `TrackRegistrationFailed` などのイベントでロールバックし、UI に失敗を通知する。
