import 'package:another_me/domains/common/range.dart';
import 'package:another_me/domains/common/transaction.dart';
import 'package:another_me/domains/profile/profile.dart';
import 'package:another_me/domains/telemetry/usage.dart';
import 'package:ulid/ulid.dart';

import '../common.dart';
import '../common/date.dart';
import '../common/identifier.dart';
import '../common/transaction.dart';
import '../enum.dart';
import '../profile/profile.dart';

class UsageMetricsIdentifierFactory
    extends ULIDBasedIdentifierFactory<UsageMetricsIdentifier> {
  UsageMetricsIdentifierFactory()
    : super((Ulid value) => UsageMetricsIdentifier(value: value));
}

class TelemetryConsentIdentifierFactory
    extends ULIDBasedIdentifierFactory<TelemetryConsentIdentifier> {
  TelemetryConsentIdentifierFactory()
    : super((Ulid value) => TelemetryConsentIdentifier(value: value));
}

typedef EventPayloadOverrides = ({Map<String, Object>? data});

class EventPayloadFactory extends Factory<EventPayload, EventPayloadOverrides> {
  @override
  EventPayload create({EventPayloadOverrides? overrides, required int seed}) {
    final data =
        overrides?.data ??
        (seed % 2 == 0
            ? {}
            : {'key_$seed': 'value_$seed', 'count': seed % 1000});

    return EventPayload(data: data);
  }

  @override
  EventPayload duplicate(
    EventPayload instance,
    EventPayloadOverrides? overrides,
  ) {
    final data = overrides?.data ?? instance.data;

    return EventPayload(data: Map.from(data));
  }
}

class UsageEventTypeFactory extends EnumFactory<UsageEventType> {
  UsageEventTypeFactory() : super(UsageEventType.values);
}

typedef UsageEventOverrides = ({
  UsageEventType? type,
  EventPayload? payload,
  DateTime? occurredAt,
});

class UsageEventFactory extends Factory<UsageEvent, UsageEventOverrides> {
  @override
  UsageEvent create({UsageEventOverrides? overrides, required int seed}) {
    final type =
        overrides?.type ??
        Builder(UsageEventTypeFactory()).buildWith(seed: seed);

    final payload =
        overrides?.payload ??
        Builder(EventPayloadFactory()).buildWith(seed: seed);

    final occurredAt =
        overrides?.occurredAt ??
        Builder(DateTimeFactory()).buildWith(seed: seed);

    return UsageEvent(type: type, payload: payload, occurredAt: occurredAt);
  }

  @override
  UsageEvent duplicate(UsageEvent instance, UsageEventOverrides? overrides) {
    final type =
        overrides?.type ??
        Builder(
          UsageEventTypeFactory(),
        ).duplicate(instance: instance.type, overrides: null);

    final payload =
        overrides?.payload ??
        Builder(
          EventPayloadFactory(),
        ).duplicate(instance: instance.payload, overrides: null);

    final occurredAt =
        overrides?.occurredAt ??
        Builder(
          DateTimeFactory(),
        ).duplicate(instance: instance.occurredAt, overrides: null);

    return UsageEvent(type: type, payload: payload, occurredAt: occurredAt);
  }
}

class TelemetryConsentStatusFactory
    extends EnumFactory<TelemetryConsentStatus> {
  TelemetryConsentStatusFactory() : super(TelemetryConsentStatus.values);
}

typedef MetricsWindowOverrides = ({Range<DateTime>? range});

class MetricsWindowFactory
    extends Factory<MetricsWindow, MetricsWindowOverrides> {
  @override
  MetricsWindow create({MetricsWindowOverrides? overrides, required int seed}) {
    if (overrides?.range != null) {
      return MetricsWindow(range: overrides!.range!);
    }

    final now = DateTime.now();

    final durationDays = (seed % 7) + 1;

    final daysAgo = (seed % 23) + 1;

    final start = now.subtract(Duration(days: daysAgo));

    final end = start.add(Duration(days: durationDays));

    return MetricsWindow(
      range: Range<DateTime>(start: start, end: end),
    );
  }

  @override
  MetricsWindow duplicate(
    MetricsWindow instance,
    MetricsWindowOverrides? overrides,
  ) {
    final range =
        overrides?.range ??
        Range<DateTime>(start: instance.start, end: instance.end);

    return MetricsWindow(range: range);
  }
}

typedef TelemetryConsentOverrides = ({
  TelemetryConsentIdentifier? identifier,
  ProfileIdentifier? profile,
  TelemetryConsentStatus? status,
  DateTime? updatedAt,
});

