import 'package:another_me/domains/common/storage.dart';
import 'package:another_me/domains/common/url.dart';
import 'package:another_me/domains/licensing/licensing.dart';
import 'package:another_me/domains/media/media.dart';

import '../common.dart';
import '../common/date.dart';
import '../common/error.dart';
import '../common/identifier.dart';
import '../common/storage.dart';
import '../common/url.dart';
import '../enum.dart';
import '../licensing/licensing.dart';
import '../string.dart';

class TrackIdentifierFactory
    extends ULIDBasedIdentifierFactory<TrackIdentifier> {
  TrackIdentifierFactory() : super((value) => TrackIdentifier(value: value));
}

typedef LoopPointOverrides = ({int? startMs, int? endMs, int? trackDurationMs});

class LoopPointFactory extends Factory<LoopPoint, LoopPointOverrides> {
  @override
  LoopPoint create({LoopPointOverrides? overrides, required int seed}) {
    final trackDurationMs =
        overrides?.trackDurationMs ?? ((seed % 300) + 60) * 1000;
    final startMs = overrides?.startMs ?? (seed % (trackDurationMs ~/ 2));
    final endMs =
        overrides?.endMs ??
        (startMs + ((seed % (trackDurationMs - startMs)) + 1));

    return LoopPoint(
      startMs: startMs,
      endMs: endMs,
      trackDurationMs: trackDurationMs,
    );
  }

  @override
  LoopPoint duplicate(LoopPoint instance, LoopPointOverrides? overrides) {
    final trackDurationMs =
        overrides?.trackDurationMs ?? instance.trackDurationMs;
    final startMs = overrides?.startMs ?? instance.startMs;
    final endMs = overrides?.endMs ?? instance.endMs;

    return LoopPoint(
      startMs: startMs,
      endMs: endMs,
      trackDurationMs: trackDurationMs,
    );
  }
}

typedef LufsValueOverrides = ({double? value});

class LufsValueFactory extends Factory<LufsValue, LufsValueOverrides> {
  @override
  LufsValue create({LufsValueOverrides? overrides, required int seed}) {
    final value = overrides?.value ?? -30.0 + ((seed % 300) / 10.0);

    return LufsValue(value: value);
  }

  @override
  LufsValue duplicate(LufsValue instance, LufsValueOverrides? overrides) {
    final value = overrides?.value ?? instance.value;

    return LufsValue(value: value);
  }
}

typedef CatalogSourceOverrides = ({String? catalogTrackID, URL? downloadURL});

class CatalogSourceFactory
    extends Factory<CatalogSource, CatalogSourceOverrides> {
  @override
  CatalogSource create({CatalogSourceOverrides? overrides, required int seed}) {
    final catalogTrackID =
        overrides?.catalogTrackID ?? 'catalog_track_${seed % 100000}';

    final downloadURL =
        overrides?.downloadURL ??
        Builder(URLFactory()).buildWith(
          overrides: (
            scheme: URLScheme.https,
            value: 'https://example.com/tracks/${seed % 100000}',
          ),
          seed: seed,
        );

    return CatalogSource(
      catalogTrackID: catalogTrackID,
      downloadURL: downloadURL,
    );
  }

  @override
  CatalogSource duplicate(
    CatalogSource instance,
    CatalogSourceOverrides? overrides,
  ) {
    final catalogTrackID = overrides?.catalogTrackID ?? instance.catalogTrackID;

    final downloadURL =
        overrides?.downloadURL ??
        Builder(URLFactory()).duplicate(instance: instance.downloadURL);

    return CatalogSource(
      catalogTrackID: catalogTrackID,
      downloadURL: downloadURL,
    );
  }
}

typedef TrackRegistrationRequestOverrides = ({
  TrackIdentifier? identifier,
  String? title,
  String? artist,
  int? durationMs,
  String? audioFormat,
  FilePath? localPath,
  Checksum? fileChecksum,
  LoopPoint? loopPoint,
  LufsValue? lufsTarget,
  LicenseIdentifier? license,
  String? catalogTrackID,
  URL? downloadURL,
});

