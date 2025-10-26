import 'package:another_me/domains/common/storage.dart';
import 'package:another_me/domains/common/url.dart';
import 'package:another_me/domains/import/catalog.dart';
import 'package:another_me/domains/library/asset.dart';
import 'package:crypto/crypto.dart';

import '../common.dart';
import '../common/date.dart';
import '../common/error.dart';
import '../common/identifier.dart';
import '../common/storage.dart';
import '../common/url.dart';
import '../enum.dart';

import 'package:thirds/blake3.dart';

import '../import/catalog.dart';
import '../string.dart';

class ChecksumAlgorithmFactory extends EnumFactory<ChecksumAlgorithm> {
  ChecksumAlgorithmFactory() : super(ChecksumAlgorithm.values);
}

class _ChecksumCalculator implements ChecksumCalculator {
  @override
  Checksum calculate(FilePath path, ChecksumAlgorithm algorithm) {
    final value = switch (algorithm) {
      ChecksumAlgorithm.sha256 =>
        sha256.convert(path.value.codeUnits).toString(),
      ChecksumAlgorithm.blake3 => blake3(
        path.value.codeUnits,
      ).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(),
    };

    return Checksum(algorithm: algorithm, value: value);
  }
}

class ChecksumCalculatorFactory extends Factory<ChecksumCalculator, void> {
  @override
  ChecksumCalculator create({void overrides, required int seed}) {
    return _ChecksumCalculator();
  }

  @override
  ChecksumCalculator duplicate(ChecksumCalculator instance, void overrides) {
    throw UnimplementedError();
  }
}

class ChecksumFactory
    extends Factory<Checksum, ({ChecksumAlgorithm? algorithm, String? value})> {
  @override
  Checksum create({
    ({ChecksumAlgorithm? algorithm, String? value})? overrides,
    required int seed,
  }) {
    final algorithm =
        overrides?.algorithm ??
        Builder(ChecksumAlgorithmFactory()).buildWith(seed: seed);

    final calculator = Builder(
      ChecksumCalculatorFactory(),
    ).buildWith(seed: seed);

    final value =
        overrides?.value ??
        calculator
            .calculate(
              Builder(FilePathFactory()).buildWith(seed: seed),
              algorithm,
            )
            .value;

    return Checksum(algorithm: algorithm, value: value);
  }

  @override
  Checksum duplicate(
    Checksum instance,
    ({ChecksumAlgorithm? algorithm, String? value})? overrides,
  ) {
    final algorithm = overrides?.algorithm ?? instance.algorithm;
    final value = overrides?.value ?? instance.value;

    return Checksum(algorithm: algorithm, value: value);
  }
}

class FileResourceFactory
    extends
        Factory<
          FileResource,
          ({FilePath? path, int? sizeBytes, Checksum? checksum})
        > {
  @override
  FileResource create({
    ({Checksum? checksum, FilePath? path, int? sizeBytes})? overrides,
    required int seed,
  }) {
    final extension = FileResource.allowedExtensions.elementAt(
      seed % FileResource.allowedExtensions.length,
    );

    final path =
        overrides?.path ??
        Builder(FilePathFactory()).buildWith(
          overrides: (value: 'example_file_$seed.$extension', os: null),
          seed: seed,
        );

    final sizeBytes =
        overrides?.sizeBytes ?? (seed % FileResource.maxFileSizeBytes) + 1;

    final checksum =
        overrides?.checksum ?? Builder(ChecksumFactory()).buildWith(seed: seed);

    return FileResource(path: path, sizeBytes: sizeBytes, checksum: checksum);
  }

  @override
  FileResource duplicate(
    FileResource instance,
    ({Checksum? checksum, FilePath? path, int? sizeBytes})? overrides,
  ) {
    final path =
        overrides?.path ??
        Builder(FilePathFactory()).duplicate(instance: instance.path);
    final sizeBytes = overrides?.sizeBytes ?? instance.sizeBytes;
    final checksum =
        overrides?.checksum ??
        Builder(ChecksumFactory()).duplicate(instance: instance.checksum);

    return FileResource(path: path, sizeBytes: sizeBytes, checksum: checksum);
  }
}

