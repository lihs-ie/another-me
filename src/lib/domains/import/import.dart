import 'dart:typed_data';

import 'package:another_me/domains/common/date.dart';
import 'package:another_me/domains/common/event.dart';
import 'package:another_me/domains/common/identifier.dart';
import 'package:another_me/domains/common/range.dart';
import 'package:another_me/domains/common/storage.dart';
import 'package:another_me/domains/common/url.dart';
import 'package:another_me/domains/common/value_object.dart';
import 'package:another_me/domains/common/variant.dart';
import 'package:another_me/domains/library/asset.dart';
import 'package:ulid/ulid.dart';

class CatalogTrackIdentifier extends ULIDBasedIdentifier {
  CatalogTrackIdentifier({required Ulid value}) : super(value);

  factory CatalogTrackIdentifier.generate() =>
      CatalogTrackIdentifier(value: Ulid());

  factory CatalogTrackIdentifier.fromString(String value) =>
      CatalogTrackIdentifier(value: Ulid.parse(value));

  factory CatalogTrackIdentifier.fromBinary(Uint8List bytes) =>
      CatalogTrackIdentifier(value: Ulid.fromBytes(bytes));

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! CatalogTrackIdentifier) {
      return false;
    }

    return value == other.value;
  }

  @override
  int get hashCode => value.hashCode;
}

class CatalogLicenseMetadata implements ValueObject {
  static const int maxLicenseNameLength = 100;
  static const int maxAttributeTextLength = 500;

  final String licenseName;
  final URL licenseURL;
  final String attributeText;
  final bool allowOffline;
  final bool redistributionAllowed;
  final Checksum licenseFileChecksum;

  CatalogLicenseMetadata({
    required this.licenseName,
    required this.licenseURL,
    required this.attributeText,
    required this.allowOffline,
    required this.redistributionAllowed,
    required this.licenseFileChecksum,
  }) {
    Invariant.length(
      value: licenseName,
      name: 'licenseName',
      min: 1,
      max: CatalogLicenseMetadata.maxLicenseNameLength,
    );
    Invariant.length(
      value: attributeText,
      name: 'attributeText',
      min: 1,
      max: CatalogLicenseMetadata.maxAttributeTextLength,
    );

    if (licenseURL.scheme != URLScheme.https) {
      throw InvariantViolationError('licenseURL must use HTTPS scheme.');
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! CatalogLicenseMetadata) {
      return false;
    }

    if (licenseName != other.licenseName) {
      return false;
    }

    if (licenseURL != other.licenseURL) {
      return false;
    }

    if (attributeText != other.attributeText) {
      return false;
    }

    if (allowOffline != other.allowOffline) {
      return false;
    }

    if (redistributionAllowed != other.redistributionAllowed) {
      return false;
    }

    if (licenseFileChecksum != other.licenseFileChecksum) {
      return false;
    }

    return true;
  }

  @override
  int get hashCode => Object.hash(
    licenseName,
    licenseURL,
    attributeText,
    allowOffline,
    redistributionAllowed,
    licenseFileChecksum,
  );
}

enum VerificationResult { verified, mismatched, pending }

class VerificationChecksums implements ValueObject {
  final Checksum expected;
  final Checksum? actual;

  VerificationChecksums({required this.expected, this.actual});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! VerificationChecksums) {
      return false;
    }

    return expected == other.expected && actual == other.actual;
  }

  @override
  int get hashCode => Object.hash(expected, actual);

  VerificationChecksums withExpected(Checksum expected) {
    return VerificationChecksums(expected: expected, actual: actual);
  }

  VerificationChecksums withActual(Checksum actual) {
    return VerificationChecksums(expected: expected, actual: actual);
  }

  bool isVerified() {
    if (actual == null) {
      return false;
    }

    return expected == actual;
  }

  VerificationResult verificationResult() {
    if (actual == null) {
      return VerificationResult.pending;
    }

    if (expected == actual) {
      return VerificationResult.verified;
    } else {
      return VerificationResult.mismatched;
    }
  }

  void requireMatched() {
    final result = verificationResult();

    if (result == VerificationResult.pending) {
      throw StateError('Checksum verification is still pending.');
    }

    if (result == VerificationResult.mismatched) {
      throw ChecksumMismatchError(
        'Checksum does not match the expected value.',
      );
    }
  }
}