class TrackRegistrationRequestFactory
    extends
        Factory<TrackRegistrationRequest, TrackRegistrationRequestOverrides> {
  @override
  TrackRegistrationRequest create({
    TrackRegistrationRequestOverrides? overrides,
    required int seed,
  }) {
    final identifier =
        overrides?.identifier ??
        Builder(TrackIdentifierFactory()).buildWith(seed: seed);

    final title =
        overrides?.title ?? StringFactory.create(seed: seed, min: 1, max: 100);

    final artist =
        overrides?.artist ?? StringFactory.create(seed: seed, min: 1, max: 100);

    final durationMs = overrides?.durationMs ?? ((seed % 300) + 60) * 1000;

    final audioFormats = ['aac', 'mp3', 'wav'];
    final audioFormat =
        overrides?.audioFormat ?? audioFormats[seed % audioFormats.length];

    final localPath =
        overrides?.localPath ??
        Builder(FilePathFactory()).buildWith(seed: seed);

    final fileChecksum =
        overrides?.fileChecksum ??
        Builder(ChecksumFactory()).buildWith(seed: seed);

    final loopPoint =
        overrides?.loopPoint ??
        Builder(LoopPointFactory()).buildWith(
          overrides: (startMs: null, endMs: null, trackDurationMs: durationMs),
          seed: seed,
        );

    final lufsTarget =
        overrides?.lufsTarget ??
        Builder(LufsValueFactory()).buildWith(seed: seed);

    final license =
        overrides?.license ??
        Builder(LicenseIdentifierFactory()).buildWith(seed: seed);

    final catalogTrackID =
        overrides?.catalogTrackID ?? 'catalog_track_${seed % 100000}';

    final downloadURL =
        overrides?.downloadURL ??
        Builder(URLFactory()).buildWith(
          overrides: (
            scheme: URLScheme.https,
            value: 'https://example.com/tracks/${seed % 100000}',
          ),
          seed: seed,
        );

    return TrackRegistrationRequest(
      identifier: identifier,
      title: title,
      artist: artist,
      durationMs: durationMs,
      audioFormat: audioFormat,
      localPath: localPath,
      fileChecksum: fileChecksum,
      loopPoint: loopPoint,
      lufsTarget: lufsTarget,
      license: license,
      catalogTrackID: catalogTrackID,
      downloadURL: downloadURL,
    );
  }

  @override
  TrackRegistrationRequest duplicate(
    TrackRegistrationRequest instance,
    TrackRegistrationRequestOverrides? overrides,
  ) {
    final identifier =
        overrides?.identifier ??
        Builder(
          TrackIdentifierFactory(),
        ).duplicate(instance: instance.identifier);

    final title = overrides?.title ?? instance.title;

    final artist = overrides?.artist ?? instance.artist;

    final durationMs = overrides?.durationMs ?? instance.durationMs;

    final audioFormat = overrides?.audioFormat ?? instance.audioFormat;

    final localPath =
        overrides?.localPath ??
        Builder(FilePathFactory()).duplicate(instance: instance.localPath);

    final fileChecksum =
        overrides?.fileChecksum ??
        Builder(ChecksumFactory()).duplicate(instance: instance.fileChecksum);

    final loopPoint =
        overrides?.loopPoint ??
        Builder(
          LoopPointFactory(),
        ).duplicate(instance: instance.loopPoint, overrides: null);

    final lufsTarget =
        overrides?.lufsTarget ??
        Builder(
          LufsValueFactory(),
        ).duplicate(instance: instance.lufsTarget, overrides: null);

    final license =
        overrides?.license ??
        Builder(
          LicenseIdentifierFactory(),
        ).duplicate(instance: instance.license);

    final catalogTrackID = overrides?.catalogTrackID ?? instance.catalogTrackID;

    final downloadURL =
        overrides?.downloadURL ??
        Builder(URLFactory()).duplicate(instance: instance.downloadURL);

    return TrackRegistrationRequest(
      identifier: identifier,
      title: title,
      artist: artist,
      durationMs: durationMs,
      audioFormat: audioFormat,
      localPath: localPath,
      fileChecksum: fileChecksum,
      loopPoint: loopPoint,
      lufsTarget: lufsTarget,
      license: license,
      catalogTrackID: catalogTrackID,
      downloadURL: downloadURL,
    );
  }
}

class TrackStatusFactory extends EnumFactory<TrackStatus> {
  TrackStatusFactory() : super(TrackStatus.values);
}

typedef TrackOverrides = ({
  TrackIdentifier? identifier,
  String? title,
  String? artist,
  int? durationMs,
  String? audioFormat,
  FilePath? localPath,
  Checksum? fileChecksum,
  LoopPoint? loopPoint,
  LufsValue? lufsTarget,
  LicenseIdentifier? license,
  CatalogSource? catalogSource,
  TrackStatus? status,
});