typedef TrackCatalogMetadataOverrides = ({
  CatalogTrackIdentifier? track,
  SignedURL? downloadURL,
  Checksum? checksum,
  CatalogLicenseMetadata? licenseMetadata,
});

class TrackCatalogMetadataFactory
    extends Factory<TrackCatalogMetadata, TrackCatalogMetadataOverrides> {
  @override
  TrackCatalogMetadata create({
    TrackCatalogMetadataOverrides? overrides,
    required int seed,
  }) {
    final track =
        overrides?.track ??
        Builder(CatalogTrackIdentifierFactory()).buildWith(seed: seed);

    final downloadURL =
        overrides?.downloadURL ??
        Builder(SignedURLFactory()).buildWith(seed: seed);

    final checksum =
        overrides?.checksum ?? Builder(ChecksumFactory()).buildWith(seed: seed);

    final licenseMetadata =
        overrides?.licenseMetadata ??
        Builder(CatalogLicenseMetadataFactory()).buildWith(seed: seed);

    return TrackCatalogMetadata(
      track: track,
      downloadURL: downloadURL,
      audioChecksum: checksum,
      licenseMetadata: licenseMetadata,
    );
  }

  @override
  TrackCatalogMetadata duplicate(
    TrackCatalogMetadata instance,
    TrackCatalogMetadataOverrides? overrides,
  ) {
    final track =
        overrides?.track ??
        Builder(
          CatalogTrackIdentifierFactory(),
        ).duplicate(instance: instance.track);

    final downloadURL =
        overrides?.downloadURL ??
        Builder(SignedURLFactory()).duplicate(instance: instance.downloadURL);

    final checksum =
        overrides?.checksum ??
        Builder(ChecksumFactory()).duplicate(instance: instance.audioChecksum);

    final licenseMetadata =
        overrides?.licenseMetadata ??
        Builder(
          CatalogLicenseMetadataFactory(),
        ).duplicate(instance: instance.licenseMetadata);

    return TrackCatalogMetadata(
      track: track,
      downloadURL: downloadURL,
      audioChecksum: checksum,
      licenseMetadata: licenseMetadata,
    );
  }
}

class CatalogStatusFactory extends EnumFactory<CatalogStatus> {
  CatalogStatusFactory() : super(CatalogStatus.values);
}

class AssetPackageIdentifierFactory
    extends ULIDBasedIdentifierFactory<AssetPackageIdentifier> {
  AssetPackageIdentifierFactory()
    : super((value) => AssetPackageIdentifier(value: value));
}

class AssetPackageTypeFactory extends EnumFactory<AssetPackageType> {
  AssetPackageTypeFactory() : super(AssetPackageType.values);
}

typedef AssetPackageOverrides = ({
  AssetPackageIdentifier? identifier,
  AssetPackageType? type,
  List<FileResource>? resources,
  Checksum? checksum,
  String? animationSpecVersion,
  TrackCatalogMetadata? trackMetadata,
});

class AssetPackageFactory extends Factory<AssetPackage, AssetPackageOverrides> {
  @override
  AssetPackage create({AssetPackageOverrides? overrides, required int seed}) {
    final identifier =
        overrides?.identifier ??
        Builder(AssetPackageIdentifierFactory()).buildWith(seed: seed);

    final type =
        overrides?.type ??
        Builder(AssetPackageTypeFactory()).buildWith(seed: seed);

    final resources =
        overrides?.resources ??
        List.generate(
          (seed % 5) + 1,
          (index) =>
              Builder(FileResourceFactory()).buildWith(seed: seed + index),
        );

    final checksum =
        overrides?.checksum ?? Builder(ChecksumFactory()).buildWith(seed: seed);

    final animationSpecVersion =
        overrides?.animationSpecVersion ?? 'v${seed % 2000000000 + 1}';

    TrackCatalogMetadata? trackMetadata = overrides?.trackMetadata;

    if (type == AssetPackageType.track) {
      trackMetadata = Builder(
        TrackCatalogMetadataFactory(),
      ).buildWith(seed: seed);
    }

    return AssetPackage(
      identifier: identifier,
      type: type,
      resources: resources,
      checksum: checksum,
      animationSpecVersion: animationSpecVersion,
      trackMetadata: trackMetadata,
    );
  }

