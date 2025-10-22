# 依存性注入 (DI) 方針

## 基本方針

- Flutter アプリで `riverpod` を DI コンテナ／状態管理として使用。
- インフラ層のリポジトリ／ACL、ユースケース実行サービスを Provider で公開し、プレゼンテーション層から取得する。
- 依存性の初期化は `ProviderScope` の `overrides` 機能で行い、テスト時にはモックを差し替える。

## プロバイダ構成

| Provider 名                         | 種別                    | 依存先                                                                 |
|-------------------------------------|-------------------------|-------------------------------------------------------------------------|
| `databaseProvider`                  | `Provider<DatabasePool>`| SQLite DB（work.db, media.db など）                                     |
| `firebaseStorageClientProvider`     | `Provider<FirebaseStorageClient>` | Firebase Storage ACL                                                  |
| `licenseRecordRepositoryProvider`   | `Provider<LicenseRecordRepository>` | `databaseProvider`, `firebaseStorageClientProvider`                  |
| `trackRepositoryProvider`           | `Provider<TrackRepository>` | `databaseProvider`, `licenseRecordRepositoryProvider`                 |
| `catalogDownloadJobServiceProvider` | `Provider<CatalogDownloadJobService>`| Repositories + ACL + EventBus                                        |
| `notificationDispatcherProvider`    | `Provider<NotificationDispatcher>` | OS ごとの通知 API ラッパー                                            |
| `pomodoroSessionControllerProvider` | `StateNotifierProvider`  | `PomodoroSessionRepository`, `NotificationDispatcher`                  |

## イベントバス

- アプリケーション内イベント（TrackRegistered など）は `StreamController.broadcast()` を用いたイベントバスで実装し、Riverpod の `StreamProvider` から購読できるようにする。
- サンプル実装：
  ```dart
  abstract class DomainEvent {
    DateTime get occurredAt;
  }

  class EventBus {
    final StreamController<DomainEvent> _controller = StreamController.broadcast();

    Stream<T> on<T extends DomainEvent>() => _controller.stream.whereType<T>();

    void publish(DomainEvent event) => _controller.add(event);
  }

  final eventBusProvider = Provider<EventBus>((ref) => EventBus());

  // 購読例
  final trackRegisteredStreamProvider = StreamProvider<TrackRegistered>((ref) {
    final eventBus = ref.watch(eventBusProvider);
    return eventBus.on<TrackRegistered>();
  });
  ```
- ユースケース内では `eventBus.publish(...)` を呼び出し、プレゼンテーション層は `StreamProvider` 経由で購読。
- 将来、外部イベントストリーム（Firebase Messaging 等）を取り込む場合も同じ仕組みで拡張可能。

## テスト時の差し替え

- `ProviderScope(overrides: [...])` でリポジトリや ACL をモックに差し替え。
- integration テストでは実際の SQLite インメモリ DB を利用。
