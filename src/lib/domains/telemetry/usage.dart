import 'dart:convert';
import 'dart:typed_data';

import 'package:another_me/domains/common/event.dart';
import 'package:another_me/domains/common/identifier.dart';
import 'package:another_me/domains/common/range.dart';
import 'package:another_me/domains/common/transaction.dart';
import 'package:another_me/domains/common/value_object.dart';
import 'package:another_me/domains/common/variant.dart';
import 'package:another_me/domains/profile/profile.dart';
import 'package:ulid/ulid.dart';

class UsageMetricsIdentifier extends ULIDBasedIdentifier {
  UsageMetricsIdentifier({required Ulid value}) : super(value);

  factory UsageMetricsIdentifier.generate() =>
      UsageMetricsIdentifier(value: Ulid());

  factory UsageMetricsIdentifier.fromString(String value) =>
      UsageMetricsIdentifier(value: Ulid.parse(value));

  factory UsageMetricsIdentifier.fromBinary(Uint8List bytes) =>
      UsageMetricsIdentifier(value: Ulid.fromBytes(bytes));
}

class EventPayload implements ValueObject {
  final Map<String, Object> _data;

  static const int maxListLength = 1000;

  static const int maxPayloadSize = 5 * 1024; // 5 KB

  EventPayload({required Map<String, Object> data}) : _data = data {
    final encoded = JsonEncoder().convert(_data);

    if (maxPayloadSize < encoded.length) {
      throw ArgumentError(
        'EventPayload exceeds maximum size of $maxPayloadSize bytes',
      );
    }

    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;

      if (value is String || value is int || value is double || value is bool) {
        continue;
      }

      if (value is List) {
        throw InvariantViolationError(
          'EventPayload values must be String, int, double, bool, or List.',
        );
      }

      if ((value as List).length > maxListLength) {
        throw InvariantViolationError(
          'EventPayload list values cannot exceed $maxListLength items.',
        );
      }

      for (var i = 0; i < (value).length; i++) {
        final element = value[i];
        if (element is! String &&
            element is! int &&
            element is! double &&
            element is! bool) {
          throw InvariantViolationError(
            'List value for key "$key" at index $i must be a primitive type '
            '(String, int, double, bool), but got ${element.runtimeType}',
          );
        }
      }
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! EventPayload) {
      return false;
    }

    if (_data.length != other._data.length) {
      return false;
    }

    for (final key in _data.keys) {
      if (!other._data.containsKey(key) || _data[key] != other._data[key]) {
        return false;
      }
    }

    return true;
  }

  @override
  int get hashCode => Object.hash(_data, runtimeType);

  Map<String, Object> get data => Map.unmodifiable(_data);

  factory EventPayload.empty() {
    return EventPayload(data: {});
  }
}

enum UsageEventType {
  pomodoroSessionStarted,
  pomodoroSessionCompleted,
  pomodoroSessionPaused,
  pomodoroPhaseChanged,
  characterSelected,
  sceneSelected,
  wardrobeSwitched,
  mediaPlayed,
  mediaPaused,
  playlistCreated,
  focusModeActivated,
  sleepModeActivated,
}

class UsageEvent implements ValueObject {
  final UsageEventType type;
  final EventPayload payload;
  final DateTime occurredAt;

  UsageEvent({
    required this.type,
    required this.payload,
    required this.occurredAt,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! UsageEvent) {
      return false;
    }

    if (type != other.type) {
      return false;
    }

    if (payload != other.payload) {
      return false;
    }

    if (occurredAt != other.occurredAt) {
      return false;
    }

    return true;
  }

  @override
  int get hashCode => Object.hash(type, payload, occurredAt);
}

class TelemetryConsentIdentifier extends ULIDBasedIdentifier {
  TelemetryConsentIdentifier({required Ulid value}) : super(value);

  factory TelemetryConsentIdentifier.generate() =>
      TelemetryConsentIdentifier(value: Ulid());

  factory TelemetryConsentIdentifier.fromString(String value) =>
      TelemetryConsentIdentifier(value: Ulid.parse(value));

  factory TelemetryConsentIdentifier.fromBinary(Uint8List bytes) =>
      TelemetryConsentIdentifier(value: Ulid.fromBytes(bytes));
}

enum TelemetryConsentStatus {
  optedIn,
  optedOut;

  TelemetryConsentStatus toggle() {
    return this == optedIn ? optedOut : optedIn;
  }

  bool isOptedIn() {
    return this == optedIn;
  }
}

