# ユースケース UC15: テレメトリ同意設定

## 目的
- ユーザーがテレメトリデータの送信を許可または拒否できるようにする。

## アクター
- メインアクター：ユーザー
- サポートアクター：TelemetryConsent 集約、UsageMetrics 集約

## 事前条件
- ユーザーが設定画面を開いている。
- プロフィールが選択されている。

## トリガー
- ユーザーが設定画面でテレメトリ同意のトグルを切り替える。

## 基本フロー
1. ユーザーがテレメトリ同意のトグルを「オン」または「オフ」に切り替える。
2. `TelemetryConsentService` が呼び出される。
3. `TelemetryConsentRepository.find(profileIdentifier)` で現在の consent を取得する（存在しない場合は新規作成）。
4. `consent.changeStatus(requestedStatus)` を呼び出し、同意状態を更新する。
5. `TelemetryConsentRepository.persist(consent)` で永続化する。
6. `TelemetryConsentChanged` イベントが発火される。
7. `TelemetryConsentSubscriber` が `TelemetryConsentChanged` イベントを受信し、`UsageMetrics` の opt-in 状態を同期する。
8. UI にフィードバックが表示される（例：「テレメトリ設定を更新しました」）。

## 代替フロー
- **オプトアウト時のデータ削除**: ユーザーがオプトアウトに切り替えた場合、`UsageMetrics.changeOptIn(false)` が自動的に既存のイベントデータをクリアする。

## 例外フロー
- **永続化失敗**: `TelemetryConsentRepository.persist(consent)` が失敗した場合、エラーメッセージをユーザーに表示し、変更をロールバックする。

## 事後条件
- テレメトリ同意状態が更新される。
- オプトインの場合、以降の利用イベントが記録される。
- オプトアウトの場合、既存のイベントデータが削除され、以降のイベントは記録されない。

## 内部設計（ユースケース層）

### TelemetryConsentService （ユースケース）

- 目的：ユーザー操作によるテレメトリ同意の変更を telemetry ドメイン内で完結させる。
- トリガー：設定画面などからの明示的な同意変更リクエスト
- 処理内容：
  1. `TelemetryConsentRepository.find(profileIdentifier)` で現在の consent を取得（存在しない場合は `TelemetryConsent` を新規作成）
  2. `consent.changeStatus(requestedStatus)` を呼び出し
  3. `TelemetryConsentRepository.persist(consent)` で永続化
  4. 発火されたイベント（`TelemetryConsentChanged`）を EventBroker に publish
- 備考：
  - `UsageMetrics` の opt-in 状態の同期は `TelemetryConsentSubscriber` が `TelemetryConsentChanged` イベントを購読して自動的に行う
# ユースケース UC15: テレメトリ同意設定

## 外部設計

### 目的
- ユーザーがテレメトリデータ送信を許可または拒否できるようにし、同意状態に応じて UsageMetrics の収集・送信を制御する。

### アクター
- メインアクター：ユーザー
- サポートアクター：TelemetryConsent 集約、UsageMetrics 集約

### 事前条件
- ユーザーが設定画面を開き、対象プロファイルが選択されている。

### トリガー
- 設定画面でテレメトリ同意トグルを切り替える。

### 基本フロー
1. ユーザーがトグルを「オン」または「オフ」に切り替えると、`TelemetryConsentService.changeStatus(profileIdentifier, requestedStatus)` が呼び出される。
2. サービスが `TelemetryConsentRepository.find(profileIdentifier)` で現在の consent を取得（未保存なら新規作成）し、`consent.changeStatus(requestedStatus)` を実行する。
3. `TelemetryConsentRepository.persist(consent)` で永続化し、`TelemetryConsentChanged` を発火する。
4. `TelemetryConsentSubscriber` がイベントを受け、`UsageMetrics.changeOptIn(status == ConsentStatus.accepted)` を実行して UsageMetrics の opt-in 状態を同期する。
5. UI で「テレメトリ設定を更新しました」などのフィードバックを表示する。

### 代替フロー
- **オプトアウト時データ削除**：オプトアウトに切り替えた場合、`UsageMetrics` が `optIn=false` になった時点で既存イベントをクリアし、以降の収集を停止する。

### 例外フロー
- **永続化失敗**：`TelemetryConsentRepository.persist` が失敗した場合、トグルを元に戻してエラーメッセージを表示する。ログに記録し、次回操作で再試行を促す。

### 事後条件
- テレメトリ同意状態が更新され、UsageMetrics の収集ポリシーが即時反映される。
- オプトイン時は今後の利用イベントが記録され、オプトアウト時は既存データが削除され以降は記録されない。

## 内部設計

### 関連ドメインモデル

#### TelemetryConsent（telemetry）
- 概要：同意状態と同意日時を保持する集約。
- 主な振る舞い：`changeStatus(requestedStatus)` が状態遷移と監査フィールド更新を行い、`TelemetryConsentChanged` を発火する。

#### UsageMetrics（telemetry）
- 概要：テレメトリ収集設定とイベントを保持する集約。
- ユースケース利用箇所：`changeOptIn` で opt-in 状態を切り替え、オプトアウト時は `purgeEvents()` を実行する。

#### TelemetryConsentRepository
- 概要：`TelemetryConsent` の取得・保存を担当。

### データフロー
1. UI → `TelemetryConsentService.changeStatus` → `TelemetryConsentRepository.find` → `TelemetryConsent.changeStatus`.
2. `TelemetryConsentRepository.persist` → `TelemetryConsentChanged` イベント。
3. `TelemetryConsentSubscriber` が UsageMetrics を更新し、必要に応じてイベントをクリア。