  @override
  AssetPackage duplicate(
    AssetPackage instance,
    AssetPackageOverrides? overrides,
  ) {
    final identifier =
        overrides?.identifier ??
        Builder(
          AssetPackageIdentifierFactory(),
        ).duplicate(instance: instance.identifier);

    final type =
        overrides?.type ??
        Builder(AssetPackageTypeFactory()).duplicate(instance: instance.type);

    final resources =
        overrides?.resources ??
        instance.resources
            .map<FileResource>(
              (resource) =>
                  Builder(FileResourceFactory()).duplicate(instance: resource),
            )
            .toList();

    final checksum =
        overrides?.checksum ??
        Builder(ChecksumFactory()).duplicate(instance: instance.checksum);

    final animationSpecVersion =
        overrides?.animationSpecVersion ?? instance.animationSpecVersion;

    TrackCatalogMetadata? trackMetadata = overrides?.trackMetadata;

    if (type == AssetPackageType.track && trackMetadata == null) {
      trackMetadata = Builder(
        TrackCatalogMetadataFactory(),
      ).duplicate(instance: instance.trackMetadata!);
    }

    return AssetPackage(
      identifier: identifier,
      type: type,
      resources: resources,
      checksum: checksum,
      animationSpecVersion: animationSpecVersion,
      trackMetadata: trackMetadata,
    );
  }
}

class AssetCatalogIdentifierFactory
    extends ULIDBasedIdentifierFactory<AssetCatalogIdentifier> {
  AssetCatalogIdentifierFactory()
    : super((value) => AssetCatalogIdentifier(value: value));
}

class SemanticVersionFactory
    extends Factory<SemanticVersion, ({int? major, int? minor, int? patch})> {
  @override
  SemanticVersion create({
    ({int? major, int? minor, int? patch})? overrides,
    required int seed,
  }) {
    final major = overrides?.major ?? (seed % 100000000000);
    final minor = overrides?.minor ?? (seed % 10000000000);
    final patch = overrides?.patch ?? (seed % 1000000000);

    return SemanticVersion(major: major, minor: minor, patch: patch);
  }

  @override
  SemanticVersion duplicate(
    SemanticVersion instance,
    ({int? major, int? minor, int? patch})? overrides,
  ) {
    final major = overrides?.major ?? instance.major;
    final minor = overrides?.minor ?? instance.minor;
    final patch = overrides?.patch ?? instance.patch;

    return SemanticVersion(major: major, minor: minor, patch: patch);
  }
}

typedef AssetCatalogPublishedOverrides = ({
  AssetCatalogIdentifier? catalog,
  SemanticVersion? version,
  List<AssetPackage>? packages,
});