class MetricsWindow implements ValueObject {
  final Range<DateTime> _range;

  MetricsWindow({required Range<DateTime> range}) : _range = range {
    if (range.start == null || range.end == null) {
      throw ArgumentError(
        'MetricsWindow requires both start and end to be non-null',
      );
    }

    if (range.end!.difference(range.start!).inDays > 7) {
      throw ArgumentError('MetricsWindow duration cannot exceed 7 days');
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! MetricsWindow) {
      return false;
    }

    if (_range != other._range) {
      return false;
    }

    return true;
  }

  @override
  int get hashCode => Object.hash(_range, runtimeType);

  DateTime get start => _range.start!;

  DateTime get end => _range.end!;

  bool includes(DateTime needle) {
    return _range.includes(needle);
  }

  MetricsWindow next() {
    final duration = end.difference(start);
    final nextStart = end;
    final nextEnd = nextStart.add(duration);

    return MetricsWindow(
      range: Range(start: nextStart, end: nextEnd),
    );
  }
}

abstract class TelemetryEvent extends BaseEvent {
  TelemetryEvent({required DateTime occurredAt}) : super(occurredAt);
}

class TelemetryConsentChanged extends TelemetryEvent {
  final TelemetryConsentIdentifier consent;
  final TelemetryConsentStatus status;
  final ProfileIdentifier profile;

  TelemetryConsentChanged({
    required this.consent,
    required this.status,
    required this.profile,
    required super.occurredAt,
  });
}

class TelemetryWindowRotated extends TelemetryEvent {
  final UsageMetricsIdentifier metrics;
  final MetricsWindow previous;
  final MetricsWindow current;

  TelemetryWindowRotated({
    required this.metrics,
    required this.previous,
    required this.current,
    required super.occurredAt,
  });
}

class TelemetryEventsPurged extends TelemetryEvent {
  final UsageMetricsIdentifier metrics;
  final int purgedCount;
  final DateTime olderThan;

  TelemetryEventsPurged({
    required this.metrics,
    required this.purgedCount,
    required this.olderThan,
    required super.occurredAt,
  });
}

class UsageEventRecorded extends TelemetryEvent {
  final UsageMetricsIdentifier metrics;
  final UsageEventType type;

  UsageEventRecorded({
    required this.metrics,
    required this.type,
    required super.occurredAt,
  });
}

class UsageOptInChanged extends TelemetryEvent {
  final UsageMetricsIdentifier metrics;
  final TelemetryConsentStatus status;

  UsageOptInChanged({
    required this.metrics,
    required this.status,
    required super.occurredAt,
  });
}

class TelemetryConsent with Publishable<TelemetryEvent> {
  final TelemetryConsentIdentifier identifier;
  final ProfileIdentifier profile;
  TelemetryConsentStatus _status;
  DateTime _updatedAt;

  TelemetryConsent({
    required this.identifier,
    required this.profile,
    required TelemetryConsentStatus status,
    required DateTime updatedAt,
  }) : _status = status,
       _updatedAt = updatedAt {
    if (updatedAt.isAfter(DateTime.now())) {
      throw InvariantViolationError(
        'updatedAt must be in the past or present.',
      );
    }
  }

  TelemetryConsentStatus get status => _status;

  DateTime get updatedAt => _updatedAt;

  void changeStatus(TelemetryConsentStatus status) {
    if (_status != status) {
      final now = DateTime.now();

      _status = status;
      _updatedAt = now;

      publish(
        TelemetryConsentChanged(
          consent: identifier,
          profile: profile,
          status: status,
          occurredAt: now,
        ),
      );
    }
  }
}

class UsageMetrics with Publishable<TelemetryEvent> {
  final UsageMetricsIdentifier identifier;
  MetricsWindow _window;
  final List<UsageEvent> _usageEvents;
  bool _optIn;

  UsageMetrics({
    required this.identifier,
    required MetricsWindow window,
    required List<UsageEvent> usageEvents,
    required bool optIn,
  }) : _window = window,
       _usageEvents = usageEvents,
       _optIn = optIn {
    if (!_optIn && usageEvents.isNotEmpty) {
      throw InvariantViolationError('Cannot have events when optIn is false.');
    }

    if (_optIn && usageEvents.isNotEmpty) {
      final now = DateTime.now();
      final cutoff = now.subtract(const Duration(days: 30));
      DateTime? previous;

      for (final event in usageEvents) {
        final occurredAt = event.occurredAt;

        if (occurredAt.isBefore(cutoff)) {
          throw InvariantViolationError(
            'Event occurredAt is older than retention period (30 days).',
          );
        }

        if (!window.includes(occurredAt)) {
          throw InvariantViolationError(
            'Event occurredAt is outside of the window.',
          );
        }

        if (previous != null && !occurredAt.isAfter(previous)) {
          throw InvariantViolationError(
            'Events are not in ascending order by occurredAt.',
          );
        }

        previous = occurredAt;
      }
    }
  }