enum AudioFormat { aac, m4a, mp3, wav }

class CatalogTrackMetadata implements ValueObject {
  static const int maxTitleLength = 100;
  static const int maxArtistLength = 100;
  static const int minDurationMilliseconds = 1000;
  static const int maxDurationMilliseconds = 3600000;

  final CatalogTrackIdentifier track;
  final String title;
  final String artist;
  final int durationMilliseconds;
  final AudioFormat format;
  final Range<num> loopPoint;

  CatalogTrackMetadata({
    required this.track,
    required this.title,
    required this.artist,
    required this.durationMilliseconds,
    required this.format,
    required this.loopPoint,
  }) {
    Invariant.length(value: title, name: 'title', min: 1, max: maxTitleLength);

    Invariant.length(
      value: artist,
      name: 'artist',
      min: 1,
      max: maxArtistLength,
    );

    Invariant.range(
      value: durationMilliseconds,
      name: 'durationMilliseconds',
      min: minDurationMilliseconds,
      max: maxDurationMilliseconds,
    );

    if (loopPoint.start! >= loopPoint.end!) {
      throw InvariantViolationError(
        'loopPoint.start must be less than loopPoint.end',
      );
    }

    if (loopPoint.end! > durationMilliseconds) {
      throw InvariantViolationError(
        'loopPoint.end must be less than or equal to durationMilliseconds',
      );
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! CatalogTrackMetadata) {
      return false;
    }

    if (track != other.track) {
      return false;
    }

    if (title != other.title) {
      return false;
    }

    if (artist != other.artist) {
      return false;
    }

    if (durationMilliseconds != other.durationMilliseconds) {
      return false;
    }

    if (format != other.format) {
      return false;
    }

    if (loopPoint != other.loopPoint) {
      return false;
    }

    return true;
  }

  @override
  int get hashCode => Object.hash(
    track,
    title,
    artist,
    durationMilliseconds,
    format,
    loopPoint,
  );
}

enum FailureCode {
  networkError,
  checksumMismatch,
  unknown,
  storageFull,
  storageQuotaExceeded,
}

extension FailureCodeExtension on FailureCode {
  bool get isRetryable {
    switch (this) {
      case FailureCode.networkError:
      case FailureCode.checksumMismatch:
        return true;
      case FailureCode.unknown:
      case FailureCode.storageFull:
      case FailureCode.storageQuotaExceeded:
        return false;
    }
  }
}

class FailureReason implements ValueObject {
  final FailureCode code;
  final String? message;

  static const int maxMessageLength = 500;

  FailureReason({required this.code, String? message}) : message = message {
    if (message != null) {
      if (message.isEmpty) {
        throw InvariantViolationError('message cannot be an empty string.');
      }

      Invariant.range(
        value: message.length,
        name: 'message',
        min: 1,
        max: maxMessageLength,
      );
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! FailureReason) {
      return false;
    }

    if (code != other.code) {
      return false;
    }

    if (message != other.message) {
      return false;
    }

    return true;
  }

  @override
  int get hashCode => Object.hash(code, message);

  bool isRetryable() {
    return code.isRetryable;
  }
}

class RetryState implements ValueObject {
  final FailureReason? failureReason;
  final int retryCount;

  static const int maxAllowedRetries = 3;

  RetryState({required this.failureReason, required this.retryCount}) {
    Invariant.range(
      value: retryCount,
      name: 'retryCount',
      min: 0,
      max: maxAllowedRetries,
    );

    if (0 < retryCount && failureReason == null) {
      throw InvariantViolationError(
        'failureReason must be provided when retryCount is greater than 0.',
      );
    }

    if (failureReason != null && retryCount == 0) {
      throw InvariantViolationError(
        'retryCount must be greater than 0 when failureReason is provided.',
      );
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! RetryState) {
      return false;
    }

    if (retryCount != other.retryCount) {
      return false;
    }

    if (failureReason != other.failureReason) {
      return false;
    }

    return true;
  }

