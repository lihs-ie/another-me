import 'package:another_me/domains/common/audio.dart';
import 'package:another_me/domains/common/date.dart';
import 'package:another_me/domains/common/error.dart';
import 'package:another_me/domains/common/range.dart';
import 'package:another_me/domains/common/storage.dart';
import 'package:another_me/domains/common/url.dart';
import 'package:another_me/domains/import/import.dart';

import '../common.dart';
import '../common/date.dart';
import '../common/identifier.dart';
import '../common/storage.dart';
import '../common/url.dart';
import '../enum.dart';
import '../string.dart';

class CatalogDownloadJobIdentifierFactory
    extends ULIDBasedIdentifierFactory<CatalogDownloadJobIdentifier> {
  CatalogDownloadJobIdentifierFactory()
    : super((value) => CatalogDownloadJobIdentifier(value: value));
}

class CatalogTrackIdentifierFactory
    extends ULIDBasedIdentifierFactory<CatalogTrackIdentifier> {
  CatalogTrackIdentifierFactory()
    : super((value) => CatalogTrackIdentifier(value: value));
}

class AudioFormatFactory extends EnumFactory<AudioFormat> {
  AudioFormatFactory() : super(AudioFormat.values);
}

typedef CatalogTrackMetadataOverrides = ({
  CatalogTrackIdentifier? track,
  String? title,
  String? artist,
  int? durationMilliseconds,
  AudioFormat? format,
  Range<num>? loopPoint,
});

class CatalogTrackMetadataFactory
    extends Factory<CatalogTrackMetadata, CatalogTrackMetadataOverrides> {
  @override
  CatalogTrackMetadata create({
    CatalogTrackMetadataOverrides? overrides,
    required int seed,
  }) {
    final track =
        overrides?.track ??
        Builder(CatalogTrackIdentifierFactory()).buildWith(seed: seed);

    final title =
        overrides?.title ??
        StringFactory.create(
          seed: seed,
          min: 1,
          max: CatalogTrackMetadata.maxTitleLength,
        );

    final artist =
        overrides?.artist ??
        StringFactory.create(
          seed: seed,
          min: 1,
          max: CatalogTrackMetadata.maxArtistLength,
        );

    final durationMilliseconds =
        overrides?.durationMilliseconds ??
        ((seed %
                    (CatalogTrackMetadata.maxDurationMilliseconds -
                        CatalogTrackMetadata.minDurationMilliseconds)) +
                CatalogTrackMetadata.minDurationMilliseconds)
            .clamp(
              CatalogTrackMetadata.minDurationMilliseconds,
              CatalogTrackMetadata.maxDurationMilliseconds,
            );

    final format =
        overrides?.format ??
        Builder(AudioFormatFactory()).buildWith(seed: seed);

    final loopStart = (seed % (durationMilliseconds ~/ 2)).toDouble();

    final loopEnd = (loopStart + (seed % (durationMilliseconds ~/ 2))).clamp(
      loopStart + 1,
      durationMilliseconds.toDouble(),
    );

    final loopPoint =
        overrides?.loopPoint ?? Range<num>(start: loopStart, end: loopEnd);

    return CatalogTrackMetadata(
      track: track,
      title: title,
      artist: artist,
      durationMilliseconds: durationMilliseconds,
      format: format,
      loopPoint: loopPoint,
    );
  }

  @override
  CatalogTrackMetadata duplicate(
    CatalogTrackMetadata instance,
    CatalogTrackMetadataOverrides? overrides,
  ) {
    final track =
        overrides?.track ??
        Builder(
          CatalogTrackIdentifierFactory(),
        ).duplicate(instance: instance.track, overrides: null);

    final title = overrides?.title ?? instance.title;

    final artist = overrides?.artist ?? instance.artist;

    final durationMilliseconds =
        overrides?.durationMilliseconds ?? instance.durationMilliseconds;

    final format = overrides?.format ?? instance.format;

    final loopPoint =
        overrides?.loopPoint ??
        Range<num>(
          start: instance.loopPoint.start,
          end: instance.loopPoint.end,
        );

    return CatalogTrackMetadata(
      track: track,
      title: title,
      artist: artist,
      durationMilliseconds: durationMilliseconds,
      format: format,
      loopPoint: loopPoint,
    );
  }
}

