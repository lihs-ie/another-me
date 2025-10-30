import 'package:another_me/domains/common/date.dart';
import 'package:another_me/domains/common/range.dart';
import 'package:another_me/domains/common/url.dart';
import 'package:another_me/domains/common/variant.dart';
import 'package:another_me/domains/import/import.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../supports/factories/common.dart';
import '../../../supports/factories/common/storage.dart';
import '../../../supports/factories/common/url.dart';
import '../../../supports/factories/import/import.dart';
import '../../../supports/factories/string.dart';

void main() {
  group('Package domains/import/import', () {
    group('CatalogTrackMetadata', () {
      group('instantiate', () {
        group('successfully with', () {
          test('valid parameters', () {
            final track = Builder(CatalogTrackIdentifierFactory()).build();

            final title = StringFactory.create(
              seed: 1,
              min: 1,
              max: CatalogTrackMetadata.maxTitleLength,
            );

            final artist = StringFactory.create(
              seed: 2,
              min: 1,
              max: CatalogTrackMetadata.maxArtistLength,
            );

            final durationMilliseconds =
                CatalogTrackMetadata.minDurationMilliseconds + 1000;

            final format = AudioFormat.mp3;

            final loopPoint = Range<num>(start: 100.0, end: 500.0);

            final instance = CatalogTrackMetadata(
              track: track,
              title: title,
              artist: artist,
              durationMilliseconds: durationMilliseconds,
              format: format,
              loopPoint: loopPoint,
            );

            expect(instance.track, equals(track));
            expect(instance.title, equals(title));
            expect(instance.artist, equals(artist));
            expect(instance.durationMilliseconds, equals(durationMilliseconds));
            expect(instance.format, equals(format));
            expect(instance.loopPoint, equals(loopPoint));
          });
        });

        group('unsuccessfully with', () {
          test('empty title', () {
            expect(
              () => CatalogTrackMetadata(
                track: Builder(CatalogTrackIdentifierFactory()).build(),
                title: '',
                artist: 'Artist',
                durationMilliseconds:
                    CatalogTrackMetadata.minDurationMilliseconds + 1000,
                format: AudioFormat.mp3,
                loopPoint: Range<num>(start: 100.0, end: 500.0),
              ),
              throwsA(isA<InvariantViolationError>()),
            );
          });

          test('empty artist', () {
            expect(
              () => CatalogTrackMetadata(
                track: Builder(CatalogTrackIdentifierFactory()).build(),
                title: 'Title',
                artist: '',
                durationMilliseconds:
                    CatalogTrackMetadata.minDurationMilliseconds + 1000,
                format: AudioFormat.mp3,
                loopPoint: Range<num>(start: 100.0, end: 500.0),
              ),
              throwsA(isA<InvariantViolationError>()),
            );
          });

          test('title too long', () {
            expect(
              () => CatalogTrackMetadata(
                track: Builder(CatalogTrackIdentifierFactory()).build(),
                title: 'a' * (CatalogTrackMetadata.maxTitleLength + 1),
                artist: 'Artist',
                durationMilliseconds:
                    CatalogTrackMetadata.minDurationMilliseconds + 1000,
                format: AudioFormat.mp3,
                loopPoint: Range<num>(start: 100.0, end: 500.0),
              ),
              throwsA(isA<InvariantViolationError>()),
            );
          });

          test('artist too long', () {
            expect(
              () => CatalogTrackMetadata(
                track: Builder(CatalogTrackIdentifierFactory()).build(),
                title: 'Title',
                artist: 'a' * (CatalogTrackMetadata.maxArtistLength + 1),
                durationMilliseconds:
                    CatalogTrackMetadata.minDurationMilliseconds + 1000,
                format: AudioFormat.mp3,
                loopPoint: Range<num>(start: 100.0, end: 500.0),
              ),
              throwsA(isA<InvariantViolationError>()),
            );
          });

          test('duration too short', () {
            expect(
              () => CatalogTrackMetadata(
                track: Builder(CatalogTrackIdentifierFactory()).build(),
                title: 'Title',
                artist: 'Artist',
                durationMilliseconds:
                    CatalogTrackMetadata.minDurationMilliseconds - 1,
                format: AudioFormat.mp3,
                loopPoint: Range<num>(start: 100.0, end: 500.0),
              ),
              throwsA(isA<InvariantViolationError>()),
            );
          });

          test('duration too long', () {
            expect(
              () => CatalogTrackMetadata(
                track: Builder(CatalogTrackIdentifierFactory()).build(),
                title: 'Title',
                artist: 'Artist',
                durationMilliseconds:
                    CatalogTrackMetadata.maxDurationMilliseconds + 1,
                format: AudioFormat.mp3,
                loopPoint: Range<num>(start: 100.0, end: 500.0),
              ),
              throwsA(isA<InvariantViolationError>()),
            );
          });

          test('loopPoint start >= end', () {
            expect(
              () => CatalogTrackMetadata(
                track: Builder(CatalogTrackIdentifierFactory()).build(),
                title: 'Title',
                artist: 'Artist',
                durationMilliseconds: 10000,
                format: AudioFormat.mp3,
                loopPoint: Range<num>(start: 500.0, end: 500.0),
              ),
              throwsA(isA<InvariantViolationError>()),
            );
          });

          test('loopPoint end > duration', () {
            expect(
              () => CatalogTrackMetadata(
                track: Builder(CatalogTrackIdentifierFactory()).build(),
                title: 'Title',
                artist: 'Artist',
                durationMilliseconds: 1000,
                format: AudioFormat.mp3,
                loopPoint: Range<num>(start: 100.0, end: 1500.0),
              ),
              throwsA(isA<InvariantViolationError>()),
            );
          });
        });
      });
    });

    group('DownloadJobMetadata', () {
      group('instantiate', () {
        group('successfully with', () {
          test('valid parameters', () {
            final track = Builder(CatalogTrackIdentifierFactory()).build();

            final title = StringFactory.create(
              seed: 1,
              min: 1,
              max: DownloadJobMetadata.maxTitleLength,
            );

            final artist = StringFactory.create(
              seed: 2,
              min: 1,
              max: DownloadJobMetadata.maxArtistLength,
            );

            final durationMilliseconds =
                DownloadJobMetadata.minDurationMilliseconds + 1000;

            final licenseName = 'CC BY 4.0';

            final licenseUrl = Builder(
              URLFactory(),
            ).build(overrides: (scheme: URLScheme.https, value: null));

            final attributionText = 'Attribution text';

            final instance = DownloadJobMetadata(
              track: track,
              title: title,
              artist: artist,
              durationMilliseconds: durationMilliseconds,
              licenseName: licenseName,
              licenseUrl: licenseUrl,
              attributionText: attributionText,
            );

            expect(instance.track, equals(track));
            expect(instance.title, equals(title));
            expect(instance.artist, equals(artist));
            expect(instance.durationMilliseconds, equals(durationMilliseconds));
            expect(instance.licenseName, equals(licenseName));
            expect(instance.licenseUrl, equals(licenseUrl));
            expect(instance.attributionText, equals(attributionText));
          });
        });

        group('unsuccessfully with', () {
          test('non-HTTPS license URL', () {
            expect(
              () => DownloadJobMetadata(
                track: Builder(CatalogTrackIdentifierFactory()).build(),
                title: 'Title',
                artist: 'Artist',
                durationMilliseconds:
                    DownloadJobMetadata.minDurationMilliseconds + 1000,
                licenseName: 'CC BY 4.0',
                licenseUrl: Builder(
                  URLFactory(),
                ).build(overrides: (scheme: URLScheme.http, value: null)),
                attributionText: 'Attribution text',
              ),
              throwsA(isA<InvariantViolationError>()),
            );
          });
        });
      });
    });

    group('FileInfo', () {
      group('instantiate', () {
        group('successfully with', () {
          test('valid parameters', () {
            final path = Builder(FilePathFactory()).build();

            final checksum = Builder(ChecksumFactory()).build();

            final sizeBytes = 1024;

            final instance = FileInfo(
              path: path,
              checksum: checksum,
              sizeBytes: sizeBytes,
            );

            expect(instance.path, equals(path));
            expect(instance.checksum, equals(checksum));
            expect(instance.sizeBytes, equals(sizeBytes));
          });
        });

        group('unsuccessfully with', () {
          test('sizeBytes = 0', () {
            expect(
              () => FileInfo(
                path: Builder(FilePathFactory()).build(),
                checksum: Builder(ChecksumFactory()).build(),
                sizeBytes: 0,
              ),
              throwsA(isA<InvariantViolationError>()),
            );
          });

          test('sizeBytes too large', () {
            expect(
              () => FileInfo(
                path: Builder(FilePathFactory()).build(),
                checksum: Builder(ChecksumFactory()).build(),
                sizeBytes: FileInfo.maxFileSizeBytes + 1,
              ),
              throwsA(isA<InvariantViolationError>()),
            );
          });
        });
      });
    });

    group('RetryState', () {
      group('recordFailure', () {
        test('increments retry count and stores failure reason', () {
          final initialState = Builder(
            RetryStateFactory(),
          ).build(overrides: (failureReason: null, retryCount: 0));

          final reason = Builder(
            FailureReasonFactory(),
          ).build(overrides: (code: FailureCode.networkError, message: null));

          final newState = initialState.recordFailure(reason);

          expect(newState.retryCount, equals(1));
          expect(newState.failureReason, equals(reason));
        });

        test('allows multiple retries up to max', () {
          final state0 = Builder(
            RetryStateFactory(),
          ).build(overrides: (failureReason: null, retryCount: 0));

          final reason = Builder(
            FailureReasonFactory(),
          ).build(overrides: (code: FailureCode.networkError, message: null));

          final state1 = state0.recordFailure(reason);
          expect(state1.canRetry(), isTrue);

          final state2 = state1.recordFailure(reason);
          expect(state2.canRetry(), isTrue);

          final state3 = state2.recordFailure(reason);
          expect(state3.canRetry(), isFalse);
          expect(state3.isRetryExhausted(), isTrue);
        });
      });

      group('reset', () {
        test('resets retry count and clears failure reason', () {
          final state = Builder(RetryStateFactory()).build(
            overrides: (
              failureReason: Builder(FailureReasonFactory()).build(),
              retryCount: 2,
            ),
          );

          final resetState = state.reset();

          expect(resetState.retryCount, equals(0));
          expect(resetState.failureReason, isNull);
        });
      });
    });

    group('DownloadAssetPaths', () {
      group('withTarget', () {
        test('returns new instance with updated target', () {
          final original = Builder(DownloadAssetPathsFactory()).build();

          final newTarget = Builder(FilePathFactory()).build();

          final updated = original.withTarget(newTarget);

          expect(updated.target, equals(newTarget));
          expect(updated.license, equals(original.license));
        });
      });

      group('withLicense', () {
        test('returns new instance with updated license', () {
          final original = Builder(DownloadAssetPathsFactory()).build();

          final newLicense = Builder(FilePathFactory()).build();

          final updated = original.withLicense(newLicense);

          expect(updated.target, equals(original.target));
          expect(updated.license, equals(newLicense));
        });
      });

      group('hasLicense', () {
        test('returns true when license is set', () {
          final paths = Builder(DownloadAssetPathsFactory()).build(
            overrides: (
              target: null,
              license: Builder(FilePathFactory()).build(),
            ),
          );

          expect(paths.hasLicense(), isTrue);
        });

        test('returns false when license is null', () {
          final paths = Builder(
            DownloadAssetPathsFactory(),
          ).build(overrides: (target: null, license: null));

          expect(paths.hasLicense(), isFalse);
        });
      });

      group('requireLicense', () {
        test('does not throw when license is set', () {
          final paths = Builder(DownloadAssetPathsFactory()).build(
            overrides: (
              target: null,
              license: Builder(FilePathFactory()).build(),
            ),
          );

          expect(() => paths.requireLicense(), returnsNormally);
        });

        test('throws when license is null', () {
          final paths = Builder(
            DownloadAssetPathsFactory(),
          ).build(overrides: (target: null, license: null));

          expect(() => paths.requireLicense(), throwsA(isA<StateError>()));
        });
      });
    });

    group('CatalogDownloadJob', () {
      group('startDownload', () {
        test('transitions from pending to downloading', () {
          final job = Builder(CatalogDownloadJobFactory()).build(
            overrides: (
              identifier: null,
              catalogTrack: null,
              downloadUrl: null,
              estimatedSizeBytes: null,
              metadata: null,
              status: DownloadStatus.pending,
              timeline: null,
              checksums: null,
              retryState: null,
              paths: null,
            ),
          );

          final checksum = Builder(ChecksumFactory()).build();

          final startedAt = DateTime.now();

          job.startDownload(startedAt, checksum);

          expect(job.status, equals(DownloadStatus.downloading));
          expect(job.checksums.expected, equals(checksum));
          expect(job.timeline.updatedAt, equals(startedAt));
        });

        test('throws when not in pending status', () {
          final job = Builder(CatalogDownloadJobFactory()).build(
            overrides: (
              identifier: null,
              catalogTrack: null,
              downloadUrl: null,
              estimatedSizeBytes: null,
              metadata: null,
              status: DownloadStatus.downloading,
              timeline: null,
              checksums: null,
              retryState: null,
              paths: null,
            ),
          );

          final checksum = Builder(ChecksumFactory()).build();

          expect(
            () => job.startDownload(DateTime.now(), checksum),
            throwsA(isA<InvalidStatusTransitionError>()),
          );
        });
      });

      group('markVerifying', () {
        test('transitions to verifying with matching checksum', () {
          final expectedChecksum = Builder(ChecksumFactory()).build();

          final job = Builder(CatalogDownloadJobFactory()).build(
            overrides: (
              identifier: null,
              catalogTrack: null,
              downloadUrl: null,
              estimatedSizeBytes: null,
              metadata: null,
              status: DownloadStatus.downloading,
              timeline: null,
              checksums: Builder(
                VerificationChecksumsFactory(),
              ).build(overrides: (expected: expectedChecksum, actual: null)),
              retryState: null,
              paths: null,
            ),
          );

          job.markVerifying(expectedChecksum);

          expect(job.status, equals(DownloadStatus.verifying));
          expect(job.checksums.actual, equals(expectedChecksum));
        });

        test('transitions to failed with mismatched checksum', () {
          final expectedChecksum = Builder(
            ChecksumFactory(),
          ).buildWith(seed: 1);

          final actualChecksum = Builder(ChecksumFactory()).buildWith(seed: 2);

          final job = Builder(CatalogDownloadJobFactory()).build(
            overrides: (
              identifier: null,
              catalogTrack: null,
              downloadUrl: null,
              estimatedSizeBytes: null,
              metadata: null,
              status: DownloadStatus.downloading,
              timeline: Timeline(
                createdAt: DateTime(2025, 1, 1, 10, 0),
                updatedAt: DateTime(2025, 1, 1, 10, 0),
              ),
              checksums: Builder(
                VerificationChecksumsFactory(),
              ).build(overrides: (expected: expectedChecksum, actual: null)),
              retryState: Builder(
                RetryStateFactory(),
              ).build(overrides: (failureReason: null, retryCount: 0)),
              paths: null,
            ),
          );

          job.markVerifying(actualChecksum);

          expect(job.status, equals(DownloadStatus.pending));
          expect(job.retryState.retryCount, equals(1));
        });
      });

      group('completeRegistration', () {
        test('transitions to completed', () {
          final job = Builder(CatalogDownloadJobFactory()).build(
            overrides: (
              identifier: null,
              catalogTrack: null,
              downloadUrl: null,
              estimatedSizeBytes: null,
              metadata: null,
              status: DownloadStatus.registering,
              timeline: null,
              checksums: null,
              retryState: null,
              paths: Builder(DownloadAssetPathsFactory()).build(),
            ),
          );

          final licensePath = Builder(FilePathFactory()).build();

          job.completeRegistration(licensePath);

          expect(job.status, equals(DownloadStatus.completed));
          expect(job.paths.license, equals(licensePath));
        });
      });

      group('markFailed', () {
        test('allows retry when retries not exhausted', () {
          final job = Builder(CatalogDownloadJobFactory()).build(
            overrides: (
              identifier: null,
              catalogTrack: null,
              downloadUrl: null,
              estimatedSizeBytes: null,
              metadata: null,
              status: DownloadStatus.downloading,
              timeline: null,
              checksums: null,
              retryState: Builder(
                RetryStateFactory(),
              ).build(overrides: (failureReason: null, retryCount: 0)),
              paths: null,
            ),
          );

          final reason = Builder(
            FailureReasonFactory(),
          ).build(overrides: (code: FailureCode.networkError, message: null));

          job.markFailed(reason);

          expect(job.status, equals(DownloadStatus.pending));
          expect(job.retryState.retryCount, equals(1));
        });

        test('sets status to failed when retries exhausted', () {
          final initialReason = Builder(
            FailureReasonFactory(),
          ).build(overrides: (code: FailureCode.networkError, message: null));

          final job = Builder(CatalogDownloadJobFactory()).build(
            overrides: (
              identifier: null,
              catalogTrack: null,
              downloadUrl: null,
              estimatedSizeBytes: null,
              metadata: null,
              status: DownloadStatus.downloading,
              timeline: null,
              checksums: null,
              retryState: Builder(RetryStateFactory()).build(
                overrides: (
                  failureReason: initialReason,
                  retryCount: RetryState.maxAllowedRetries - 1,
                ),
              ),
              paths: null,
            ),
          );

          final reason = Builder(
            FailureReasonFactory(),
          ).build(overrides: (code: FailureCode.networkError, message: null));

          job.markFailed(reason);

          expect(job.status, equals(DownloadStatus.failed));
          expect(job.retryState.isRetryExhausted(), isTrue);
        });
      });

      group('requestRedownload', () {
        test('resets job to pending state', () {
          final job = Builder(CatalogDownloadJobFactory()).build(
            overrides: (
              identifier: null,
              catalogTrack: null,
              downloadUrl: null,
              estimatedSizeBytes: null,
              metadata: null,
              status: DownloadStatus.failed,
              timeline: null,
              checksums: null,
              retryState: Builder(RetryStateFactory()).build(
                overrides: (
                  failureReason: Builder(FailureReasonFactory()).build(),
                  retryCount: 2,
                ),
              ),
              paths: null,
            ),
          );

          job.requestRedownload();

          expect(job.status, equals(DownloadStatus.pending));
          expect(job.retryState.retryCount, equals(0));
          expect(job.retryState.failureReason, isNull);
        });
      });
    });
  });
}