  @override
  int get hashCode => Object.hash(retryCount, failureReason);

  factory RetryState.initial() {
    return RetryState(failureReason: null, retryCount: 0);
  }

  RetryState recordFailure(FailureReason reason) {
    return RetryState(failureReason: reason, retryCount: retryCount + 1);
  }

  RetryState reset() {
    return RetryState.initial();
  }

  bool canRetry() {
    if (failureReason == null) {
      return false;
    }

    if (!failureReason!.isRetryable()) {
      return false;
    }

    if (retryCount >= maxAllowedRetries) {
      return false;
    }

    return true;
  }

  bool isRetryExhausted() {
    if (failureReason == null) {
      return false;
    }

    if (!failureReason!.isRetryable()) {
      return true;
    }

    if (retryCount >= maxAllowedRetries) {
      return true;
    }

    return false;
  }
}

class CatalogDownloadJobIdentifier extends ULIDBasedIdentifier {
  CatalogDownloadJobIdentifier({required Ulid value}) : super(value);

  factory CatalogDownloadJobIdentifier.generate() =>
      CatalogDownloadJobIdentifier(value: Ulid());

  factory CatalogDownloadJobIdentifier.fromString(String value) =>
      CatalogDownloadJobIdentifier(value: Ulid.parse(value));

  factory CatalogDownloadJobIdentifier.fromBinary(Uint8List bytes) =>
      CatalogDownloadJobIdentifier(value: Ulid.fromBytes(bytes));

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! CatalogDownloadJobIdentifier) {
      return false;
    }

    return value == other.value;
  }

  @override
  int get hashCode => value.hashCode;
}

enum DownloadStatus {
  pending,
  downloading,
  verifying,
  verified,
  registering,
  completed,
  failed,
}

class DownloadAssetPaths implements ValueObject {
  final FilePath target;
  final FilePath? license;

  DownloadAssetPaths({required this.target, this.license});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! DownloadAssetPaths) {
      return false;
    }

    return target == other.target && license == other.license;
  }

  @override
  int get hashCode => Object.hash(target, license);

  DownloadAssetPaths withTarget(FilePath target) {
    return DownloadAssetPaths(target: target, license: license);
  }

  DownloadAssetPaths withLicense(FilePath license) {
    return DownloadAssetPaths(target: target, license: license);
  }

  bool hasLicense() {
    return license != null;
  }

  bool isComplete() {
    return license != null;
  }

  void requireLicense() {
    if (license == null) {
      throw StateError('License path is required but not set.');
    }
  }

  static FilePath generateLicensePath(
    String baseDirectory,
    CatalogTrackIdentifier track,
  ) {
    final path = '$baseDirectory/licenses/${track.value}_LICENSE.txt';
    return FilePath(value: path, os: OperatingSystem.iOS);
  }
}

class DownloadJobMetadata implements ValueObject {
  static const int maxTitleLength = 100;
  static const int maxArtistLength = 100;
  static const int minDurationMilliseconds = 1000;
  static const int maxDurationMilliseconds = 3600000;

  final CatalogTrackIdentifier track;
  final String title;
  final String artist;
  final int durationMilliseconds;
  final String licenseName;
  final URL licenseUrl;
  final String attributionText;