class VerificationResultFactory extends EnumFactory<VerificationResult> {
  VerificationResultFactory() : super(VerificationResult.values);
}

typedef VerificationChecksumsOverrides = ({
  Checksum? expected,
  Checksum? actual,
});

class VerificationChecksumsFactory
    extends Factory<VerificationChecksums, VerificationChecksumsOverrides> {
  @override
  VerificationChecksums create({
    VerificationChecksumsOverrides? overrides,
    required int seed,
  }) {
    final expected =
        overrides?.expected ?? Builder(ChecksumFactory()).buildWith(seed: seed);

    final actual = overrides?.actual;

    return VerificationChecksums(expected: expected, actual: actual);
  }

  @override
  VerificationChecksums duplicate(
    VerificationChecksums instance,
    VerificationChecksumsOverrides? overrides,
  ) {
    final expected =
        overrides?.expected ??
        Builder(
          ChecksumFactory(),
        ).duplicate(instance: instance.expected, overrides: null);

    final actual =
        overrides?.actual ??
        (instance.actual != null
            ? Builder(
                ChecksumFactory(),
              ).duplicate(instance: instance.actual!, overrides: null)
            : null);

    return VerificationChecksums(expected: expected, actual: actual);
  }
}

class FailureCodeFactory extends EnumFactory<FailureCode> {
  FailureCodeFactory() : super(FailureCode.values);
}

typedef FailureReasonOverrides = ({FailureCode? code, String? message});

class FailureReasonFactory
    extends Factory<FailureReason, FailureReasonOverrides> {
  @override
  FailureReason create({FailureReasonOverrides? overrides, required int seed}) {
    final code =
        overrides?.code ?? Builder(FailureCodeFactory()).buildWith(seed: seed);

    final message =
        overrides?.message ??
        (seed % 2 == 0
            ? StringFactory.create(
                seed: seed,
                min: 1,
                max: FailureReason.maxMessageLength,
              )
            : null);

    return FailureReason(code: code, message: message);
  }

  @override
  FailureReason duplicate(
    FailureReason instance,
    FailureReasonOverrides? overrides,
  ) {
    final code = overrides?.code ?? instance.code;

    final message = overrides?.message ?? instance.message;

    return FailureReason(code: code, message: message);
  }
}

typedef RetryStateOverrides = ({FailureReason? failureReason, int? retryCount});

class RetryStateFactory extends Factory<RetryState, RetryStateOverrides> {
  @override
  RetryState create({RetryStateOverrides? overrides, required int seed}) {
    final retryCount =
        overrides?.retryCount ?? (seed % (RetryState.maxAllowedRetries + 1));

    final failureReason =
        overrides?.failureReason ??
        (retryCount > 0
            ? Builder(FailureReasonFactory()).buildWith(seed: seed)
            : null);

    return RetryState(failureReason: failureReason, retryCount: retryCount);
  }

  @override
  RetryState duplicate(RetryState instance, RetryStateOverrides? overrides) {
    final retryCount = overrides?.retryCount ?? instance.retryCount;

    final failureReason =
        overrides?.failureReason ??
        (instance.failureReason != null
            ? Builder(
                FailureReasonFactory(),
              ).duplicate(instance: instance.failureReason!, overrides: null)
            : null);

    return RetryState(failureReason: failureReason, retryCount: retryCount);
  }
}

typedef DownloadAssetPathsOverrides = ({FilePath? target, FilePath? license});

