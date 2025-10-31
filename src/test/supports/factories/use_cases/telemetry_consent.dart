import 'package:another_me/domains/common/transaction.dart';
import 'package:another_me/domains/telemetry/usage.dart';
import 'package:another_me/use_cases/telemetry_consent.dart' as use_case;
import 'package:logger/logger.dart';

import '../common.dart';
import '../common/transaction.dart' as transaction_factory;
import '../logger.dart';
import '../telemetry/usage.dart' as telemetry_factory;

typedef TelemetryConsentOverrides = ({
  TelemetryConsentRepository? consentRepository,
  Transaction? transaction,
  Logger? logger,
});

class TelemetryConsentFactory
    extends Factory<use_case.TelemetryConsent, TelemetryConsentOverrides> {
  @override
  use_case.TelemetryConsent create({
    TelemetryConsentOverrides? overrides,
    required int seed,
  }) {
    final consentRepository =
        overrides?.consentRepository ??
        Builder(
          telemetry_factory.TelemetryConsentRepositoryFactory(),
        ).buildWith(seed: seed);

    final transaction =
        overrides?.transaction ??
        Builder(transaction_factory.TransactionFactory()).buildWith(seed: seed);

    final logger =
        overrides?.logger ?? Builder(LoggerFactory()).buildWith(seed: seed);

    return use_case.TelemetryConsent(
      consentRepository: consentRepository,
      transaction: transaction,
      logger: logger,
    );
  }

  @override
  use_case.TelemetryConsent duplicate(
    use_case.TelemetryConsent instance,
    TelemetryConsentOverrides? overrides,
  ) {
    throw UnimplementedError();
  }
}