class AssetCatalogPublishedFactory
    extends Factory<AssetCatalogPublished, AssetCatalogPublishedOverrides> {
  @override
  AssetCatalogPublished create({
    AssetCatalogPublishedOverrides? overrides,
    required int seed,
  }) {
    final catalog =
        overrides?.catalog ??
        Builder(AssetCatalogIdentifierFactory()).buildWith(seed: seed);

    final version =
        overrides?.version ??
        Builder(SemanticVersionFactory()).buildWith(seed: seed);

    final packages =
        overrides?.packages ??
        Builder(
          AssetPackageFactory(),
        ).buildListWith(count: (seed % 5) + 1, seed: seed);

    return AssetCatalogPublished(
      catalog: catalog,
      version: version,
      packages: packages,
    );
  }

  @override
  AssetCatalogPublished duplicate(
    AssetCatalogPublished instance,
    AssetCatalogPublishedOverrides? overrides,
  ) {
    final catalog =
        overrides?.catalog ??
        Builder(
          AssetCatalogIdentifierFactory(),
        ).duplicate(instance: instance.catalog);

    final version =
        overrides?.version ??
        Builder(SemanticVersionFactory()).duplicate(instance: instance.version);

    final packages =
        overrides?.packages ??
        instance.packages
            .map<AssetPackage>(
              (package) =>
                  Builder(AssetPackageFactory()).duplicate(instance: package),
            )
            .toList();

    return AssetCatalogPublished(
      catalog: catalog,
      version: version,
      packages: packages,
    );
  }
}

typedef AssetCatalogUpdatedOverrides = ({
  AssetCatalogIdentifier? catalog,
  SemanticVersion? oldVersion,
  SemanticVersion? newVersion,
});

class AssetCatalogUpdatedFactory
    extends Factory<AssetCatalogUpdated, AssetCatalogUpdatedOverrides> {
  @override
  AssetCatalogUpdated create({
    AssetCatalogUpdatedOverrides? overrides,
    required int seed,
  }) {
    final catalog =
        overrides?.catalog ??
        Builder(AssetCatalogIdentifierFactory()).buildWith(seed: seed);

    final oldVersion = overrides?.oldVersion;

    final newVersion =
        overrides?.newVersion ??
        Builder(SemanticVersionFactory()).buildWith(seed: seed + 1);

    return AssetCatalogUpdated(
      catalog: catalog,
      oldVersion: oldVersion,
      newVersion: newVersion,
    );
  }

  @override
  AssetCatalogUpdated duplicate(
    AssetCatalogUpdated instance,
    AssetCatalogUpdatedOverrides? overrides,
  ) {
    final catalog =
        overrides?.catalog ??
        Builder(
          AssetCatalogIdentifierFactory(),
        ).duplicate(instance: instance.catalog);

    final oldVersion = overrides?.oldVersion != null
        ? Builder(
            SemanticVersionFactory(),
          ).duplicate(instance: instance.oldVersion!)
        : null;

    final newVersion =
        overrides?.newVersion ??
        Builder(
          SemanticVersionFactory(),
        ).duplicate(instance: instance.newVersion);

    return AssetCatalogUpdated(
      catalog: catalog,
      oldVersion: oldVersion,
      newVersion: newVersion,
    );
  }
}

typedef AssetCatalogDeprecatedOverrides = ({
  AssetCatalogIdentifier? catalog,
  String? reason,
});

class AssetCatalogDeprecatedFactory
    extends Factory<AssetCatalogDeprecated, AssetCatalogDeprecatedOverrides> {
  @override
  AssetCatalogDeprecated create({
    AssetCatalogDeprecatedOverrides? overrides,
    required int seed,
  }) {
    final catalog =
        overrides?.catalog ??
        Builder(AssetCatalogIdentifierFactory()).buildWith(seed: seed);

    final reason = overrides?.reason ?? StringFactory.create(seed: seed);

    return AssetCatalogDeprecated(catalog: catalog, reason: reason);
  }

  @override
  AssetCatalogDeprecated duplicate(
    AssetCatalogDeprecated instance,
    AssetCatalogDeprecatedOverrides? overrides,
  ) {
    final catalog =
        overrides?.catalog ??
        Builder(
          AssetCatalogIdentifierFactory(),
        ).duplicate(instance: instance.catalog);

    final reason = overrides?.reason ?? instance.reason;

    return AssetCatalogDeprecated(catalog: catalog, reason: reason);
  }
}

typedef TrackCatalogUpdatedOverrides = ({
  AssetCatalogIdentifier? catalog,
  List<CatalogTrackIdentifier>? addedTracks,
  List<CatalogTrackIdentifier>? updatedTracks,
  List<CatalogTrackIdentifier>? removedTracks,
});