class DownloadAssetPathsFactory
    extends Factory<DownloadAssetPaths, DownloadAssetPathsOverrides> {
  @override
  DownloadAssetPaths create({
    DownloadAssetPathsOverrides? overrides,
    required int seed,
  }) {
    final target =
        overrides?.target ?? Builder(FilePathFactory()).buildWith(seed: seed);

    final license = overrides?.license;

    return DownloadAssetPaths(target: target, license: license);
  }

  @override
  DownloadAssetPaths duplicate(
    DownloadAssetPaths instance,
    DownloadAssetPathsOverrides? overrides,
  ) {
    final target =
        overrides?.target ??
        Builder(
          FilePathFactory(),
        ).duplicate(instance: instance.target, overrides: null);

    final license =
        overrides?.license ??
        (instance.license != null
            ? Builder(
                FilePathFactory(),
              ).duplicate(instance: instance.license!, overrides: null)
            : null);

    return DownloadAssetPaths(target: target, license: license);
  }
}

typedef CatalogDownloadRequestOverrides = ({
  CatalogTrackIdentifier? catalogTrack,
  SignedURL? downloadURL,
  int? estimatedSizeBytes,
  FilePath? targetPath,
  DownloadJobMetadata? metadata,
});

class CatalogDownloadRequestFactory
    extends Factory<CatalogDownloadRequest, CatalogDownloadRequestOverrides> {
  @override
  CatalogDownloadRequest create({
    CatalogDownloadRequestOverrides? overrides,
    required int seed,
  }) {
    final catalogTrack =
        overrides?.catalogTrack ??
        Builder(CatalogTrackIdentifierFactory()).buildWith(seed: seed);

    final downloadURL =
        overrides?.downloadURL ??
        Builder(SignedURLFactory()).buildWith(seed: seed);

    final estimatedSizeBytes =
        overrides?.estimatedSizeBytes ??
        ((seed % CatalogDownloadRequest.maxEstimatedSizeBytes) + 1);

    final targetPath =
        overrides?.targetPath ??
        Builder(FilePathFactory()).buildWith(seed: seed);

    final metadata =
        overrides?.metadata ??
        Builder(DownloadJobMetadataFactory()).buildWith(seed: seed);

    return CatalogDownloadRequest(
      catalogTrack: catalogTrack,
      downloadURL: downloadURL,
      estimatedSizeBytes: estimatedSizeBytes,
      targetPath: targetPath,
      metadata: metadata,
    );
  }

  @override
  CatalogDownloadRequest duplicate(
    CatalogDownloadRequest instance,
    CatalogDownloadRequestOverrides? overrides,
  ) {
    final catalogTrack =
        overrides?.catalogTrack ??
        Builder(
          CatalogTrackIdentifierFactory(),
        ).duplicate(instance: instance.catalogTrack, overrides: null);

    final downloadURL =
        overrides?.downloadURL ??
        Builder(
          SignedURLFactory(),
        ).duplicate(instance: instance.downloadURL, overrides: null);

    final estimatedSizeBytes =
        overrides?.estimatedSizeBytes ?? instance.estimatedSizeBytes;

    final targetPath =
        overrides?.targetPath ??
        Builder(
          FilePathFactory(),
        ).duplicate(instance: instance.targetPath, overrides: null);

    final metadata =
        overrides?.metadata ??
        Builder(
          DownloadJobMetadataFactory(),
        ).duplicate(instance: instance.metadata, overrides: null);

    return CatalogDownloadRequest(
      catalogTrack: catalogTrack,
      downloadURL: downloadURL,
      estimatedSizeBytes: estimatedSizeBytes,
      targetPath: targetPath,
      metadata: metadata,
    );
  }
}

typedef DownloadJobMetadataOverrides = ({
  CatalogTrackIdentifier? track,
  String? title,
  String? artist,
  int? durationMilliseconds,
  String? licenseName,
  URL? licenseUrl,
  String? attributionText,
});

