import 'package:another_me/domains/common/range.dart';
import 'package:another_me/domains/common/variant.dart';
import 'package:another_me/domains/profile/profile.dart';
import 'package:another_me/domains/telemetry/usage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulid/ulid.dart';

import '../../../supports/factories/common.dart';
import '../../../supports/factories/telemetry/usage.dart';
import '../common/identifier.dart';
import '../common/value_object.dart';

void main() {
  group('Package domains/telemetry/usage', () {
    ulidBasedIdentifierTest<UsageMetricsIdentifier, Ulid>(
      constructor: (Ulid value) => UsageMetricsIdentifier(value: value),
      generate: UsageMetricsIdentifier.generate,
      fromString: UsageMetricsIdentifier.fromString,
      fromBinary: UsageMetricsIdentifier.fromBinary,
    );

    ulidBasedIdentifierTest<TelemetryConsentIdentifier, Ulid>(
      constructor: (Ulid value) => TelemetryConsentIdentifier(value: value),
      generate: TelemetryConsentIdentifier.generate,
      fromString: TelemetryConsentIdentifier.fromString,
      fromBinary: TelemetryConsentIdentifier.fromBinary,
    );

    group('EventPayload', () {
      group('instantiate', () {
        group('successfully with', () {
          test('valid data.', () {
            final payload = EventPayload(data: {'key': 'value', 'count': 42});

            expect(payload, isA<EventPayload>());
            expect(payload.data, equals({'key': 'value', 'count': 42}));
          });

          test('empty data.', () {
            final payload = EventPayload(data: {});

            expect(payload, isA<EventPayload>());
            expect(payload.data, isEmpty);
          });
        });
      });

      group('equals', () {
        test('returns true with same data.', () {
          final payload1 = EventPayload(data: {'key': 'value'});
          final payload2 = EventPayload(data: {'key': 'value'});

          expect(payload1 == payload2, isTrue);
        });

        test('returns false with different data.', () {
          final payload1 = EventPayload(data: {'key': 'value1'});
          final payload2 = EventPayload(data: {'key': 'value2'});

          expect(payload1 == payload2, isFalse);
        });
      });
    });

    group('UsageEventType', () {
      test('declares all defined enumerators.', () {
        expect(UsageEventType.pomodoroSessionStarted, isA<UsageEventType>());
        expect(UsageEventType.pomodoroSessionCompleted, isA<UsageEventType>());
        expect(UsageEventType.pomodoroSessionPaused, isA<UsageEventType>());
        expect(UsageEventType.pomodoroPhaseChanged, isA<UsageEventType>());
        expect(UsageEventType.characterSelected, isA<UsageEventType>());
        expect(UsageEventType.sceneSelected, isA<UsageEventType>());
        expect(UsageEventType.wardrobeSwitched, isA<UsageEventType>());
        expect(UsageEventType.mediaPlayed, isA<UsageEventType>());
        expect(UsageEventType.mediaPaused, isA<UsageEventType>());
        expect(UsageEventType.playlistCreated, isA<UsageEventType>());
      });
    });

    valueObjectTest(
      constructor:
          (
            ({UsageEventType type, EventPayload payload, DateTime occurredAt})
            props,
          ) => UsageEvent(
            type: props.type,
            payload: props.payload,
            occurredAt: props.occurredAt,
          ),
      generator: () {
        final now = DateTime.now();
        return (
          type: UsageEventType.characterSelected,
          payload: EventPayload(data: {'key': 'value'}),
          occurredAt: now,
        );
      },
      variations:
          (
            ({UsageEventType type, EventPayload payload, DateTime occurredAt})
            props,
          ) => [
            (
              type: UsageEventType.sceneSelected,
              payload: props.payload,
              occurredAt: props.occurredAt,
            ),
            (
              type: props.type,
              payload: EventPayload(data: {'different': 'data'}),
              occurredAt: props.occurredAt,
            ),
            (
              type: props.type,
              payload: props.payload,
              occurredAt: props.occurredAt.add(const Duration(seconds: 1)),
            ),
          ],
      invalids:
          (
            ({UsageEventType type, EventPayload payload, DateTime occurredAt})
            props,
          ) => [],
    );

    group('TelemetryConsentStatus', () {
      test('declares all defined enumerators.', () {
        expect(TelemetryConsentStatus.optedIn, isA<TelemetryConsentStatus>());
        expect(TelemetryConsentStatus.optedOut, isA<TelemetryConsentStatus>());
      });

      group('toggle', () {
        test('returns optedOut when current is optedIn.', () {
          final status = TelemetryConsentStatus.optedIn;
          final toggled = status.toggle();

          expect(toggled, equals(TelemetryConsentStatus.optedOut));
        });

        test('returns optedIn when current is optedOut.', () {
          final status = TelemetryConsentStatus.optedOut;
          final toggled = status.toggle();

          expect(toggled, equals(TelemetryConsentStatus.optedIn));
        });
      });

      group('isOptedIn', () {
        test('returns true when optedIn.', () {
          final status = TelemetryConsentStatus.optedIn;

          expect(status.isOptedIn(), isTrue);
        });

        test('returns false when optedOut.', () {
          final status = TelemetryConsentStatus.optedOut;

          expect(status.isOptedIn(), isFalse);
        });
      });
    });

    valueObjectTest(
      constructor: (({Range<DateTime> range}) props) =>
          MetricsWindow(range: props.range),
      generator: () {
        final now = DateTime.now();
        return (
          range: Range<DateTime>(
            start: now.subtract(const Duration(days: 5)),
            end: now,
          ),
        );
      },
      variations: (({Range<DateTime> range}) props) {
        final now = DateTime.now();
        return [
          (
            range: Range<DateTime>(
              start: now.subtract(const Duration(days: 3)),
              end: now,
            ),
          ),
          (
            range: Range<DateTime>(
              start: now.subtract(const Duration(days: 7)),
              end: now.subtract(const Duration(days: 1)),
            ),
          ),
        ];
      },
      invalids: (({Range<DateTime> range}) props) => [],
    );

    group('TelemetryConsent', () {
      group('instantiate', () {
        group('successfully with', () {
          test('valid parameters.', () {
            final consent = TelemetryConsent(
              identifier: TelemetryConsentIdentifier.generate(),
              profile: ProfileIdentifier.generate(),
              status: TelemetryConsentStatus.optedIn,
              updatedAt: DateTime.now(),
            );

            expect(consent, isA<TelemetryConsent>());
            expect(consent.status, equals(TelemetryConsentStatus.optedIn));
          });
        });

        group('unsuccessfully with', () {
          test('future updatedAt.', () {
            expect(
              () => TelemetryConsent(
                identifier: TelemetryConsentIdentifier.generate(),
                profile: ProfileIdentifier.generate(),
                status: TelemetryConsentStatus.optedIn,
                updatedAt: DateTime.now().add(const Duration(days: 1)),
              ),
              throwsA(isA<InvariantViolationError>()),
            );
          });
        });
      });

      group('changeStatus', () {
        test('changes status and publishes TelemetryConsentChanged event.', () {
          final consent = Builder(TelemetryConsentFactory()).buildWith(
            seed: 1,
            overrides: (
              identifier: null,
              profile: null,
              status: TelemetryConsentStatus.optedOut,
              updatedAt: null,
            ),
          );

          final previousStatus = consent.status;
          consent.changeStatus(TelemetryConsentStatus.optedIn);

          expect(consent.status, equals(TelemetryConsentStatus.optedIn));
          expect(consent.status, isNot(equals(previousStatus)));

          final events = consent.events();
          expect(events.length, equals(1));
          expect(events.first, isA<TelemetryConsentChanged>());

          final event = events.first as TelemetryConsentChanged;
          expect(event.consent, equals(consent.identifier));
          expect(event.profile, equals(consent.profile));
          expect(event.status, equals(TelemetryConsentStatus.optedIn));
        });

        test('does not publish event when status is unchanged.', () {
          final consent = Builder(TelemetryConsentFactory()).buildWith(
            seed: 1,
            overrides: (
              identifier: null,
              profile: null,
              status: TelemetryConsentStatus.optedIn,
              updatedAt: null,
            ),
          );

          consent.changeStatus(TelemetryConsentStatus.optedIn);

          final events = consent.events();
          expect(events, isEmpty);
        });
      });
    });

    group('UsageMetrics', () {
      group('instantiate', () {
        group('successfully with', () {
          test('optIn true and events within window.', () {
            final now = DateTime.now();
            final window = MetricsWindow(
              range: Range<DateTime>(
                start: now.subtract(const Duration(days: 5)),
                end: now,
              ),
            );

            final events = [
              UsageEvent(
                type: UsageEventType.characterSelected,
                payload: EventPayload(data: {}),
                occurredAt: now.subtract(const Duration(days: 3)),
              ),
              UsageEvent(
                type: UsageEventType.sceneSelected,
                payload: EventPayload(data: {}),
                occurredAt: now.subtract(const Duration(days: 1)),
              ),
            ];

            final metrics = UsageMetrics(
              identifier: UsageMetricsIdentifier.generate(),
              window: window,
              usageEvents: events,
              optIn: true,
            );

            expect(metrics, isA<UsageMetrics>());
            expect(metrics.optIn, isTrue);
            expect(metrics.usageEvents.length, equals(2));
          });

          test('optIn false with empty events.', () {
            final now = DateTime.now();
            final window = MetricsWindow(
              range: Range<DateTime>(
                start: now.subtract(const Duration(days: 5)),
                end: now,
              ),
            );

            final metrics = UsageMetrics(
              identifier: UsageMetricsIdentifier.generate(),
              window: window,
              usageEvents: [],
              optIn: false,
            );

            expect(metrics.optIn, isFalse);
            expect(metrics.usageEvents, isEmpty);
          });
        });

        group('unsuccessfully with', () {
          test('optIn false but has events.', () {
            final now = DateTime.now();
            final window = MetricsWindow(
              range: Range<DateTime>(
                start: now.subtract(const Duration(days: 5)),
                end: now,
              ),
            );

            final events = [
              UsageEvent(
                type: UsageEventType.characterSelected,
                payload: EventPayload(data: {}),
                occurredAt: now.subtract(const Duration(days: 3)),
              ),
            ];

            expect(
              () => UsageMetrics(
                identifier: UsageMetricsIdentifier.generate(),
                window: window,
                usageEvents: events,
                optIn: false,
              ),
              throwsA(isA<InvariantViolationError>()),
            );
          });

          test('event older than 30 days.', () {
            final now = DateTime.now();
            final window = MetricsWindow(
              range: Range<DateTime>(
                start: now.subtract(const Duration(days: 35)),
                end: now.subtract(const Duration(days: 31)),
              ),
            );

            final events = [
              UsageEvent(
                type: UsageEventType.characterSelected,
                payload: EventPayload(data: {}),
                occurredAt: now.subtract(const Duration(days: 32)),
              ),
            ];

            expect(
              () => UsageMetrics(
                identifier: UsageMetricsIdentifier.generate(),
                window: window,
                usageEvents: events,
                optIn: true,
              ),
              throwsA(isA<InvariantViolationError>()),
            );
          });

          test('event outside window.', () {
            final now = DateTime.now();
            final window = MetricsWindow(
              range: Range<DateTime>(
                start: now.subtract(const Duration(days: 5)),
                end: now,
              ),
            );

            final events = [
              UsageEvent(
                type: UsageEventType.characterSelected,
                payload: EventPayload(data: {}),
                occurredAt: now.subtract(const Duration(days: 10)),
              ),
            ];

            expect(
              () => UsageMetrics(
                identifier: UsageMetricsIdentifier.generate(),
                window: window,
                usageEvents: events,
                optIn: true,
              ),
              throwsA(isA<InvariantViolationError>()),
            );
          });

          test('events not in ascending order.', () {
            final now = DateTime.now();
            final window = MetricsWindow(
              range: Range<DateTime>(
                start: now.subtract(const Duration(days: 5)),
                end: now,
              ),
            );

            final events = [
              UsageEvent(
                type: UsageEventType.characterSelected,
                payload: EventPayload(data: {}),
                occurredAt: now.subtract(const Duration(days: 1)),
              ),
              UsageEvent(
                type: UsageEventType.sceneSelected,
                payload: EventPayload(data: {}),
                occurredAt: now.subtract(const Duration(days: 3)),
              ),
            ];

            expect(
              () => UsageMetrics(
                identifier: UsageMetricsIdentifier.generate(),
                window: window,
                usageEvents: events,
                optIn: true,
              ),
              throwsA(isA<InvariantViolationError>()),
            );
          });

          test('events with duplicate timestamps.', () {
            final now = DateTime.now();
            final window = MetricsWindow(
              range: Range<DateTime>(
                start: now.subtract(const Duration(days: 5)),
                end: now,
              ),
            );

            final timestamp = now.subtract(const Duration(days: 2));
            final events = [
              UsageEvent(
                type: UsageEventType.characterSelected,
                payload: EventPayload(data: {}),
                occurredAt: timestamp,
              ),
              UsageEvent(
                type: UsageEventType.sceneSelected,
                payload: EventPayload(data: {}),
                occurredAt: timestamp,
              ),
            ];

            expect(
              () => UsageMetrics(
                identifier: UsageMetricsIdentifier.generate(),
                window: window,
                usageEvents: events,
                optIn: true,
              ),
              throwsA(isA<InvariantViolationError>()),
            );
          });
        });
      });

      group('recordEvent', () {
        test(
          'adds event to usageEvents and publishes UsageEventRecorded event.',
          () {
            final now = DateTime.now();
            final window = MetricsWindow(
              range: Range<DateTime>(
                start: now.subtract(const Duration(days: 5)),
                end: now.add(const Duration(hours: 1)),
              ),
            );

            final metrics = Builder(UsageMetricsFactory()).buildWith(
              seed: 2,
              overrides: (
                identifier: null,
                window: window,
                usageEvents: null,
                optIn: true,
              ),
            );

            final initialCount = metrics.usageEvents.length;
            final newEvent = UsageEvent(
              type: UsageEventType.characterSelected,
              payload: EventPayload(data: {'character': 'test'}),
              occurredAt: now,
            );

            metrics.recordEvent(newEvent);

            expect(metrics.usageEvents.length, equals(initialCount + 1));
            expect(metrics.usageEvents.last, equals(newEvent));

            final events = metrics.events();
            expect(events.isNotEmpty, isTrue);
            expect(events.any((event) => event is UsageEventRecorded), isTrue);
          },
        );
      });

      group('changeOptIn', () {
        test('changes optIn status and publishes UsageOptInChanged event.', () {
          final metrics = Builder(UsageMetricsFactory()).buildWith(
            seed: 1,
            overrides: (
              identifier: null,
              window: null,
              usageEvents: null,
              optIn: false,
            ),
          );

          expect(metrics.optIn, isFalse);

          metrics.changeOptIn(TelemetryConsentStatus.optedIn);

          expect(metrics.optIn, isTrue);

          final events = metrics.events();
          expect(events.isNotEmpty, isTrue);
          expect(events.any((event) => event is UsageOptInChanged), isTrue);
        });

        test('clears events when opting out.', () {
          final metrics = Builder(UsageMetricsFactory()).buildWith(
            seed: 2,
            overrides: (
              identifier: null,
              window: null,
              usageEvents: null,
              optIn: true,
            ),
          );

          expect(metrics.usageEvents.isNotEmpty, isTrue);

          metrics.changeOptIn(TelemetryConsentStatus.optedOut);

          expect(metrics.optIn, isFalse);
          expect(metrics.usageEvents, isEmpty);
        });
      });
    });
  });
}