  DownloadJobMetadata({
    required this.track,
    required this.title,
    required this.artist,
    required this.durationMilliseconds,
    required this.licenseName,
    required this.licenseUrl,
    required this.attributionText,
  }) {
    Invariant.length(value: title, name: 'title', min: 1, max: maxTitleLength);

    Invariant.length(
      value: artist,
      name: 'artist',
      min: 1,
      max: maxArtistLength,
    );

    Invariant.range(
      value: durationMilliseconds,
      name: 'durationMilliseconds',
      min: minDurationMilliseconds,
      max: maxDurationMilliseconds,
    );

    Invariant.length(value: licenseName, name: 'licenseName', min: 1, max: 100);

    Invariant.length(
      value: attributionText,
      name: 'attributionText',
      min: 1,
      max: 500,
    );

    if (licenseUrl.scheme != URLScheme.https) {
      throw InvariantViolationError('licenseUrl must use HTTPS scheme.');
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! DownloadJobMetadata) {
      return false;
    }

    return track == other.track &&
        title == other.title &&
        artist == other.artist &&
        durationMilliseconds == other.durationMilliseconds &&
        licenseName == other.licenseName &&
        licenseUrl == other.licenseUrl &&
        attributionText == other.attributionText;
  }

  @override
  int get hashCode => Object.hash(
    track,
    title,
    artist,
    durationMilliseconds,
    licenseName,
    licenseUrl,
    attributionText,
  );
}

class FileInfo implements ValueObject {
  static const int maxFileSizeBytes = 209715200;

  final FilePath path;
  final Checksum checksum;
  final int sizeBytes;

  FileInfo({
    required this.path,
    required this.checksum,
    required this.sizeBytes,
  }) {
    Invariant.range(
      value: sizeBytes,
      name: 'sizeBytes',
      min: 1,
      max: maxFileSizeBytes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! FileInfo) {
      return false;
    }

    return path == other.path &&
        checksum == other.checksum &&
        sizeBytes == other.sizeBytes;
  }

  @override
  int get hashCode => Object.hash(path, checksum, sizeBytes);

  bool verify(ChecksumCalculator calculator) {
    final actualChecksum = calculator.calculate(path, checksum.algorithm);

    if (actualChecksum != checksum) {
      throw StateError(
        'File integrity check failed for ${path.value}: '
        'expected ${checksum.value}, got ${actualChecksum.value}',
      );
    }

    return true;
  }
}

class InvalidStatusTransitionError extends StateError {
  InvalidStatusTransitionError(super.message);
}

class CatalogDownloadJob with Publishable<CatalogDownloadEvent> {
  static const int maxEstimatedSizeBytes = 209715200;

  final CatalogDownloadJobIdentifier identifier;
  final CatalogTrackIdentifier catalogTrack;
  final SignedURL downloadUrl;
  final int estimatedSizeBytes;
  final DownloadJobMetadata metadata;

  DownloadStatus _status;
  Timeline _timeline;
  VerificationChecksums _checksums;
  RetryState _retryState;
  DownloadAssetPaths _paths;

  CatalogDownloadJob({
    required this.identifier,
    required this.catalogTrack,
    required this.downloadUrl,
    required this.estimatedSizeBytes,
    required this.metadata,
    required DownloadStatus status,
    required Timeline timeline,
    required VerificationChecksums checksums,
    required RetryState retryState,
    required DownloadAssetPaths paths,
  }) : _status = status,
       _timeline = timeline,
       _checksums = checksums,
       _retryState = retryState,
       _paths = paths {
    Invariant.range(
      value: estimatedSizeBytes,
      name: 'estimatedSizeBytes',
      min: 1,
      max: maxEstimatedSizeBytes,
    );

    if (_status == DownloadStatus.completed && !_paths.isComplete()) {
      throw InvariantViolationError(
        'When status is Completed, both target and license paths must be set.',
      );
    }
  }

  DownloadStatus get status => _status;
  Timeline get timeline => _timeline;
  VerificationChecksums get checksums => _checksums;
  RetryState get retryState => _retryState;
  DownloadAssetPaths get paths => _paths;

  void startDownload(DateTime startedAt, Checksum expectedChecksum) {
    if (_status != DownloadStatus.pending) {
      throw InvalidStatusTransitionError(
        'Cannot start download from status: $_status',
      );
    }

    _checksums = _checksums.withExpected(expectedChecksum);
    _status = DownloadStatus.downloading;
    _timeline = _timeline.markUpdated(startedAt);

    publish(
      CatalogDownloadStarted(
        job: identifier,
        catalogTrack: catalogTrack,
        downloadUrl: downloadUrl,
        expectedChecksum: expectedChecksum,
      ),
    );
  }

