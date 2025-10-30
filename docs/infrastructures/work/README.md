# work パッケージ（PomodoroSession / SessionLog）

## 永続化戦略

| 集約/データ            | ストア                    | 保存形式                         |
|-------------------------|---------------------------|----------------------------------|
| PomodoroSession（進行中） | SQLite (`work.db`)        | テーブル `pomodoro_session`      |
| SessionLog               | SQLite (`work.db`)        | テーブル `session_log`           |
| PhaseHistory             | SQLite (`work.db`)        | テーブル `session_phase_history` |

- SQLite を選択した理由：フェーズ履歴・統計照会・期間フィルタなどクエリが必要なため。
- 進行中セッションは 1 レコードのみ保持（`status != Completed`）。

## 保存形式（テーブル定義）

### pomodoro_session
- `session_identifier` TEXT PRIMARY KEY
- `status` TEXT (`Idle`/`Running`/`Paused`/`Completed`)
- `phase` TEXT
- `remaining_time_ms` INTEGER
- `elapsed_cycles` INTEGER
- `work_minutes` INTEGER
- `break_minutes` INTEGER
- `long_break_minutes` INTEGER
- `long_break_every` INTEGER
- `last_tick_at` INTEGER (UTC epoch ms)
- `next_coffee_at` INTEGER NULLABLE (UTC epoch ms)
- `updated_at` INTEGER

### session_phase_history
- `id` INTEGER PRIMARY KEY AUTOINCREMENT
- `session_identifier` TEXT
- `phase` TEXT
- `started_at` INTEGER
- `ended_at` INTEGER
- `skipped` INTEGER (0/1)
- FOREIGN KEY(session_identifier) REFERENCES pomodoro_session(session_identifier)

### session_log
- `log_identifier` TEXT PRIMARY KEY
- `session_identifier` TEXT UNIQUE
- `started_at` INTEGER
- `ended_at` INTEGER
- `total_work_ms` INTEGER
- `total_break_ms` INTEGER
- `cycle_count` INTEGER

## リポジトリ実装

- `PomodoroSessionRepository`
  - `findActive()` → `SELECT * FROM pomodoro_session WHERE status != 'Completed' LIMIT 1`
  - `persist(session)` → UPSERT してフェーズ履歴を同期
  - `terminate(sessionIdentifier)` → レコード削除

- `SessionLogRepository`
  - `append(log)` → `INSERT`（UNIQUE 制約で重複防止）
  - `findRange(from,to)` → `SELECT ... WHERE started_at BETWEEN ...`
  - `findLatest(limit)` → `ORDER BY started_at DESC LIMIT ?`

## 追加メモ

- クロスプラットフォーム対応：macOS/iOS は `Library/Application Support/another-me/work.db`、Windows は `%APPDATA%\another-me\work.db`、Android は `Context.getDatabasePath()` 相当を利用。
- スリープ補正のため `last_tick_at` を保持し、アプリ起動時に差分を計算する。

## トランザクション境界

- `PomodoroSessionRepository.persist` は以下のステップを 1 トランザクションで実施する：
  1. `pomodoro_session` テーブルを UPSERT。
  2. `session_phase_history` に新規フェーズを INSERT（既存はそのまま）。
  3. 失敗時はトランザクション全体をロールバック。
- `SessionLogRepository.append` もトランザクションを利用し、ログ本体とフェーズサマリーの整合を維持する。

## マイグレーション・スキーマバージョン

- `work.db` に `schema_version` テーブルを配置し、`migrations/work/` 以下の SQL を適用。
- 起動時に未適用バージョンを順次実行し、エラー時はロールバックしてアプリ起動をブロックする。
