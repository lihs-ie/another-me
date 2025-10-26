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
  final List<BaseEvent> _pending = [];

  EventBroker({required this.queue});

  void listen<T extends BaseEvent>(void Function(T event) handler) {
    final eventType = T;
    final listeners = _listeners[eventType] ?? [];

    listeners.add(Listener<T>(handler));
    _listeners[eventType] = listeners;
  }

  void publish<T extends BaseEvent>(T event) {
    _pending.add(event);
  }

  void publishAll(List<BaseEvent> events) {
    _pending.addAll(events);
  }

  Future<void> deliver() async {
    for (final event in _pending) {
      await queue.enqueue(event);
    }

    _pending.clear();
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

mixin Publishable<T extends BaseEvent> {
  final List<T> _events = [];

  void publish(T event) {
    _events.add(event);
  }

  void publishAll(List<T> events) {
    _events.addAll(events);
  }

  List<T> events() {
    final events = List<T>.unmodifiable(_events);

    clear();

    return events;
  }

  void clear() {
    _events.clear();
  }
}
