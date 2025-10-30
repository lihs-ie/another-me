import 'package:another_me/domains/common/storage.dart';
import 'package:another_me/domains/common/url.dart';
import 'package:another_me/domains/common/variant.dart';
import 'package:another_me/domains/licensing/licensing.dart';
import 'package:another_me/domains/media/media.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulid/ulid.dart';

import '../../../supports/factories/common/storage.dart';
import '../../../supports/factories/common/url.dart';
import '../../../supports/factories/licensing/licensing.dart';
import '../../../supports/factories/media/media.dart';
import '../../../supports/factories/common.dart';
import '../common/identifier.dart';
import '../common/value_object.dart';

void main() {
  group('Package domains/licensing', () {
    ulidBasedIdentifierTest<LicenseIdentifier, Ulid>(
      constructor: (Ulid value) => LicenseIdentifier(value: value),
      generate: LicenseIdentifier.generate,
      fromString: LicenseIdentifier.fromString,
      fromBinary: LicenseIdentifier.fromBinary,
    );

    ulidBasedIdentifierTest<AttributionBookIdentifier, Ulid>(
      constructor: (Ulid value) => AttributionBookIdentifier(value: value),
      generate: AttributionBookIdentifier.generate,
      fromString: AttributionBookIdentifier.fromString,
      fromBinary: AttributionBookIdentifier.fromBinary,
    );

    ulidBasedIdentifierTest<AttributionResourceIdentifier, Ulid>(
      constructor: (Ulid value) => AttributionResourceIdentifier(value: value),
      generate: AttributionResourceIdentifier.generate,
      fromString: AttributionResourceIdentifier.fromString,
      fromBinary: AttributionResourceIdentifier.fromBinary,
    );

    group('LicenseStatus', () {
      test('declares all defined enumerators.', () {
        expect(LicenseStatus.pending, isA<LicenseStatus>());
        expect(LicenseStatus.active, isA<LicenseStatus>());
        expect(LicenseStatus.revoked, isA<LicenseStatus>());
      });
    });

    valueObjectTest<
      LicensePolicy,
      ({
        bool commercialUseAllowed,
        bool redistributionAllowed,
        String creditRequirement,
        String? memo,
      }),
      ({
        bool commercialUseAllowed,
        bool redistributionAllowed,
        String creditRequirement,
        String? memo,
      })
    >(
      constructor: (props) => LicensePolicy(
        commercialUseAllowed: props.commercialUseAllowed,
        redistributionAllowed: props.redistributionAllowed,
        creditRequirement: props.creditRequirement,
        memo: props.memo,
      ),
      generator: () => (
        commercialUseAllowed: true,
        redistributionAllowed: true,
        creditRequirement: 'Credit required',
        memo: 'Test memo',
      ),
      variations: (props) => [
        (
          commercialUseAllowed: false,
          redistributionAllowed: false,
          creditRequirement: props.creditRequirement,
          memo: props.memo,
        ),
        (
          commercialUseAllowed: props.commercialUseAllowed,
          redistributionAllowed: false,
          creditRequirement: props.creditRequirement,
          memo: props.memo,
        ),
        (
          commercialUseAllowed: props.commercialUseAllowed,
          redistributionAllowed: props.redistributionAllowed,
          creditRequirement: 'Different credit',
          memo: props.memo,
        ),
        (
          commercialUseAllowed: props.commercialUseAllowed,
          redistributionAllowed: props.redistributionAllowed,
          creditRequirement: props.creditRequirement,
          memo: 'Different memo',
        ),
        (
          commercialUseAllowed: props.commercialUseAllowed,
          redistributionAllowed: props.redistributionAllowed,
          creditRequirement: props.creditRequirement,
          memo: null,
        ),
      ],
      invalids: (props) => [
        (
          commercialUseAllowed: props.commercialUseAllowed,
          redistributionAllowed: props.redistributionAllowed,
          creditRequirement: '',
          memo: props.memo,
        ),
        (
          commercialUseAllowed: props.commercialUseAllowed,
          redistributionAllowed: props.redistributionAllowed,
          creditRequirement:
              'a' * (LicensePolicy.maxCreditRequirementLength + 1),
          memo: props.memo,
        ),
        (
          commercialUseAllowed: props.commercialUseAllowed,
          redistributionAllowed: props.redistributionAllowed,
          creditRequirement: props.creditRequirement,
          memo: '',
        ),
        (
          commercialUseAllowed: props.commercialUseAllowed,
          redistributionAllowed: props.redistributionAllowed,
          creditRequirement: props.creditRequirement,
          memo: 'a' * (LicensePolicy.maxMemoLength + 1),
        ),
        (
          commercialUseAllowed: false,
          redistributionAllowed: true,
          creditRequirement: props.creditRequirement,
          memo: props.memo,
        ),
      ],
    );

    valueObjectTest<AttributionText, ({String text}), ({String text})>(
      constructor: (props) => AttributionText(text: props.text),
      generator: () => (text: 'Valid attribution text'),
      variations: (props) => [
        (text: 'Different text'),
        (text: 'Another different text'),
      ],
      invalids: (props) => [
        (text: ''),
        (text: 'a' * (AttributionText.maxLength + 1)),
      ],
      additionalTests: () {
        group('normalization', () {
          test('normalizes newlines from \\r\\n to \\n.', () {
            final instance = AttributionText(text: 'Line1\r\nLine2\rLine3\n');

            expect(instance.text, equals('Line1\nLine2\nLine3\n'));
          });
        });
      },
    );

    valueObjectTest<
      LicenseRegistrationRequest,
      ({
        String trackTitle,
        String licenseName,
        URL licenseURL,
        String attributionText,
        String licenseText,
        LicensePolicy policy,
        URL sourceURL,
      }),
      ({
        String trackTitle,
        String licenseName,
        URL licenseURL,
        String attributionText,
        String licenseText,
        LicensePolicy policy,
        URL sourceURL,
      })
    >(
      constructor: (props) => LicenseRegistrationRequest(
        trackTitle: props.trackTitle,
        licenseName: props.licenseName,
        licenseURL: props.licenseURL,
        attributionText: props.attributionText,
        licenseText: props.licenseText,
        policy: props.policy,
        sourceURL: props.sourceURL,
      ),
      generator: () => (
        trackTitle: 'Track Title',
        licenseName: 'License Name',
        licenseURL: Builder(URLFactory()).build(
          overrides: (
            scheme: URLScheme.https,
            value: 'https://example.com/license',
          ),
        ),
        attributionText: 'Attribution text',
        licenseText: 'License text content',
        policy: LicensePolicy(
          commercialUseAllowed: true,
          redistributionAllowed: true,
          creditRequirement: 'Credit required',
          memo: null,
        ),
        sourceURL: Builder(URLFactory()).build(
          overrides: (
            scheme: URLScheme.https,
            value: 'https://example.com/source',
          ),
        ),
      ),
      variations: (props) => [
        (
          trackTitle: 'Different Title',
          licenseName: props.licenseName,
          licenseURL: props.licenseURL,
          attributionText: props.attributionText,
          licenseText: props.licenseText,
          policy: props.policy,
          sourceURL: props.sourceURL,
        ),
        (
          trackTitle: props.trackTitle,
          licenseName: 'Different License',
          licenseURL: props.licenseURL,
          attributionText: props.attributionText,
          licenseText: props.licenseText,
          policy: props.policy,
          sourceURL: props.sourceURL,
        ),
        (
          trackTitle: props.trackTitle,
          licenseName: props.licenseName,
          licenseURL: Builder(URLFactory()).build(
            overrides: (
              scheme: URLScheme.https,
              value: 'https://different.com/license',
            ),
          ),
          attributionText: props.attributionText,
          licenseText: props.licenseText,
          policy: props.policy,
          sourceURL: props.sourceURL,
        ),
      ],
      invalids: (props) => [
        (
          trackTitle: props.trackTitle,
          licenseName: props.licenseName,
          licenseURL: Builder(URLFactory()).build(
            overrides: (
              scheme: URLScheme.ftp,
              value: 'ftp://example.com/license',
            ),
          ),
          attributionText: props.attributionText,
          licenseText: props.licenseText,
          policy: props.policy,
          sourceURL: props.sourceURL,
        ),
        (
          trackTitle: props.trackTitle,
          licenseName: props.licenseName,
          licenseURL: props.licenseURL,
          attributionText: props.attributionText,
          licenseText: props.licenseText,
          policy: props.policy,
          sourceURL: Builder(URLFactory()).build(
            overrides: (
              scheme: URLScheme.file,
              value: 'file:///path/to/source',
            ),
          ),
        ),
      ],
    );

    valueObjectTest<
      LicenseStatusEntry,
      ({LicenseStatus status, DateTime changedAt, String reason}),
      ({LicenseStatus status, DateTime changedAt, String reason})
    >(
      constructor: (props) => LicenseStatusEntry(
        status: props.status,
        changedAt: props.changedAt,
        reason: props.reason,
      ),
      generator: () => (
        status: LicenseStatus.active,
        changedAt: DateTime(2024, 1, 1, 12, 0, 0),
        reason: 'Status changed',
      ),
      variations: (props) => [
        (
          status: LicenseStatus.pending,
          changedAt: props.changedAt,
          reason: props.reason,
        ),
        (
          status: props.status,
          changedAt: props.changedAt.add(const Duration(days: 1)),
          reason: props.reason,
        ),
        (
          status: props.status,
          changedAt: props.changedAt,
          reason: 'Different reason',
        ),
      ],
      invalids: (props) => [],
    );

    valueObjectTest<
      LicenseRecordSearchCriteria,
      ({Set<LicenseStatus>? statuses, bool allowOfflineOnly}),
      ({Set<LicenseStatus>? statuses, bool allowOfflineOnly})
    >(
      constructor: (props) => LicenseRecordSearchCriteria(
        statuses: props.statuses,
        allowOfflineOnly: props.allowOfflineOnly,
      ),
      generator: () => (
        statuses: {LicenseStatus.active, LicenseStatus.pending},
        allowOfflineOnly: false,
      ),
      variations: (props) => [
        (
          statuses: {LicenseStatus.revoked},
          allowOfflineOnly: props.allowOfflineOnly,
        ),
        (statuses: null, allowOfflineOnly: props.allowOfflineOnly),
        (statuses: props.statuses, allowOfflineOnly: true),
      ],
      invalids: (props) => [
        (statuses: <LicenseStatus>{}, allowOfflineOnly: props.allowOfflineOnly),
      ],
    );

    valueObjectTest<
      AttributionEntry,
      ({
        AttributionResourceIdentifier resource,
        String displayName,
        AttributionText attributionText,
        LicenseIdentifier license,
        bool isValid,
      }),
      ({
        AttributionResourceIdentifier resource,
        String displayName,
        AttributionText attributionText,
        LicenseIdentifier license,
        bool isValid,
      })
    >(
      constructor: (props) => AttributionEntry(
        resource: props.resource,
        displayName: props.displayName,
        attributionText: props.attributionText,
        license: props.license,
        isValid: props.isValid,
      ),
      generator: () => (
        resource: AttributionResourceIdentifier.generate(),
        displayName: 'Display Name',
        attributionText: AttributionText(text: 'Attribution text'),
        license: LicenseIdentifier.generate(),
        isValid: true,
      ),
      variations: (props) => [
        (
          resource: AttributionResourceIdentifier.generate(),
          displayName: props.displayName,
          attributionText: props.attributionText,
          license: props.license,
          isValid: props.isValid,
        ),
        (
          resource: props.resource,
          displayName: 'Different Name',
          attributionText: props.attributionText,
          license: props.license,
          isValid: props.isValid,
        ),
        (
          resource: props.resource,
          displayName: props.displayName,
          attributionText: AttributionText(text: 'Different attribution'),
          license: props.license,
          isValid: props.isValid,
        ),
        (
          resource: props.resource,
          displayName: props.displayName,
          attributionText: props.attributionText,
          license: LicenseIdentifier.generate(),
          isValid: props.isValid,
        ),
        (
          resource: props.resource,
          displayName: props.displayName,
          attributionText: props.attributionText,
          license: props.license,
          isValid: false,
        ),
      ],
      invalids: (props) => [],
      additionalTests: () {
        group('copyWith', () {
          test('returns new instance with updated isValid.', () {
            final entry = AttributionEntry(
              resource: AttributionResourceIdentifier.generate(),
              displayName: 'Test',
              attributionText: AttributionText(text: 'Test text'),
              license: LicenseIdentifier.generate(),
              isValid: true,
            );

            final updated = entry.copyWith(isValid: false);

            expect(updated.isValid, isFalse);
            expect(updated.resource, equals(entry.resource));
            expect(updated.displayName, equals(entry.displayName));
            expect(updated.attributionText, equals(entry.attributionText));
            expect(updated.license, equals(entry.license));
          });

          test(
            'returns new instance with same isValid when null is passed.',
            () {
              final entry = AttributionEntry(
                resource: AttributionResourceIdentifier.generate(),
                displayName: 'Test',
                attributionText: AttributionText(text: 'Test text'),
                license: LicenseIdentifier.generate(),
                isValid: true,
              );

              final updated = entry.copyWith();

              expect(updated.isValid, isTrue);
              expect(updated, equals(entry));
            },
          );
        });
      },
    );

    valueObjectTest<
      LicenseSnapshot,
      ({
        LicenseIdentifier identifier,
        TrackIdentifier track,
        String trackTitle,
        String licenseName,
        URL licenseURL,
        AttributionText attributionText,
        LicensePolicy policy,
        URL sourceURL,
        List<LicenseStatusEntry> statusHistory,
        FilePath? licenseFilePath,
        Checksum? licenseFileChecksum,
      }),
      ({
        LicenseIdentifier identifier,
        TrackIdentifier track,
        String trackTitle,
        String licenseName,
        URL licenseURL,
        AttributionText attributionText,
        LicensePolicy policy,
        URL sourceURL,
        List<LicenseStatusEntry> statusHistory,
        FilePath? licenseFilePath,
        Checksum? licenseFileChecksum,
      })
    >(
      constructor: (props) => LicenseSnapshot(
        identifier: props.identifier,
        track: props.track,
        trackTitle: props.trackTitle,
        licenseName: props.licenseName,
        licenseURL: props.licenseURL,
        attributionText: props.attributionText,
        policy: props.policy,
        sourceURL: props.sourceURL,
        statusHistory: props.statusHistory,
        licenseFilePath: props.licenseFilePath,
        licenseFileChecksum: props.licenseFileChecksum,
      ),
      generator: () => (
        identifier: LicenseIdentifier.generate(),
        track: Builder(TrackIdentifierFactory()).build(),
        trackTitle: 'Track Title',
        licenseName: 'License Name',
        licenseURL: Builder(URLFactory()).build(
          overrides: (
            scheme: URLScheme.https,
            value: 'https://example.com/license',
          ),
        ),
        attributionText: AttributionText(text: 'Attribution'),
        policy: LicensePolicy(
          commercialUseAllowed: true,
          redistributionAllowed: true,
          creditRequirement: 'Credit',
          memo: null,
        ),
        sourceURL: Builder(URLFactory()).build(
          overrides: (
            scheme: URLScheme.https,
            value: 'https://example.com/source',
          ),
        ),
        statusHistory: [
          LicenseStatusEntry(
            status: LicenseStatus.pending,
            changedAt: DateTime(2024, 1, 1),
            reason: 'Initial',
          ),
        ],
        licenseFilePath: Builder(FilePathFactory()).build(),
        licenseFileChecksum: Builder(ChecksumFactory()).build(),
      ),
      variations: (props) => [
        (
          identifier: LicenseIdentifier.generate(),
          track: props.track,
          trackTitle: props.trackTitle,
          licenseName: props.licenseName,
          licenseURL: props.licenseURL,
          attributionText: props.attributionText,
          policy: props.policy,
          sourceURL: props.sourceURL,
          statusHistory: props.statusHistory,
          licenseFilePath: props.licenseFilePath,
          licenseFileChecksum: props.licenseFileChecksum,
        ),
        (
          identifier: props.identifier,
          track: props.track,
          trackTitle: 'Different Title',
          licenseName: props.licenseName,
          licenseURL: props.licenseURL,
          attributionText: props.attributionText,
          policy: props.policy,
          sourceURL: props.sourceURL,
          statusHistory: props.statusHistory,
          licenseFilePath: props.licenseFilePath,
          licenseFileChecksum: props.licenseFileChecksum,
        ),
        (
          identifier: props.identifier,
          track: props.track,
          trackTitle: props.trackTitle,
          licenseName: props.licenseName,
          licenseURL: props.licenseURL,
          attributionText: props.attributionText,
          policy: props.policy,
          sourceURL: props.sourceURL,
          statusHistory: props.statusHistory,
          licenseFilePath: null,
          licenseFileChecksum: null,
        ),
      ],
      invalids: (props) => [
        (
          identifier: props.identifier,
          track: props.track,
          trackTitle: props.trackTitle,
          licenseName: props.licenseName,
          licenseURL: Builder(URLFactory()).build(
            overrides: (
              scheme: URLScheme.ftp,
              value: 'ftp://example.com/license',
            ),
          ),
          attributionText: props.attributionText,
          policy: props.policy,
          sourceURL: props.sourceURL,
          statusHistory: props.statusHistory,
          licenseFilePath: props.licenseFilePath,
          licenseFileChecksum: props.licenseFileChecksum,
        ),
        (
          identifier: props.identifier,
          track: props.track,
          trackTitle: props.trackTitle,
          licenseName: props.licenseName,
          licenseURL: props.licenseURL,
          attributionText: props.attributionText,
          policy: props.policy,
          sourceURL: Builder(URLFactory()).build(
            overrides: (
              scheme: URLScheme.file,
              value: 'file:///path/to/source',
            ),
          ),
          statusHistory: props.statusHistory,
          licenseFilePath: props.licenseFilePath,
          licenseFileChecksum: props.licenseFileChecksum,
        ),
      ],
    );

    group('LicenseRecord', () {
      group('register', () {
        test('creates new license record.', () {
          final request = Builder(LicenseRegistrationRequestFactory()).build();

          final trackIdentifier = Builder(TrackIdentifierFactory()).build();

          final licenseFilePath = Builder(FilePathFactory()).build();

          final licenseFileChecksum = Builder(ChecksumFactory()).build();

          final record = LicenseRecord.register(
            request: request,
            trackIdentifier: trackIdentifier,
            licenseFilePath: licenseFilePath,
            licenseFileChecksum: licenseFileChecksum,
          );

          expect(record.trackTitle, equals(request.trackTitle));
          expect(record.track, equals(trackIdentifier));
          expect(record.currentStatus, equals(LicenseStatus.pending));

          final events = record.events();
          expect(events.length, equals(1));
          expect(events.first, isA<LicenseRecordRegistered>());
        });
      });

      group('updateStatus', () {
        test('transitions from pending to active.', () {
          final request = Builder(LicenseRegistrationRequestFactory()).build();

          final record = LicenseRecord.register(
            request: request,
            trackIdentifier: Builder(TrackIdentifierFactory()).build(),
            licenseFilePath: Builder(FilePathFactory()).build(),
            licenseFileChecksum: Builder(ChecksumFactory()).build(),
          );

          record.events();

          final statusEntry = LicenseStatusEntry(
            status: LicenseStatus.active,
            changedAt: DateTime.now(),
            reason: 'Approved',
          );

          record.updateStatus(statusEntry);

          expect(record.currentStatus, equals(LicenseStatus.active));

          final events = record.events();
          expect(events.length, equals(1));
          expect(events.first, isA<LicenseRecordStatusChanged>());
        });

        test('rejects transition from pending to revoked.', () {
          final request = Builder(LicenseRegistrationRequestFactory()).build();

          final record = LicenseRecord.register(
            request: request,
            trackIdentifier: Builder(TrackIdentifierFactory()).build(),
            licenseFilePath: Builder(FilePathFactory()).build(),
            licenseFileChecksum: Builder(ChecksumFactory()).build(),
          );

          record.events();

          final statusEntry = LicenseStatusEntry(
            status: LicenseStatus.revoked,
            changedAt: DateTime.now(),
            reason: 'Invalid',
          );

          expect(
            () => record.updateStatus(statusEntry),
            throwsA(isA<InvariantViolationError>()),
          );
        });

        test(
          'transitions from active to revoked and sets redistributionAllowed=false.',
          () {
            final request = Builder(LicenseRegistrationRequestFactory()).build(
              overrides: (
                trackTitle: null,
                licenseName: null,
                licenseURL: null,
                attributionText: null,
                licenseText: null,
                policy: Builder(LicensePolicyFactory()).build(
                  overrides: (
                    commercialUseAllowed: true,
                    redistributionAllowed: true,
                    creditRequirement: null,
                    memo: null,
                  ),
                ),
                sourceURL: null,
              ),
            );

            final record = LicenseRecord.register(
              request: request,
              trackIdentifier: Builder(TrackIdentifierFactory()).build(),
              licenseFilePath: Builder(FilePathFactory()).build(),
              licenseFileChecksum: Builder(ChecksumFactory()).build(),
            );

            record.events();

            record.updateStatus(
              LicenseStatusEntry(
                status: LicenseStatus.active,
                changedAt: DateTime.now(),
                reason: 'Approved',
              ),
            );

            record.events();

            record.updateStatus(
              LicenseStatusEntry(
                status: LicenseStatus.revoked,
                changedAt: DateTime.now(),
                reason: 'Violation',
              ),
            );

            expect(record.currentStatus, equals(LicenseStatus.revoked));
            expect(record.policy.redistributionAllowed, isFalse);
          },
        );
      });

      group('updatePolicy', () {
        test('updates policy when status is active.', () {
          final request = Builder(LicenseRegistrationRequestFactory()).build();

          final record = LicenseRecord.register(
            request: request,
            trackIdentifier: Builder(TrackIdentifierFactory()).build(),
            licenseFilePath: Builder(FilePathFactory()).build(),
            licenseFileChecksum: Builder(ChecksumFactory()).build(),
          );

          record.events();

          record.updateStatus(
            LicenseStatusEntry(
              status: LicenseStatus.active,
              changedAt: DateTime.now(),
              reason: 'Approved',
            ),
          );

          record.events();

          final newPolicy = Builder(LicensePolicyFactory()).build(
            overrides: (
              commercialUseAllowed: false,
              redistributionAllowed: false,
              creditRequirement: null,
              memo: null,
            ),
          );

          record.updatePolicy(newPolicy);

          expect(record.policy.commercialUseAllowed, isFalse);

          final events = record.events();
          expect(events.length, equals(1));
          expect(events.first, isA<LicensePolicyUpdated>());
        });

        test('rejects update when status is not active.', () {
          final request = Builder(LicenseRegistrationRequestFactory()).build();

          final record = LicenseRecord.register(
            request: request,
            trackIdentifier: Builder(TrackIdentifierFactory()).build(),
            licenseFilePath: Builder(FilePathFactory()).build(),
            licenseFileChecksum: Builder(ChecksumFactory()).build(),
          );

          record.events();

          final newPolicy = Builder(LicensePolicyFactory()).build();

          expect(
            () => record.updatePolicy(newPolicy),
            throwsA(isA<InvariantViolationError>()),
          );
        });
      });

      group('revoke', () {
        test(
          'revokes active license and sets redistributionAllowed=false.',
          () {
            final request = Builder(LicenseRegistrationRequestFactory()).build(
              overrides: (
                trackTitle: null,
                licenseName: null,
                licenseURL: null,
                attributionText: null,
                licenseText: null,
                policy: Builder(LicensePolicyFactory()).build(
                  overrides: (
                    commercialUseAllowed: true,
                    redistributionAllowed: true,
                    creditRequirement: null,
                    memo: null,
                  ),
                ),
                sourceURL: null,
              ),
            );

            final record = LicenseRecord.register(
              request: request,
              trackIdentifier: Builder(TrackIdentifierFactory()).build(),
              licenseFilePath: Builder(FilePathFactory()).build(),
              licenseFileChecksum: Builder(ChecksumFactory()).build(),
            );

            record.events();

            record.updateStatus(
              LicenseStatusEntry(
                status: LicenseStatus.active,
                changedAt: DateTime.now(),
                reason: 'Approved',
              ),
            );

            record.events();

            record.revoke('License violation');

            expect(record.currentStatus, equals(LicenseStatus.revoked));
            expect(record.policy.redistributionAllowed, isFalse);

            final events = record.events();
            expect(events.length, equals(1));
            expect(events.first, isA<LicenseRecordRevoked>());
          },
        );

        test('rejects revoke when status is not active.', () {
          final request = Builder(LicenseRegistrationRequestFactory()).build();

          final record = LicenseRecord.register(
            request: request,
            trackIdentifier: Builder(TrackIdentifierFactory()).build(),
            licenseFilePath: Builder(FilePathFactory()).build(),
            licenseFileChecksum: Builder(ChecksumFactory()).build(),
          );

          record.events();

          expect(
            () => record.revoke('Cannot revoke pending license'),
            throwsA(isA<InvariantViolationError>()),
          );
        });
      });

      group('snapshot', () {
        test('returns snapshot of current state.', () {
          final request = Builder(LicenseRegistrationRequestFactory()).build();

          final trackIdentifier = Builder(TrackIdentifierFactory()).build();

          final record = LicenseRecord.register(
            request: request,
            trackIdentifier: trackIdentifier,
            licenseFilePath: Builder(FilePathFactory()).build(),
            licenseFileChecksum: Builder(ChecksumFactory()).build(),
          );

          final snapshot = record.snapshot();

          expect(snapshot.trackTitle, equals(request.trackTitle));
          expect(snapshot.track, equals(trackIdentifier));
        });
      });
    });

    group('AttributionBook', () {
      group('appendEntry', () {
        test('appends entry with active license.', () async {
          final request = Builder(LicenseRegistrationRequestFactory()).build();

          final record = LicenseRecord.register(
            request: request,
            trackIdentifier: Builder(TrackIdentifierFactory()).build(),
            licenseFilePath: Builder(FilePathFactory()).build(),
            licenseFileChecksum: Builder(ChecksumFactory()).build(),
          );

          record.events();

          record.updateStatus(
            LicenseStatusEntry(
              status: LicenseStatus.active,
              changedAt: DateTime.now(),
              reason: 'Approved',
            ),
          );

          final repository = Builder(
            LicenseRecordRepositoryFactory(),
          ).build(overrides: (instances: [record], onPersist: null));

          final book = Builder(AttributionBookFactory()).build(
            overrides: (identifier: null, entries: [], publishedVersion: null),
          );

          final entry = Builder(AttributionEntryFactory()).build(
            overrides: (
              resource: null,
              displayName: null,
              attributionText: null,
              license: record.identifier,
              isValid: null,
            ),
          );

          await book.appendEntry(entry, repository);

          expect(book.entries.length, equals(1));

          final events = book.events();
          expect(events.length, equals(1));
          expect(events.first, isA<AttributionEntryAppended>());
        });

        test('rejects entry with non-active license.', () async {
          final request = Builder(LicenseRegistrationRequestFactory()).build();

          final record = LicenseRecord.register(
            request: request,
            trackIdentifier: Builder(TrackIdentifierFactory()).build(),
            licenseFilePath: Builder(FilePathFactory()).build(),
            licenseFileChecksum: Builder(ChecksumFactory()).build(),
          );

          final repository = Builder(
            LicenseRecordRepositoryFactory(),
          ).build(overrides: (instances: [record], onPersist: null));

          final book = Builder(AttributionBookFactory()).build(
            overrides: (identifier: null, entries: [], publishedVersion: null),
          );

          final entry = Builder(AttributionEntryFactory()).build(
            overrides: (
              resource: null,
              displayName: null,
              attributionText: null,
              license: record.identifier,
              isValid: null,
            ),
          );

          expect(
            () async => await book.appendEntry(entry, repository),
            throwsA(isA<InvariantViolationError>()),
          );
        });
      });

      group('invalidateEntriesByLicense', () {
        test('invalidates entries with matching license.', () {
          final license1 = Builder(LicenseIdentifierFactory()).build();

          final license2 = Builder(LicenseIdentifierFactory()).build();

          final book = Builder(AttributionBookFactory()).build(
            overrides: (
              identifier: null,
              entries: [
                Builder(AttributionEntryFactory()).build(
                  overrides: (
                    resource: null,
                    displayName: null,
                    attributionText: null,
                    license: license1,
                    isValid: true,
                  ),
                ),
                Builder(AttributionEntryFactory()).build(
                  overrides: (
                    resource: null,
                    displayName: null,
                    attributionText: null,
                    license: license2,
                    isValid: true,
                  ),
                ),
              ],
              publishedVersion: null,
            ),
          );

          book.invalidateEntriesByLicense(license1);

          expect(book.entries[0].isValid, isFalse);
          expect(book.entries[1].isValid, isTrue);

          final events = book.events();
          expect(events.length, equals(1));
          expect(events.first, isA<AttributionEntriesInvalidated>());
        });
      });

      group('publishVersion', () {
        test('publishes new version.', () {
          final book = Builder(AttributionBookFactory()).build(
            overrides: (identifier: null, entries: null, publishedVersion: 1),
          );

          book.publishVersion(2);

          expect(book.publishedVersion, equals(2));

          final events = book.events();
          expect(events.length, equals(1));
          expect(events.first, isA<AttributionBookPublished>());
        });

        test('rejects version not greater than current.', () {
          final book = Builder(AttributionBookFactory()).build(
            overrides: (identifier: null, entries: null, publishedVersion: 2),
          );

          expect(
            () => book.publishVersion(2),
            throwsA(isA<InvariantViolationError>()),
          );
        });
      });
    });
  });
}
