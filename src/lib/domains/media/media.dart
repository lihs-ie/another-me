import 'dart:typed_data';

import 'package:another_me/domains/common/event.dart';
import 'package:another_me/domains/common/identifier.dart';
import 'package:another_me/domains/common/storage.dart';
import 'package:another_me/domains/common/url.dart';
import 'package:another_me/domains/common/value_object.dart';
import 'package:another_me/domains/common/variant.dart';
import 'package:another_me/domains/licensing/licensing.dart';
import 'package:ulid/ulid.dart';

// ============================================================================
// Track Aggregate
// ============================================================================

class TrackIdentifier extends ULIDBasedIdentifier {
  TrackIdentifier({required Ulid value}) : super(value);

  factory TrackIdentifier.generate() => TrackIdentifier(value: Ulid());

  factory TrackIdentifier.fromString(String value) =>
      TrackIdentifier(value: Ulid.parse(value));

  factory TrackIdentifier.fromBinary(Uint8List bytes) =>
      TrackIdentifier(value: Ulid.fromBytes(bytes));

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! TrackIdentifier) {
      return false;
    }

    return value == other.value;
  }

  @override
  int get hashCode => value.hashCode;
}

class LoopPoint implements ValueObject {
  final int startMs;
  final int endMs;
  final int trackDurationMs;

  LoopPoint({
    required this.startMs,
    required this.endMs,
    required this.trackDurationMs,
  }) {
    if (startMs < 0 || startMs >= endMs || endMs > trackDurationMs) {
      throw InvariantViolationError(
        '0 <= startMs < endMs <= trackDurationMs must be satisfied.',
      );
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! LoopPoint) {
      return false;
    }

    return startMs == other.startMs &&
        endMs == other.endMs &&
        trackDurationMs == other.trackDurationMs;
  }

  @override
  int get hashCode => Object.hash(startMs, endMs, trackDurationMs);
}

class LufsValue implements ValueObject {
  final double value;

  LufsValue({required this.value}) {
    if (value < -30 || value > 0) {
      throw InvariantViolationError('LufsValue must be between -30 and 0.');
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! LufsValue) {
      return false;
    }

    return value == other.value;
  }

  @override
  int get hashCode => value.hashCode;
}

class CatalogSource implements ValueObject {
  final String catalogTrackID;
  final URL downloadURL;

  CatalogSource({required this.catalogTrackID, required this.downloadURL}) {
    if (catalogTrackID.isEmpty) {
      throw InvariantViolationError('catalogTrackID must not be empty.');
    }

    if (downloadURL.scheme != URLScheme.https) {
      throw InvariantViolationError('downloadURL must use HTTPS scheme.');
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! CatalogSource) {
      return false;
    }

    return catalogTrackID == other.catalogTrackID &&
        downloadURL == other.downloadURL;
  }

  @override
  int get hashCode => Object.hash(catalogTrackID, downloadURL);
}

class TrackRegistrationRequest implements ValueObject {
  final TrackIdentifier identifier;
  final String title;
  final String artist;
  final int durationMs;
  final String audioFormat;
  final FilePath localPath;
  final Checksum fileChecksum;
  final LoopPoint loopPoint;
  final LufsValue lufsTarget;
  final LicenseIdentifier license;
  final String catalogTrackID;
  final URL downloadURL;

  TrackRegistrationRequest({
    required this.identifier,
    required this.title,
    required this.artist,
    required this.durationMs,
    required this.audioFormat,
    required this.localPath,
    required this.fileChecksum,
    required this.loopPoint,
    required this.lufsTarget,
    required this.license,
    required this.catalogTrackID,
    required this.downloadURL,
  }) {
    if (durationMs <= 0) {
      throw InvariantViolationError('durationMs must be positive.');
    }

    if (loopPoint.startMs < 0 ||
        loopPoint.startMs >= loopPoint.endMs ||
        loopPoint.endMs > durationMs) {
      throw InvariantViolationError(
        'loopPoint must satisfy: 0 <= startMs < endMs <= durationMs',
      );
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! TrackRegistrationRequest) {
      return false;
    }

    return identifier == other.identifier &&
        title == other.title &&
        artist == other.artist &&
        durationMs == other.durationMs &&
        audioFormat == other.audioFormat &&
        localPath == other.localPath &&
        fileChecksum == other.fileChecksum &&
        loopPoint == other.loopPoint &&
        lufsTarget == other.lufsTarget &&
        license == other.license &&
        catalogTrackID == other.catalogTrackID &&
        downloadURL == other.downloadURL;
  }