class TrackCatalogUpdatedFactory
    extends Factory<TrackCatalogUpdated, TrackCatalogUpdatedOverrides> {
  @override
  TrackCatalogUpdated create({
    TrackCatalogUpdatedOverrides? overrides,
    required int seed,
  }) {
    final catalog =
        overrides?.catalog ??
        Builder(AssetCatalogIdentifierFactory()).buildWith(seed: seed);

    final addedTracks = overrides?.addedTracks ?? List.empty();
    final updatedTracks = overrides?.updatedTracks ?? List.empty();

    final removedTracks = overrides?.removedTracks ?? List.empty();

    return TrackCatalogUpdated(
      catalog: catalog,
      addedTracks: addedTracks,
      updatedTracks: updatedTracks,
      removedTracks: removedTracks,
    );
  }

  @override
  TrackCatalogUpdated duplicate(
    TrackCatalogUpdated instance,
    TrackCatalogUpdatedOverrides? overrides,
  ) {
    final catalog =
        overrides?.catalog ??
        Builder(
          AssetCatalogIdentifierFactory(),
        ).duplicate(instance: instance.catalog);

    final addedTracks =
        overrides?.addedTracks ??
        instance.addedTracks
            .map(
              (track) => Builder(
                CatalogTrackIdentifierFactory(),
              ).duplicate(instance: track),
            )
            .toList();

    final updatedTracks =
        overrides?.updatedTracks ??
        instance.updatedTracks
            .map(
              (track) => Builder(
                CatalogTrackIdentifierFactory(),
              ).duplicate(instance: track),
            )
            .toList();

    final removedTracks =
        overrides?.removedTracks ??
        instance.removedTracks
            .map(
              (track) => Builder(
                CatalogTrackIdentifierFactory(),
              ).duplicate(instance: track),
            )
            .toList();

    return TrackCatalogUpdated(
      catalog: catalog,
      addedTracks: addedTracks,
      updatedTracks: updatedTracks,
      removedTracks: removedTracks,
    );
  }
}

typedef AssetCatalogOverrides = ({
  AssetCatalogIdentifier? identifier,
  SemanticVersion? version,
  SemanticVersion? minimumAppVersion,
  List<AssetPackage>? packages,
  DateTime? publishedAt,
  CatalogStatus? status,
});

class AssetCatalogFactory extends Factory<AssetCatalog, AssetCatalogOverrides> {
  @override
  AssetCatalog create({AssetCatalogOverrides? overrides, required int seed}) {
    final identifier =
        overrides?.identifier ??
        Builder(AssetCatalogIdentifierFactory()).buildWith(seed: seed);

    final version =
        overrides?.version ??
        Builder(SemanticVersionFactory()).buildWith(seed: seed);

    final minimumAppVersion =
        overrides?.minimumAppVersion ??
        Builder(SemanticVersionFactory()).buildWith(seed: seed + 1);

    final packages =
        overrides?.packages ??
        Builder(
          AssetPackageFactory(),
        ).buildListWith(count: (seed % 5) + 1, seed: seed);

    final publishedAt =
        overrides?.publishedAt ??
        Builder(DateTimeFactory()).buildWith(seed: seed);

    final status =
        overrides?.status ??
        Builder(CatalogStatusFactory()).buildWith(seed: seed);

    return AssetCatalog(
      identifier: identifier,
      version: version,
      minimumAppVersion: minimumAppVersion,
      packages: packages,
      publishedAt: publishedAt,
      status: status,
    );
  }