class DownloadJobMetadataFactory
    extends Factory<DownloadJobMetadata, DownloadJobMetadataOverrides> {
  @override
  DownloadJobMetadata create({
    DownloadJobMetadataOverrides? overrides,
    required int seed,
  }) {
    final track =
        overrides?.track ??
        Builder(CatalogTrackIdentifierFactory()).buildWith(seed: seed);

    final title =
        overrides?.title ??
        StringFactory.create(
          seed: seed,
          min: 1,
          max: DownloadJobMetadata.maxTitleLength,
        );

    final artist =
        overrides?.artist ??
        StringFactory.create(
          seed: seed,
          min: 1,
          max: DownloadJobMetadata.maxArtistLength,
        );

    final durationMilliseconds =
        overrides?.durationMilliseconds ??
        ((seed %
                    (DownloadJobMetadata.maxDurationMilliseconds -
                        DownloadJobMetadata.minDurationMilliseconds)) +
                DownloadJobMetadata.minDurationMilliseconds)
            .clamp(
              DownloadJobMetadata.minDurationMilliseconds,
              DownloadJobMetadata.maxDurationMilliseconds,
            );

    final licenseName =
        overrides?.licenseName ??
        StringFactory.create(seed: seed, min: 1, max: 100);

    final licenseUrl =
        overrides?.licenseUrl ??
        Builder(URLFactory()).buildWith(
          overrides: (scheme: URLScheme.https, value: null),
          seed: seed,
        );

    final attributionText =
        overrides?.attributionText ??
        StringFactory.create(seed: seed, min: 1, max: 500);

    return DownloadJobMetadata(
      track: track,
      title: title,
      artist: artist,
      durationMilliseconds: durationMilliseconds,
      licenseName: licenseName,
      licenseUrl: licenseUrl,
      attributionText: attributionText,
    );
  }

  @override
  DownloadJobMetadata duplicate(
    DownloadJobMetadata instance,
    DownloadJobMetadataOverrides? overrides,
  ) {
    final track =
        overrides?.track ??
        Builder(
          CatalogTrackIdentifierFactory(),
        ).duplicate(instance: instance.track, overrides: null);

    final title = overrides?.title ?? instance.title;

    final artist = overrides?.artist ?? instance.artist;

    final durationMilliseconds =
        overrides?.durationMilliseconds ?? instance.durationMilliseconds;

    final licenseName = overrides?.licenseName ?? instance.licenseName;

    final licenseUrl =
        overrides?.licenseUrl ??
        Builder(
          URLFactory(),
        ).duplicate(instance: instance.licenseUrl, overrides: null);

    final attributionText =
        overrides?.attributionText ?? instance.attributionText;

    return DownloadJobMetadata(
      track: track,
      title: title,
      artist: artist,
      durationMilliseconds: durationMilliseconds,
      licenseName: licenseName,
      licenseUrl: licenseUrl,
      attributionText: attributionText,
    );
  }
}

typedef FileInfoOverrides = ({
  FilePath? path,
  Checksum? checksum,
  int? sizeBytes,
});

class FileInfoFactory extends Factory<FileInfo, FileInfoOverrides> {
  @override
  FileInfo create({FileInfoOverrides? overrides, required int seed}) {
    final path =
        overrides?.path ?? Builder(FilePathFactory()).buildWith(seed: seed);

    final checksum =
        overrides?.checksum ?? Builder(ChecksumFactory()).buildWith(seed: seed);

    final sizeBytes =
        overrides?.sizeBytes ?? ((seed % FileInfo.maxFileSizeBytes) + 1);

    return FileInfo(path: path, checksum: checksum, sizeBytes: sizeBytes);
  }

  @override
  FileInfo duplicate(FileInfo instance, FileInfoOverrides? overrides) {
    final path =
        overrides?.path ??
        Builder(
          FilePathFactory(),
        ).duplicate(instance: instance.path, overrides: null);

    final checksum =
        overrides?.checksum ??
        Builder(
          ChecksumFactory(),
        ).duplicate(instance: instance.checksum, overrides: null);

    final sizeBytes = overrides?.sizeBytes ?? instance.sizeBytes;

    return FileInfo(path: path, checksum: checksum, sizeBytes: sizeBytes);
  }
}

