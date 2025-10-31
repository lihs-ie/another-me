import 'package:another_me/domains/common/error.dart';
import 'package:another_me/domains/common.dart' as common_domain;
import 'package:another_me/domains/import/import.dart' as import_domain;
import 'package:another_me/domains/library/asset.dart' as library_domain;
import 'package:another_me/domains/media/media.dart' as media_domain;
import 'package:another_me/use_cases/track.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../supports/factories/common.dart';
import '../../supports/factories/common/common.dart' as common_factory;
import '../../supports/factories/common/transaction.dart'
    as transaction_factory;
import '../../supports/factories/import/import.dart' as import_factory;
import '../../supports/factories/library/asset.dart' as library_factory;
import '../../supports/factories/media/media.dart' as media_factory;
import '../../supports/factories/profile/profile.dart' as profile_factory;

void main() {
  group('CatalogTrack', () {
    group('play', () {
      test('plays active track successfully.', () async {
        final trackIdentifier = Builder(
          media_factory.TrackIdentifierFactory(),
        ).build();

        final track = Builder(media_factory.TrackFactory()).buildWith(
          seed: 1,
          overrides: (
            identifier: trackIdentifier,
            title: null,
            artist: null,
            durationMs: null,
            audioFormat: null,
            localPath: null,
            fileChecksum: null,
            loopPoint: null,
            lufsTarget: null,
            license: null,
            allowOffline: true,
            catalogSource: null,
            status: media_domain.TrackStatus.active,
          ),
        );

        track.events();

        var persistCallCount = 0;
        var addToQueueCallCount = 0;

        final trackRepository = Builder(media_factory.TrackRepositoryFactory())
            .buildWith(
              seed: 1,
              overrides: (
                instances: [track],
                onPersist: (_) {
                  persistCallCount++;
                },
              ),
            );

        final playbackService =
            Builder(profile_factory.PlaybackServiceFactory()).buildWith(
              seed: 1,
              overrides: (
                onAddToQueue: (_, __) {
                  addToQueueCallCount++;
                },
              ),
            );

        final connectivityService = Builder(
          common_factory.NetworkConnectivityServiceFactory(),
        ).buildWith(seed: 1, overrides: (isOnline: true));

        final useCase = CatalogTrack(
          assetCatalogRepository: Builder(
            library_factory.AssetCatalogRepositoryFactory(),
          ).buildWith(seed: 1),
          catalogDownloadJobRepository: Builder(
            import_factory.CatalogDownloadJobRepositoryFactory(),
          ).buildWith(seed: 1),
          trackRepository: trackRepository,
          storagePathProvider: Builder(
            common_factory.ApplicationStoragePathProviderFactory(),
          ).buildWith(seed: 1),
          connectivityService: connectivityService,
          playbackService: playbackService,
          transaction: Builder(
            transaction_factory.TransactionFactory(),
          ).build(),
        );

        await useCase.play(
          trackIdentifier: trackIdentifier,
          playbackMode: common_domain.PlaybackMode.normal,
        );

        expect(addToQueueCallCount, equals(1));
        expect(persistCallCount, equals(1));

        final events = track.events();
        expect(events.length, equals(1));
        expect(events.first, isA<media_domain.TrackPlaybackStarted>());

        final event = events.first as media_domain.TrackPlaybackStarted;
        expect(event.trackIdentifier, equals(trackIdentifier));
        expect(event.playbackMode, contains('normal'));
      });

      test('throws TrackDeprecatedError when track is deprecated.', () async {
        final trackIdentifier = Builder(
          media_factory.TrackIdentifierFactory(),
        ).build();

        final track = Builder(media_factory.TrackFactory()).buildWith(
          seed: 1,
          overrides: (
            identifier: trackIdentifier,
            title: null,
            artist: null,
            durationMs: null,
            audioFormat: null,
            localPath: null,
            fileChecksum: null,
            loopPoint: null,
            lufsTarget: null,
            license: null,
            allowOffline: true,
            catalogSource: null,
            status: media_domain.TrackStatus.deprecated,
          ),
        );

        final trackRepository = Builder(
          media_factory.TrackRepositoryFactory(),
        ).buildWith(seed: 1, overrides: (instances: [track], onPersist: null));

        final useCase = CatalogTrack(
          assetCatalogRepository: Builder(
            library_factory.AssetCatalogRepositoryFactory(),
          ).buildWith(seed: 1),
          catalogDownloadJobRepository: Builder(
            import_factory.CatalogDownloadJobRepositoryFactory(),
          ).buildWith(seed: 1),
          trackRepository: trackRepository,
          storagePathProvider: Builder(
            common_factory.ApplicationStoragePathProviderFactory(),
          ).buildWith(seed: 1),
          connectivityService: Builder(
            common_factory.NetworkConnectivityServiceFactory(),
          ).buildWith(seed: 1),
          playbackService: Builder(
            profile_factory.PlaybackServiceFactory(),
          ).buildWith(seed: 1),
          transaction: Builder(
            transaction_factory.TransactionFactory(),
          ).build(),
        );

        expect(
          () async => await useCase.play(
            trackIdentifier: trackIdentifier,
            playbackMode: common_domain.PlaybackMode.normal,
          ),
          throwsA(isA<media_domain.TrackDeprecatedError>()),
        );
      });

      test(
        'throws OfflinePlaybackNotAllowedError when offline and allowOffline is false.',
        () async {
          final trackIdentifier = Builder(
            media_factory.TrackIdentifierFactory(),
          ).build();

          final track = Builder(media_factory.TrackFactory()).buildWith(
            seed: 1,
            overrides: (
              identifier: trackIdentifier,
              title: null,
              artist: null,
              durationMs: null,
              audioFormat: null,
              localPath: null,
              fileChecksum: null,
              loopPoint: null,
              lufsTarget: null,
              license: null,
              allowOffline: false,
              catalogSource: null,
              status: media_domain.TrackStatus.active,
            ),
          );

          final trackRepository =
              Builder(media_factory.TrackRepositoryFactory()).buildWith(
                seed: 1,
                overrides: (instances: [track], onPersist: null),
              );

          final connectivityService = Builder(
            common_factory.NetworkConnectivityServiceFactory(),
          ).buildWith(seed: 1, overrides: (isOnline: false));

          final useCase = CatalogTrack(
            assetCatalogRepository: Builder(
              library_factory.AssetCatalogRepositoryFactory(),
            ).buildWith(seed: 1),
            catalogDownloadJobRepository: Builder(
              import_factory.CatalogDownloadJobRepositoryFactory(),
            ).buildWith(seed: 1),
            trackRepository: trackRepository,
            storagePathProvider: Builder(
              common_factory.ApplicationStoragePathProviderFactory(),
            ).buildWith(seed: 1),
            connectivityService: connectivityService,
            playbackService: Builder(
              profile_factory.PlaybackServiceFactory(),
            ).buildWith(seed: 1),
            transaction: Builder(
              transaction_factory.TransactionFactory(),
            ).build(),
          );

          expect(
            () async => await useCase.play(
              trackIdentifier: trackIdentifier,
              playbackMode: common_domain.PlaybackMode.normal,
            ),
            throwsA(isA<media_domain.OfflinePlaybackNotAllowedError>()),
          );
        },
      );

      test(
        'plays successfully when offline and allowOffline is true.',
        () async {
          final trackIdentifier = Builder(
            media_factory.TrackIdentifierFactory(),
          ).build();

          final track = Builder(media_factory.TrackFactory()).buildWith(
            seed: 1,
            overrides: (
              identifier: trackIdentifier,
              title: null,
              artist: null,
              durationMs: null,
              audioFormat: null,
              localPath: null,
              fileChecksum: null,
              loopPoint: null,
              lufsTarget: null,
              license: null,
              allowOffline: true,
              catalogSource: null,
              status: media_domain.TrackStatus.active,
            ),
          );

          track.events();

          var addToQueueCallCount = 0;

          final trackRepository =
              Builder(media_factory.TrackRepositoryFactory()).buildWith(
                seed: 1,
                overrides: (instances: [track], onPersist: null),
              );

          final connectivityService = Builder(
            common_factory.NetworkConnectivityServiceFactory(),
          ).buildWith(seed: 1, overrides: (isOnline: false));

          final playbackService =
              Builder(profile_factory.PlaybackServiceFactory()).buildWith(
                seed: 1,
                overrides: (
                  onAddToQueue: (_, __) {
                    addToQueueCallCount++;
                  },
                ),
              );

          final useCase = CatalogTrack(
            assetCatalogRepository: Builder(
              library_factory.AssetCatalogRepositoryFactory(),
            ).buildWith(seed: 1),
            catalogDownloadJobRepository: Builder(
              import_factory.CatalogDownloadJobRepositoryFactory(),
            ).buildWith(seed: 1),
            trackRepository: trackRepository,
            storagePathProvider: Builder(
              common_factory.ApplicationStoragePathProviderFactory(),
            ).buildWith(seed: 1),
            connectivityService: connectivityService,
            playbackService: playbackService,
            transaction: Builder(
              transaction_factory.TransactionFactory(),
            ).build(),
          );

          await useCase.play(
            trackIdentifier: trackIdentifier,
            playbackMode: common_domain.PlaybackMode.normal,
          );

          expect(addToQueueCallCount, equals(1));

          final events = track.events();
          expect(events.length, equals(1));
          expect(events.first, isA<media_domain.TrackPlaybackStarted>());
        },
      );

      test('throws AggregateNotFoundError when track not found.', () async {
        final trackIdentifier = Builder(
          media_factory.TrackIdentifierFactory(),
        ).build();

        final trackRepository = Builder(
          media_factory.TrackRepositoryFactory(),
        ).buildWith(seed: 1, overrides: (instances: [], onPersist: null));

        final useCase = CatalogTrack(
          assetCatalogRepository: Builder(
            library_factory.AssetCatalogRepositoryFactory(),
          ).buildWith(seed: 1),
          catalogDownloadJobRepository: Builder(
            import_factory.CatalogDownloadJobRepositoryFactory(),
          ).buildWith(seed: 1),
          trackRepository: trackRepository,
          storagePathProvider: Builder(
            common_factory.ApplicationStoragePathProviderFactory(),
          ).buildWith(seed: 1),
          connectivityService: Builder(
            common_factory.NetworkConnectivityServiceFactory(),
          ).buildWith(seed: 1),
          playbackService: Builder(
            profile_factory.PlaybackServiceFactory(),
          ).buildWith(seed: 1),
          transaction: Builder(
            transaction_factory.TransactionFactory(),
          ).build(),
        );

        expect(
          () async => await useCase.play(
            trackIdentifier: trackIdentifier,
            playbackMode: common_domain.PlaybackMode.normal,
          ),
          throwsA(isA<AggregateNotFoundError>()),
        );
      });
    });

    group('download', () {
      test('creates download job successfully.', () async {
        final catalogTrackIdentifier = Builder(
          import_factory.CatalogTrackIdentifierFactory(),
        ).build();

        final trackMetadata =
            Builder(library_factory.TrackCatalogMetadataFactory()).buildWith(
              seed: 1,
              overrides: (
                track: catalogTrackIdentifier,
                title: null,
                artist: null,
                durationMilliseconds: null,
                format: null,
                loopPoint: null,
                downloadURL: null,
                checksum: null,
                licenseMetadata: null,
              ),
            );

        final assetPackage = Builder(library_factory.AssetPackageFactory())
            .buildWith(
              seed: 1,
              overrides: (
                identifier: null,
                type: library_domain.AssetPackageType.track,
                resources: null,
                checksum: null,
                animationSpecVersion: null,
                trackMetadata: trackMetadata,
              ),
            );

        final catalog = Builder(library_factory.AssetCatalogFactory())
            .buildWith(
              seed: 1,
              overrides: (
                identifier: null,
                version: null,
                minimumAppVersion: null,
                packages: [assetPackage],
                publishedAt: null,
                status: null,
              ),
            );

        var persistCallCount = 0;

        final catalogRepository =
            Builder(library_factory.AssetCatalogRepositoryFactory()).buildWith(
              seed: 1,
              overrides: (instances: [catalog], onPersist: null),
            );

        final jobRepository =
            Builder(
              import_factory.CatalogDownloadJobRepositoryFactory(),
            ).buildWith(
              seed: 1,
              overrides: (
                instances: [],
                onPersist: (_) {
                  persistCallCount++;
                },
              ),
            );

        final useCase = CatalogTrack(
          assetCatalogRepository: catalogRepository,
          catalogDownloadJobRepository: jobRepository,
          trackRepository: Builder(
            media_factory.TrackRepositoryFactory(),
          ).buildWith(seed: 1),
          storagePathProvider: Builder(
            common_factory.ApplicationStoragePathProviderFactory(),
          ).buildWith(seed: 1),
          connectivityService: Builder(
            common_factory.NetworkConnectivityServiceFactory(),
          ).buildWith(seed: 1),
          playbackService: Builder(
            profile_factory.PlaybackServiceFactory(),
          ).buildWith(seed: 1),
          transaction: Builder(
            transaction_factory.TransactionFactory(),
          ).build(),
        );

        final jobIdentifier = await useCase.download(
          catalogTrackIdentifier: catalogTrackIdentifier,
        );

        expect(jobIdentifier, isNotNull);
        expect(persistCallCount, equals(1));
      });

      test('throws AggregateNotFoundError when catalog not found.', () async {
        final catalogTrackIdentifier = Builder(
          import_factory.CatalogTrackIdentifierFactory(),
        ).build();

        final catalogRepository = Builder(
          library_factory.AssetCatalogRepositoryFactory(),
        ).buildWith(seed: 1, overrides: (instances: [], onPersist: null));

        final useCase = CatalogTrack(
          assetCatalogRepository: catalogRepository,
          catalogDownloadJobRepository: Builder(
            import_factory.CatalogDownloadJobRepositoryFactory(),
          ).buildWith(seed: 1),
          trackRepository: Builder(
            media_factory.TrackRepositoryFactory(),
          ).buildWith(seed: 1),
          storagePathProvider: Builder(
            common_factory.ApplicationStoragePathProviderFactory(),
          ).buildWith(seed: 1),
          connectivityService: Builder(
            common_factory.NetworkConnectivityServiceFactory(),
          ).buildWith(seed: 1),
          playbackService: Builder(
            profile_factory.PlaybackServiceFactory(),
          ).buildWith(seed: 1),
          transaction: Builder(
            transaction_factory.TransactionFactory(),
          ).build(),
        );

        expect(
          () async => await useCase.download(
            catalogTrackIdentifier: catalogTrackIdentifier,
          ),
          throwsA(isA<AggregateNotFoundError>()),
        );
      });
    });

    group('reDownload', () {
      test('retries failed job successfully.', () async {
        final catalogTrackIdentifier = Builder(
          import_factory.CatalogTrackIdentifierFactory(),
        ).build();

        final failureReason = Builder(import_factory.FailureReasonFactory())
            .buildWith(
              seed: 1,
              overrides: (
                code: import_domain.FailureCode.networkError,
                message: null,
              ),
            );

        final job = Builder(import_factory.CatalogDownloadJobFactory())
            .buildWith(
              seed: 1,
              overrides: (
                identifier: null,
                catalogTrack: catalogTrackIdentifier,
                downloadUrl: null,
                estimatedSizeBytes: null,
                metadata: null,
                status: import_domain.DownloadStatus.failed,
                timeline: null,
                checksums: null,
                retryState: Builder(import_factory.RetryStateFactory())
                    .buildWith(
                      seed: 1,
                      overrides: (failureReason: failureReason, retryCount: 1),
                    ),
                paths: null,
              ),
            );

        var persistCallCount = 0;

        final jobRepository =
            Builder(
              import_factory.CatalogDownloadJobRepositoryFactory(),
            ).buildWith(
              seed: 1,
              overrides: (
                instances: [job],
                onPersist: (_) {
                  persistCallCount++;
                },
              ),
            );

        final useCase = CatalogTrack(
          assetCatalogRepository: Builder(
            library_factory.AssetCatalogRepositoryFactory(),
          ).buildWith(seed: 1),
          catalogDownloadJobRepository: jobRepository,
          trackRepository: Builder(
            media_factory.TrackRepositoryFactory(),
          ).buildWith(seed: 1),
          storagePathProvider: Builder(
            common_factory.ApplicationStoragePathProviderFactory(),
          ).buildWith(seed: 1),
          connectivityService: Builder(
            common_factory.NetworkConnectivityServiceFactory(),
          ).buildWith(seed: 1),
          playbackService: Builder(
            profile_factory.PlaybackServiceFactory(),
          ).buildWith(seed: 1),
          transaction: Builder(
            transaction_factory.TransactionFactory(),
          ).build(),
        );

        await useCase.reDownload(jobIdentifier: job.identifier);

        expect(persistCallCount, equals(1));
        expect(job.status, equals(import_domain.DownloadStatus.pending));
        expect(job.retryState.retryCount, equals(2));

        final events = job.events();
        expect(events.isNotEmpty, isTrue);
        expect(
          events.any((e) => e is import_domain.CatalogDownloadQueued),
          isTrue,
        );
      });

      test(
        'throws InvalidStatusTransitionError when job is not failed.',
        () async {
          final catalogTrackIdentifier = Builder(
            import_factory.CatalogTrackIdentifierFactory(),
          ).build();

          final request =
              Builder(import_factory.CatalogDownloadRequestFactory()).buildWith(
                seed: 1,
                overrides: (
                  catalogTrack: catalogTrackIdentifier,
                  downloadURL: null,
                  estimatedSizeBytes: null,
                  targetPath: null,
                  metadata: null,
                ),
              );

          final job = import_domain.CatalogDownloadJob.queue(request);

          final jobRepository = Builder(
            import_factory.CatalogDownloadJobRepositoryFactory(),
          ).buildWith(seed: 1, overrides: (instances: [job], onPersist: null));

          final useCase = CatalogTrack(
            assetCatalogRepository: Builder(
              library_factory.AssetCatalogRepositoryFactory(),
            ).buildWith(seed: 1),
            catalogDownloadJobRepository: jobRepository,
            trackRepository: Builder(
              media_factory.TrackRepositoryFactory(),
            ).buildWith(seed: 1),
            storagePathProvider: Builder(
              common_factory.ApplicationStoragePathProviderFactory(),
            ).buildWith(seed: 1),
            connectivityService: Builder(
              common_factory.NetworkConnectivityServiceFactory(),
            ).buildWith(seed: 1),
            playbackService: Builder(
              profile_factory.PlaybackServiceFactory(),
            ).buildWith(seed: 1),
            transaction: Builder(
              transaction_factory.TransactionFactory(),
            ).build(),
          );

          expect(
            () async => await useCase.reDownload(jobIdentifier: job.identifier),
            throwsA(isA<import_domain.InvalidStatusTransitionError>()),
          );
        },
      );

      test('throws AggregateNotFoundError when job not found.', () async {
        final jobIdentifier = Builder(
          import_factory.CatalogDownloadJobIdentifierFactory(),
        ).build();

        final jobRepository = Builder(
          import_factory.CatalogDownloadJobRepositoryFactory(),
        ).buildWith(seed: 1, overrides: (instances: [], onPersist: null));

        final useCase = CatalogTrack(
          assetCatalogRepository: Builder(
            library_factory.AssetCatalogRepositoryFactory(),
          ).buildWith(seed: 1),
          catalogDownloadJobRepository: jobRepository,
          trackRepository: Builder(
            media_factory.TrackRepositoryFactory(),
          ).buildWith(seed: 1),
          storagePathProvider: Builder(
            common_factory.ApplicationStoragePathProviderFactory(),
          ).buildWith(seed: 1),
          connectivityService: Builder(
            common_factory.NetworkConnectivityServiceFactory(),
          ).buildWith(seed: 1),
          playbackService: Builder(
            profile_factory.PlaybackServiceFactory(),
          ).buildWith(seed: 1),
          transaction: Builder(
            transaction_factory.TransactionFactory(),
          ).build(),
        );

        expect(
          () async => await useCase.reDownload(jobIdentifier: jobIdentifier),
          throwsA(isA<AggregateNotFoundError>()),
        );
      });
    });
  });
}
