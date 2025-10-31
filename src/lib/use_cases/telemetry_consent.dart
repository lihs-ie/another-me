import 'package:another_me/domains/common/error.dart';
import 'package:another_me/domains/common/transaction.dart';
import 'package:another_me/domains/profile/profile.dart';
import 'package:another_me/domains/telemetry/usage.dart' as telemetry_domain;
import 'package:logger/logger.dart';

class TelemetryConsent {
  final telemetry_domain.TelemetryConsentRepository _consentRepository;
  final Transaction _transaction;
  final Logger _logger;

  TelemetryConsent({
    required telemetry_domain.TelemetryConsentRepository consentRepository,
    required Transaction transaction,
    required Logger logger,
  }) : _consentRepository = consentRepository,
       _transaction = transaction,
       _logger = logger;

  Future<void> optIn({required ProfileIdentifier profile}) async {
    await _transaction.execute(() async {
      telemetry_domain.TelemetryConsent consent;

      try {
        consent = await _consentRepository.findByProfile(profile);
      } on AggregateNotFoundError {
        consent = telemetry_domain.TelemetryConsent(
          identifier: telemetry_domain.TelemetryConsentIdentifier.generate(),
          profile: profile,
          status: telemetry_domain.TelemetryConsentStatus.optedOut,
          updatedAt: DateTime.now(),
        );
      }

      consent.changeStatus(telemetry_domain.TelemetryConsentStatus.optedIn);

      await _consentRepository.persist(consent);

      _logger.d('Telemetry consent opted in for profile: ${profile.value}');
    });
  }

  Future<void> optOut({required ProfileIdentifier profile}) async {
    await _transaction.execute(() async {
      telemetry_domain.TelemetryConsent consent;

      try {
        consent = await _consentRepository.findByProfile(profile);
      } on AggregateNotFoundError {
        consent = telemetry_domain.TelemetryConsent(
          identifier: telemetry_domain.TelemetryConsentIdentifier.generate(),
          profile: profile,
          status: telemetry_domain.TelemetryConsentStatus.optedIn,
          updatedAt: DateTime.now(),
        );
      }

      consent.changeStatus(telemetry_domain.TelemetryConsentStatus.optedOut);

      await _consentRepository.persist(consent);

      _logger.d('Telemetry consent opted out for profile: ${profile.value}');
    });
  }
}