class TrackFactory extends Factory<Track, TrackOverrides> {
  @override
  Track create({TrackOverrides? overrides, required int seed}) {
    final request = Builder(TrackRegistrationRequestFactory()).buildWith(
      overrides: (
        identifier: overrides?.identifier,
        title: overrides?.title,
        artist: overrides?.artist,
        durationMs: overrides?.durationMs,
        audioFormat: overrides?.audioFormat,
        localPath: overrides?.localPath,
        fileChecksum: overrides?.fileChecksum,
        loopPoint: overrides?.loopPoint,
        lufsTarget: overrides?.lufsTarget,
        license: overrides?.license,
        catalogTrackID: overrides?.catalogSource?.catalogTrackID,
        downloadURL: overrides?.catalogSource?.downloadURL,
      ),
      seed: seed,
    );

    return Track.registerFromCatalog(request);
  }

  @override
  Track duplicate(Track instance, TrackOverrides? overrides) {
    throw UnimplementedError(
      'Track.duplicate is not implemented because Track has private fields. '
      'Use create with overrides instead.',
    );
  }
}

class PlaylistIdentifierFactory
    extends ULIDBasedIdentifierFactory<PlaylistIdentifier> {
  PlaylistIdentifierFactory()
    : super((value) => PlaylistIdentifier(value: value));
}

class PlaylistEntryIdentifierFactory
    extends ULIDBasedIdentifierFactory<PlaylistEntryIdentifier> {
  PlaylistEntryIdentifierFactory()
    : super((value) => PlaylistEntryIdentifier(value: value));
}

typedef RepeatPolicyOverrides = ({LoopMode? mode});

class RepeatPolicyFactory extends Factory<RepeatPolicy, RepeatPolicyOverrides> {
  @override
  RepeatPolicy create({RepeatPolicyOverrides? overrides, required int seed}) {
    final mode =
        overrides?.mode ?? Builder(LoopModeFactory()).buildWith(seed: seed);

    return RepeatPolicy(mode: mode);
  }

  @override
  RepeatPolicy duplicate(
    RepeatPolicy instance,
    RepeatPolicyOverrides? overrides,
  ) {
    final mode =
        overrides?.mode ??
        Builder(LoopModeFactory()).duplicate(instance: instance.mode);

    return RepeatPolicy(mode: mode);
  }
}

class LoopModeFactory extends EnumFactory<LoopMode> {
  LoopModeFactory() : super(LoopMode.values);
}

typedef PlaylistEntryOverrides = ({
  PlaylistEntryIdentifier? identifier,
  TrackIdentifier? track,
  int? orderIndex,
  DateTime? addedAt,
});

class PlaylistEntryFactory
    extends Factory<PlaylistEntry, PlaylistEntryOverrides> {
  @override
  PlaylistEntry create({PlaylistEntryOverrides? overrides, required int seed}) {
    final identifier =
        overrides?.identifier ??
        Builder(PlaylistEntryIdentifierFactory()).buildWith(seed: seed);

    final track =
        overrides?.track ??
        Builder(TrackIdentifierFactory()).buildWith(seed: seed);

    final orderIndex = overrides?.orderIndex ?? (seed % 100);

    final addedAt =
        overrides?.addedAt ?? Builder(DateTimeFactory()).buildWith(seed: seed);

    return PlaylistEntry(
      identifier: identifier,
      track: track,
      orderIndex: orderIndex,
      addedAt: addedAt,
    );
  }

  @override
  PlaylistEntry duplicate(
    PlaylistEntry instance,
    PlaylistEntryOverrides? overrides,
  ) {
    final identifier =
        overrides?.identifier ??
        Builder(
          PlaylistEntryIdentifierFactory(),
        ).duplicate(instance: instance.identifier);

    final track =
        overrides?.track ??
        Builder(TrackIdentifierFactory()).duplicate(instance: instance.track);

    final orderIndex = overrides?.orderIndex ?? instance.orderIndex;

    final addedAt =
        overrides?.addedAt ??
        Builder(DateTimeFactory()).duplicate(instance: instance.addedAt);

    return PlaylistEntry(
      identifier: identifier,
      track: track,
      orderIndex: orderIndex,
      addedAt: addedAt,
    );
  }
}

typedef PlaylistOverrides = ({
  PlaylistIdentifier? identifier,
  String? name,
  List<PlaylistEntry>? entries,
  RepeatPolicy? repeatPolicy,
  bool? allowDuplicates,
  DateTime? createdAt,
  DateTime? updatedAt,
});