class TelemetryConsentFactory
    extends Factory<TelemetryConsent, TelemetryConsentOverrides> {
  @override
  TelemetryConsent create({
    TelemetryConsentOverrides? overrides,
    required int seed,
  }) {
    final identifier =
        overrides?.identifier ??
        Builder(TelemetryConsentIdentifierFactory()).buildWith(seed: seed);

    final profile =
        overrides?.profile ??
        Builder(ProfileIdentifierFactory()).buildWith(seed: seed);
    final status =
        overrides?.status ??
        Builder(TelemetryConsentStatusFactory()).buildWith(seed: seed);

    final updatedAt =
        overrides?.updatedAt ??
        Builder(DateTimeFactory()).buildWith(seed: seed);

    return TelemetryConsent(
      identifier: identifier,
      profile: profile,
      status: status,
      updatedAt: updatedAt,
    );
  }

  @override
  TelemetryConsent duplicate(
    TelemetryConsent instance,
    TelemetryConsentOverrides? overrides,
  ) {
    final identifier =
        overrides?.identifier ??
        Builder(
          TelemetryConsentIdentifierFactory(),
        ).duplicate(instance: instance.identifier, overrides: null);

    final profile =
        overrides?.profile ??
        Builder(
          ProfileIdentifierFactory(),
        ).duplicate(instance: instance.profile, overrides: null);

    final status =
        overrides?.status ??
        Builder(
          TelemetryConsentStatusFactory(),
        ).duplicate(instance: instance.status, overrides: null);

    final updatedAt =
        overrides?.updatedAt ??
        Builder(
          DateTimeFactory(),
        ).duplicate(instance: instance.updatedAt, overrides: null);

    return TelemetryConsent(
      identifier: identifier,
      profile: profile,
      status: status,
      updatedAt: updatedAt,
    );
  }
}

typedef UsageMetricsOverrides = ({
  UsageMetricsIdentifier? identifier,
  MetricsWindow? window,
  List<UsageEvent>? usageEvents,
  bool? optIn,
});

class UsageMetricsFactory extends Factory<UsageMetrics, UsageMetricsOverrides> {
  @override
  UsageMetrics create({UsageMetricsOverrides? overrides, required int seed}) {
    final identifier =
        overrides?.identifier ??
        Builder(UsageMetricsIdentifierFactory()).buildWith(seed: seed);

    final window =
        overrides?.window ??
        Builder(MetricsWindowFactory()).buildWith(seed: seed);

    final optIn = overrides?.optIn ?? (seed % 2 == 0);

    final usageEvents =
        overrides?.usageEvents ??
        (optIn ? _createEventsWithinWindow(window, seed) : <UsageEvent>[]);

    return UsageMetrics(
      identifier: identifier,
      window: window,
      usageEvents: usageEvents,
      optIn: optIn,
    );
  }

  List<UsageEvent> _createEventsWithinWindow(MetricsWindow window, int seed) {
    final count = (seed % 5) + 1;
    final events = <UsageEvent>[];
    final windowDuration = window.end.difference(window.start);

    for (var i = 0; i < count; i++) {
      final fraction = (i + 1) / (count + 1);
      final occurredAt = window.start.add(
        Duration(
          microseconds: (windowDuration.inMicroseconds * fraction).round(),
        ),
      );

      final event = Builder(UsageEventFactory()).buildWith(
        seed: seed + i,
        overrides: (type: null, payload: null, occurredAt: occurredAt),
      );

      events.add(event);
    }

    return events;
  }

  @override
  UsageMetrics duplicate(
    UsageMetrics instance,
    UsageMetricsOverrides? overrides,
  ) {
    final identifier =
        overrides?.identifier ??
        Builder(
          UsageMetricsIdentifierFactory(),
        ).duplicate(instance: instance.identifier, overrides: null);

    final window =
        overrides?.window ??
        Builder(
          MetricsWindowFactory(),
        ).duplicate(instance: instance.window, overrides: null);

    final optIn = overrides?.optIn ?? instance.optIn;

    final usageEvents =
        overrides?.usageEvents ??
        instance.usageEvents
            .map(
              (event) => Builder(
                UsageEventFactory(),
              ).duplicate(instance: event, overrides: null),
            )
            .toList();

    return UsageMetrics(
      identifier: identifier,
      window: window,
      usageEvents: usageEvents,
      optIn: optIn,
    );
  }
}

class _UsageMetricsRepository implements UsageMetricsRepository {
  UsageMetrics _current;
  final void Function(UsageMetrics)? _onPersist;

  _UsageMetricsRepository({
    required UsageMetrics current,
    void Function(UsageMetrics)? onPersist,
  }) : _current = current,
       _onPersist = onPersist;

  @override
  Future<UsageMetrics> current() {
    return Future.value(_current);
  }

