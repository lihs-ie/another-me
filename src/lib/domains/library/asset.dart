import 'dart:typed_data';

import 'package:another_me/domains/common/event.dart';
import 'package:another_me/domains/common/identifier.dart';
import 'package:another_me/domains/common/storage.dart';
import 'package:another_me/domains/common/url.dart';
import 'package:another_me/domains/common/value_object.dart';
import 'package:another_me/domains/common/variant.dart';
import 'package:another_me/domains/import/import.dart';
import 'package:flutter/foundation.dart';
import 'package:ulid/ulid.dart';

class FileResource implements ValueObject {
  final FilePath path;
  final int sizeBytes;
  final Checksum checksum;

  static const int maxFileSizeBytes = 200 * 1024 * 1024; // 200MB

  static const Set<String> allowedExtensions = {
    'png',
    'json',
    'aac',
    'm4a',
    'mp3',
    'wav',
    'txt',
  };

  FileResource({
    required this.path,
    required this.sizeBytes,
    required this.checksum,
  }) {
    Invariant.range(
      value: sizeBytes,
      name: 'sizeBytes',
      min: 1,
      max: maxFileSizeBytes,
    );

    final extension = _getFileExtension(path);

    if (!allowedExtensions.contains(extension)) {
      throw InvariantViolationError(
        'Invalid file extension: "$extension" (path: "${path.value}"). '
        'Allowed extensions: ${allowedExtensions.join(', ')}',
      );
    }
  }

  static String _getFileExtension(FilePath filePath) {
    final value = filePath.value;

    final separator = switch (filePath.os) {
      OperatingSystem.windows => r'\',
      OperatingSystem.macOS ||
      OperatingSystem.iOS ||
      OperatingSystem.android => '/',
    };

    final lastSeparatorIndex = value.lastIndexOf(separator);
    final fileName = lastSeparatorIndex == -1
        ? value
        : value.substring(lastSeparatorIndex + 1);

    final lastDotIndex = fileName.lastIndexOf('.');

    if (lastDotIndex == -1 || lastDotIndex == fileName.length - 1) {
      return '';
    }

    return fileName.substring(lastDotIndex + 1).toLowerCase();
  }

  bool verifyIntegrity(ChecksumCalculator calculator) {
    final actualChecksum = calculator.calculate(path, checksum.algorithm);

    if (actualChecksum != checksum) {
      throw StateError(
        'File integrity check failed for ${path.value}: '
        'expected ${checksum.value}, got ${actualChecksum.value}',
      );
    }

    return true;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! FileResource) {
      return false;
    }

    if (path != other.path) {
      return false;
    }

    if (sizeBytes != other.sizeBytes) {
      return false;
    }

    if (checksum != other.checksum) {
      return false;
    }

    return true;
  }

  @override
  int get hashCode => Object.hash(path, sizeBytes, checksum);
}

class TrackCatalogMetadata implements ValueObject {
  final CatalogTrackIdentifier track;
  final SignedURL downloadURL;
  final Checksum audioChecksum;
  final CatalogLicenseMetadata licenseMetadata;

  TrackCatalogMetadata({
    required this.track,
    required this.downloadURL,
    required this.audioChecksum,
    required this.licenseMetadata,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! TrackCatalogMetadata) {
      return false;
    }

    if (track != other.track) {
      return false;
    }

    if (downloadURL != other.downloadURL) {
      return false;
    }

    if (audioChecksum != other.audioChecksum) {
      return false;
    }

    if (licenseMetadata != other.licenseMetadata) {
      return false;
    }

    return true;
  }

  @override
  int get hashCode =>
      Object.hash(track, downloadURL, audioChecksum, licenseMetadata);
}

enum CatalogStatus { draft, published, deprecated }

class AssetPackageIdentifier extends ULIDBasedIdentifier {
  AssetPackageIdentifier({required Ulid value}) : super(value);

  factory AssetPackageIdentifier.generate() =>
      AssetPackageIdentifier(value: Ulid());

  factory AssetPackageIdentifier.fromString(String value) =>
      AssetPackageIdentifier(value: Ulid.parse(value));

  factory AssetPackageIdentifier.fromBinary(Uint8List bytes) =>
      AssetPackageIdentifier(value: Ulid.fromBytes(bytes));

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! AssetPackageIdentifier) {
      return false;
    }

    return value == other.value;
  }

  @override
  int get hashCode => value.hashCode;
}

enum AssetPackageType { character, scene, ui, sfx, track }

class AssetPackage {
  final AssetPackageIdentifier identifier;
  final AssetPackageType type;
  final List<FileResource> resources;
  final Checksum checksum;
  final String? animationSpecVersion;
  final TrackCatalogMetadata? trackMetadata;

  AssetPackage({
    required this.identifier,
    required this.type,
    required this.resources,
    required this.checksum,
    this.animationSpecVersion,
    this.trackMetadata,
  }) {
    if (type == AssetPackageType.track && trackMetadata == null) {
      throw InvariantViolationError(
        'trackMetadata is required for AssetPackageType.track',
      );
    }
  }

  bool validateFiles(ChecksumCalculator calculator) {
    for (final resource in resources) {
      resource.verifyIntegrity(calculator);
    }

    return true;
  }

  TrackCatalogMetadata extractTrackSeed() {
    if (type != AssetPackageType.track || trackMetadata == null) {
      throw StateError('AssetPackage does not contain track metadata.');
    }

    return trackMetadata!;
  }
}

