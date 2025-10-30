import 'package:another_me/domains/common/error.dart';
import 'package:another_me/domains/common/variant.dart';
import 'package:another_me/domains/notification/notification.dart';
import 'package:flutter/material.dart' hide Builder;
import 'package:flutter_test/flutter_test.dart';
import 'package:ulid/ulid.dart';

import '../../../supports/factories/common.dart';
import '../../../supports/factories/notification/notification.dart';
import '../../../supports/factories/profile/profile.dart';
import '../common/identifier.dart';
import '../common/value_object.dart';

void main() {
  group('Package domains/notification', () {
    ulidBasedIdentifierTest<NotificationRuleIdentifier, Ulid>(
      constructor: (Ulid value) => NotificationRuleIdentifier(value: value),
      generate: NotificationRuleIdentifier.generate,
      fromString: (String value) =>
          NotificationRuleIdentifier(value: Ulid.parse(value)),
      fromBinary: (value) =>
          NotificationRuleIdentifier(value: Ulid.fromBytes(value)),
    );

    group('TemplatePlaceholder', () {
      test('declares all defined enumerators.', () {
        expect(
          TemplatePlaceholder.remainingMinutes,
          isA<TemplatePlaceholder>(),
        );
        expect(
          TemplatePlaceholder.remainingSeconds,
          isA<TemplatePlaceholder>(),
        );
        expect(TemplatePlaceholder.phaseName, isA<TemplatePlaceholder>());
        expect(TemplatePlaceholder.trackTitle, isA<TemplatePlaceholder>());
        expect(TemplatePlaceholder.artistName, isA<TemplatePlaceholder>());
      });
    });

    valueObjectTest<
      NotificationTemplate,
      ({String template, Set<TemplatePlaceholder> requiredPlaceholders}),
      ({String template, Set<TemplatePlaceholder> requiredPlaceholders})
    >(
      constructor: (props) => NotificationTemplate(
        template: props.template,
        requiredPlaceholders: props.requiredPlaceholders,
      ),
      generator: () => (
        template: '{{phaseName}} started',
        requiredPlaceholders: {TemplatePlaceholder.phaseName},
      ),
      variations: (props) => [
        (
          template: '{{trackTitle}} by {{artistName}}',
          requiredPlaceholders: {
            TemplatePlaceholder.trackTitle,
            TemplatePlaceholder.artistName,
          },
        ),
        (
          template: '{{remainingMinutes}} minutes left',
          requiredPlaceholders: {TemplatePlaceholder.remainingMinutes},
        ),
      ],
      invalids: (props) => [
        (template: '', requiredPlaceholders: props.requiredPlaceholders),
        (template: 'A' * 201, requiredPlaceholders: props.requiredPlaceholders),
        (
          template: 'Missing placeholder',
          requiredPlaceholders: {TemplatePlaceholder.phaseName},
        ),
      ],
      additionalTests: () {
        group('render', () {
          test('renders template with context values.', () {
            final template = NotificationTemplate(
              template: '{{phaseName}} - {{remainingMinutes}} min left',
              requiredPlaceholders: {
                TemplatePlaceholder.phaseName,
                TemplatePlaceholder.remainingMinutes,
              },
            );

            final context = NotificationContext(
              values: {'phaseName': 'Work', 'remainingMinutes': '25'},
            );

            final result = template.render(context);

            expect(result, equals('Work - 25 min left'));
          });
        });
      },
    );

    valueObjectTest<
      NotificationContext,
      ({Map<String, String> values}),
      ({Map<String, String> values})
    >(
      constructor: (props) => NotificationContext(values: props.values),
      generator: () =>
          (values: {'phaseName': 'Work', 'remainingMinutes': '25'}),
      variations: (props) => [
        (values: {'trackTitle': 'Song Name', 'artistName': 'Artist Name'}),
        (values: {}),
      ],
      invalids: (props) => [],
      additionalTests: () {
        group('forPomodoroPhase', () {
          test('creates context with pomodoro phase data.', () {
            final context = NotificationContext.forPomodoroPhase(
              remainingMinutes: 24,
              remainingSeconds: 59,
              phaseName: 'Focus',
            );

            expect(context.values['remainingMinutes'], equals('24'));
            expect(context.values['remainingSeconds'], equals('59'));
            expect(context.values['phaseName'], equals('Focus'));
          });
        });

        group('forTrackRegistered', () {
          test('creates context with track data.', () {
            final context = NotificationContext.forTrackRegistered(
              trackTitle: 'Beautiful Song',
              artistName: 'Great Artist',
            );

            expect(context.values['trackTitle'], equals('Beautiful Song'));
            expect(context.values['artistName'], equals('Great Artist'));
          });
        });

        group('getValue', () {
          test('returns value for existing placeholder.', () {
            final context = NotificationContext(values: {'phaseName': 'Work'});

            final value = context.getValue(TemplatePlaceholder.phaseName);

            expect(value, equals('Work'));
          });

          test('throws error for missing placeholder.', () {
            final context = NotificationContext.empty();

            expect(
              () => context.getValue(TemplatePlaceholder.phaseName),
              throwsA(isA<ArgumentError>()),
            );
          });
        });
      },
    );

    group('NotificationEventType', () {
      test('PomodoroPhaseStartedEvent has correct properties.', () {
        final event = PomodoroPhaseStartedEvent();

        expect(event.name, equals('PomodoroPhaseStarted'));
        expect(
          event.requiredPlaceholders,
          equals({
            TemplatePlaceholder.phaseName,
            TemplatePlaceholder.remainingMinutes,
            TemplatePlaceholder.remainingSeconds,
          }),
        );
      });

      test('TrackRegisteredEvent has correct properties.', () {
        final event = TrackRegisteredEvent();

        expect(event.name, equals('TrackRegistered'));
        expect(
          event.requiredPlaceholders,
          equals({
            TemplatePlaceholder.trackTitle,
            TemplatePlaceholder.artistName,
          }),
        );
      });
    });

    group('NotificationChannel', () {
      test('declares all defined enumerators.', () {
        expect(NotificationChannel.desktop, isA<NotificationChannel>());
        expect(NotificationChannel.menuBar, isA<NotificationChannel>());
        expect(NotificationChannel.sound, isA<NotificationChannel>());
      });
    });

    valueObjectTest<
      QuietHours,
      ({TimeOfDay startTime, TimeOfDay endTime}),
      ({TimeOfDay startTime, TimeOfDay endTime})
    >(
      constructor: (props) =>
          QuietHours(startTime: props.startTime, endTime: props.endTime),
      generator: () => (
        startTime: const TimeOfDay(hour: 22, minute: 0),
        endTime: const TimeOfDay(hour: 7, minute: 0),
      ),
      variations: (props) => [
        (
          startTime: const TimeOfDay(hour: 9, minute: 0),
          endTime: const TimeOfDay(hour: 17, minute: 0),
        ),
        (
          startTime: const TimeOfDay(hour: 0, minute: 0),
          endTime: const TimeOfDay(hour: 23, minute: 59),
        ),
      ],
      invalids: (props) => [
        (
          startTime: const TimeOfDay(hour: 10, minute: 0),
          endTime: const TimeOfDay(hour: 10, minute: 0),
        ),
      ],
      additionalTests: () {
        group('spansMidnight', () {
          test('is true when start time is after end time.', () {
            final quietHours = QuietHours(
              startTime: const TimeOfDay(hour: 22, minute: 0),
              endTime: const TimeOfDay(hour: 7, minute: 0),
            );

            expect(quietHours.spansMidnight, isTrue);
          });

          test('is false when start time is before end time.', () {
            final quietHours = QuietHours(
              startTime: const TimeOfDay(hour: 9, minute: 0),
              endTime: const TimeOfDay(hour: 17, minute: 0),
            );

            expect(quietHours.spansMidnight, isFalse);
          });
        });

        group('isQuietTime', () {
          test('returns true during quiet hours (non-spanning).', () {
            final quietHours = QuietHours(
              startTime: const TimeOfDay(hour: 9, minute: 0),
              endTime: const TimeOfDay(hour: 17, minute: 0),
            );

            final now = DateTime(2025, 1, 1, 12, 0);

            expect(quietHours.isQuietTime(now), isTrue);
          });

          test('returns false outside quiet hours (non-spanning).', () {
            final quietHours = QuietHours(
              startTime: const TimeOfDay(hour: 9, minute: 0),
              endTime: const TimeOfDay(hour: 17, minute: 0),
            );

            final now = DateTime(2025, 1, 1, 20, 0);

            expect(quietHours.isQuietTime(now), isFalse);
          });

          test('returns true during quiet hours (spanning midnight).', () {
            final quietHours = QuietHours(
              startTime: const TimeOfDay(hour: 22, minute: 0),
              endTime: const TimeOfDay(hour: 7, minute: 0),
            );

            final now1 = DateTime(2025, 1, 1, 23, 0);

            expect(quietHours.isQuietTime(now1), isTrue);

            final now2 = DateTime(2025, 1, 2, 6, 0);

            expect(quietHours.isQuietTime(now2), isTrue);
          });

          test('returns false outside quiet hours (spanning midnight).', () {
            final quietHours = QuietHours(
              startTime: const TimeOfDay(hour: 22, minute: 0),
              endTime: const TimeOfDay(hour: 7, minute: 0),
            );

            final now = DateTime(2025, 1, 1, 12, 0);

            expect(quietHours.isQuietTime(now), isFalse);
          });
        });
      },
    );

    group('NotificationChannelSetting', () {
      test('creates valid instance.', () {
        final template = NotificationTemplate(
          template:
              '{{phaseName}} started - {{remainingMinutes}}:{{remainingSeconds}}',
          requiredPlaceholders: {
            TemplatePlaceholder.phaseName,
            TemplatePlaceholder.remainingMinutes,
            TemplatePlaceholder.remainingSeconds,
          },
        );

        final setting = NotificationChannelSetting(
          eventType: PomodoroPhaseStartedEvent(),
          channels: {NotificationChannel.desktop},
          template: template,
        );

        expect(setting.eventType.name, equals('PomodoroPhaseStarted'));
        expect(setting.channels, contains(NotificationChannel.desktop));
        expect(setting.template, equals(template));
      });

      test('throws when channels is empty.', () {
        final template = NotificationTemplate(
          template: '{{phaseName}} started',
          requiredPlaceholders: {TemplatePlaceholder.phaseName},
        );

        expect(
          () => NotificationChannelSetting(
            eventType: PomodoroPhaseStartedEvent(),
            channels: {},
            template: template,
          ),
          throwsA(isA<InvariantViolationError>()),
        );
      });

      test('throws when template is incompatible with event type.', () {
        final template = NotificationTemplate(
          template: '{{trackTitle}} registered',
          requiredPlaceholders: {TemplatePlaceholder.trackTitle},
        );

        expect(
          () => NotificationChannelSetting(
            eventType: PomodoroPhaseStartedEvent(),
            channels: {NotificationChannel.desktop},
            template: template,
          ),
          throwsA(isA<InvariantViolationError>()),
        );
      });
    });

    group('NotificationHistory', () {
      test('creates empty history.', () {
        final history = NotificationHistory.empty();

        final shouldSuppress = history.shouldSuppress(
          eventType: PomodoroPhaseStartedEvent(),
          now: DateTime.now(),
          minimumInterval: const Duration(minutes: 5),
        );

        expect(shouldSuppress, isFalse);
      });

      test('records sent notification.', () {
        final history = NotificationHistory.empty();

        final now = DateTime(2025, 1, 1, 12, 0);

        final updated = history.recordSent(
          eventType: PomodoroPhaseStartedEvent(),
          sentAt: now,
        );

        final elapsed = updated.elapsedSince(
          eventType: PomodoroPhaseStartedEvent(),
          now: now.add(const Duration(minutes: 3)),
        );

        expect(elapsed, equals(const Duration(minutes: 3)));
      });

      test('shouldSuppress returns true when sent too recently.', () {
        final history = NotificationHistory.empty();

        final now = DateTime(2025, 1, 1, 12, 0);

        final updated = history.recordSent(
          eventType: PomodoroPhaseStartedEvent(),
          sentAt: now,
        );

        final shouldSuppress = updated.shouldSuppress(
          eventType: PomodoroPhaseStartedEvent(),
          now: now.add(const Duration(minutes: 3)),
          minimumInterval: const Duration(minutes: 5),
        );

        expect(shouldSuppress, isTrue);
      });

      test('shouldSuppress returns false when enough time has passed.', () {
        final history = NotificationHistory.empty();

        final now = DateTime(2025, 1, 1, 12, 0);

        final updated = history.recordSent(
          eventType: PomodoroPhaseStartedEvent(),
          sentAt: now,
        );

        final shouldSuppress = updated.shouldSuppress(
          eventType: PomodoroPhaseStartedEvent(),
          now: now.add(const Duration(minutes: 6)),
          minimumInterval: const Duration(minutes: 5),
        );

        expect(shouldSuppress, isFalse);
      });
    });

    group('NotificationRule', () {
      group('create', () {
        test('creates new notification rule.', () {
          final profile = Builder(ProfileIdentifierFactory()).build();

          final template = NotificationTemplate(
            template:
                '{{phaseName}} started - {{remainingMinutes}}:{{remainingSeconds}} remaining',
            requiredPlaceholders: {
              TemplatePlaceholder.phaseName,
              TemplatePlaceholder.remainingMinutes,
              TemplatePlaceholder.remainingSeconds,
            },
          );

          final setting = NotificationChannelSetting(
            eventType: PomodoroPhaseStartedEvent(),
            channels: {NotificationChannel.desktop},
            template: template,
          );

          final quietHours = QuietHours(
            startTime: const TimeOfDay(hour: 22, minute: 0),
            endTime: const TimeOfDay(hour: 7, minute: 0),
          );

          final rule = NotificationRule.create(
            profile: profile,
            channelSettings: {PomodoroPhaseStartedEvent(): setting},
            quietHours: quietHours,
          );

          expect(rule.profile, equals(profile));
          expect(rule.dndEnabled, isFalse);

          final events = rule.events();

          expect(events.length, equals(1));
          expect(events.first, isA<NotificationRuleCreated>());
        });
      });

      group('evaluateNotification', () {
        test('returns suppressed when DND is enabled.', () {
          final rule = Builder(NotificationRuleFactory()).build(
            overrides: (
              identifier: null,
              profile: null,
              channelSettings: null,
              quietHours: null,
              dndEnabled: true,
              history: null,
              minimumNotificationInterval: null,
            ),
          );

          final context = NotificationContext.forPomodoroPhase(
            remainingMinutes: 25,
            remainingSeconds: 0,
            phaseName: 'Work',
          );

          final result = rule.evaluateNotification(
            eventType: PomodoroPhaseStartedEvent(),
            context: context,
            now: DateTime.now(),
          );

          expect(result.sent, isFalse);
          expect(result.message, equals('DND is enabled'));

          final events = rule.events();

          expect(
            events.any((event) => event is NotificationSuppressed),
            isTrue,
          );
        });

        test('returns suppressed during quiet hours.', () {
          final quietHours = QuietHours(
            startTime: const TimeOfDay(hour: 22, minute: 0),
            endTime: const TimeOfDay(hour: 7, minute: 0),
          );

          final rule = Builder(NotificationRuleFactory()).build(
            overrides: (
              identifier: null,
              profile: null,
              channelSettings: null,
              quietHours: quietHours,
              dndEnabled: false,
              history: null,
              minimumNotificationInterval: null,
            ),
          );

          final context = NotificationContext.forPomodoroPhase(
            remainingMinutes: 25,
            remainingSeconds: 0,
            phaseName: 'Work',
          );

          final now = DateTime(2025, 1, 1, 23, 0);

          final result = rule.evaluateNotification(
            eventType: PomodoroPhaseStartedEvent(),
            context: context,
            now: now,
          );

          expect(result.sent, isFalse);
          expect(result.message, equals('Quiet hours active'));
        });

        test('returns suppressed when sent too recently.', () {
          final now = DateTime(2025, 1, 1, 12, 0);

          final history = NotificationHistory.empty().recordSent(
            eventType: PomodoroPhaseStartedEvent(),
            sentAt: now.subtract(const Duration(minutes: 3)),
          );

          final rule = Builder(NotificationRuleFactory()).build(
            overrides: (
              identifier: null,
              profile: null,
              channelSettings: null,
              quietHours: QuietHours(
                startTime: const TimeOfDay(hour: 22, minute: 0),
                endTime: const TimeOfDay(hour: 7, minute: 0),
              ),
              dndEnabled: false,
              history: history,
              minimumNotificationInterval: const Duration(minutes: 5),
            ),
          );

          final context = NotificationContext.forPomodoroPhase(
            remainingMinutes: 25,
            remainingSeconds: 0,
            phaseName: 'Work',
          );

          final result = rule.evaluateNotification(
            eventType: PomodoroPhaseStartedEvent(),
            context: context,
            now: now,
          );

          expect(result.sent, isFalse);
          expect(result.message, equals('Sent too recently'));
        });

        test('returns sent result when conditions are met.', () {
          final quietHours = QuietHours(
            startTime: const TimeOfDay(hour: 22, minute: 0),
            endTime: const TimeOfDay(hour: 7, minute: 0),
          );

          final template = NotificationTemplate(
            template:
                '{{phaseName}} - {{remainingMinutes}}:{{remainingSeconds}}',
            requiredPlaceholders: {
              TemplatePlaceholder.phaseName,
              TemplatePlaceholder.remainingMinutes,
              TemplatePlaceholder.remainingSeconds,
            },
          );

          final setting = NotificationChannelSetting(
            eventType: PomodoroPhaseStartedEvent(),
            channels: {NotificationChannel.desktop},
            template: template,
          );

          final rule = Builder(NotificationRuleFactory()).build(
            overrides: (
              identifier: null,
              profile: null,
              channelSettings: {'PomodoroPhaseStarted': setting},
              quietHours: quietHours,
              dndEnabled: false,
              history: NotificationHistory.empty(),
              minimumNotificationInterval: const Duration(minutes: 5),
            ),
          );

          final context = NotificationContext.forPomodoroPhase(
            remainingMinutes: 25,
            remainingSeconds: 0,
            phaseName: 'Work',
          );

          final now = DateTime(2025, 1, 1, 12, 0);

          final result = rule.evaluateNotification(
            eventType: PomodoroPhaseStartedEvent(),
            context: context,
            now: now,
          );

          expect(result.sent, isTrue);
          expect(result.message, isNotNull);

          final events = rule.events();

          expect(events.any((event) => event is NotificationRequested), isTrue);
        });
      });

      group('toggleDnd', () {
        test('toggles DND and publishes event.', () {
          final rule = Builder(NotificationRuleFactory()).build(
            overrides: (
              identifier: null,
              profile: null,
              channelSettings: null,
              quietHours: null,
              dndEnabled: false,
              history: null,
              minimumNotificationInterval: null,
            ),
          );

          rule.clear();

          rule.toggleDnd(true);

          expect(rule.dndEnabled, isTrue);

          final events = rule.events();

          expect(events.length, equals(1));
          expect(events.first, isA<NotificationRuleUpdated>());

          final updated = events.first as NotificationRuleUpdated;

          expect(updated.dndEnabled, isTrue);
        });
      });

      group('updateQuietHours', () {
        test('updates quiet hours and publishes event.', () {
          final rule = Builder(NotificationRuleFactory()).build();

          rule.clear();

          final newQuietHours = QuietHours(
            startTime: const TimeOfDay(hour: 23, minute: 0),
            endTime: const TimeOfDay(hour: 8, minute: 0),
          );

          rule.updateQuietHours(newQuietHours);

          expect(rule.quietHours, equals(newQuietHours));

          final events = rule.events();

          expect(events.length, equals(1));
          expect(events.first, isA<NotificationRuleUpdated>());
        });
      });
    });

    group('NotificationRuleRepository', () {
      test('find returns rule by profile identifier.', () async {
        final profile = Builder(ProfileIdentifierFactory()).build();

        final rule = Builder(NotificationRuleFactory()).build(
          overrides: (
            identifier: null,
            profile: profile,
            channelSettings: null,
            quietHours: null,
            dndEnabled: null,
            history: null,
            minimumNotificationInterval: null,
          ),
        );

        final repository = Builder(
          NotificationRuleRepositoryFactory(),
        ).build(overrides: (instances: [rule], onPersist: null));

        final found = await repository.find(profile);

        expect(found, equals(rule));
      });

      test('find throws when rule not found.', () async {
        final repository = Builder(
          NotificationRuleRepositoryFactory(),
        ).build(overrides: (instances: [], onPersist: null));

        final profile = Builder(ProfileIdentifierFactory()).build();

        expect(
          () => repository.find(profile),
          throwsA(isA<AggregateNotFoundError>()),
        );
      });

      test('persist saves rule.', () async {
        final repository = Builder(
          NotificationRuleRepositoryFactory(),
        ).build(overrides: (instances: [], onPersist: null));

        final rule = Builder(NotificationRuleFactory()).build();

        await repository.persist(rule);

        final found = await repository.find(rule.profile);

        expect(found, equals(rule));
      });

      test('persist calls onPersist callback.', () async {
        NotificationRule? persistedRule;

        final repository = Builder(NotificationRuleRepositoryFactory()).build(
          overrides: (
            instances: [],
            onPersist: (rule) {
              persistedRule = rule;
            },
          ),
        );

        final rule = Builder(NotificationRuleFactory()).build();

        await repository.persist(rule);

        expect(persistedRule, equals(rule));
      });
    });
  });
}
