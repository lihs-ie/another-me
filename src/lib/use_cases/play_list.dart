import 'package:another_me/domains/common.dart' as common_domain;
import 'package:another_me/domains/media/media.dart' as media_domain;

class PlaylistManagement {
  final media_domain.PlaylistRepository _playlistRepository;
  final media_domain.TrackRepository _trackRepository;
  final media_domain.EntitlementService _entitlementService;
  final common_domain.Transaction _transaction;

  PlaylistManagement({
    required media_domain.PlaylistRepository playlistRepository,
    required media_domain.TrackRepository trackRepository,
    required media_domain.EntitlementService entitlementService,
    required common_domain.Transaction transaction,
  }) : _playlistRepository = playlistRepository,
       _trackRepository = trackRepository,
       _entitlementService = entitlementService,
       _transaction = transaction;

  Future<media_domain.PlaylistIdentifier> create({
    required String name,
    required media_domain.RepeatPolicy repeatPolicy,
    required bool allowDuplicates,
  }) async {
    return await _transaction.execute(() async {
      final identifier = media_domain.PlaylistIdentifier.generate();

      final playlist = media_domain.Playlist.create(
        identifier: identifier,
        name: name,
        repeatPolicy: repeatPolicy,
        allowDuplicates: allowDuplicates,
      );

      await _playlistRepository.persist(playlist);

      return identifier;
    });
  }

  Future<void> addTrack({
    required media_domain.PlaylistIdentifier playlistIdentifier,
    required media_domain.TrackIdentifier trackIdentifier,
  }) async {
    return await _transaction.execute(() async {
      final playlist = await _playlistRepository.find(playlistIdentifier);
      final track = await _trackRepository.find(trackIdentifier);

      playlist.addTrack(
        track: trackIdentifier,
        entitlement: _entitlementService,
        trackStatus: track.status,
      );

      await _playlistRepository.persist(playlist);
    });
  }

  Future<void> reorder({
    required media_domain.PlaylistIdentifier playlistIdentifier,
    required media_domain.PlaylistEntryIdentifier entryIdentifier,
    required int newIndex,
  }) async {
    return await _transaction.execute(() async {
      final playlist = await _playlistRepository.find(playlistIdentifier);

      playlist.reorder(entry: entryIdentifier, newIndex: newIndex);

      await _playlistRepository.persist(playlist);
    });
  }

  Future<void> removeTrack({
    required media_domain.PlaylistIdentifier playlistIdentifier,
    required media_domain.PlaylistEntryIdentifier entryIdentifier,
  }) async {
    return await _transaction.execute(() async {
      final playlist = await _playlistRepository.find(playlistIdentifier);

      playlist.removeTrack(entry: entryIdentifier);

      await _playlistRepository.persist(playlist);
    });
  }

  Future<void> delete({
    required media_domain.PlaylistIdentifier playlistIdentifier,
  }) async {
    return await _transaction.execute(() async {
      final playlist = await _playlistRepository.find(playlistIdentifier);

      playlist.delete();

      await _playlistRepository.terminate(playlistIdentifier);
    });
  }
}
