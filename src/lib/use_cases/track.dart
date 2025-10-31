import 'package:another_me/domains/common.dart' as common_domain;
import 'package:another_me/domains/import/import.dart' as import_domain;
import 'package:another_me/domains/library/asset.dart' as library_domain;
import 'package:another_me/domains/media/media.dart' as media_domain;
import 'package:another_me/domains/profile/profile.dart' as profile_domain;

class CatalogTrack {
  final library_domain.AssetCatalogRepository _assetCatalogRepository;
  final import_domain.CatalogDownloadJobRepository
  _catalogDownloadJobRepository;
  final common_domain.ApplicationStoragePathProvider _storagePathProvider;
  final common_domain.NetworkConnectivityService _connectivityService;
  final media_domain.TrackRepository _trackRepository;
  final profile_domain.PlaybackService _playbackService;
  final common_domain.Transaction _transaction;

  CatalogTrack({
    required library_domain.AssetCatalogRepository assetCatalogRepository,
    required import_domain.CatalogDownloadJobRepository
    catalogDownloadJobRepository,
    required media_domain.TrackRepository trackRepository,
    required common_domain.ApplicationStoragePathProvider storagePathProvider,
    required common_domain.NetworkConnectivityService connectivityService,
    required profile_domain.PlaybackService playbackService,
    required common_domain.Transaction transaction,
  }) : _assetCatalogRepository = assetCatalogRepository,
       _catalogDownloadJobRepository = catalogDownloadJobRepository,
       _trackRepository = trackRepository,
       _storagePathProvider = storagePathProvider,
       _connectivityService = connectivityService,
       _playbackService = playbackService,
       _transaction = transaction;

  Future<import_domain.CatalogDownloadJobIdentifier> download({
    required import_domain.CatalogTrackIdentifier catalogTrackIdentifier,
  }) async {
    return await _transaction.execute(() async {
      final catalog = await _assetCatalogRepository.findLatest();

      final trackMetadata = catalog.findTrack(catalogTrackIdentifier);

      final path = await _storagePathProvider.getApplicationSupportDirectory();

      final targetPath = path.combine(
        'tracks/${catalogTrackIdentifier.value}.${trackMetadata.format.name}',
      );

      final metadata = import_domain.DownloadJobMetadata(
        track: catalogTrackIdentifier,
        title: trackMetadata.title,
        artist: trackMetadata.artist,
        durationMilliseconds: trackMetadata.durationMilliseconds,
        licenseName: trackMetadata.licenseMetadata.licenseName,
        licenseUrl: trackMetadata.licenseMetadata.licenseURL,
        attributionText: trackMetadata.licenseMetadata.attributeText,
      );

      final request = import_domain.CatalogDownloadRequest(
        catalogTrack: catalogTrackIdentifier,
        downloadURL: trackMetadata.downloadURL,
        estimatedSizeBytes: 10 * 1024 * 1024,
        targetPath: targetPath,
        metadata: metadata,
      );

      final job = import_domain.CatalogDownloadJob.queue(request);

      await _catalogDownloadJobRepository.persist(job);

      return job.identifier;
    });
  }

  Future<void> play({
    required media_domain.TrackIdentifier trackIdentifier,
    required common_domain.PlaybackMode playbackMode,
  }) async {
    return await _transaction.execute(() async {
      final track = await _trackRepository.find(trackIdentifier);

      if (track.status != media_domain.TrackStatus.active) {
        throw media_domain.TrackDeprecatedError(
          'Track ${trackIdentifier.value} is not active.',
        );
      }

      final isOffline = await _connectivityService.isOffline();

      if (isOffline && !track.allowOffline) {
        throw media_domain.OfflinePlaybackNotAllowedError(
          'Cannot play track ${trackIdentifier.value} while offline. '
          'This track does not allow offline playback.',
        );
      }

      await _playbackService.addToQueue(trackIdentifier, playbackMode);

      final event = media_domain.TrackPlaybackStarted(
        trackIdentifier: trackIdentifier,
        playbackMode: playbackMode.toString(),
        startedAt: DateTime.now(),
      );

      track.publish(event);

      await _trackRepository.persist(track);
    });
  }

  Future<void> reDownload({
    required import_domain.CatalogDownloadJobIdentifier jobIdentifier,
  }) async {
    return await _transaction.execute(() async {
      final job = await _catalogDownloadJobRepository.find(jobIdentifier);

      job.reset();

      await _catalogDownloadJobRepository.persist(job);
    });
  }
}
