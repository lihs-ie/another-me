import 'package:another_me/domains/common/url.dart';
import 'package:another_me/domains/import/catalog.dart';
import 'package:another_me/domains/library/asset.dart';

import '../common.dart';
import '../common/identifier.dart';
import '../common/url.dart';
import '../library/asset.dart';
import '../string.dart';

class CatalogTrackIdentifierFactory
    extends ULIDBasedIdentifierFactory<CatalogTrackIdentifier> {
  CatalogTrackIdentifierFactory()
    : super((value) => CatalogTrackIdentifier(value: value));
}

typedef CatalogTrackMetadataOverrides = ({
  String? licenseName,
  URL? licenseURL,
  String? attributeText,
  bool? allowOffline,
  bool? redistributionAllowed,
  Checksum? licenseFileChecksum,
});

class CatalogLicenseMetadataFactory
    extends Factory<CatalogLicenseMetadata, CatalogTrackMetadataOverrides> {
  @override
  CatalogLicenseMetadata create({
    CatalogTrackMetadataOverrides? overrides,
    required int seed,
  }) {
    final licenseName =
        overrides?.licenseName ??
        StringFactory.create(
          seed: seed,
          min: 1,
          max: CatalogLicenseMetadata.maxLicenseNameLength,
        );

    final licenseURL =
        overrides?.licenseURL ??
        Builder(URLFactory()).buildWith(
          overrides: (scheme: URLScheme.https, value: null),
          seed: seed,
        );

    final attributeText =
        overrides?.attributeText ??
        StringFactory.create(
          seed: seed,
          min: 0,
          max: CatalogLicenseMetadata.maxAttributeTextLength,
        );

    final allowOffline = overrides?.allowOffline ?? (seed % 2 == 0);

    final redistributionAllowed =
        overrides?.redistributionAllowed ?? (seed % 2 == 1);

    final licenseFileChecksum =
        overrides?.licenseFileChecksum ??
        Builder(ChecksumFactory()).buildWith(seed: seed);

    return CatalogLicenseMetadata(
      licenseName: licenseName,
      licenseURL: licenseURL,
      attributeText: attributeText,
      allowOffline: allowOffline,
      redistributionAllowed: redistributionAllowed,
      licenseFileChecksum: licenseFileChecksum,
    );
  }

  @override
  CatalogLicenseMetadata duplicate(
    CatalogLicenseMetadata instance,
    CatalogTrackMetadataOverrides? overrides,
  ) {
    final licenseName = overrides?.licenseName ?? instance.licenseName;

    final licenseURL =
        overrides?.licenseURL ??
        Builder(URLFactory()).duplicate(
          instance: instance.licenseURL,
          overrides: (scheme: URLScheme.https, value: null),
        );

    final attributeText = overrides?.attributeText ?? instance.attributeText;

    final allowOffline = overrides?.allowOffline ?? instance.allowOffline;

    final redistributionAllowed =
        overrides?.redistributionAllowed ?? instance.redistributionAllowed;

    final licenseFileChecksum =
        overrides?.licenseFileChecksum ??
        Builder(
          ChecksumFactory(),
        ).duplicate(instance: instance.licenseFileChecksum);

    return CatalogLicenseMetadata(
      licenseName: licenseName,
      licenseURL: licenseURL,
      attributeText: attributeText,
      allowOffline: allowOffline,
      redistributionAllowed: redistributionAllowed,
      licenseFileChecksum: licenseFileChecksum,
    );
  }
}
