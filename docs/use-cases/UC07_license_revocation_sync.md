# ユースケース UC07: ライセンス取り消し時の自動トラック無効化（システム）

## 目的
- 外部ライセンスが取り消された際に、ユーザー操作なしで該当曲を再生不可にし、プレイリストから安全に外す。

## アクター
- メインアクター：ライセンス管理サービス（Licensing パッケージ）
- サポートアクター：Media パッケージ、Notification パッケージ

## 事前条件
- 対象楽曲に対応する `LicenseRecord` が存在し、少なくとも一つの `Track` がそのライセンスを参照している。

## トリガー
- ライセンス提供元からの通知、もしくは手動更新により `LicenseRecord.revoke(reason)` が呼び出される。

## 基本フロー
1. Licensing パッケージが `LicenseRecordRevoked` イベントを発火し、ペイロードに `licenseIdentifier` と `reason` を含める。
2. Media パッケージの `LicenseRecordSyncSubscriber` がイベントを受け取り、該当ライセンスを参照するトラック一覧を取得する。
3. 各トラックに対して `Track.syncLicense(revokedRecord)` でライセンス状態を更新したのち `Track.markDeprecated(reason)` を実行し、`TrackDeprecated` イベントを発火する。必要に応じて `licenseFilePath` と `licenseFileChecksum` の整合を確認し、利用不可としてマークする。
4. `TrackDeprecationSubscriber` が関連プレイリストを走査し、該当曲を無効化 or 削除、`PlaylistUpdated` イベントを発生させる。
5. Notification パッケージが「登録曲が利用できなくなりました」通知を作成し、ユーザーへ告知する。

## 代替フロー
- **オフライン許可あり**: `allowOffline=true` だった場合も、ライセンス取り消し後はローカルファイルを読み取り不可フォルダへ移動し、復元できないようにする。
- **新ライセンス登録**: ライセンスが再発行された場合は別途 `LicenseRecord.update` → `TrackMetadataUpdated` の流れで復活させる。

## 例外フロー
- **トラック未検出**: ライセンスを参照する曲が存在しない場合は警告ログを残し、ユーザー通知は行わない。
- **プレイリスト全消失**: プレイリストがすべて空になった場合、ガイドモーダルを表示して新しい曲の取り込みを促す。

## 事後条件
- 対象トラックは再生リストから排除され、ライブラリにも「使用不可」として表示される。
- 監査ログ（SessionLog / LicenseRecordHistory）に取り消し事実が記録される。
# ユースケース UC07: ライセンス取り消し時の自動トラック無効化（システム）

## 外部設計

### 目的
- 外部ライセンスが取り消された際に、対象トラックを自動で利用不可へ切り替え、プレイリストから安全に外したうえでユーザーへ通知する。

### アクター
- メインアクター：Licensing 境界（ライセンス管理サービス）
- サポートアクター：Media 境界、Profile 境界、Notification 境界

### 事前条件
- 対象ライセンスの `LicenseRecord` が存在し、少なくとも 1 つの `Track` が参照している。
- ローカルストレージ上に音源ファイルと LICENSE ファイルが保存済み。

### トリガー
- ライセンス提供元からの取り消し通知、または管理者による `LicenseRecord.revoke(reason)` 呼び出し。

### 基本フロー
1. Licensing 境界が `LicenseRecord.revoke(reason)` を実行し、`LicenseRecordRevoked` イベントを発火する。ペイロードには `licenseIdentifier`, `reason`, `revokedAt` が含まれる。
2. Media 境界の `LicenseRecordSyncSubscriber` がイベントを受け取り、`TrackRepository.searchByLicense(licenseIdentifier)` で関連トラックを取得する。
3. 各トラックに対して `Track.syncLicense(revokedRecord)` を実行し、`Track.markDeprecated(reason)` で再生不可にする。結果として `TrackDeprecated` イベントが発火し、必要ならローカルファイルを隔離フォルダへ移動する。
4. `TrackDeprecated` を購読する `PlaylistSanitizerUseCase` が影響プレイリストを走査し、該当曲を削除または無効化して `PlaylistUpdated` を発火する。プレイリストが空になった場合はガイド表示を行う。
5. Notification 境界が `LicenseRecordRevoked` と `TrackDeprecated` をもとにユーザー通知を作成し、「利用できなくなりました」メッセージと再取得案内を提示する。

### 代替フロー
- **オフラインキャッシュあり**：`allowOffline=true` のライセンスでも、取り消し直後に Media 境界がローカルファイルを読み取り不可領域へ移動し、再生を阻止する。
- **ライセンス再発行**：後日 `LicenseRecord.updateFromProvider` が成功した場合、`LicenseRecordRestored` → `Track.reactivate()` の流れでトラックが復活する。

### 例外フロー
- **対象トラックなし**：関連トラックが存在しない場合、Media 境界は警告ログのみ記録し、ユーザー通知は行わない。
- **プレイリスト全削除**：削除結果としてプレイリストがすべて空になった場合、UI が「新しい曲を追加してください」ガイドモーダルを表示する。
- **ファイル隔離失敗**：ファイル移動に失敗した場合は再試行（最大 3 回）後に、ユーザーへ手動削除を促す。

### 事後条件
- 影響トラックが再生不可となり、プレイリスト・ライブラリ上で「使用不可」と表示される。
- `LicenseRecordHistory` や監査ログに取り消し事実が記録される。

## 内部設計

### 関連ドメインモデル

#### LicenseRecord（licensing）
- 概要：外部ライセンス本文・メタデータを保持する集約。
- 主な振る舞い：`revoke(reason)` で状態を `Revoked` に遷移させ、`LicenseRecordRevoked` を発火する。

#### Track（media）
- 概要：楽曲メタデータとライセンス参照を保持する集約。
- 主な振る舞い：
  - `syncLicense(revokedRecord)`：最新ライセンス状態を取り込み。
  - `markDeprecated(reason)`：再生不可に設定し、`TrackDeprecated` を発火。

#### Playlist（media）
- 概要：楽曲集合を管理する集約。
- 関連ユースケース：`removeTrack` / `markUnavailable` を通じてプレイリストから削除・無効化する。

#### PlaylistSanitizerUseCase（media アプリケーション層）
- 概要：`TrackDeprecated` を受けてプレイリストを走査し、`Playlist` を更新して `PlaylistUpdated` を発火。

#### NotificationFacade（notification）
- 概要：ライセンス解除に伴う通知テンプレートを適用し、ユーザーへ配信する。

### データフロー
1. `LicenseRecord.revoke` → `LicenseRecordRevoked`。
2. Media 境界が関連トラックを取得し、`Track.syncLicense` → `Track.markDeprecated` → `TrackDeprecated`。
3. `TrackDeprecated` を受けた Playlist ユースケースがトラックを除去し、`PlaylistUpdated` を発火。
4. Notification 境界が `LicenseRecordRevoked` / `TrackDeprecated` を統合し、ユーザーに通知。