  void markVerifying(Checksum actualChecksum) {
    if (_status != DownloadStatus.downloading) {
      throw InvalidStatusTransitionError(
        'Cannot mark verifying from status: $_status',
      );
    }

    _checksums = _checksums.withActual(actualChecksum);

    final result = _checksums.verificationResult();
    if (result == VerificationResult.mismatched) {
      markFailed(
        FailureReason(
          code: FailureCode.checksumMismatch,
          message: 'Checksum verification failed',
        ),
      );
      return;
    }

    _status = DownloadStatus.verifying;
    _timeline = _timeline.markUpdated(DateTime.now());

    publish(
      CatalogDownloadVerifying(job: identifier, checksum: actualChecksum),
    );
  }

  void markVerified(FileInfo fileInfo) {
    if (_status != DownloadStatus.verifying) {
      throw InvalidStatusTransitionError(
        'Cannot mark verified from status: $_status',
      );
    }

    _status = DownloadStatus.verified;
    _timeline = _timeline.markUpdated(DateTime.now());

    publish(
      CatalogDownloadVerified(
        job: identifier,
        checksum: fileInfo.checksum,
        fileInfo: fileInfo,
      ),
    );
  }

  void startRegistration() {
    if (_status != DownloadStatus.verified) {
      throw InvalidStatusTransitionError(
        'Cannot start registration from status: $_status',
      );
    }

    _status = DownloadStatus.registering;
    _timeline = _timeline.markUpdated(DateTime.now());
  }

  void completeRegistration(FilePath licenseFilePath) {
    if (_status != DownloadStatus.registering) {
      throw InvalidStatusTransitionError(
        'Cannot complete registration from status: $_status',
      );
    }

    _paths = _paths.withLicense(licenseFilePath);
    _paths.requireLicense();

    _status = DownloadStatus.completed;
    _timeline = _timeline.markUpdated(DateTime.now());

    publish(
      CatalogDownloadCompleted(
        job: identifier,
        targetPath: _paths.target,
        licenseFilePath: licenseFilePath,
      ),
    );
  }

  void markFailed(FailureReason reason) {
    _retryState = _retryState.recordFailure(reason);

    if (_retryState.canRetry()) {
      _status = DownloadStatus.pending;
      _timeline = _timeline.markUpdated(DateTime.now());

      publish(
        CatalogDownloadFailed(
          job: identifier,
          reason: reason,
          retriesExhausted: false,
          willRetry: true,
        ),
      );
    } else {
      _status = DownloadStatus.failed;
      _timeline = _timeline.markUpdated(DateTime.now());

      publish(
        CatalogDownloadFailed(
          job: identifier,
          reason: reason,
          retriesExhausted: _retryState.isRetryExhausted(),
          willRetry: false,
        ),
      );
    }
  }

  void clearCache() {
    if (_status == DownloadStatus.downloading ||
        _status == DownloadStatus.verifying ||
        _status == DownloadStatus.registering) {
      throw StateError(
        'Cannot clear cache while download is in progress (status: $_status)',
      );
    }

    _status = DownloadStatus.pending;
    _checksums = VerificationChecksums(expected: _checksums.expected);
    _retryState = RetryState.initial();
    _paths = DownloadAssetPaths(target: _paths.target);
    _timeline = _timeline.markUpdated(DateTime.now());

    publish(
      CatalogCacheCleared(
        job: identifier,
        catalogTrack: catalogTrack,
        targetPath: _paths.target,
      ),
    );
  }

  void requestRedownload() {
    if (_status != DownloadStatus.completed &&
        _status != DownloadStatus.failed) {
      throw StateError(
        'Can only request redownload from Completed or Failed status (current: $_status)',
      );
    }

    clearCache();

    publish(
      CatalogRedownloadRequested(job: identifier, catalogTrack: catalogTrack),
    );
  }
}