class AssetCatalogIdentifier extends ULIDBasedIdentifier {
  AssetCatalogIdentifier({required Ulid value}) : super(value);

  factory AssetCatalogIdentifier.generate() =>
      AssetCatalogIdentifier(value: Ulid());

  factory AssetCatalogIdentifier.fromString(String value) =>
      AssetCatalogIdentifier(value: Ulid.parse(value));

  factory AssetCatalogIdentifier.fromBinary(Uint8List bytes) =>
      AssetCatalogIdentifier(value: Ulid.fromBytes(bytes));

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! AssetCatalogIdentifier) {
      return false;
    }

    return value == other.value;
  }

  @override
  int get hashCode => value.hashCode;
}

class SemanticVersion implements ValueObject {
  static const String pattern = r'^\d+\.\d+\.\d+(-[0-9A-Za-z-.]+)?$';

  final int major;
  final int minor;
  final int patch;

  SemanticVersion({
    required this.major,
    required this.minor,
    required this.patch,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! SemanticVersion) {
      return false;
    }

    if (major != other.major) {
      return false;
    }

    if (minor != other.minor) {
      return false;
    }

    if (patch != other.patch) {
      return false;
    }

    return true;
  }

  @override
  int get hashCode => Object.hash(major, minor, patch);

  factory SemanticVersion.fromString(String version) {
    final parts = version.split('.');

    if (parts.length != 3) {
      throw InvariantViolationError(
        'Invalid semantic version format: $version',
      );
    }

    final major = int.parse(parts[0]);
    final minor = int.parse(parts[1]);
    final patch = int.parse(parts[2]);

    return SemanticVersion(major: major, minor: minor, patch: patch);
  }
}

abstract class AssetCatalogEvent extends BaseEvent {
  AssetCatalogEvent(super.occurredAt);
}

class AssetCatalogPublished extends AssetCatalogEvent {
  final AssetCatalogIdentifier catalog;
  final SemanticVersion version;
  final List<AssetPackage> packages;

  AssetCatalogPublished({
    required this.catalog,
    required this.version,
    required this.packages,
  }) : super(DateTime.now());
}

class AssetCatalogUpdated extends AssetCatalogEvent {
  final AssetCatalogIdentifier catalog;
  final List<AssetPackage> updatedPackages;

  AssetCatalogUpdated({required this.catalog, required this.updatedPackages})
    : super(DateTime.now());
}

class AssetCatalogDeprecated extends AssetCatalogEvent {
  final AssetCatalogIdentifier catalog;
  final String reason;

  AssetCatalogDeprecated({required this.catalog, required this.reason})
    : super(DateTime.now());
}

class TrackCatalogUpdated extends AssetCatalogEvent {
  final AssetCatalogIdentifier catalog;
  final List<CatalogTrackIdentifier> addedTracks;
  final List<CatalogTrackIdentifier> updatedTracks;
  final List<CatalogTrackIdentifier> removedTracks;

  TrackCatalogUpdated({
    required this.catalog,
    required this.addedTracks,
    required this.updatedTracks,
    required this.removedTracks,
  }) : super(DateTime.now());
}

class AssetCatalog with Publishable<AssetCatalogEvent> {
  final AssetCatalogIdentifier identifier;
  final SemanticVersion _version;
  final SemanticVersion _minimumAppVersion;
  final List<AssetPackage> _packages;
  DateTime _publishedAt;
  CatalogStatus _status;

  AssetCatalog({
    required this.identifier,
    required SemanticVersion version,
    required SemanticVersion minimumAppVersion,
    required List<AssetPackage> packages,
    required DateTime publishedAt,
    required CatalogStatus status,
  }) : _version = version,
       _minimumAppVersion = minimumAppVersion,
       _packages = packages,
       _publishedAt = publishedAt,
       _status = status;

  SemanticVersion get version => _version;

  SemanticVersion get minimumAppVersion => _minimumAppVersion;

  List<AssetPackage> get packages => List.unmodifiable(_packages);

  DateTime get publishedAt => _publishedAt;

  CatalogStatus get status => _status;

  void addPackage(AssetPackage package) {
    _packages.add(package);
  }

  void release({
    required DateTime publishedAt,
    required ChecksumCalculator calculator,
  }) {
    for (var package in _packages) {
      package.validateFiles(calculator);
    }

    _status = CatalogStatus.published;
    _publishedAt = publishedAt;

    publish(
      AssetCatalogPublished(
        catalog: identifier,
        version: _version,
        packages: List.unmodifiable(_packages),
      ),
    );
  }

  void deprecate(String reason) {
    _status = CatalogStatus.deprecated;

    publish(AssetCatalogDeprecated(catalog: identifier, reason: reason));
  }
}

abstract interface class AssetCatalogRepository {
  Future<AssetCatalog> findLatest();
  Future<AssetCatalog> find(AssetCatalogIdentifier identifier);
  Future<void> persist(AssetCatalog catalog);
}

class CatalogPublishSubscriber implements EventSubscriber {
  @override
  void subscribe(EventBroker broker) {
    broker.listen<AssetCatalogPublished>(_onAssetCatalogPublished(broker));
  }

  void Function(AssetCatalogPublished) _onAssetCatalogPublished(
    EventBroker broker,
  ) {
    return (AssetCatalogPublished event) {
      broker.publish(
        AssetCatalogUpdated(
          catalog: event.catalog,
          updatedPackages: event.packages,
        ),
      );
    };
  }
}
