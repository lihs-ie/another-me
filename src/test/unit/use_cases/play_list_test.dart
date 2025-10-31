import 'package:another_me/domains/common/error.dart';
import 'package:another_me/domains/media/media.dart' as media_domain;
import 'package:another_me/use_cases/play_list.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../supports/factories/common.dart';
import '../../supports/factories/common/transaction.dart'
    as transaction_factory;
import '../../supports/factories/media/media.dart' as media_factory;

void main() {
  group('PlaylistManagement', () {
    group('create', () {
      test('creates new playlist successfully.', () async {
        var persistCallCount = 0;
        media_domain.Playlist? persistedPlaylist;

        final playlistRepository =
            Builder(media_factory.PlaylistRepositoryFactory()).buildWith(
              seed: 1,
              overrides: (
                instances: [],
                onPersist: (playlist) {
                  persistCallCount++;
                  persistedPlaylist = playlist;
                },
                onTerminate: null,
              ),
            );

        final useCase = PlaylistManagement(
          playlistRepository: playlistRepository,
          trackRepository: Builder(
            media_factory.TrackRepositoryFactory(),
          ).buildWith(seed: 1),
          entitlementService: Builder(
            media_factory.EntitlementServiceFactory(),
          ).buildWith(seed: 1),
          transaction: Builder(
            transaction_factory.TransactionFactory(),
          ).build(),
        );

        final identifier = await useCase.create(
          name: 'Test Playlist',
          repeatPolicy: media_domain.RepeatPolicy(
            mode: media_domain.LoopMode.playlist,
          ),
          allowDuplicates: false,
        );

        expect(identifier, isA<media_domain.PlaylistIdentifier>());
        expect(persistCallCount, equals(1));
        expect(persistedPlaylist, isNotNull);
        expect(persistedPlaylist!.name, equals('Test Playlist'));
        expect(persistedPlaylist!.allowDuplicates, equals(false));
        expect(persistedPlaylist!.entries.length, equals(0));
      });
    });

    group('addTrack', () {
      test('adds track to playlist successfully.', () async {
        final playlistIdentifier = Builder(
          media_factory.PlaylistIdentifierFactory(),
        ).build();

        final trackIdentifier = Builder(
          media_factory.TrackIdentifierFactory(),
        ).build();

        final playlist = Builder(media_factory.PlaylistFactory()).buildWith(
          seed: 1,
          overrides: (
            identifier: playlistIdentifier,
            name: null,
            entries: null,
            repeatPolicy: null,
            allowDuplicates: true,
            createdAt: null,
            updatedAt: null,
          ),
        );

        playlist.clear();

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
            allowOffline: null,
            catalogSource: null,
            status: media_domain.TrackStatus.active,
          ),
        );

        track.events();

        var persistCallCount = 0;

        final playlistRepository =
            Builder(media_factory.PlaylistRepositoryFactory()).buildWith(
              seed: 1,
              overrides: (
                instances: [playlist],
                onPersist: (_) {
                  persistCallCount++;
                },
                onTerminate: null,
              ),
            );

        final trackRepository = Builder(
          media_factory.TrackRepositoryFactory(),
        ).buildWith(seed: 1, overrides: (instances: [track], onPersist: null));

        final entitlementService =
            Builder(media_factory.EntitlementServiceFactory()).buildWith(
              seed: 1,
              overrides: (canAddTrack: (_) => true, trackLimit: 100),
            );

        final useCase = PlaylistManagement(
          playlistRepository: playlistRepository,
          trackRepository: trackRepository,
          entitlementService: entitlementService,
          transaction: Builder(
            transaction_factory.TransactionFactory(),
          ).build(),
        );

        await useCase.addTrack(
          playlistIdentifier: playlistIdentifier,
          trackIdentifier: trackIdentifier,
        );

        expect(persistCallCount, equals(1));
        expect(playlist.entries.length, equals(1));
        expect(playlist.entries.first.track, equals(trackIdentifier));
      });

      test(
        'throws EntitlementLimitExceededError when limit reached.',
        () async {
          final playlistIdentifier = Builder(
            media_factory.PlaylistIdentifierFactory(),
          ).build();

          final trackIdentifier = Builder(
            media_factory.TrackIdentifierFactory(),
          ).build();

          final playlist = Builder(media_factory.PlaylistFactory()).buildWith(
            seed: 1,
            overrides: (
              identifier: playlistIdentifier,
              name: null,
              entries: null,
              repeatPolicy: null,
              allowDuplicates: true,
              createdAt: null,
              updatedAt: null,
            ),
          );

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
              allowOffline: null,
              catalogSource: null,
              status: media_domain.TrackStatus.active,
            ),
          );

          track.events();

          final playlistRepository =
              Builder(media_factory.PlaylistRepositoryFactory()).buildWith(
                seed: 1,
                overrides: (
                  instances: [playlist],
                  onPersist: null,
                  onTerminate: null,
                ),
              );

          final trackRepository =
              Builder(media_factory.TrackRepositoryFactory()).buildWith(
                seed: 1,
                overrides: (instances: [track], onPersist: null),
              );

          final entitlementService =
              Builder(media_factory.EntitlementServiceFactory()).buildWith(
                seed: 1,
                overrides: (canAddTrack: (_) => false, trackLimit: 0),
              );

          final useCase = PlaylistManagement(
            playlistRepository: playlistRepository,
            trackRepository: trackRepository,
            entitlementService: entitlementService,
            transaction: Builder(
              transaction_factory.TransactionFactory(),
            ).build(),
          );

          expect(
            () async => await useCase.addTrack(
              playlistIdentifier: playlistIdentifier,
              trackIdentifier: trackIdentifier,
            ),
            throwsA(isA<media_domain.EntitlementLimitExceededError>()),
          );
        },
      );

      test('throws AggregateNotFoundError when playlist not found.', () async {
        final playlistIdentifier = Builder(
          media_factory.PlaylistIdentifierFactory(),
        ).build();

        final trackIdentifier = Builder(
          media_factory.TrackIdentifierFactory(),
        ).build();

        final playlistRepository =
            Builder(media_factory.PlaylistRepositoryFactory()).buildWith(
              seed: 1,
              overrides: (instances: [], onPersist: null, onTerminate: null),
            );

        final trackRepository = Builder(
          media_factory.TrackRepositoryFactory(),
        ).buildWith(seed: 1, overrides: (instances: [], onPersist: null));

        final entitlementService =
            Builder(media_factory.EntitlementServiceFactory()).buildWith(
              seed: 1,
              overrides: (canAddTrack: (_) => true, trackLimit: 100),
            );

        final useCase = PlaylistManagement(
          playlistRepository: playlistRepository,
          trackRepository: trackRepository,
          entitlementService: entitlementService,
          transaction: Builder(
            transaction_factory.TransactionFactory(),
          ).build(),
        );

        expect(
          () async => await useCase.addTrack(
            playlistIdentifier: playlistIdentifier,
            trackIdentifier: trackIdentifier,
          ),
          throwsA(isA<AggregateNotFoundError>()),
        );
      });
    });

    group('reorder', () {
      test('reorders entries successfully.', () async {
        final playlistIdentifier = Builder(
          media_factory.PlaylistIdentifierFactory(),
        ).build();

        final playlist = Builder(media_factory.PlaylistFactory()).buildWith(
          seed: 1,
          overrides: (
            identifier: playlistIdentifier,
            name: null,
            entries: null,
            repeatPolicy: null,
            allowDuplicates: true,
            createdAt: null,
            updatedAt: null,
          ),
        );

        final entitlement = Builder(media_factory.EntitlementServiceFactory())
            .buildWith(
              seed: 1,
              overrides: (canAddTrack: (_) => true, trackLimit: 100),
            );

        final track1 = Builder(media_factory.TrackIdentifierFactory()).build();
        final track2 = Builder(media_factory.TrackIdentifierFactory()).build();
        final track3 = Builder(media_factory.TrackIdentifierFactory()).build();

        playlist.addTrack(
          track: track1,
          entitlement: entitlement,
          trackStatus: media_domain.TrackStatus.active,
        );
        playlist.addTrack(
          track: track2,
          entitlement: entitlement,
          trackStatus: media_domain.TrackStatus.active,
        );
        playlist.addTrack(
          track: track3,
          entitlement: entitlement,
          trackStatus: media_domain.TrackStatus.active,
        );

        final entryToMove = playlist.entries[0].identifier;
        playlist.clear();

        var persistCallCount = 0;

        final playlistRepository =
            Builder(media_factory.PlaylistRepositoryFactory()).buildWith(
              seed: 1,
              overrides: (
                instances: [playlist],
                onPersist: (_) {
                  persistCallCount++;
                },
                onTerminate: null,
              ),
            );

        final useCase = PlaylistManagement(
          playlistRepository: playlistRepository,
          trackRepository: Builder(
            media_factory.TrackRepositoryFactory(),
          ).buildWith(seed: 1),
          entitlementService: entitlement,
          transaction: Builder(
            transaction_factory.TransactionFactory(),
          ).build(),
        );

        await useCase.reorder(
          playlistIdentifier: playlistIdentifier,
          entryIdentifier: entryToMove,
          newIndex: 2,
        );

        expect(persistCallCount, equals(1));
        expect(playlist.entries[0].track, equals(track2));
        expect(playlist.entries[1].track, equals(track3));
        expect(playlist.entries[2].track, equals(track1));
      });
    });

    group('removeTrack', () {
      test('removes entry successfully.', () async {
        final playlistIdentifier = Builder(
          media_factory.PlaylistIdentifierFactory(),
        ).build();

        final playlist = Builder(media_factory.PlaylistFactory()).buildWith(
          seed: 1,
          overrides: (
            identifier: playlistIdentifier,
            name: null,
            entries: null,
            repeatPolicy: null,
            allowDuplicates: true,
            createdAt: null,
            updatedAt: null,
          ),
        );

        final entitlement = Builder(media_factory.EntitlementServiceFactory())
            .buildWith(
              seed: 1,
              overrides: (canAddTrack: (_) => true, trackLimit: 100),
            );

        final track1 = Builder(media_factory.TrackIdentifierFactory()).build();
        final track2 = Builder(media_factory.TrackIdentifierFactory()).build();

        playlist.addTrack(
          track: track1,
          entitlement: entitlement,
          trackStatus: media_domain.TrackStatus.active,
        );
        playlist.addTrack(
          track: track2,
          entitlement: entitlement,
          trackStatus: media_domain.TrackStatus.active,
        );

        final entryToRemove = playlist.entries[0].identifier;
        playlist.clear();

        var persistCallCount = 0;

        final playlistRepository =
            Builder(media_factory.PlaylistRepositoryFactory()).buildWith(
              seed: 1,
              overrides: (
                instances: [playlist],
                onPersist: (_) {
                  persistCallCount++;
                },
                onTerminate: null,
              ),
            );

        final useCase = PlaylistManagement(
          playlistRepository: playlistRepository,
          trackRepository: Builder(
            media_factory.TrackRepositoryFactory(),
          ).buildWith(seed: 1),
          entitlementService: entitlement,
          transaction: Builder(
            transaction_factory.TransactionFactory(),
          ).build(),
        );

        await useCase.removeTrack(
          playlistIdentifier: playlistIdentifier,
          entryIdentifier: entryToRemove,
        );

        expect(persistCallCount, equals(1));
        expect(playlist.entries.length, equals(1));
        expect(playlist.entries[0].track, equals(track2));
      });
    });

    group('delete', () {
      test('deletes playlist successfully.', () async {
        final playlistIdentifier = Builder(
          media_factory.PlaylistIdentifierFactory(),
        ).build();

        final playlist = Builder(media_factory.PlaylistFactory()).buildWith(
          seed: 1,
          overrides: (
            identifier: playlistIdentifier,
            name: null,
            entries: null,
            repeatPolicy: null,
            allowDuplicates: true,
            createdAt: null,
            updatedAt: null,
          ),
        );

        playlist.clear();

        var terminateCallCount = 0;
        media_domain.PlaylistIdentifier? terminatedIdentifier;

        final playlistRepository =
            Builder(media_factory.PlaylistRepositoryFactory()).buildWith(
              seed: 1,
              overrides: (
                instances: [playlist],
                onPersist: null,
                onTerminate: (identifier) {
                  terminateCallCount++;
                  terminatedIdentifier = identifier;
                },
              ),
            );

        final useCase = PlaylistManagement(
          playlistRepository: playlistRepository,
          trackRepository: Builder(
            media_factory.TrackRepositoryFactory(),
          ).buildWith(seed: 1),
          entitlementService: Builder(
            media_factory.EntitlementServiceFactory(),
          ).buildWith(seed: 1),
          transaction: Builder(
            transaction_factory.TransactionFactory(),
          ).build(),
        );

        await useCase.delete(playlistIdentifier: playlistIdentifier);

        expect(terminateCallCount, equals(1));
        expect(terminatedIdentifier, equals(playlistIdentifier));
        final events = playlist.events();
        expect(events.length, equals(1));
        expect(events.first, isA<media_domain.PlaylistDeleted>());
      });
    });
  });
}