class PlaylistFactory extends Factory<Playlist, PlaylistOverrides> {
  @override
  Playlist create({PlaylistOverrides? overrides, required int seed}) {
    final identifier =
        overrides?.identifier ??
        Builder(PlaylistIdentifierFactory()).buildWith(seed: seed);

    final name =
        overrides?.name ?? StringFactory.create(seed: seed, min: 1, max: 100);

    final repeatPolicy =
        overrides?.repeatPolicy ??
        Builder(RepeatPolicyFactory()).buildWith(seed: seed);

    final allowDuplicates = overrides?.allowDuplicates ?? (seed % 2 == 0);

    return Playlist.create(
      identifier: identifier,
      name: name,
      repeatPolicy: repeatPolicy,
      allowDuplicates: allowDuplicates,
    );
  }

  @override
  Playlist duplicate(Playlist instance, PlaylistOverrides? overrides) {
    throw UnimplementedError(
      'Playlist.duplicate is not implemented because Playlist has private fields. '
      'Use create with overrides instead.',
    );
  }
}

typedef TrackRepositoryOverrides = ({
  List<Track>? instances,
  void Function(Track)? onPersist,
});

class _TrackRepository implements TrackRepository {
  final Map<TrackIdentifier, Track> _instances;
  final void Function(Track)? _onPersist;

  _TrackRepository({
    required List<Track> instances,
    void Function(Track)? onPersist,
  }) : _instances = {
         for (final instance in instances) instance.identifier: instance,
       },
       _onPersist = onPersist;

  @override
  Future<Track> find(TrackIdentifier identifier) {
    final instance = _instances[identifier];

    if (instance == null) {
      throw AggregateNotFoundError(
        'Track with identifier ${identifier.value} not found.',
      );
    }

    return Future.value(instance);
  }

  @override
  Future<List<Track>> all() {
    return Future.value(_instances.values.toList());
  }

  @override
  Future<void> persist(Track track) {
    _instances[track.identifier] = track;

    if (_onPersist != null) {
      _onPersist(track);
    }

    return Future.value();
  }

  @override
  Future<void> terminate(TrackIdentifier identifier) {
    _instances.remove(identifier);

    return Future.value();
  }
}

class TrackRepositoryFactory
    extends Factory<TrackRepository, TrackRepositoryOverrides> {
  @override
  TrackRepository create({
    TrackRepositoryOverrides? overrides,
    required int seed,
  }) {
    final instances =
        overrides?.instances ??
        Builder(
          TrackFactory(),
        ).buildListWith(count: (seed % 10) + 1, seed: seed);

    return _TrackRepository(
      instances: instances,
      onPersist: overrides?.onPersist,
    );
  }

  @override
  TrackRepository duplicate(
    TrackRepository instance,
    TrackRepositoryOverrides? overrides,
  ) {
    throw UnimplementedError();
  }
}

typedef PlaylistRepositoryOverrides = ({
  List<Playlist>? instances,
  void Function(Playlist)? onPersist,
});

class _PlaylistRepository implements PlaylistRepository {
  final Map<PlaylistIdentifier, Playlist> _instances;
  final void Function(Playlist)? _onPersist;

  _PlaylistRepository({
    required List<Playlist> instances,
    void Function(Playlist)? onPersist,
  }) : _instances = {
         for (final instance in instances) instance.identifier: instance,
       },
       _onPersist = onPersist;

  @override
  Future<Playlist> find(PlaylistIdentifier identifier) {
    final instance = _instances[identifier];

    if (instance == null) {
      throw AggregateNotFoundError(
        'Playlist with identifier ${identifier.value} not found.',
      );
    }

    return Future.value(instance);
  }

  @override
  Future<List<Playlist>> all() {
    return Future.value(_instances.values.toList());
  }

  @override
  Future<void> persist(Playlist playlist) {
    _instances[playlist.identifier] = playlist;

    if (_onPersist != null) {
      _onPersist(playlist);
    }

    return Future.value();
  }

  @override
  Future<void> terminate(PlaylistIdentifier identifier) {
    _instances.remove(identifier);

    return Future.value();
  }
}

class PlaylistRepositoryFactory
    extends Factory<PlaylistRepository, PlaylistRepositoryOverrides> {
  @override
  PlaylistRepository create({
    PlaylistRepositoryOverrides? overrides,
    required int seed,
  }) {
    final instances =
        overrides?.instances ??
        Builder(
          PlaylistFactory(),
        ).buildListWith(count: (seed % 10) + 1, seed: seed);

    return _PlaylistRepository(
      instances: instances,
      onPersist: overrides?.onPersist,
    );
  }

  @override
  PlaylistRepository duplicate(
    PlaylistRepository instance,
    PlaylistRepositoryOverrides? overrides,
  ) {
    throw UnimplementedError();
  }
}

typedef EntitlementServiceOverrides = ({
  bool Function(int currentTrackCount)? canAddTrack,
  int? trackLimit,
});