  @override
  int get hashCode => Object.hash(
    identifier,
    title,
    artist,
    durationMs,
    audioFormat,
    localPath,
    fileChecksum,
    loopPoint,
    lufsTarget,
    license,
    Object.hash(catalogTrackID, downloadURL),
  );
}

enum TrackStatus { active, deprecated }

abstract class TrackEvent extends BaseEvent {
  TrackEvent(super.occurredAt);
}

class TrackRegistered extends TrackEvent {
  final TrackIdentifier identifier;
  final LicenseIdentifier license;
  final int durationMs;

  TrackRegistered({
    required this.identifier,
    required this.license,
    required this.durationMs,
    required DateTime occurredAt,
  }) : super(occurredAt);
}

class TrackMetadataUpdated extends TrackEvent {
  final TrackIdentifier identifier;
  final String? title;
  final String? artist;

  TrackMetadataUpdated({
    required this.identifier,
    this.title,
    this.artist,
    required DateTime occurredAt,
  }) : super(occurredAt);
}

class TrackDeprecated extends TrackEvent {
  final TrackIdentifier identifier;
  final String reason;

  TrackDeprecated({
    required this.identifier,
    required this.reason,
    required DateTime occurredAt,
  }) : super(occurredAt);
}

class TrackRegistrationFailed extends TrackEvent {
  final String catalogTrackID;
  final String reason;

  TrackRegistrationFailed({
    required this.catalogTrackID,
    required this.reason,
    required DateTime occurredAt,
  }) : super(occurredAt);
}

class Track with Publishable<TrackEvent> {
  final TrackIdentifier identifier;
  final String title;
  final String artist;
  final int durationMs;
  final String audioFormat;
  final FilePath localPath;
  final Checksum fileChecksum;
  final LoopPoint loopPoint;
  final LufsValue lufsTarget;
  final LicenseIdentifier license;
  final CatalogSource catalogSource;
  TrackStatus _status;

  Track._({
    required this.identifier,
    required this.title,
    required this.artist,
    required this.durationMs,
    required this.audioFormat,
    required this.localPath,
    required this.fileChecksum,
    required this.loopPoint,
    required this.lufsTarget,
    required this.license,
    required this.catalogSource,
    required TrackStatus status,
  }) : _status = status {
    if (title.isEmpty) {
      throw InvariantViolationError('title must not be empty.');
    }

    if (artist.isEmpty) {
      throw InvariantViolationError('artist must not be empty.');
    }

    if (durationMs <= 0) {
      throw InvariantViolationError('durationMs must be positive.');
    }

    if (loopPoint.startMs < 0 ||
        loopPoint.startMs >= loopPoint.endMs ||
        loopPoint.endMs > durationMs) {
      throw InvariantViolationError(
        'loopPoint must satisfy: 0 <= startMs < endMs <= durationMs',
      );
    }
  }

  TrackStatus get status => _status;

  factory Track.registerFromCatalog(TrackRegistrationRequest request) {
    final track = Track._(
      identifier: request.identifier,
      title: request.title,
      artist: request.artist,
      durationMs: request.durationMs,
      audioFormat: request.audioFormat,
      localPath: request.localPath,
      fileChecksum: request.fileChecksum,
      loopPoint: request.loopPoint,
      lufsTarget: request.lufsTarget,
      license: request.license,
      catalogSource: CatalogSource(
        catalogTrackID: request.catalogTrackID,
        downloadURL: request.downloadURL,
      ),
      status: TrackStatus.active,
    );

    track.publish(
      TrackRegistered(
        identifier: track.identifier,
        license: track.license,
        durationMs: track.durationMs,
        occurredAt: DateTime.now(),
      ),
    );

    return track;
  }

  void updateMetadata({String? title, String? artist}) {
    if (title == null && artist == null) {
      return;
    }

    publish(
      TrackMetadataUpdated(
        identifier: identifier,
        title: title,
        artist: artist,
        occurredAt: DateTime.now(),
      ),
    );
  }

  void markDeprecated(String reason) {
    if (_status == TrackStatus.deprecated) {
      return;
    }

    _status = TrackStatus.deprecated;

    publish(
      TrackDeprecated(
        identifier: identifier,
        reason: reason,
        occurredAt: DateTime.now(),
      ),
    );
  }
}

abstract interface class TrackRepository {
  Future<Track> find(TrackIdentifier identifier);
  Future<List<Track>> all();
  Future<void> persist(Track track);
  Future<void> terminate(TrackIdentifier identifier);
}

// ============================================================================
// Playlist Aggregate
// ============================================================================

class PlaylistIdentifier extends ULIDBasedIdentifier {
  PlaylistIdentifier({required Ulid value}) : super(value);

  factory PlaylistIdentifier.generate() => PlaylistIdentifier(value: Ulid());

