import 'package:another_me/domains/licensing.dart' as licensing_domain;
import 'package:another_me/use_cases/attribution.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../supports/factories/common.dart';
import '../../supports/factories/common/common.dart' as common_factory;
import '../../supports/factories/licensing/licensing.dart' as licensing_factory;
import '../../supports/factories/media/media.dart' as media_factory;

void main() {
  group('AttributionViewing', () {
    group('viewCredits', () {
      test('returns all attribution entries successfully.', () async {
        final attributionBook = Builder(
          licensing_factory.AttributionBookFactory(),
        ).build();

        final attributionBookRepository = Builder(
          licensing_factory.AttributionBookRepositoryFactory(),
        ).build(overrides: (book: attributionBook, onPersist: null));

        final licenseRecordRepository = Builder(
          licensing_factory.LicenseRecordRepositoryFactory(),
        ).build(overrides: (instances: [], onPersist: null));

        final useCase = AttributionViewing(
          attributionBookRepository: attributionBookRepository,
          licenseRecordRepository: licenseRecordRepository,
        );

        final entries = await useCase.viewCredits();

        expect(entries, isA<List<licensing_domain.AttributionEntry>>());
        expect(entries, equals(attributionBook.entries));
      });
    });

    group('viewLicenseDetail', () {
      test('returns license record for given identifier.', () async {
        final request = Builder(
          licensing_factory.LicenseRegistrationRequestFactory(),
        ).build();

        final licenseRecord = licensing_domain.LicenseRecord.register(
          request: request,
          trackIdentifier: Builder(
            media_factory.TrackIdentifierFactory(),
          ).build(),
          licenseFilePath: Builder(common_factory.FilePathFactory()).build(),
          licenseFileChecksum: Builder(
            common_factory.ChecksumFactory(),
          ).build(),
        );

        licenseRecord.events();

        final attributionBook = Builder(
          licensing_factory.AttributionBookFactory(),
        ).build();

        final attributionBookRepository = Builder(
          licensing_factory.AttributionBookRepositoryFactory(),
        ).build(overrides: (book: attributionBook, onPersist: null));

        final licenseRecordRepository = Builder(
          licensing_factory.LicenseRecordRepositoryFactory(),
        ).build(overrides: (instances: [licenseRecord], onPersist: null));

        final useCase = AttributionViewing(
          attributionBookRepository: attributionBookRepository,
          licenseRecordRepository: licenseRecordRepository,
        );

        final result = await useCase.viewLicenseDetail(
          licenseIdentifier: licenseRecord.identifier,
        );

        expect(result, isA<licensing_domain.LicenseRecord>());
        expect(result.identifier, equals(licenseRecord.identifier));
        expect(result.licenseName, equals(licenseRecord.licenseName));
      });
    });

    group('searchCredits', () {
      test('returns all entries when search text is null.', () async {
        final attributionBook = Builder(
          licensing_factory.AttributionBookFactory(),
        ).build();

        final attributionBookRepository = Builder(
          licensing_factory.AttributionBookRepositoryFactory(),
        ).build(overrides: (book: attributionBook, onPersist: null));

        final licenseRecordRepository = Builder(
          licensing_factory.LicenseRecordRepositoryFactory(),
        ).build(overrides: (instances: [], onPersist: null));

        final useCase = AttributionViewing(
          attributionBookRepository: attributionBookRepository,
          licenseRecordRepository: licenseRecordRepository,
        );

        final entries = await useCase.searchCredits(searchText: null);

        expect(entries, equals(attributionBook.entries));
      });

      test('returns all entries when search text is empty.', () async {
        final attributionBook = Builder(
          licensing_factory.AttributionBookFactory(),
        ).build();

        final attributionBookRepository = Builder(
          licensing_factory.AttributionBookRepositoryFactory(),
        ).build(overrides: (book: attributionBook, onPersist: null));

        final licenseRecordRepository = Builder(
          licensing_factory.LicenseRecordRepositoryFactory(),
        ).build(overrides: (instances: [], onPersist: null));

        final useCase = AttributionViewing(
          attributionBookRepository: attributionBookRepository,
          licenseRecordRepository: licenseRecordRepository,
        );

        final entries = await useCase.searchCredits(searchText: '');

        expect(entries, equals(attributionBook.entries));
      });

      test('filters entries by display name match.', () async {
        final request1 =
            Builder(
              licensing_factory.LicenseRegistrationRequestFactory(),
            ).build(
              overrides: (
                trackTitle: null,
                licenseName: 'MIT License',
                licenseURL: null,
                attributionText: null,
                licenseText: null,
                policy: null,
                sourceURL: null,
              ),
            );

        final licenseRecord1 = licensing_domain.LicenseRecord.register(
          request: request1,
          trackIdentifier: Builder(
            media_factory.TrackIdentifierFactory(),
          ).build(),
          licenseFilePath: Builder(common_factory.FilePathFactory()).build(),
          licenseFileChecksum: Builder(
            common_factory.ChecksumFactory(),
          ).build(),
        );

        licenseRecord1.events();

        final request2 =
            Builder(
              licensing_factory.LicenseRegistrationRequestFactory(),
            ).buildWith(
              seed: 2,
              overrides: (
                trackTitle: null,
                licenseName: 'Apache License',
                licenseURL: null,
                attributionText: null,
                licenseText: null,
                policy: null,
                sourceURL: null,
              ),
            );

        final licenseRecord2 = licensing_domain.LicenseRecord.register(
          request: request2,
          trackIdentifier: Builder(
            media_factory.TrackIdentifierFactory(),
          ).buildWith(seed: 2),
          licenseFilePath: Builder(
            common_factory.FilePathFactory(),
          ).buildWith(seed: 2),
          licenseFileChecksum: Builder(
            common_factory.ChecksumFactory(),
          ).buildWith(seed: 2),
        );

        licenseRecord2.events();

        final attributionEntry1 =
            Builder(licensing_factory.AttributionEntryFactory()).build(
              overrides: (
                resource: null,
                displayName: 'Test Library',
                attributionText: null,
                license: licenseRecord1.identifier,
                isValid: true,
              ),
            );

        final attributionEntry2 =
            Builder(licensing_factory.AttributionEntryFactory()).buildWith(
              seed: 2,
              overrides: (
                resource: null,
                displayName: 'Another Package',
                attributionText: null,
                license: licenseRecord2.identifier,
                isValid: true,
              ),
            );

        final attributionBook =
            Builder(licensing_factory.AttributionBookFactory()).build(
              overrides: (
                identifier: null,
                entries: [attributionEntry1, attributionEntry2],
                publishedVersion: null,
              ),
            );

        final attributionBookRepository = Builder(
          licensing_factory.AttributionBookRepositoryFactory(),
        ).build(overrides: (book: attributionBook, onPersist: null));

        final licenseRecordRepository =
            Builder(licensing_factory.LicenseRecordRepositoryFactory()).build(
              overrides: (
                instances: [licenseRecord1, licenseRecord2],
                onPersist: null,
              ),
            );

        final useCase = AttributionViewing(
          attributionBookRepository: attributionBookRepository,
          licenseRecordRepository: licenseRecordRepository,
        );

        final entries = await useCase.searchCredits(searchText: 'Library');

        expect(entries.length, equals(1));
        expect(entries.first.displayName, equals('Test Library'));
      });

      test('filters entries by attribution text match.', () async {
        final request = Builder(
          licensing_factory.LicenseRegistrationRequestFactory(),
        ).build();

        final licenseRecord = licensing_domain.LicenseRecord.register(
          request: request,
          trackIdentifier: Builder(
            media_factory.TrackIdentifierFactory(),
          ).build(),
          licenseFilePath: Builder(common_factory.FilePathFactory()).build(),
          licenseFileChecksum: Builder(
            common_factory.ChecksumFactory(),
          ).build(),
        );

        licenseRecord.events();

        final attributionText1 = Builder(
          licensing_factory.AttributionTextFactory(),
        ).buildWith(seed: 1, overrides: (text: 'Copyright 2024 Test Author'));

        final attributionText2 = Builder(
          licensing_factory.AttributionTextFactory(),
        ).buildWith(seed: 2, overrides: (text: 'Copyright 2024 Other Author'));

        final attributionEntry1 =
            Builder(licensing_factory.AttributionEntryFactory()).build(
              overrides: (
                resource: null,
                displayName: 'Package A',
                attributionText: attributionText1,
                license: licenseRecord.identifier,
                isValid: true,
              ),
            );

        final attributionEntry2 =
            Builder(licensing_factory.AttributionEntryFactory()).buildWith(
              seed: 2,
              overrides: (
                resource: null,
                displayName: 'Package B',
                attributionText: attributionText2,
                license: licenseRecord.identifier,
                isValid: true,
              ),
            );

        final attributionBook =
            Builder(licensing_factory.AttributionBookFactory()).build(
              overrides: (
                identifier: null,
                entries: [attributionEntry1, attributionEntry2],
                publishedVersion: null,
              ),
            );

        final attributionBookRepository = Builder(
          licensing_factory.AttributionBookRepositoryFactory(),
        ).build(overrides: (book: attributionBook, onPersist: null));

        final licenseRecordRepository = Builder(
          licensing_factory.LicenseRecordRepositoryFactory(),
        ).build(overrides: (instances: [licenseRecord], onPersist: null));

        final useCase = AttributionViewing(
          attributionBookRepository: attributionBookRepository,
          licenseRecordRepository: licenseRecordRepository,
        );

        final entries = await useCase.searchCredits(searchText: 'Test Author');

        expect(entries.length, equals(1));
        expect(entries.first.displayName, equals('Package A'));
      });

      test('filters entries by license name match.', () async {
        final request1 =
            Builder(
              licensing_factory.LicenseRegistrationRequestFactory(),
            ).build(
              overrides: (
                trackTitle: null,
                licenseName: 'MIT License',
                licenseURL: null,
                attributionText: null,
                licenseText: null,
                policy: null,
                sourceURL: null,
              ),
            );

        final licenseRecord1 = licensing_domain.LicenseRecord.register(
          request: request1,
          trackIdentifier: Builder(
            media_factory.TrackIdentifierFactory(),
          ).build(),
          licenseFilePath: Builder(common_factory.FilePathFactory()).build(),
          licenseFileChecksum: Builder(
            common_factory.ChecksumFactory(),
          ).build(),
        );

        licenseRecord1.events();

        final request2 =
            Builder(
              licensing_factory.LicenseRegistrationRequestFactory(),
            ).buildWith(
              seed: 2,
              overrides: (
                trackTitle: null,
                licenseName: 'Apache License 2.0',
                licenseURL: null,
                attributionText: null,
                licenseText: null,
                policy: null,
                sourceURL: null,
              ),
            );

        final licenseRecord2 = licensing_domain.LicenseRecord.register(
          request: request2,
          trackIdentifier: Builder(
            media_factory.TrackIdentifierFactory(),
          ).buildWith(seed: 2),
          licenseFilePath: Builder(
            common_factory.FilePathFactory(),
          ).buildWith(seed: 2),
          licenseFileChecksum: Builder(
            common_factory.ChecksumFactory(),
          ).buildWith(seed: 2),
        );

        licenseRecord2.events();

        final attributionEntry1 =
            Builder(licensing_factory.AttributionEntryFactory()).build(
              overrides: (
                resource: null,
                displayName: 'Package A',
                attributionText: null,
                license: licenseRecord1.identifier,
                isValid: true,
              ),
            );

        final attributionEntry2 =
            Builder(licensing_factory.AttributionEntryFactory()).buildWith(
              seed: 2,
              overrides: (
                resource: null,
                displayName: 'Package B',
                attributionText: null,
                license: licenseRecord2.identifier,
                isValid: true,
              ),
            );

        final attributionBook =
            Builder(licensing_factory.AttributionBookFactory()).build(
              overrides: (
                identifier: null,
                entries: [attributionEntry1, attributionEntry2],
                publishedVersion: null,
              ),
            );

        final attributionBookRepository = Builder(
          licensing_factory.AttributionBookRepositoryFactory(),
        ).build(overrides: (book: attributionBook, onPersist: null));

        final licenseRecordRepository =
            Builder(licensing_factory.LicenseRecordRepositoryFactory()).build(
              overrides: (
                instances: [licenseRecord1, licenseRecord2],
                onPersist: null,
              ),
            );

        final useCase = AttributionViewing(
          attributionBookRepository: attributionBookRepository,
          licenseRecordRepository: licenseRecordRepository,
        );

        final entries = await useCase.searchCredits(searchText: 'Apache');

        expect(entries.length, equals(1));
        expect(entries.first.displayName, equals('Package B'));
      });

      test('is case insensitive when searching.', () async {
        final request = Builder(
          licensing_factory.LicenseRegistrationRequestFactory(),
        ).build();

        final licenseRecord = licensing_domain.LicenseRecord.register(
          request: request,
          trackIdentifier: Builder(
            media_factory.TrackIdentifierFactory(),
          ).build(),
          licenseFilePath: Builder(common_factory.FilePathFactory()).build(),
          licenseFileChecksum: Builder(
            common_factory.ChecksumFactory(),
          ).build(),
        );

        licenseRecord.events();

        final attributionEntry =
            Builder(licensing_factory.AttributionEntryFactory()).build(
              overrides: (
                resource: null,
                displayName: 'Test Library',
                attributionText: null,
                license: licenseRecord.identifier,
                isValid: true,
              ),
            );

        final attributionBook =
            Builder(licensing_factory.AttributionBookFactory()).build(
              overrides: (
                identifier: null,
                entries: [attributionEntry],
                publishedVersion: null,
              ),
            );

        final attributionBookRepository = Builder(
          licensing_factory.AttributionBookRepositoryFactory(),
        ).build(overrides: (book: attributionBook, onPersist: null));

        final licenseRecordRepository = Builder(
          licensing_factory.LicenseRecordRepositoryFactory(),
        ).build(overrides: (instances: [licenseRecord], onPersist: null));

        final useCase = AttributionViewing(
          attributionBookRepository: attributionBookRepository,
          licenseRecordRepository: licenseRecordRepository,
        );

        final entries = await useCase.searchCredits(searchText: 'TEST LIBRARY');

        expect(entries.length, equals(1));
        expect(entries.first.displayName, equals('Test Library'));
      });
    });
  });
}