class _EntitlementService implements EntitlementService {
  final bool Function(int currentTrackCount) _canAddTrack;
  final int _trackLimit;

  _EntitlementService({
    required bool Function(int currentTrackCount) canAddTrack,
    required int trackLimit,
  }) : _canAddTrack = canAddTrack,
       _trackLimit = trackLimit;

  @override
  bool canAddTrack({required int currentTrackCount}) {
    return _canAddTrack(currentTrackCount);
  }

  @override
  int getTrackLimit() {
    return _trackLimit;
  }
}

class EntitlementServiceFactory
    extends Factory<EntitlementService, EntitlementServiceOverrides> {
  @override
  EntitlementService create({
    EntitlementServiceOverrides? overrides,
    required int seed,
  }) {
    final trackLimit = overrides?.trackLimit ?? ((seed % 100) + 10);

    final canAddTrack =
        overrides?.canAddTrack ??
        (int currentTrackCount) => currentTrackCount < trackLimit;

    return _EntitlementService(
      canAddTrack: canAddTrack,
      trackLimit: trackLimit,
    );
  }

  @override
  EntitlementService duplicate(
    EntitlementService instance,
    EntitlementServiceOverrides? overrides,
  ) {
    throw UnimplementedError();
  }
}

typedef TrackRegisteredOverrides = ({
  TrackIdentifier? identifier,
  LicenseIdentifier? license,
  int? durationMs,
  DateTime? occurredAt,
});

class TrackRegisteredFactory
    extends Factory<TrackRegistered, TrackRegisteredOverrides> {
  @override
  TrackRegistered create({
    TrackRegisteredOverrides? overrides,
    required int seed,
  }) {
    final identifier =
        overrides?.identifier ??
        Builder(TrackIdentifierFactory()).buildWith(seed: seed);

    final license =
        overrides?.license ??
        Builder(LicenseIdentifierFactory()).buildWith(seed: seed);

    final durationMs = overrides?.durationMs ?? ((seed % 300) + 60) * 1000;

    final occurredAt =
        overrides?.occurredAt ??
        Builder(DateTimeFactory()).buildWith(seed: seed);

    return TrackRegistered(
      identifier: identifier,
      license: license,
      durationMs: durationMs,
      occurredAt: occurredAt,
    );
  }

  @override
  TrackRegistered duplicate(
    TrackRegistered instance,
    TrackRegisteredOverrides? overrides,
  ) {
    final identifier =
        overrides?.identifier ??
        Builder(
          TrackIdentifierFactory(),
        ).duplicate(instance: instance.identifier);

    final license =
        overrides?.license ??
        Builder(
          LicenseIdentifierFactory(),
        ).duplicate(instance: instance.license);

    final durationMs = overrides?.durationMs ?? instance.durationMs;

    final occurredAt =
        overrides?.occurredAt ??
        Builder(DateTimeFactory()).duplicate(instance: instance.occurredAt);

    return TrackRegistered(
      identifier: identifier,
      license: license,
      durationMs: durationMs,
      occurredAt: occurredAt,
    );
  }
}

typedef TrackMetadataUpdatedOverrides = ({
  TrackIdentifier? identifier,
  String? title,
  String? artist,
  DateTime? occurredAt,
});

class TrackMetadataUpdatedFactory
    extends Factory<TrackMetadataUpdated, TrackMetadataUpdatedOverrides> {
  @override
  TrackMetadataUpdated create({
    TrackMetadataUpdatedOverrides? overrides,
    required int seed,
  }) {
    final identifier =
        overrides?.identifier ??
        Builder(TrackIdentifierFactory()).buildWith(seed: seed);

    final title =
        overrides?.title ?? StringFactory.create(seed: seed, min: 1, max: 100);

    final artist =
        overrides?.artist ?? StringFactory.create(seed: seed, min: 1, max: 100);

    final occurredAt =
        overrides?.occurredAt ??
        Builder(DateTimeFactory()).buildWith(seed: seed);

    return TrackMetadataUpdated(
      identifier: identifier,
      title: title,
      artist: artist,
      occurredAt: occurredAt,
    );
  }

  @override
  TrackMetadataUpdated duplicate(
    TrackMetadataUpdated instance,
    TrackMetadataUpdatedOverrides? overrides,
  ) {
    final identifier =
        overrides?.identifier ??
        Builder(
          TrackIdentifierFactory(),
        ).duplicate(instance: instance.identifier);

    final title = overrides?.title ?? instance.title;

    final artist = overrides?.artist ?? instance.artist;

    final occurredAt =
        overrides?.occurredAt ??
        Builder(DateTimeFactory()).duplicate(instance: instance.occurredAt);

    return TrackMetadataUpdated(
      identifier: identifier,
      title: title,
      artist: artist,
      occurredAt: occurredAt,
    );
  }
}

