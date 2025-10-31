import 'package:another_me/domains/common/transaction.dart';
import 'package:another_me/domains/notification/notification.dart';
import 'package:another_me/use_cases/notification_settings.dart' as use_case;
import 'package:logger/logger.dart';

import '../common.dart';
import '../common/transaction.dart' as transaction_factory;
import '../logger.dart';
import '../notification/notification.dart' as notification_factory;

typedef NotificationSettingsOverrides = ({
  NotificationRuleRepository? notificationRuleRepository,
  Transaction? transaction,
  Logger? logger,
});

class NotificationSettingsFactory
    extends
        Factory<use_case.NotificationSettings, NotificationSettingsOverrides> {
  @override
  use_case.NotificationSettings create({
    NotificationSettingsOverrides? overrides,
    required int seed,
  }) {
    final notificationRuleRepository =
        overrides?.notificationRuleRepository ??
        Builder(
          notification_factory.NotificationRuleRepositoryFactory(),
        ).buildWith(seed: seed);

    final transaction =
        overrides?.transaction ??
        Builder(transaction_factory.TransactionFactory()).buildWith(seed: seed);

    final logger =
        overrides?.logger ?? Builder(LoggerFactory()).buildWith(seed: seed);

    return use_case.NotificationSettings(
      notificationRuleRepository: notificationRuleRepository,
      transaction: transaction,
      logger: logger,
    );
  }

  @override
  use_case.NotificationSettings duplicate(
    use_case.NotificationSettings instance,
    NotificationSettingsOverrides? overrides,
  ) {
    throw UnimplementedError();
  }
}
