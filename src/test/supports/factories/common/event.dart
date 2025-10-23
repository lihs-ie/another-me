import 'package:another_me/domains/common/event.dart';

import '../common.dart';

class _QueueingDriver implements QueueingDriver {
  final List<BaseEvent> _events;

  _QueueingDriver(this._events);

  @override
  Future<void> enqueue(BaseEvent event) async {
    _events.add(event);
  }

  @override
  Future<BaseEvent?> dequeue() async {
    return _events.isNotEmpty ? _events.removeAt(0) : null;
  }
}

class QueuingDriverFactory
    extends Factory<QueueingDriver, ({List<BaseEvent>? events})> {
  @override
  QueueingDriver create({
    ({List<BaseEvent>? events})? overrides,
    required int seed,
  }) {
    final events = overrides?.events ?? [];

    return _QueueingDriver(events);
  }

  @override
  QueueingDriver duplicate(
    QueueingDriver instance,
    ({List<BaseEvent>? events})? overrides,
  ) {
    throw UnimplementedError();
  }
}

typedef EventBrokerOverrides = ({QueueingDriver? queue});

class EventBrokerFactory extends Factory<EventBroker, EventBrokerOverrides> {
  @override
  EventBroker create({EventBrokerOverrides? overrides, required int seed}) {
    return EventBroker(
      queue:
          overrides?.queue ??
          Builder(QueuingDriverFactory()).buildWith(seed: seed),
    );
  }

  @override
  EventBroker duplicate(EventBroker instance, EventBrokerOverrides? overrides) {
    throw UnimplementedError();
  }
}