class DownloadStatusFactory extends EnumFactory<DownloadStatus> {
  DownloadStatusFactory() : super(DownloadStatus.values);
}

typedef CatalogDownloadJobOverrides = ({
  CatalogDownloadJobIdentifier? identifier,
  CatalogTrackIdentifier? catalogTrack,
  SignedURL? downloadUrl,
  int? estimatedSizeBytes,
  DownloadJobMetadata? metadata,
  DownloadStatus? status,
  Timeline? timeline,
  VerificationChecksums? checksums,
  RetryState? retryState,
  DownloadAssetPaths? paths,
});

class CatalogDownloadJobFactory
    extends Factory<CatalogDownloadJob, CatalogDownloadJobOverrides> {
  @override
  CatalogDownloadJob create({
    CatalogDownloadJobOverrides? overrides,
    required int seed,
  }) {
    final identifier =
        overrides?.identifier ??
        Builder(CatalogDownloadJobIdentifierFactory()).buildWith(seed: seed);

    final catalogTrack =
        overrides?.catalogTrack ??
        Builder(CatalogTrackIdentifierFactory()).buildWith(seed: seed);

    final downloadUrl =
        overrides?.downloadUrl ??
        Builder(SignedURLFactory()).buildWith(seed: seed);

    final estimatedSizeBytes =
        overrides?.estimatedSizeBytes ??
        ((seed % CatalogDownloadJob.maxEstimatedSizeBytes) + 1);

    final metadata =
        overrides?.metadata ??
        Builder(DownloadJobMetadataFactory()).buildWith(seed: seed);

    final status =
        overrides?.status ??
        Builder(DownloadStatusFactory()).buildWith(seed: seed);

    final timeline =
        overrides?.timeline ?? Builder(TimelineFactory()).buildWith(seed: seed);

    final expectedChecksum = Builder(ChecksumFactory()).buildWith(seed: seed);

    final checksums =
        overrides?.checksums ??
        Builder(VerificationChecksumsFactory()).buildWith(
          overrides: (expected: expectedChecksum, actual: null),
          seed: seed,
        );

    final retryState =
        overrides?.retryState ??
        Builder(RetryStateFactory()).buildWith(
          overrides: (failureReason: null, retryCount: 0),
          seed: seed,
        );

    final paths =
        overrides?.paths ??
        Builder(DownloadAssetPathsFactory()).buildWith(seed: seed);

    return CatalogDownloadJob(
      identifier: identifier,
      catalogTrack: catalogTrack,
      downloadUrl: downloadUrl,
      estimatedSizeBytes: estimatedSizeBytes,
      metadata: metadata,
      status: status,
      timeline: timeline,
      checksums: checksums,
      retryState: retryState,
      paths: paths,
    );
  }

  @override
  CatalogDownloadJob duplicate(
    CatalogDownloadJob instance,
    CatalogDownloadJobOverrides? overrides,
  ) {
    throw UnimplementedError();
  }
}

typedef CatalogDownloadQueuedOverrides = ({
  CatalogDownloadJobIdentifier? job,
  CatalogTrackIdentifier? catalogTrack,
  bool? isRetry,
});

class CatalogDownloadQueuedFactory
    extends Factory<CatalogDownloadQueued, CatalogDownloadQueuedOverrides> {
  @override
  CatalogDownloadQueued create({
    CatalogDownloadQueuedOverrides? overrides,
    required int seed,
  }) {
    final job =
        overrides?.job ??
        Builder(CatalogDownloadJobIdentifierFactory()).buildWith(seed: seed);

    final catalogTrack =
        overrides?.catalogTrack ??
        Builder(CatalogTrackIdentifierFactory()).buildWith(seed: seed);

    final isRetry = overrides?.isRetry ?? (seed % 2 == 0);

    return CatalogDownloadQueued(
      job: job,
      catalogTrack: catalogTrack,
      isRetry: isRetry,
    );
  }

  @override
  CatalogDownloadQueued duplicate(
    CatalogDownloadQueued instance,
    CatalogDownloadQueuedOverrides? overrides,
  ) {
    final job =
        overrides?.job ??
        Builder(
          CatalogDownloadJobIdentifierFactory(),
        ).duplicate(instance: instance.job, overrides: null);

    final catalogTrack =
        overrides?.catalogTrack ??
        Builder(
          CatalogTrackIdentifierFactory(),
        ).duplicate(instance: instance.catalogTrack, overrides: null);

    final isRetry = overrides?.isRetry ?? instance.isRetry;

    return CatalogDownloadQueued(
      job: job,
      catalogTrack: catalogTrack,
      isRetry: isRetry,
    );
  }
}

