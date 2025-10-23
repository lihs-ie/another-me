abstract class BaseEvent {
  final DateTime occurredAt;

  BaseEvent(this.occurredAt);
}

class Listener<T extends BaseEvent> {
  final void Function(T event) handler;

  Listener(this.handler);

  bool matches(Type eventType) {
    return T == eventType;
  }

  void handle(T event) {
    handler(event);
  }
}

abstract interface class QueueingDriver {
  Future<void> enqueue(BaseEvent event);
  Future<BaseEvent?> dequeue();
}

class EventBroker {
  final Map<Type, List<Listener>> _listeners = {};
  final QueueingDriver queue;

  EventBroker({required this.queue});

  void listen<T extends BaseEvent>(Listener<T> listener) {
    final eventType = T;
    final listeners = _listeners[eventType] ?? [];

    listeners.add(listener);
    _listeners[eventType] = listeners;
  }

  void publish<T extends BaseEvent>(T event) {
    queue.enqueue(event);
  }

  void publishAll(List<BaseEvent> events) {
    for (final event in events) {
      queue.enqueue(event);
    }
  }

  Future<void> consume<T extends BaseEvent>() async {
    final event = await queue.dequeue();

    if (event == null) {
      return;
    }

    final eventType = event.runtimeType;
    final listeners = _listeners[eventType] ?? [];

    for (final listener in listeners) {
      if (listener.matches(eventType)) {
        listener.handle(event);
      }
    }
  }
}

abstract interface class EventSubscriber {
  void subscribe(EventBroker broker);
}
