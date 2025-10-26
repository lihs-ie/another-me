import 'dart:typed_data';

import 'package:another_me/domains/common/identifier.dart';
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