typedef CatalogDownloadJobRepositoryOverrides = ({
  List<CatalogDownloadJob>? instances,
  void Function(CatalogDownloadJob)? onPersist,
});

class _CatalogDownloadJobRepository implements CatalogDownloadJobRepository {
  final Map<CatalogDownloadJobIdentifier, CatalogDownloadJob> _instances;
  final void Function(CatalogDownloadJob)? _onPersist;

  _CatalogDownloadJobRepository({
    required List<CatalogDownloadJob> instances,
    void Function(CatalogDownloadJob)? onPersist,
  }) : _instances = {
         for (final instance in instances) instance.identifier: instance,
       },
       _onPersist = onPersist;

  @override
  Future<CatalogDownloadJob> find(CatalogDownloadJobIdentifier identifier) {
    final instance = _instances[identifier];

    if (instance == null) {
      throw AggregateNotFoundError(
        'CatalogDownloadJob with identifier ${identifier.value} not found.',
      );
    }

    return Future.value(instance);
  }

  @override
  Future<CatalogDownloadJob> findOrNull(
    CatalogDownloadJobIdentifier identifier,
  ) {
    final instance = _instances[identifier];

    if (instance == null) {
      throw AggregateNotFoundError(
        'CatalogDownloadJob with identifier ${identifier.value} not found.',
      );
    }

    return Future.value(instance);
  }

  @override
  Future<void> persist(CatalogDownloadJob job) {
    _instances[job.identifier] = job;

    _onPersist?.call(job);

    return Future.value();
  }

  @override
  Future<List<CatalogDownloadJob>> findByStatus(
    DownloadStatus status, {
    int? limit,
  }) {
    final jobs = _instances.values
        .where((job) => job.status == status)
        .take(limit ?? _instances.length)
        .toList();

    return Future.value(jobs);
  }

  @override
  Future<List<CatalogDownloadJob>> findPending({int? limit = 10}) {
    return findByStatus(DownloadStatus.pending, limit: limit);
  }

  @override
  Future<List<CatalogDownloadJob>> findRetryable({int? limit}) {
    return findByStatus(DownloadStatus.failed, limit: limit);
  }

  @override
  Future<CatalogDownloadJob> findByCatalogTrack(CatalogTrackIdentifier track) {
    final instance = _instances.values.firstWhere(
      (job) => job.catalogTrack == track,
      orElse: () => throw AggregateNotFoundError(
        'CatalogDownloadJob with catalog track ${track.value} not found.',
      ),
    );

    return Future.value(instance);
  }

  @override
  Future<void> terminate(CatalogDownloadJobIdentifier identifier) {
    _instances.remove(identifier);

    return Future.value();
  }
}

class CatalogDownloadJobRepositoryFactory
    extends
        Factory<
          CatalogDownloadJobRepository,
          CatalogDownloadJobRepositoryOverrides
        > {
  @override
  CatalogDownloadJobRepository create({
    CatalogDownloadJobRepositoryOverrides? overrides,
    required int seed,
  }) {
    final instances = overrides?.instances ?? [];

    return _CatalogDownloadJobRepository(
      instances: instances,
      onPersist: overrides?.onPersist,
    );
  }

  @override
  CatalogDownloadJobRepository duplicate(
    CatalogDownloadJobRepository instance,
    CatalogDownloadJobRepositoryOverrides? overrides,
  ) {
    throw UnimplementedError();
  }
}