  @override
  AssetCatalog duplicate(
    AssetCatalog instance,
    AssetCatalogOverrides? overrides,
  ) {
    final identifier =
        overrides?.identifier ??
        Builder(
          AssetCatalogIdentifierFactory(),
        ).duplicate(instance: instance.identifier);

    final version =
        overrides?.version ??
        Builder(SemanticVersionFactory()).duplicate(instance: instance.version);

    final minimumAppVersion =
        overrides?.minimumAppVersion ??
        Builder(
          SemanticVersionFactory(),
        ).duplicate(instance: instance.minimumAppVersion);

    final packages =
        overrides?.packages ??
        instance.packages
            .map<AssetPackage>(
              (package) =>
                  Builder(AssetPackageFactory()).duplicate(instance: package),
            )
            .toList();

    final publishedAt =
        overrides?.publishedAt ??
        Builder(DateTimeFactory()).duplicate(instance: instance.publishedAt);

    final status =
        overrides?.status ??
        Builder(CatalogStatusFactory()).duplicate(instance: instance.status);

    return AssetCatalog(
      identifier: identifier,
      version: version,
      minimumAppVersion: minimumAppVersion,
      packages: packages,
      publishedAt: publishedAt,
      status: status,
    );
  }
}

typedef AssetCatalogRepositoryOverrides = ({
  List<AssetCatalog>? instances,
  void Function(AssetCatalog)? onPersist,
});

class _AssetCatalogRepository implements AssetCatalogRepository {
  final Map<AssetCatalogIdentifier, AssetCatalog> _instances;
  final void Function(AssetCatalog)? _onPersist;

  _AssetCatalogRepository({
    required List<AssetCatalog> instances,
    void Function(AssetCatalog)? onPersist,
  }) : _instances = {
         for (final instance in instances) instance.identifier: instance,
       },
       _onPersist = onPersist;

  @override
  Future<AssetCatalog> find(AssetCatalogIdentifier identifier) {
    final instance = _instances[identifier];

    if (instance == null) {
      throw AggregateNotFoundError(
        'AssetCatalog with identifier ${identifier.value} not found.',
      );
    }

    return Future.value(instance);
  }

  @override
  Future<AssetCatalog> findLatest() {
    if (_instances.isEmpty) {
      throw AggregateNotFoundError('No AssetCatalog instances found.');
    }

    final latest = _instances.values.reduce((left, right) {
      return left.publishedAt.compareTo(right.publishedAt) >= 0 ? left : right;
    });

    return Future.value(latest);
  }

  @override
  Future<void> persist(AssetCatalog catalog) {
    final existing = _instances[catalog.identifier];

    if (existing != null) {
      if (catalog.version.toString().compareTo(existing.version.toString()) <=
          0) {
        throw StateError(
          'Cannot persist AssetCatalog with version '
          '${catalog.version} older than or equal to existing version '
          '${existing.version}.',
        );
      }
    }

    _instances[catalog.identifier] = catalog;

    if (_onPersist != null) {
      _onPersist(catalog);
    }

    return Future.value();
  }
}

class AssetCatalogRepositoryFactory
    extends Factory<AssetCatalogRepository, AssetCatalogRepositoryOverrides> {
  @override
  AssetCatalogRepository create({
    AssetCatalogRepositoryOverrides? overrides,
    required int seed,
  }) {
    final instances =
        overrides?.instances ??
        Builder(
          AssetCatalogFactory(),
        ).buildListWith(count: (seed % 10) + 1, seed: seed);

    return _AssetCatalogRepository(
      instances: instances,
      onPersist: overrides?.onPersist,
    );
  }

  @override
  AssetCatalogRepository duplicate(
    AssetCatalogRepository instance,
    AssetCatalogRepositoryOverrides? overrides,
  ) {
    throw UnimplementedError();
  }
}

class CatalogPublishSubscriberFactory
    extends Factory<CatalogPublishSubscriber, void> {
  @override
  CatalogPublishSubscriber create({void overrides, required int seed}) {
    return CatalogPublishSubscriber();
  }

  @override
  CatalogPublishSubscriber duplicate(
    CatalogPublishSubscriber instance,
    void overrides,
  ) {
    throw UnimplementedError();
  }
}