  @override
  Future<void> persist(UsageMetrics metrics) {
    _current = metrics;

    _onPersist?.call(metrics);

    return Future.value();
  }
}

typedef UsageMetricsRepositoryOverrides = ({
  UsageMetrics? current,
  void Function(UsageMetrics)? onPersist,
});

class UsageMetricsRepositoryFactory
    extends Factory<UsageMetricsRepository, UsageMetricsRepositoryOverrides> {
  @override
  UsageMetricsRepository create({
    UsageMetricsRepositoryOverrides? overrides,
    required int seed,
  }) {
    final current =
        overrides?.current ??
        Builder(UsageMetricsFactory()).buildWith(seed: seed);

    return _UsageMetricsRepository(
      current: current,
      onPersist: overrides?.onPersist,
    );
  }

  @override
  UsageMetricsRepository duplicate(
    UsageMetricsRepository instance,
    UsageMetricsRepositoryOverrides? overrides,
  ) {
    throw UnimplementedError();
  }
}

class _TelemetryConsentRepository implements TelemetryConsentRepository {
  final Map<TelemetryConsentIdentifier, TelemetryConsent> _instances;
  final Map<ProfileIdentifier, TelemetryConsentIdentifier> _profileIndex;
  final void Function(TelemetryConsent)? _onPersist;

  _TelemetryConsentRepository({
    required List<TelemetryConsent> instances,
    void Function(TelemetryConsent)? onPersist,
  }) : _instances = {
         for (final instance in instances) instance.identifier: instance,
       },
       _profileIndex = {
         for (final instance in instances)
           instance.profile: instance.identifier,
       },
       _onPersist = onPersist;

  @override
  Future<TelemetryConsent> find(TelemetryConsentIdentifier identifier) {
    final instance = _instances[identifier];

    if (instance == null) {
      throw StateError(
        'TelemetryConsent with identifier ${identifier.value} not found.',
      );
    }

    return Future.value(instance);
  }

  @override
  Future<TelemetryConsent?> findByProfile(ProfileIdentifier profile) {
    final identifier = _profileIndex[profile];

    if (identifier == null) {
      return Future.value(null);
    }

    return Future.value(_instances[identifier]);
  }

  @override
  Future<void> persist(TelemetryConsent consent) {
    _instances[consent.identifier] = consent;
    _profileIndex[consent.profile] = consent.identifier;

    _onPersist?.call(consent);

    return Future.value();
  }
}

typedef TelemetryConsentRepositoryOverrides = ({
  List<TelemetryConsent>? instances,
  void Function(TelemetryConsent)? onPersist,
});

class TelemetryConsentRepositoryFactory
    extends
        Factory<
          TelemetryConsentRepository,
          TelemetryConsentRepositoryOverrides
        > {
  @override
  TelemetryConsentRepository create({
    TelemetryConsentRepositoryOverrides? overrides,
    required int seed,
  }) {
    final instances =
        overrides?.instances ??
        Builder(
          TelemetryConsentFactory(),
        ).buildListWith(count: (seed % 10) + 1, seed: seed);

    return _TelemetryConsentRepository(
      instances: instances,
      onPersist: overrides?.onPersist,
    );
  }

  @override
  TelemetryConsentRepository duplicate(
    TelemetryConsentRepository instance,
    TelemetryConsentRepositoryOverrides? overrides,
  ) {
    throw UnimplementedError();
  }
}

typedef TelemetryConsentSubscriberOverrides = ({
  UsageMetricsRepository? metricsRepository,
  TelemetryConsentRepository? consentRepository,
  Transaction? transaction,
});

class TelemetryConsentSubscriberFactory
    extends
        Factory<
          TelemetryConsentSubscriber,
          TelemetryConsentSubscriberOverrides
        > {
  @override
  TelemetryConsentSubscriber create({
    TelemetryConsentSubscriberOverrides? overrides,
    required int seed,
  }) {
    final metricsRepository =
        overrides?.metricsRepository ??
        Builder(UsageMetricsRepositoryFactory()).buildWith(seed: seed);

    final consentRepository =
        overrides?.consentRepository ??
        Builder(TelemetryConsentRepositoryFactory()).buildWith(seed: seed);

    final transaction =
        overrides?.transaction ??
        Builder(TransactionFactory()).buildWith(seed: seed);

    return TelemetryConsentSubscriber(
      metricsRepository: metricsRepository,
      consentRepository: consentRepository,
      transaction: transaction,
    );
  }

  @override
  TelemetryConsentSubscriber duplicate(
    TelemetryConsentSubscriber instance,
    TelemetryConsentSubscriberOverrides? overrides,
  ) {
    throw UnimplementedError();
  }
}
