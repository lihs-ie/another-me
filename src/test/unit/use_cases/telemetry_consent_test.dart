import 'package:another_me/domains/telemetry/usage.dart' as telemetry_domain;
import 'package:another_me/use_cases/telemetry_consent.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../supports/factories/common.dart';
import '../../supports/factories/common/transaction.dart'
    as transaction_factory;
import '../../supports/factories/logger.dart';
import '../../supports/factories/profile/profile.dart' as profile_factory;
import '../../supports/factories/telemetry/usage.dart' as telemetry_factory;

void main() {
  group('TelemetryConsent', () {
    group('optIn', () {
      test('opts in successfully when consent exists.', () async {
        final profileIdentifier = Builder(
          profile_factory.ProfileIdentifierFactory(),
        ).buildWith(seed: 1);

        final consent = Builder(telemetry_factory.TelemetryConsentFactory())
            .buildWith(
              seed: 1,
              overrides: (
                identifier: null,
                profile: profileIdentifier,
                status: telemetry_domain.TelemetryConsentStatus.optedOut,
                updatedAt: null,
              ),
            );

        consent.events();

        var persistCallCount = 0;
        telemetry_domain.TelemetryConsent? persistedConsent;

        final consentRepository =
            Builder(
              telemetry_factory.TelemetryConsentRepositoryFactory(),
            ).buildWith(
              seed: 1,
              overrides: (
                instances: [consent],
                onPersist: (c) {
                  persistCallCount++;
                  persistedConsent = c;
                },
              ),
            );

        final useCase = TelemetryConsent(
          consentRepository: consentRepository,
          transaction: Builder(
            transaction_factory.TransactionFactory(),
          ).build(),
          logger: Builder(LoggerFactory()).buildWith(seed: 1),
        );

        await useCase.optIn(profile: profileIdentifier);

        expect(persistCallCount, equals(1));
        expect(persistedConsent, isNotNull);
        expect(
          persistedConsent!.status,
          equals(telemetry_domain.TelemetryConsentStatus.optedIn),
        );

        final events = persistedConsent!.events();
        expect(events.length, equals(1));
        expect(events.first, isA<telemetry_domain.TelemetryConsentChanged>());

        final consentChanged =
            events.first as telemetry_domain.TelemetryConsentChanged;
        expect(
          consentChanged.status,
          equals(telemetry_domain.TelemetryConsentStatus.optedIn),
        );
      });

      test(
        'creates new consent and opts in when consent does not exist.',
        () async {
          final profileIdentifier = Builder(
            profile_factory.ProfileIdentifierFactory(),
          ).buildWith(seed: 1);

          var persistCallCount = 0;
          telemetry_domain.TelemetryConsent? persistedConsent;

          final consentRepository =
              Builder(
                telemetry_factory.TelemetryConsentRepositoryFactory(),
              ).buildWith(
                seed: 1,
                overrides: (
                  instances: [],
                  onPersist: (c) {
                    persistCallCount++;
                    persistedConsent = c;
                  },
                ),
              );

          final useCase = TelemetryConsent(
            consentRepository: consentRepository,
            transaction: Builder(
              transaction_factory.TransactionFactory(),
            ).build(),
            logger: Builder(LoggerFactory()).buildWith(seed: 1),
          );

          await useCase.optIn(profile: profileIdentifier);

          expect(persistCallCount, equals(1));
          expect(persistedConsent, isNotNull);
          expect(persistedConsent!.profile, equals(profileIdentifier));
          expect(
            persistedConsent!.status,
            equals(telemetry_domain.TelemetryConsentStatus.optedIn),
          );

          final events = persistedConsent!.events();
          expect(events.length, equals(1));
          expect(events.first, isA<telemetry_domain.TelemetryConsentChanged>());

          final consentChanged =
              events.first as telemetry_domain.TelemetryConsentChanged;
          expect(
            consentChanged.status,
            equals(telemetry_domain.TelemetryConsentStatus.optedIn),
          );
          expect(consentChanged.profile, equals(profileIdentifier));
        },
      );
    });

    group('optOut', () {
      test('opts out successfully when consent exists.', () async {
        final profileIdentifier = Builder(
          profile_factory.ProfileIdentifierFactory(),
        ).buildWith(seed: 1);

        final consent = Builder(telemetry_factory.TelemetryConsentFactory())
            .buildWith(
              seed: 1,
              overrides: (
                identifier: null,
                profile: profileIdentifier,
                status: telemetry_domain.TelemetryConsentStatus.optedIn,
                updatedAt: null,
              ),
            );

        consent.events();

        var persistCallCount = 0;
        telemetry_domain.TelemetryConsent? persistedConsent;

        final consentRepository =
            Builder(
              telemetry_factory.TelemetryConsentRepositoryFactory(),
            ).buildWith(
              seed: 1,
              overrides: (
                instances: [consent],
                onPersist: (c) {
                  persistCallCount++;
                  persistedConsent = c;
                },
              ),
            );

        final useCase = TelemetryConsent(
          consentRepository: consentRepository,
          transaction: Builder(
            transaction_factory.TransactionFactory(),
          ).build(),
          logger: Builder(LoggerFactory()).buildWith(seed: 1),
        );

        await useCase.optOut(profile: profileIdentifier);

        expect(persistCallCount, equals(1));
        expect(persistedConsent, isNotNull);
        expect(
          persistedConsent!.status,
          equals(telemetry_domain.TelemetryConsentStatus.optedOut),
        );

        final events = persistedConsent!.events();
        expect(events.length, equals(1));
        expect(events.first, isA<telemetry_domain.TelemetryConsentChanged>());

        final consentChanged =
            events.first as telemetry_domain.TelemetryConsentChanged;
        expect(
          consentChanged.status,
          equals(telemetry_domain.TelemetryConsentStatus.optedOut),
        );
      });

      test(
        'creates new consent and opts out when consent does not exist.',
        () async {
          final profileIdentifier = Builder(
            profile_factory.ProfileIdentifierFactory(),
          ).buildWith(seed: 1);

          var persistCallCount = 0;
          telemetry_domain.TelemetryConsent? persistedConsent;

          final consentRepository =
              Builder(
                telemetry_factory.TelemetryConsentRepositoryFactory(),
              ).buildWith(
                seed: 1,
                overrides: (
                  instances: [],
                  onPersist: (c) {
                    persistCallCount++;
                    persistedConsent = c;
                  },
                ),
              );

          final useCase = TelemetryConsent(
            consentRepository: consentRepository,
            transaction: Builder(
              transaction_factory.TransactionFactory(),
            ).build(),
            logger: Builder(LoggerFactory()).buildWith(seed: 1),
          );

          await useCase.optOut(profile: profileIdentifier);

          expect(persistCallCount, equals(1));
          expect(persistedConsent, isNotNull);
          expect(persistedConsent!.profile, equals(profileIdentifier));
          expect(
            persistedConsent!.status,
            equals(telemetry_domain.TelemetryConsentStatus.optedOut),
          );

          final events = persistedConsent!.events();
          expect(events.length, equals(1));
          expect(events.first, isA<telemetry_domain.TelemetryConsentChanged>());

          final consentChanged =
              events.first as telemetry_domain.TelemetryConsentChanged;
          expect(
            consentChanged.status,
            equals(telemetry_domain.TelemetryConsentStatus.optedOut),
          );
          expect(consentChanged.profile, equals(profileIdentifier));
        },
      );
    });
  });
}
