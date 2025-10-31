import 'package:another_me/domains/notification/notification.dart'
    as notification_domain;
import 'package:another_me/use_cases/notification_settings.dart';
import 'package:flutter/material.dart' hide Builder;
import 'package:flutter_test/flutter_test.dart';

import '../../supports/factories/common.dart';
import '../../supports/factories/common/transaction.dart'
    as transaction_factory;
import '../../supports/factories/logger.dart';
import '../../supports/factories/notification/notification.dart'
    as notification_factory;
import '../../supports/factories/profile/profile.dart' as profile_factory;

void main() {
  group('NotificationSettings', () {
    group('updateChannelSetting', () {
      test('updates channel setting successfully.', () async {
        final profileIdentifier = Builder(
          profile_factory.ProfileIdentifierFactory(),
        ).buildWith(seed: 1);

        final initialChannelSettings =
            <String, notification_domain.NotificationChannelSetting>{
              'PomodoroPhaseStarted':
                  Builder(
                    notification_factory.NotificationChannelSettingFactory(),
                  ).buildWith(
                    seed: 1,
                    overrides: (
                      eventType: null,
                      channels: {
                        notification_domain.NotificationChannel.desktop,
                      },
                      template: null,
                    ),
                  ),
            };

        final notificationRule =
            Builder(notification_factory.NotificationRuleFactory()).buildWith(
              seed: 1,
              overrides: (
                identifier: null,
                profile: profileIdentifier,
                channelSettings: initialChannelSettings,
                quietHours: null,
                dndEnabled: false,
                history: null,
                minimumNotificationInterval: null,
              ),
            );

        notificationRule.events();

        var persistCallCount = 0;
        notification_domain.NotificationRule? persistedRule;

        final notificationRuleRepository =
            Builder(
              notification_factory.NotificationRuleRepositoryFactory(),
            ).buildWith(
              seed: 1,
              overrides: (
                instances: [notificationRule],
                onPersist: (rule) {
                  persistCallCount++;
                  persistedRule = rule;
                },
              ),
            );

        final useCase = NotificationSettings(
          notificationRuleRepository: notificationRuleRepository,
          transaction: Builder(
            transaction_factory.TransactionFactory(),
          ).build(),
          logger: Builder(LoggerFactory()).buildWith(seed: 1),
        );

        final eventType = notification_domain.PomodoroPhaseStartedEvent();

        final newSetting =
            Builder(
              notification_factory.NotificationChannelSettingFactory(),
            ).buildWith(
              seed: 2,
              overrides: (
                eventType: null,
                channels: {
                  notification_domain.NotificationChannel.desktop,
                  notification_domain.NotificationChannel.sound,
                },
                template: null,
              ),
            );

        await useCase.updateChannelSetting(
          profile: profileIdentifier,
          eventType: eventType,
          setting: newSetting,
        );

        expect(persistCallCount, equals(1));
        expect(persistedRule, isNotNull);

        final events = persistedRule!.events();
        expect(events.length, equals(1));
        expect(
          events.first,
          isA<notification_domain.NotificationRuleUpdated>(),
        );
      });
    });

    group('updateQuietHours', () {
      test('updates quiet hours successfully.', () async {
        final profileIdentifier = Builder(
          profile_factory.ProfileIdentifierFactory(),
        ).buildWith(seed: 1);

        final initialQuietHours =
            Builder(notification_factory.QuietHoursFactory()).buildWith(
              seed: 1,
              overrides: (
                startTime: const TimeOfDay(hour: 23, minute: 0),
                endTime: const TimeOfDay(hour: 7, minute: 0),
              ),
            );

        final notificationRule =
            Builder(notification_factory.NotificationRuleFactory()).buildWith(
              seed: 1,
              overrides: (
                identifier: null,
                profile: profileIdentifier,
                channelSettings: null,
                quietHours: initialQuietHours,
                dndEnabled: false,
                history: null,
                minimumNotificationInterval: null,
              ),
            );

        notificationRule.events();

        var persistCallCount = 0;
        notification_domain.NotificationRule? persistedRule;

        final notificationRuleRepository =
            Builder(
              notification_factory.NotificationRuleRepositoryFactory(),
            ).buildWith(
              seed: 1,
              overrides: (
                instances: [notificationRule],
                onPersist: (rule) {
                  persistCallCount++;
                  persistedRule = rule;
                },
              ),
            );

        final useCase = NotificationSettings(
          notificationRuleRepository: notificationRuleRepository,
          transaction: Builder(
            transaction_factory.TransactionFactory(),
          ).build(),
          logger: Builder(LoggerFactory()).buildWith(seed: 1),
        );

        final newQuietHours = Builder(notification_factory.QuietHoursFactory())
            .buildWith(
              seed: 2,
              overrides: (
                startTime: const TimeOfDay(hour: 22, minute: 0),
                endTime: const TimeOfDay(hour: 8, minute: 0),
              ),
            );

        await useCase.updateQuietHours(
          profile: profileIdentifier,
          quietHours: newQuietHours,
        );

        expect(persistCallCount, equals(1));
        expect(persistedRule, isNotNull);
        expect(persistedRule!.quietHours, equals(newQuietHours));

        final events = persistedRule!.events();
        expect(events.length, equals(1));
        expect(
          events.first,
          isA<notification_domain.NotificationRuleUpdated>(),
        );
      });
    });

    group('toggleDnd', () {
      test('toggles DND from false to true.', () async {
        final profileIdentifier = Builder(
          profile_factory.ProfileIdentifierFactory(),
        ).buildWith(seed: 1);

        final notificationRule =
            Builder(notification_factory.NotificationRuleFactory()).buildWith(
              seed: 1,
              overrides: (
                identifier: null,
                profile: profileIdentifier,
                channelSettings: null,
                quietHours: null,
                dndEnabled: false,
                history: null,
                minimumNotificationInterval: null,
              ),
            );

        notificationRule.events();

        var persistCallCount = 0;
        notification_domain.NotificationRule? persistedRule;

        final notificationRuleRepository =
            Builder(
              notification_factory.NotificationRuleRepositoryFactory(),
            ).buildWith(
              seed: 1,
              overrides: (
                instances: [notificationRule],
                onPersist: (rule) {
                  persistCallCount++;
                  persistedRule = rule;
                },
              ),
            );

        final useCase = NotificationSettings(
          notificationRuleRepository: notificationRuleRepository,
          transaction: Builder(
            transaction_factory.TransactionFactory(),
          ).build(),
          logger: Builder(LoggerFactory()).buildWith(seed: 1),
        );

        await useCase.toggleDnd(profile: profileIdentifier);

        expect(persistCallCount, equals(1));
        expect(persistedRule, isNotNull);
        expect(persistedRule!.dndEnabled, equals(true));

        final events = persistedRule!.events();
        expect(events.length, equals(1));
        expect(
          events.first,
          isA<notification_domain.NotificationRuleUpdated>(),
        );
      });

      test('toggles DND from true to false.', () async {
        final profileIdentifier = Builder(
          profile_factory.ProfileIdentifierFactory(),
        ).buildWith(seed: 1);

        final notificationRule =
            Builder(notification_factory.NotificationRuleFactory()).buildWith(
              seed: 1,
              overrides: (
                identifier: null,
                profile: profileIdentifier,
                channelSettings: null,
                quietHours: null,
                dndEnabled: true,
                history: null,
                minimumNotificationInterval: null,
              ),
            );

        notificationRule.events();

        var persistCallCount = 0;
        notification_domain.NotificationRule? persistedRule;

        final notificationRuleRepository =
            Builder(
              notification_factory.NotificationRuleRepositoryFactory(),
            ).buildWith(
              seed: 1,
              overrides: (
                instances: [notificationRule],
                onPersist: (rule) {
                  persistCallCount++;
                  persistedRule = rule;
                },
              ),
            );

        final useCase = NotificationSettings(
          notificationRuleRepository: notificationRuleRepository,
          transaction: Builder(
            transaction_factory.TransactionFactory(),
          ).build(),
          logger: Builder(LoggerFactory()).buildWith(seed: 1),
        );

        await useCase.toggleDnd(profile: profileIdentifier);

        expect(persistCallCount, equals(1));
        expect(persistedRule, isNotNull);
        expect(persistedRule!.dndEnabled, equals(false));

        final events = persistedRule!.events();
        expect(events.length, equals(1));
        expect(
          events.first,
          isA<notification_domain.NotificationRuleUpdated>(),
        );
      });
    });
  });
}