  MetricsWindow get window => _window;

  List<UsageEvent> get usageEvents => List.unmodifiable(_usageEvents);

  bool get optIn => _optIn;

  void recordEvent(UsageEvent event) {
    if (!_optIn) {
      return;
    }

    final occurredAt = event.occurredAt;

    if (_usageEvents.isNotEmpty &&
        _usageEvents.last.occurredAt.isAfter(occurredAt)) {
      throw InvariantViolationError(
        'New event occurredAt must be after the last recorded event.',
      );
    }

    if (!window.includes(occurredAt)) {
      throw InvariantViolationError(
        'Event occurredAt is outside of the window.',
      );
    }

    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: 30));

    _usageEvents.removeWhere((event) => event.occurredAt.isBefore(cutoff));

    _usageEvents.add(event);

    publish(
      UsageEventRecorded(
        metrics: identifier,
        type: event.type,
        occurredAt: occurredAt,
      ),
    );
  }

  void changeOptIn(TelemetryConsentStatus next) {
    if (_optIn != next.isOptedIn()) {
      _optIn = next.isOptedIn();

      if (!next.isOptedIn()) {
        _usageEvents.clear();
      }

      publish(
        UsageOptInChanged(
          metrics: identifier,
          status: next,
          occurredAt: DateTime.now(),
        ),
      );
    }
  }

  List<UsageEvent> rotateWindow(MetricsWindow nextWindow) {
    final previousWindow = _window;
    _window = nextWindow;

    final excludedEvents = <UsageEvent>[];

    for (final event in _usageEvents) {
      if (!nextWindow.includes(event.occurredAt)) {
        excludedEvents.add(event);
      }
    }

    _usageEvents.removeWhere((event) => !nextWindow.includes(event.occurredAt));

    publish(
      TelemetryWindowRotated(
        metrics: identifier,
        previous: previousWindow,
        current: nextWindow,
        occurredAt: DateTime.now(),
      ),
    );

    return excludedEvents;
  }

  void purgeOldEvents(DateTime olderThan) {
    final initialCount = _usageEvents.length;

    _usageEvents.removeWhere((event) => event.occurredAt.isBefore(olderThan));

    final purgedCount = initialCount - _usageEvents.length;

    if (purgedCount > 0) {
      publish(
        TelemetryEventsPurged(
          metrics: identifier,
          purgedCount: purgedCount,
          olderThan: olderThan,
          occurredAt: DateTime.now(),
        ),
      );
    }
  }
}

abstract interface class UsageMetricsRepository {
  Future<UsageMetrics> current();
  Future<void> persist(UsageMetrics metrics);
}

abstract interface class TelemetryConsentRepository {
  Future<TelemetryConsent> find(TelemetryConsentIdentifier identifier);
  Future<TelemetryConsent?> findByProfile(ProfileIdentifier profile);
  Future<void> persist(TelemetryConsent consent);
}

class TelemetryConsentSubscriber implements EventSubscriber {
  final UsageMetricsRepository _metricsRepository;
  final TelemetryConsentRepository _consentRepository;
  final Transaction _transaction;

  TelemetryConsentSubscriber({
    required UsageMetricsRepository metricsRepository,
    required TelemetryConsentRepository consentRepository,
    required Transaction transaction,
  }) : _metricsRepository = metricsRepository,
       _consentRepository = consentRepository,
       _transaction = transaction;

  @override
  void subscribe(EventBroker broker) {
    broker.listen<TelemetryConsentChanged>(_onTelemetryConsentChanged(broker));
  }

  void Function(TelemetryConsentChanged event) _onTelemetryConsentChanged(
    EventBroker broker,
  ) {
    return (TelemetryConsentChanged event) {
      _transaction.execute(() async {
        final consent = await _consentRepository.find(event.consent);

        if (consent.status == event.status) {
          throw StateError(
            'TelemetryConsent status is already ${event.status}.',
          );
        }

        final metrics = await _metricsRepository.current();

        metrics.changeOptIn(event.status);

        await _metricsRepository.persist(metrics);

        broker.publishAll(metrics.events());
      });
    };
  }
}