  factory PlaylistIdentifier.fromString(String value) =>
      PlaylistIdentifier(value: Ulid.parse(value));

  factory PlaylistIdentifier.fromBinary(Uint8List bytes) =>
      PlaylistIdentifier(value: Ulid.fromBytes(bytes));

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! PlaylistIdentifier) {
      return false;
    }

    return value == other.value;
  }

  @override
  int get hashCode => value.hashCode;
}

class PlaylistEntryIdentifier extends ULIDBasedIdentifier {
  PlaylistEntryIdentifier({required Ulid value}) : super(value);

  factory PlaylistEntryIdentifier.generate() =>
      PlaylistEntryIdentifier(value: Ulid());

  factory PlaylistEntryIdentifier.fromString(String value) =>
      PlaylistEntryIdentifier(value: Ulid.parse(value));

  factory PlaylistEntryIdentifier.fromBinary(Uint8List bytes) =>
      PlaylistEntryIdentifier(value: Ulid.fromBytes(bytes));

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! PlaylistEntryIdentifier) {
      return false;
    }

    return value == other.value;
  }

  @override
  int get hashCode => value.hashCode;
}

abstract interface class EntitlementService {
  bool canAddTrack({required int currentTrackCount});
  int getTrackLimit();
}

class EntitlementLimitExceededError extends Error {
  final String message;

  EntitlementLimitExceededError(this.message);

  @override
  String toString() => 'EntitlementLimitExceededError: $message';
}

enum LoopMode { single, playlist, none }

class RepeatPolicy implements ValueObject {
  final LoopMode mode;

  RepeatPolicy({required this.mode});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! RepeatPolicy) {
      return false;
    }

    return mode == other.mode;
  }

  @override
  int get hashCode => mode.hashCode;
}

class PlaylistEntry {
  final PlaylistEntryIdentifier identifier;
  final TrackIdentifier track;
  final int orderIndex;
  final DateTime addedAt;

  PlaylistEntry({
    required this.identifier,
    required this.track,
    required this.orderIndex,
    required this.addedAt,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! PlaylistEntry) {
      return false;
    }

    return identifier == other.identifier &&
        track == other.track &&
        orderIndex == other.orderIndex &&
        addedAt == other.addedAt;
  }

  @override
  int get hashCode => Object.hash(identifier, track, orderIndex, addedAt);
}

abstract class PlaylistEvent extends BaseEvent {
  PlaylistEvent(super.occurredAt);
}

class PlaylistCreated extends PlaylistEvent {
  final PlaylistIdentifier identifier;
  final String name;
  final int trackCount;

  PlaylistCreated({
    required this.identifier,
    required this.name,
    required this.trackCount,
    required DateTime occurredAt,
  }) : super(occurredAt);
}

class PlaylistEntryAdded extends PlaylistEvent {
  final PlaylistIdentifier playlist;
  final PlaylistEntryIdentifier entry;
  final TrackIdentifier track;

  PlaylistEntryAdded({
    required this.playlist,
    required this.entry,
    required this.track,
    required DateTime occurredAt,
  }) : super(occurredAt);
}

class PlaylistEntryRemoved extends PlaylistEvent {
  final PlaylistIdentifier playlist;
  final PlaylistEntryIdentifier entry;

  PlaylistEntryRemoved({
    required this.playlist,
    required this.entry,
    required DateTime occurredAt,
  }) : super(occurredAt);
}

class PlaylistReordered extends PlaylistEvent {
  final PlaylistIdentifier playlist;
  final PlaylistEntryIdentifier entry;
  final int newIndex;

  PlaylistReordered({
    required this.playlist,
    required this.entry,
    required this.newIndex,
    required DateTime occurredAt,
  }) : super(occurredAt);
}

class PlaylistDeleted extends PlaylistEvent {
  final PlaylistIdentifier identifier;

  PlaylistDeleted({required this.identifier, required DateTime occurredAt})
    : super(occurredAt);
}

class PlaylistExceedsEntitlementLimit extends PlaylistEvent {
  final PlaylistIdentifier playlist;
  final int currentCount;
  final int limit;

  PlaylistExceedsEntitlementLimit({
    required this.playlist,
    required this.currentCount,
    required this.limit,
    required DateTime occurredAt,
  }) : super(occurredAt);
}

class Playlist with Publishable<PlaylistEvent> {
  final PlaylistIdentifier identifier;
  final String name;
  final List<PlaylistEntry> _entries;
  final RepeatPolicy repeatPolicy;
  final bool allowDuplicates;
  final DateTime createdAt;
  DateTime _updatedAt;