abstract class CatalogDownloadEvent extends BaseEvent {
  CatalogDownloadEvent(super.occurredAt);
}

class CatalogDownloadStarted extends CatalogDownloadEvent {
  final CatalogDownloadJobIdentifier job;
  final CatalogTrackIdentifier catalogTrack;
  final SignedURL downloadUrl;
  final Checksum expectedChecksum;

  CatalogDownloadStarted({
    required this.job,
    required this.catalogTrack,
    required this.downloadUrl,
    required this.expectedChecksum,
  }) : super(DateTime.now());
}

class CatalogDownloadVerifying extends CatalogDownloadEvent {
  final CatalogDownloadJobIdentifier job;
  final Checksum checksum;

  CatalogDownloadVerifying({required this.job, required this.checksum})
    : super(DateTime.now());
}

class CatalogDownloadVerified extends CatalogDownloadEvent {
  final CatalogDownloadJobIdentifier job;
  final Checksum checksum;
  final FileInfo fileInfo;

  CatalogDownloadVerified({
    required this.job,
    required this.checksum,
    required this.fileInfo,
  }) : super(DateTime.now());
}

class CatalogDownloadCompleted extends CatalogDownloadEvent {
  final CatalogDownloadJobIdentifier job;
  final FilePath targetPath;
  final FilePath licenseFilePath;

  CatalogDownloadCompleted({
    required this.job,
    required this.targetPath,
    required this.licenseFilePath,
  }) : super(DateTime.now());
}

class CatalogDownloadFailed extends CatalogDownloadEvent {
  final CatalogDownloadJobIdentifier job;
  final FailureReason reason;
  final bool retriesExhausted;
  final bool willRetry;

  CatalogDownloadFailed({
    required this.job,
    required this.reason,
    required this.retriesExhausted,
    required this.willRetry,
  }) : super(DateTime.now());
}

class CatalogCacheCleared extends CatalogDownloadEvent {
  final CatalogDownloadJobIdentifier job;
  final CatalogTrackIdentifier catalogTrack;
  final FilePath targetPath;

  CatalogCacheCleared({
    required this.job,
    required this.catalogTrack,
    required this.targetPath,
  }) : super(DateTime.now());
}

class CatalogRedownloadRequested extends CatalogDownloadEvent {
  final CatalogDownloadJobIdentifier job;
  final CatalogTrackIdentifier catalogTrack;

  CatalogRedownloadRequested({required this.job, required this.catalogTrack})
    : super(DateTime.now());
}

abstract interface class CatalogDownloadJobRepository {
  Future<CatalogDownloadJob> find(CatalogDownloadJobIdentifier identifier);
  Future<CatalogDownloadJob> findOrNull(
    CatalogDownloadJobIdentifier identifier,
  );
  Future<void> persist(CatalogDownloadJob job);
  Future<List<CatalogDownloadJob>> findByStatus(
    DownloadStatus status, {
    int? limit,
  });
  Future<List<CatalogDownloadJob>> findPending({int? limit = 10});
  Future<List<CatalogDownloadJob>> findRetryable({int? limit});
  Future<CatalogDownloadJob> findByCatalogTrack(CatalogTrackIdentifier track);
  Future<void> terminate(CatalogDownloadJobIdentifier identifier);
}

abstract interface class FileDownloadService {
  Future<FileInfo> download(SignedURL url, FilePath destination);
  Future<Checksum> calculateChecksum(FilePath path);
}

abstract interface class StorageQuotaService {
  Future<int> getCurrentUsage();
  Future<int> getQuotaLimit();
  Future<void> reserveSpace(CatalogDownloadJobIdentifier job, int sizeBytes);
  Future<void> releaseSpace(CatalogDownloadJobIdentifier job);
}

abstract interface class LicenseFileWriter {
  Future<FilePath> write(CatalogTrackIdentifier track, String licenseText);
}