typedef TrackDeprecatedOverrides = ({
  TrackIdentifier? identifier,
  String? reason,
  DateTime? occurredAt,
});

class TrackDeprecatedFactory
    extends Factory<TrackDeprecated, TrackDeprecatedOverrides> {
  @override
  TrackDeprecated create({
    TrackDeprecatedOverrides? overrides,
    required int seed,
  }) {
    final identifier =
        overrides?.identifier ??
        Builder(TrackIdentifierFactory()).buildWith(seed: seed);

    final reason =
        overrides?.reason ?? StringFactory.create(seed: seed, min: 1, max: 200);

    final occurredAt =
        overrides?.occurredAt ??
        Builder(DateTimeFactory()).buildWith(seed: seed);

    return TrackDeprecated(
      identifier: identifier,
      reason: reason,
      occurredAt: occurredAt,
    );
  }

  @override
  TrackDeprecated duplicate(
    TrackDeprecated instance,
    TrackDeprecatedOverrides? overrides,
  ) {
    final identifier =
        overrides?.identifier ??
        Builder(
          TrackIdentifierFactory(),
        ).duplicate(instance: instance.identifier);

    final reason = overrides?.reason ?? instance.reason;

    final occurredAt =
        overrides?.occurredAt ??
        Builder(DateTimeFactory()).duplicate(instance: instance.occurredAt);

    return TrackDeprecated(
      identifier: identifier,
      reason: reason,
      occurredAt: occurredAt,
    );
  }
}

typedef TrackRegistrationFailedOverrides = ({
  String? catalogTrackID,
  String? reason,
  DateTime? occurredAt,
});

class TrackRegistrationFailedFactory
    extends Factory<TrackRegistrationFailed, TrackRegistrationFailedOverrides> {
  @override
  TrackRegistrationFailed create({
    TrackRegistrationFailedOverrides? overrides,
    required int seed,
  }) {
    final catalogTrackID =
        overrides?.catalogTrackID ?? 'catalog_track_${seed % 100000}';

    final reason =
        overrides?.reason ?? StringFactory.create(seed: seed, min: 1, max: 200);

    final occurredAt =
        overrides?.occurredAt ??
        Builder(DateTimeFactory()).buildWith(seed: seed);

    return TrackRegistrationFailed(
      catalogTrackID: catalogTrackID,
      reason: reason,
      occurredAt: occurredAt,
    );
  }

  @override
  TrackRegistrationFailed duplicate(
    TrackRegistrationFailed instance,
    TrackRegistrationFailedOverrides? overrides,
  ) {
    final catalogTrackID = overrides?.catalogTrackID ?? instance.catalogTrackID;

    final reason = overrides?.reason ?? instance.reason;

    final occurredAt =
        overrides?.occurredAt ??
        Builder(DateTimeFactory()).duplicate(instance: instance.occurredAt);

    return TrackRegistrationFailed(
      catalogTrackID: catalogTrackID,
      reason: reason,
      occurredAt: occurredAt,
    );
  }
}

typedef PlaylistCreatedOverrides = ({
  PlaylistIdentifier? identifier,
  String? name,
  int? trackCount,
  DateTime? occurredAt,
});

class PlaylistCreatedFactory
    extends Factory<PlaylistCreated, PlaylistCreatedOverrides> {
  @override
  PlaylistCreated create({
    PlaylistCreatedOverrides? overrides,
    required int seed,
  }) {
    final identifier =
        overrides?.identifier ??
        Builder(PlaylistIdentifierFactory()).buildWith(seed: seed);

    final name =
        overrides?.name ?? StringFactory.create(seed: seed, min: 1, max: 100);

    final trackCount = overrides?.trackCount ?? (seed % 10);

    final occurredAt =
        overrides?.occurredAt ??
        Builder(DateTimeFactory()).buildWith(seed: seed);

    return PlaylistCreated(
      identifier: identifier,
      name: name,
      trackCount: trackCount,
      occurredAt: occurredAt,
    );
  }

  @override
  PlaylistCreated duplicate(
    PlaylistCreated instance,
    PlaylistCreatedOverrides? overrides,
  ) {
    final identifier =
        overrides?.identifier ??
        Builder(
          PlaylistIdentifierFactory(),
        ).duplicate(instance: instance.identifier);

    final name = overrides?.name ?? instance.name;

    final trackCount = overrides?.trackCount ?? instance.trackCount;

    final occurredAt =
        overrides?.occurredAt ??
        Builder(DateTimeFactory()).duplicate(instance: instance.occurredAt);

    return PlaylistCreated(
      identifier: identifier,
      name: name,
      trackCount: trackCount,
      occurredAt: occurredAt,
    );
  }
}

