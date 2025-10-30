# システムエラーハンドリング方針

プレゼンテーション層の UI 表現は `docs/presentation/error_handling.md` を参照。本ドキュメントではアプリケーション層／インフラ層での例外分類と処理を定義する。

## 例外分類

- `DomainException`：ドメインルール違反（例：ポモドーロ設定が範囲外）。 → UI でインライン警告。
- `InfrastructureException`：DB/ネットワーク等のインフラ系エラー。
- `ApplicationException`：ユースケースの制御フローで発生するエラー（例：再試行回数超過）。

## 複数 DB 間トランザクションと再試行ポリシー

- Track（media.db）と LicenseRecord（licensing.db）など複数データベースにまたがる処理はサガパターンで調整する。
  1. `LicenseRecord.registerFromCatalog` を Pending 状態でコミット（licensing.db）。
  2. `Track.registerFromCatalog` をコミット（media.db）。
  3. 成功した場合のみ `LicenseRecord` を Active に更新（licensing.db）。
  4. 途中で失敗した場合：
     - Track 登録失敗 → `LicenseRecord` を Pending に戻し、再試行キューへ追加。
     - Active 更新失敗 → Track を削除して整合性を保つ。
- ネットワークエラー（InfrastructureException）：指数バックオフ 3 回 + ユーザー再試行に委ねる。
- DB 書き込みエラー：単一トランザクションでロールバックし、ユーザーに再起動を推奨。
- ドメイン例外：即座にエラーを返し、UI 側で修正を促す。

## ロギング

- 例外発生時には `logging.md` で定義したレベルに応じてログ出力。
- `ERROR` レベルではスタックトレースを含め、クラッシュレポートに送信可能とする（将来拡張）。

## フォールバック

- ライセンス登録後に Track 登録が失敗した場合：`LicenseRecord` を Pending に戻し、再試行キューへ追加。
- カタログ同期で JSON ダウンロードが失敗した場合：前回の catalog.json を使用しつつ、次回同期で再試行。
