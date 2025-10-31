import 'package:another_me/domains/common/transaction.dart';
import 'package:another_me/domains/notification/notification.dart'
    as notification_domain;
import 'package:another_me/domains/profile/profile.dart' as profile_domain;
import 'package:logger/logger.dart';

class NotificationSettings {
  final notification_domain.NotificationRuleRepository
  _notificationRuleRepository;
  final Transaction _transaction;
  final Logger _logger;

  NotificationSettings({
    required notification_domain.NotificationRuleRepository
    notificationRuleRepository,
    required Transaction transaction,
    required Logger logger,
  }) : _notificationRuleRepository = notificationRuleRepository,
       _transaction = transaction,
       _logger = logger;

  Future<void> updateChannelSetting({
    required profile_domain.ProfileIdentifier profile,
    required notification_domain.NotificationEventType eventType,
    required notification_domain.NotificationChannelSetting setting,
  }) async {
    await _transaction.execute(() async {
      final notificationRule = await _notificationRuleRepository.find(profile);

      notificationRule.updateChannelSetting(
        eventType: eventType,
        setting: setting,
      );

      await _notificationRuleRepository.persist(notificationRule);

      _logger.i(
        'Notification channel setting updated for profile ${profile.value}: ${eventType.name}',
      );
    });
  }

  Future<void> updateQuietHours({
    required profile_domain.ProfileIdentifier profile,
    required notification_domain.QuietHours quietHours,
  }) async {
    await _transaction.execute(() async {
      final notificationRule = await _notificationRuleRepository.find(profile);

      notificationRule.updateQuietHours(quietHours);

      await _notificationRuleRepository.persist(notificationRule);

      _logger.i('Quiet hours updated for profile ${profile.value}');
    });
  }

  Future<void> toggleDnd({
    required profile_domain.ProfileIdentifier profile,
  }) async {
    await _transaction.execute(() async {
      final notificationRule = await _notificationRuleRepository.find(profile);

      final newDndState = !notificationRule.dndEnabled;

      notificationRule.toggleDnd(newDndState);

      await _notificationRuleRepository.persist(notificationRule);

      _logger.i('DND toggled for profile ${profile.value}: $newDndState');
    });
  }
}
