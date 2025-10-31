import 'package:another_me/domains/common/storage.dart';
import 'package:another_me/domains/common/url.dart';
import 'package:another_me/domains/common/variant.dart';
import 'package:another_me/domains/licensing/licensing.dart';
import 'package:another_me/domains/media/media.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulid/ulid.dart';

import '../../../supports/factories/common.dart';
import '../../../supports/factories/common/storage.dart';
import '../../../supports/factories/common/url.dart';
import '../../../supports/factories/licensing/licensing.dart';
import '../../../supports/factories/media/media.dart';
import '../common/identifier.dart';
import '../common/value_object.dart';

void main() {
  group('Package domains/media', () {
    ulidBasedIdentifierTest<TrackIdentifier, Ulid>(
      constructor: (Ulid value) => TrackIdentifier(value: value),
      generate: TrackIdentifier.generate,
      fromString: TrackIdentifier.fromString,
      fromBinary: TrackIdentifier.fromBinary,
    );

    ulidBasedIdentifierTest<PlaylistIdentifier, Ulid>(
      constructor: (Ulid value) => PlaylistIdentifier(value: value),
      generate: PlaylistIdentifier.generate,
      fromString: PlaylistIdentifier.fromString,
      fromBinary: PlaylistIdentifier.fromBinary,
    );

    ulidBasedIdentifierTest<PlaylistEntryIdentifier, Ulid>(
      constructor: (Ulid value) => PlaylistEntryIdentifier(value: value),
      generate: PlaylistEntryIdentifier.generate,
      fromString: PlaylistEntryIdentifier.fromString,
      fromBinary: PlaylistEntryIdentifier.fromBinary,
    );

    group('TrackStatus', () {
      test('declares all defined enumerators.', () {
        expect(TrackStatus.active, isA<TrackStatus>());
        expect(TrackStatus.deprecated, isA<TrackStatus>());
      });
    });

    group('LoopMode', () {
      test('declares all defined enumerators.', () {
        expect(LoopMode.single, isA<LoopMode>());
        expect(LoopMode.playlist, isA<LoopMode>());
        expect(LoopMode.none, isA<LoopMode>());
      });
    });

    valueObjectTest<
      LoopPoint,
      ({int startMs, int endMs, int trackDurationMs}),
      ({int startMs, int endMs, int trackDurationMs})
    >(
      constructor: (props) => LoopPoint(
        startMs: props.startMs,
        endMs: props.endMs,
        trackDurationMs: props.trackDurationMs,
      ),
      generator: () => (startMs: 1000, endMs: 5000, trackDurationMs: 10000),
      variations: (props) => [
        (
          startMs: 0,
          endMs: props.endMs,
          trackDurationMs: props.trackDurationMs,
        ),
        (
          startMs: props.startMs,
          endMs: 8000,
          trackDurationMs: props.trackDurationMs,
        ),
        (startMs: props.startMs, endMs: props.endMs, trackDurationMs: 15000),
      ],
      invalids: (props) => [
        (
          startMs: -1,
          endMs: props.endMs,
          trackDurationMs: props.trackDurationMs,
        ),
        (
          startMs: props.endMs,
          endMs: props.endMs,
          trackDurationMs: props.trackDurationMs,
        ),
        (
          startMs: props.startMs,
          endMs: props.trackDurationMs + 1,
          trackDurationMs: props.trackDurationMs,
        ),
      ],
    );

    valueObjectTest<LufsValue, ({double value}), ({double value})>(
      constructor: (props) => LufsValue(value: props.value),
      generator: () => (value: -14.0),
      variations: (props) => [(value: -30.0), (value: 0.0), (value: -20.5)],
      invalids: (props) => [
        (value: -30.1),
        (value: 0.1),
        (value: -31.0),
        (value: 1.0),
      ],
    );

    valueObjectTest<
      CatalogSource,
      ({String catalogTrackID, URL downloadURL}),
      ({String catalogTrackID, URL downloadURL})
    >(
      constructor: (props) => CatalogSource(
        catalogTrackID: props.catalogTrackID,
        downloadURL: props.downloadURL,
      ),
      generator: () => (
        catalogTrackID: 'catalog_track_123',
        downloadURL: Builder(URLFactory()).build(
          overrides: (
            scheme: URLScheme.https,
            value: 'https://example.com/track',
          ),
        ),
      ),
      variations: (props) => [
        (catalogTrackID: 'different_id', downloadURL: props.downloadURL),
        (
          catalogTrackID: props.catalogTrackID,
          downloadURL: Builder(URLFactory()).build(
            overrides: (
              scheme: URLScheme.https,
              value: 'https://example.com/other',
            ),
          ),
        ),
      ],
      invalids: (props) => [
        (catalogTrackID: '', downloadURL: props.downloadURL),
        (
          catalogTrackID: props.catalogTrackID,
          downloadURL: Builder(URLFactory()).build(
            overrides: (
              scheme: URLScheme.http,
              value: 'http://example.com/track',
            ),
          ),
        ),
        (
          catalogTrackID: props.catalogTrackID,
          downloadURL: Builder(URLFactory()).build(
            overrides: (
              scheme: URLScheme.ftp,
              value: 'ftp://example.com/track',
            ),
          ),
        ),
      ],
    );

    valueObjectTest<
      TrackRegistrationRequest,
      ({
        TrackIdentifier identifier,
        String title,
        String artist,
        int durationMs,
        String audioFormat,
        FilePath localPath,
        Checksum fileChecksum,
        LoopPoint loopPoint,
        LufsValue lufsTarget,
        LicenseIdentifier license,
        String catalogTrackID,
        URL downloadURL,
        bool allowOffline,
      }),
      ({
        TrackIdentifier identifier,
        String title,
        String artist,
        int durationMs,
        String audioFormat,
        FilePath localPath,
        Checksum fileChecksum,
        LoopPoint loopPoint,
        LufsValue lufsTarget,
        LicenseIdentifier license,
        String catalogTrackID,
        URL downloadURL,
        bool allowOffline,
      })
    >(
      constructor: (props) => TrackRegistrationRequest(
        identifier: props.identifier,
        title: props.title,
        artist: props.artist,
        durationMs: props.durationMs,
        audioFormat: props.audioFormat,
        localPath: props.localPath,
        fileChecksum: props.fileChecksum,
        loopPoint: props.loopPoint,
        lufsTarget: props.lufsTarget,
        license: props.license,
        catalogTrackID: props.catalogTrackID,
        downloadURL: props.downloadURL,
        allowOffline: props.allowOffline,
      ),
      generator: () => (
        identifier: Builder(TrackIdentifierFactory()).build(),
        title: 'Test Track',
        artist: 'Test Artist',
        durationMs: 180000,
        audioFormat: 'aac',
        localPath: Builder(FilePathFactory()).build(),
        fileChecksum: Builder(ChecksumFactory()).build(),
        loopPoint: Builder(LoopPointFactory()).build(
          overrides: (startMs: 1000, endMs: 5000, trackDurationMs: 180000),
        ),
        lufsTarget: Builder(LufsValueFactory()).build(),
        license: Builder(LicenseIdentifierFactory()).build(),
        catalogTrackID: 'catalog_track_123',
        downloadURL: Builder(URLFactory()).build(
          overrides: (
            scheme: URLScheme.https,
            value: 'https://example.com/track',
          ),
        ),
        allowOffline: true,
      ),
      variations: (props) => [
        (
          identifier: Builder(TrackIdentifierFactory()).build(),
          title: props.title,
          artist: props.artist,
          durationMs: props.durationMs,
          audioFormat: props.audioFormat,
          localPath: props.localPath,
          fileChecksum: props.fileChecksum,
          loopPoint: props.loopPoint,
          lufsTarget: props.lufsTarget,
          license: props.license,
          catalogTrackID: props.catalogTrackID,
          downloadURL: props.downloadURL,
          allowOffline: props.allowOffline,
        ),
        (
          identifier: props.identifier,
          title: 'Different Title',
          artist: props.artist,
          durationMs: props.durationMs,
          audioFormat: props.audioFormat,
          localPath: props.localPath,
          fileChecksum: props.fileChecksum,
          loopPoint: props.loopPoint,
          lufsTarget: props.lufsTarget,
          license: props.license,
          catalogTrackID: props.catalogTrackID,
          downloadURL: props.downloadURL,
          allowOffline: props.allowOffline,
        ),
        (
          identifier: props.identifier,
          title: props.title,
          artist: 'Different Artist',
          durationMs: props.durationMs,
          audioFormat: props.audioFormat,
          localPath: props.localPath,
          fileChecksum: props.fileChecksum,
          loopPoint: props.loopPoint,
          lufsTarget: props.lufsTarget,
          license: props.license,
          catalogTrackID: props.catalogTrackID,
          downloadURL: props.downloadURL,
          allowOffline: props.allowOffline,
        ),
      ],
      invalids: (props) => [
        (
          identifier: props.identifier,
          title: props.title,
          artist: props.artist,
          durationMs: 0,
          audioFormat: props.audioFormat,
          localPath: props.localPath,
          fileChecksum: props.fileChecksum,
          loopPoint: props.loopPoint,
          lufsTarget: props.lufsTarget,
          license: props.license,
          catalogTrackID: props.catalogTrackID,
          downloadURL: props.downloadURL,
          allowOffline: props.allowOffline,
        ),
        (
          identifier: props.identifier,
          title: props.title,
          artist: props.artist,
          durationMs: -1,
          audioFormat: props.audioFormat,
          localPath: props.localPath,
          fileChecksum: props.fileChecksum,
          loopPoint: props.loopPoint,
          lufsTarget: props.lufsTarget,
          license: props.license,
          catalogTrackID: props.catalogTrackID,
          downloadURL: props.downloadURL,
          allowOffline: props.allowOffline,
        ),
      ],
    );

    valueObjectTest<RepeatPolicy, ({LoopMode mode}), ({LoopMode mode})>(
      constructor: (props) => RepeatPolicy(mode: props.mode),
      generator: () => (mode: LoopMode.playlist),
      variations: (props) => [(mode: LoopMode.single), (mode: LoopMode.none)],
      invalids: (props) => [],
    );

    group('Track', () {
      test('can be registered from catalog.', () {
        final request = Builder(TrackRegistrationRequestFactory()).build();

        final track = Track.registerFromCatalog(request);

        expect(track.identifier, equals(request.identifier));
        expect(track.title, equals(request.title));
        expect(track.artist, equals(request.artist));
        expect(track.durationMs, equals(request.durationMs));
        expect(track.audioFormat, equals(request.audioFormat));
        expect(track.localPath, equals(request.localPath));
        expect(track.fileChecksum, equals(request.fileChecksum));
        expect(track.loopPoint, equals(request.loopPoint));
        expect(track.lufsTarget, equals(request.lufsTarget));
        expect(track.license, equals(request.license));
        expect(track.status, equals(TrackStatus.active));
        final events = track.events();
        expect(events.length, equals(1));
        expect(events.first, isA<TrackRegistered>());
      });

      test('can update metadata.', () {
        final track = Builder(TrackFactory()).build();
        track.clear();

        track.updateMetadata(title: 'New Title', artist: 'New Artist');

        final events = track.events();
        expect(events.length, equals(1));
        expect(events.first, isA<TrackMetadataUpdated>());
        final event = events.first as TrackMetadataUpdated;
        expect(event.title, equals('New Title'));
        expect(event.artist, equals('New Artist'));
      });

      test(
        'does not emit event when updateMetadata is called with no changes.',
        () {
          final track = Builder(TrackFactory()).build();
          track.clear();

          track.updateMetadata();

          expect(track.events().length, equals(0));
        },
      );

      test('can be marked as deprecated.', () {
        final track = Builder(TrackFactory()).build();
        track.clear();

        track.markDeprecated('Test reason');

        expect(track.status, equals(TrackStatus.deprecated));
        final events = track.events();
        expect(events.length, equals(1));
        expect(events.first, isA<TrackDeprecated>());
      });

      test('markDeprecated is idempotent.', () {
        final track = Builder(TrackFactory()).build();
        track.markDeprecated('First reason');
        track.clear();

        track.markDeprecated('Second reason');

        expect(track.status, equals(TrackStatus.deprecated));
        expect(track.events().length, equals(0));
      });
    });

    group('Playlist', () {
      test('can be created.', () {
        final identifier = Builder(PlaylistIdentifierFactory()).build();
        final name = 'Test Playlist';
        final repeatPolicy = Builder(RepeatPolicyFactory()).build();
        final allowDuplicates = true;

        final playlist = Playlist.create(
          identifier: identifier,
          name: name,
          repeatPolicy: repeatPolicy,
          allowDuplicates: allowDuplicates,
        );

        expect(playlist.identifier, equals(identifier));
        expect(playlist.name, equals(name));
        expect(playlist.repeatPolicy, equals(repeatPolicy));
        expect(playlist.allowDuplicates, equals(allowDuplicates));
        expect(playlist.entries.length, equals(0));
        final events = playlist.events();
        expect(events.length, equals(1));
        expect(events.first, isA<PlaylistCreated>());
      });

      test('can add track when entitlement allows.', () {
        final playlist = Builder(PlaylistFactory()).build();
        final trackIdentifier = Builder(TrackIdentifierFactory()).build();
        final entitlement = Builder(
          EntitlementServiceFactory(),
        ).build(overrides: (canAddTrack: (_) => true, trackLimit: 10));
        playlist.clear();

        playlist.addTrack(
          track: trackIdentifier,
          entitlement: entitlement,
          trackStatus: TrackStatus.active,
        );

        expect(playlist.entries.length, equals(1));
        expect(playlist.entries.first.track, equals(trackIdentifier));
        expect(playlist.entries.first.orderIndex, equals(0));
        final events = playlist.events();
        expect(events.length, equals(1));
        expect(events.first, isA<PlaylistEntryAdded>());
      });

      test(
        'throws EntitlementLimitExceededError when entitlement limit is reached.',
        () {
          final playlist = Builder(PlaylistFactory()).build();
          final trackIdentifier = Builder(TrackIdentifierFactory()).build();
          final entitlement = Builder(
            EntitlementServiceFactory(),
          ).build(overrides: (canAddTrack: (_) => false, trackLimit: 0));

          expect(
            () => playlist.addTrack(
              track: trackIdentifier,
              entitlement: entitlement,
              trackStatus: TrackStatus.active,
            ),
            throwsA(isA<EntitlementLimitExceededError>()),
          );
        },
      );

      test('throws InvariantViolationError when adding deprecated track.', () {
        final playlist = Builder(PlaylistFactory()).build();
        final trackIdentifier = Builder(TrackIdentifierFactory()).build();
        final entitlement = Builder(
          EntitlementServiceFactory(),
        ).build(overrides: (canAddTrack: (_) => true, trackLimit: 10));

        expect(
          () => playlist.addTrack(
            track: trackIdentifier,
            entitlement: entitlement,
            trackStatus: TrackStatus.deprecated,
          ),
          throwsA(isA<InvariantViolationError>()),
        );
      });

      test(
        'throws InvariantViolationError when adding duplicate track with allowDuplicates=false.',
        () {
          final playlist = Builder(PlaylistFactory()).build(
            overrides: (
              identifier: null,
              name: null,
              entries: null,
              repeatPolicy: null,
              allowDuplicates: false,
              createdAt: null,
              updatedAt: null,
            ),
          );
          final trackIdentifier = Builder(TrackIdentifierFactory()).build();
          final entitlement = Builder(
            EntitlementServiceFactory(),
          ).build(overrides: (canAddTrack: (_) => true, trackLimit: 10));

          playlist.addTrack(
            track: trackIdentifier,
            entitlement: entitlement,
            trackStatus: TrackStatus.active,
          );

          expect(
            () => playlist.addTrack(
              track: trackIdentifier,
              entitlement: entitlement,
              trackStatus: TrackStatus.active,
            ),
            throwsA(isA<InvariantViolationError>()),
          );
        },
      );

      test('can reorder tracks.', () {
        final playlist = Builder(PlaylistFactory()).build();
        final entitlement = Builder(
          EntitlementServiceFactory(),
        ).build(overrides: (canAddTrack: (_) => true, trackLimit: 10));
        final track1 = Builder(TrackIdentifierFactory()).build();
        final track2 = Builder(TrackIdentifierFactory()).build();
        final track3 = Builder(TrackIdentifierFactory()).build();

        playlist.addTrack(
          track: track1,
          entitlement: entitlement,
          trackStatus: TrackStatus.active,
        );
        playlist.addTrack(
          track: track2,
          entitlement: entitlement,
          trackStatus: TrackStatus.active,
        );
        playlist.addTrack(
          track: track3,
          entitlement: entitlement,
          trackStatus: TrackStatus.active,
        );
        final entryToMove = playlist.entries[0].identifier;
        playlist.clear();

        playlist.reorder(entry: entryToMove, newIndex: 2);

        expect(playlist.entries.length, equals(3));
        expect(playlist.entries[0].track, equals(track2));
        expect(playlist.entries[1].track, equals(track3));
        expect(playlist.entries[2].track, equals(track1));
        expect(playlist.entries[0].orderIndex, equals(0));
        expect(playlist.entries[1].orderIndex, equals(1));
        expect(playlist.entries[2].orderIndex, equals(2));
        final events = playlist.events();
        expect(events.length, equals(1));
        expect(events.first, isA<PlaylistReordered>());
      });

      test('throws ArgumentError when reorder newIndex is out of bounds.', () {
        final playlist = Builder(PlaylistFactory()).build();
        final entitlement = Builder(
          EntitlementServiceFactory(),
        ).build(overrides: (canAddTrack: (_) => true, trackLimit: 10));
        final track1 = Builder(TrackIdentifierFactory()).build();

        playlist.addTrack(
          track: track1,
          entitlement: entitlement,
          trackStatus: TrackStatus.active,
        );
        final entry = playlist.entries[0].identifier;

        expect(
          () => playlist.reorder(entry: entry, newIndex: 10),
          throwsArgumentError,
        );
      });

      test('can remove track.', () {
        final playlist = Builder(PlaylistFactory()).build();
        final entitlement = Builder(
          EntitlementServiceFactory(),
        ).build(overrides: (canAddTrack: (_) => true, trackLimit: 10));
        final track1 = Builder(TrackIdentifierFactory()).build();
        final track2 = Builder(TrackIdentifierFactory()).build();

        playlist.addTrack(
          track: track1,
          entitlement: entitlement,
          trackStatus: TrackStatus.active,
        );
        playlist.addTrack(
          track: track2,
          entitlement: entitlement,
          trackStatus: TrackStatus.active,
        );
        final entryToRemove = playlist.entries[0].identifier;
        playlist.clear();

        playlist.removeTrack(entry: entryToRemove);

        expect(playlist.entries.length, equals(1));
        expect(playlist.entries[0].track, equals(track2));
        expect(playlist.entries[0].orderIndex, equals(0));
        final events = playlist.events();
        expect(events.length, equals(1));
        expect(events.first, isA<PlaylistEntryRemoved>());
      });

      test('can be deleted.', () {
        final playlist = Builder(PlaylistFactory()).build();
        playlist.clear();

        playlist.delete();

        final events = playlist.events();
        expect(events.length, equals(1));
        expect(events.first, isA<PlaylistDeleted>());
        final deletedEvent = events.first as PlaylistDeleted;
        expect(deletedEvent.identifier, equals(playlist.identifier));
      });
    });
  });
}