typedef PlaylistEntryAddedOverrides = ({
  PlaylistIdentifier? playlist,
  PlaylistEntryIdentifier? entry,
  TrackIdentifier? track,
  DateTime? occurredAt,
});

class PlaylistEntryAddedFactory
    extends Factory<PlaylistEntryAdded, PlaylistEntryAddedOverrides> {
  @override
  PlaylistEntryAdded create({
    PlaylistEntryAddedOverrides? overrides,
    required int seed,
  }) {
    final playlist =
        overrides?.playlist ??
        Builder(PlaylistIdentifierFactory()).buildWith(seed: seed);

    final entry =
        overrides?.entry ??
        Builder(PlaylistEntryIdentifierFactory()).buildWith(seed: seed);

    final track =
        overrides?.track ??
        Builder(TrackIdentifierFactory()).buildWith(seed: seed);

    final occurredAt =
        overrides?.occurredAt ??
        Builder(DateTimeFactory()).buildWith(seed: seed);

    return PlaylistEntryAdded(
      playlist: playlist,
      entry: entry,
      track: track,
      occurredAt: occurredAt,
    );
  }

  @override
  PlaylistEntryAdded duplicate(
    PlaylistEntryAdded instance,
    PlaylistEntryAddedOverrides? overrides,
  ) {
    final playlist =
        overrides?.playlist ??
        Builder(
          PlaylistIdentifierFactory(),
        ).duplicate(instance: instance.playlist);

    final entry =
        overrides?.entry ??
        Builder(
          PlaylistEntryIdentifierFactory(),
        ).duplicate(instance: instance.entry);

    final track =
        overrides?.track ??
        Builder(TrackIdentifierFactory()).duplicate(instance: instance.track);

    final occurredAt =
        overrides?.occurredAt ??
        Builder(DateTimeFactory()).duplicate(instance: instance.occurredAt);

    return PlaylistEntryAdded(
      playlist: playlist,
      entry: entry,
      track: track,
      occurredAt: occurredAt,
    );
  }
}

typedef PlaylistEntryRemovedOverrides = ({
  PlaylistIdentifier? playlist,
  PlaylistEntryIdentifier? entry,
  DateTime? occurredAt,
});

class PlaylistEntryRemovedFactory
    extends Factory<PlaylistEntryRemoved, PlaylistEntryRemovedOverrides> {
  @override
  PlaylistEntryRemoved create({
    PlaylistEntryRemovedOverrides? overrides,
    required int seed,
  }) {
    final playlist =
        overrides?.playlist ??
        Builder(PlaylistIdentifierFactory()).buildWith(seed: seed);

    final entry =
        overrides?.entry ??
        Builder(PlaylistEntryIdentifierFactory()).buildWith(seed: seed);

    final occurredAt =
        overrides?.occurredAt ??
        Builder(DateTimeFactory()).buildWith(seed: seed);

    return PlaylistEntryRemoved(
      playlist: playlist,
      entry: entry,
      occurredAt: occurredAt,
    );
  }

  @override
  PlaylistEntryRemoved duplicate(
    PlaylistEntryRemoved instance,
    PlaylistEntryRemovedOverrides? overrides,
  ) {
    final playlist =
        overrides?.playlist ??
        Builder(
          PlaylistIdentifierFactory(),
        ).duplicate(instance: instance.playlist);

    final entry =
        overrides?.entry ??
        Builder(
          PlaylistEntryIdentifierFactory(),
        ).duplicate(instance: instance.entry);

    final occurredAt =
        overrides?.occurredAt ??
        Builder(DateTimeFactory()).duplicate(instance: instance.occurredAt);

    return PlaylistEntryRemoved(
      playlist: playlist,
      entry: entry,
      occurredAt: occurredAt,
    );
  }
}

typedef PlaylistReorderedOverrides = ({
  PlaylistIdentifier? playlist,
  PlaylistEntryIdentifier? entry,
  int? newIndex,
  DateTime? occurredAt,
});

