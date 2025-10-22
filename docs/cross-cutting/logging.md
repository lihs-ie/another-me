# ログ / モニタリング方針

## ログレベル

- `DEBUG`：開発時のみ。詳細なステップログ（ダウンロード進捗など）。
- `INFO`：主要イベント（TrackRegistered, PomodoroPhaseCompleted）。
- `WARN`：再試行が必要なエラー（ネットワーク一時的障害）。
- `ERROR`：致命的エラー（DB 書き込み失敗など）。

## 出力先

- デフォルトはコンソール（Flutter Logger パッケージ等）。
- 将来的に Crashlytics/Sentry を導入する場合は `LogSink` インターフェースを実装して DI で切替。

## コンテキスト

- ログには `sessionIdentifier`, `trackIdentifier`, `catalogTrackIdentifier` など、トラブルシューティングに必要な ID を付与。
- ユーザー個人情報は記録しない。
- 将来ユーザーアカウントを扱う場合は、ログには匿名化されたハッシュ ID（例：SHA-256 でソルト付き）を使用し、生のメールアドレスや氏名は出力しない。

## ログフォーマット

- JSON 形式で構造化ログを出力：
  ```json
  {
    "timestamp": "2025-10-22T10:00:00Z",
    "level": "INFO",
    "message": "Track registered",
    "context": {
      "trackIdentifier": "lofi_chill_piano_001",
      "licenseIdentifier": "license_lofi_001",
      "sessionIdentifier": null
    }
  }
  ```
- Crashlytics/Sentry へ送信する場合も同じキー構造を使い、分析しやすくする。

## エラー連携

- `ERROR` レベルのログは `docs/presentation/error_handling.md` の UI 表示と連動。例えば DB エラー時は Dialog 表示 + ログ。

## テスト

- ログ出力が多すぎないか（スパムの懸念）を確認。
- 重要イベント（セッション開始/終了、ダウンロード完了など）が INFO で出力されるかのユニットテストを追加。