  Playlist._({
    required this.identifier,
    required this.name,
    required List<PlaylistEntry> entries,
    required this.repeatPolicy,
    required this.allowDuplicates,
    required this.createdAt,
    required DateTime updatedAt,
  }) : _entries = entries,
       _updatedAt = updatedAt {
    if (name.isEmpty) {
      throw InvariantViolationError('name must not be empty.');
    }

    for (var i = 0; i < _entries.length; i++) {
      if (_entries[i].orderIndex != i) {
        throw InvariantViolationError('orderIndex must be sequential from 0.');
      }
    }

    if (!allowDuplicates) {
      final trackIds = _entries.map((entry) => entry.track).toSet();
      if (trackIds.length != _entries.length) {
        throw InvariantViolationError(
          'Duplicate tracks are not allowed when allowDuplicates is false.',
        );
      }
    }
  }

  List<PlaylistEntry> get entries => List.unmodifiable(_entries);

  DateTime get updatedAt => _updatedAt;

  factory Playlist.create({
    required PlaylistIdentifier identifier,
    required String name,
    required RepeatPolicy repeatPolicy,
    required bool allowDuplicates,
  }) {
    final now = DateTime.now();
    final playlist = Playlist._(
      identifier: identifier,
      name: name,
      entries: [],
      repeatPolicy: repeatPolicy,
      allowDuplicates: allowDuplicates,
      createdAt: now,
      updatedAt: now,
    );

    playlist.publish(
      PlaylistCreated(
        identifier: identifier,
        name: name,
        trackCount: 0,
        occurredAt: now,
      ),
    );

    return playlist;
  }

  void addTrack({
    required TrackIdentifier track,
    required EntitlementService entitlement,
    required TrackStatus trackStatus,
  }) {
    if (!entitlement.canAddTrack(currentTrackCount: _entries.length)) {
      throw EntitlementLimitExceededError(
        'Cannot add track: entitlement limit reached.',
      );
    }

    if (trackStatus == TrackStatus.deprecated) {
      throw InvariantViolationError('Cannot add deprecated track.');
    }

    if (!allowDuplicates && _entries.any((entry) => entry.track == track)) {
      throw InvariantViolationError('Duplicate tracks are not allowed.');
    }

    final entry = PlaylistEntry(
      identifier: PlaylistEntryIdentifier.generate(),
      track: track,
      orderIndex: _entries.length,
      addedAt: DateTime.now(),
    );

    _entries.add(entry);
    _updatedAt = DateTime.now();

    publish(
      PlaylistEntryAdded(
        playlist: identifier,
        entry: entry.identifier,
        track: track,
        occurredAt: _updatedAt,
      ),
    );
  }

  void reorder({
    required PlaylistEntryIdentifier entry,
    required int newIndex,
  }) {
    if (newIndex < 0 || newIndex >= _entries.length) {
      throw ArgumentError('newIndex out of bounds.');
    }

    final targetIndex = _entries.indexWhere(
      (playlistEntry) => playlistEntry.identifier == entry,
    );

    if (targetIndex == -1) {
      throw InvariantViolationError('Entry not found.');
    }

    final targetEntry = _entries.removeAt(targetIndex);
    _entries.insert(newIndex, targetEntry);

    for (var i = 0; i < _entries.length; i++) {
      _entries[i] = PlaylistEntry(
        identifier: _entries[i].identifier,
        track: _entries[i].track,
        orderIndex: i,
        addedAt: _entries[i].addedAt,
      );
    }

    _updatedAt = DateTime.now();

    publish(
      PlaylistReordered(
        playlist: identifier,
        entry: entry,
        newIndex: newIndex,
        occurredAt: _updatedAt,
      ),
    );
  }

  void removeTrack({required PlaylistEntryIdentifier entry}) {
    final targetIndex = _entries.indexWhere(
      (playlistEntry) => playlistEntry.identifier == entry,
    );

    if (targetIndex == -1) {
      throw InvariantViolationError('Entry not found.');
    }

    _entries.removeAt(targetIndex);

    for (var i = 0; i < _entries.length; i++) {
      _entries[i] = PlaylistEntry(
        identifier: _entries[i].identifier,
        track: _entries[i].track,
        orderIndex: i,
        addedAt: _entries[i].addedAt,
      );
    }

    _updatedAt = DateTime.now();

    publish(
      PlaylistEntryRemoved(
        playlist: identifier,
        entry: entry,
        occurredAt: _updatedAt,
      ),
    );
  }
}

abstract interface class PlaylistRepository {
  Future<Playlist> find(PlaylistIdentifier identifier);
  Future<List<Playlist>> all();
  Future<void> persist(Playlist playlist);
  Future<void> terminate(PlaylistIdentifier identifier);
}