class PlaylistReorderedFactory
    extends Factory<PlaylistReordered, PlaylistReorderedOverrides> {
  @override
  PlaylistReordered create({
    PlaylistReorderedOverrides? overrides,
    required int seed,
  }) {
    final playlist =
        overrides?.playlist ??
        Builder(PlaylistIdentifierFactory()).buildWith(seed: seed);

    final entry =
        overrides?.entry ??
        Builder(PlaylistEntryIdentifierFactory()).buildWith(seed: seed);

    final newIndex = overrides?.newIndex ?? (seed % 100);

    final occurredAt =
        overrides?.occurredAt ??
        Builder(DateTimeFactory()).buildWith(seed: seed);

    return PlaylistReordered(
      playlist: playlist,
      entry: entry,
      newIndex: newIndex,
      occurredAt: occurredAt,
    );
  }

  @override
  PlaylistReordered duplicate(
    PlaylistReordered instance,
    PlaylistReorderedOverrides? overrides,
  ) {
    final playlist =
        overrides?.playlist ??
        Builder(
          PlaylistIdentifierFactory(),
        ).duplicate(instance: instance.playlist);

    final entry =
        overrides?.entry ??
        Builder(
          PlaylistEntryIdentifierFactory(),
        ).duplicate(instance: instance.entry);

    final newIndex = overrides?.newIndex ?? instance.newIndex;

    final occurredAt =
        overrides?.occurredAt ??
        Builder(DateTimeFactory()).duplicate(instance: instance.occurredAt);

    return PlaylistReordered(
      playlist: playlist,
      entry: entry,
      newIndex: newIndex,
      occurredAt: occurredAt,
    );
  }
}

typedef PlaylistDeletedOverrides = ({
  PlaylistIdentifier? identifier,
  DateTime? occurredAt,
});

class PlaylistDeletedFactory
    extends Factory<PlaylistDeleted, PlaylistDeletedOverrides> {
  @override
  PlaylistDeleted create({
    PlaylistDeletedOverrides? overrides,
    required int seed,
  }) {
    final identifier =
        overrides?.identifier ??
        Builder(PlaylistIdentifierFactory()).buildWith(seed: seed);

    final occurredAt =
        overrides?.occurredAt ??
        Builder(DateTimeFactory()).buildWith(seed: seed);

    return PlaylistDeleted(identifier: identifier, occurredAt: occurredAt);
  }

  @override
  PlaylistDeleted duplicate(
    PlaylistDeleted instance,
    PlaylistDeletedOverrides? overrides,
  ) {
    final identifier =
        overrides?.identifier ??
        Builder(
          PlaylistIdentifierFactory(),
        ).duplicate(instance: instance.identifier);

    final occurredAt =
        overrides?.occurredAt ??
        Builder(DateTimeFactory()).duplicate(instance: instance.occurredAt);

    return PlaylistDeleted(identifier: identifier, occurredAt: occurredAt);
  }
}

typedef PlaylistExceedsEntitlementLimitOverrides = ({
  PlaylistIdentifier? playlist,
  int? currentCount,
  int? limit,
  DateTime? occurredAt,
});

class PlaylistExceedsEntitlementLimitFactory
    extends
        Factory<
          PlaylistExceedsEntitlementLimit,
          PlaylistExceedsEntitlementLimitOverrides
        > {
  @override
  PlaylistExceedsEntitlementLimit create({
    PlaylistExceedsEntitlementLimitOverrides? overrides,
    required int seed,
  }) {
    final playlist =
        overrides?.playlist ??
        Builder(PlaylistIdentifierFactory()).buildWith(seed: seed);

    final currentCount = overrides?.currentCount ?? ((seed % 100) + 10);
    final limit = overrides?.limit ?? (seed % 100);

    final occurredAt =
        overrides?.occurredAt ??
        Builder(DateTimeFactory()).buildWith(seed: seed);

    return PlaylistExceedsEntitlementLimit(
      playlist: playlist,
      currentCount: currentCount,
      limit: limit,
      occurredAt: occurredAt,
    );
  }

  @override
  PlaylistExceedsEntitlementLimit duplicate(
    PlaylistExceedsEntitlementLimit instance,
    PlaylistExceedsEntitlementLimitOverrides? overrides,
  ) {
    final playlist =
        overrides?.playlist ??
        Builder(
          PlaylistIdentifierFactory(),
        ).duplicate(instance: instance.playlist);

    final currentCount = overrides?.currentCount ?? instance.currentCount;
    final limit = overrides?.limit ?? instance.limit;

    final occurredAt =
        overrides?.occurredAt ??
        Builder(DateTimeFactory()).duplicate(instance: instance.occurredAt);

    return PlaylistExceedsEntitlementLimit(
      playlist: playlist,
      currentCount: currentCount,
      limit: limit,
      occurredAt: occurredAt,
    );
  }
}
