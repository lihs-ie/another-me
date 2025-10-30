import 'package:another_me/domains/common/value_object.dart';
import 'package:another_me/domains/common/variant.dart';

enum URLScheme { http, https, ftp, file }

class URL implements ValueObject {
  static const httpPattern =
      r"^(?:http://[a-zA-Z0-9\-._~:/?#[\]@!$&\'()*+,;=%]+)$";

  static const httpsPattern =
      r"^(?:https://[a-zA-Z0-9\-._~:/?#[\]@!$&\'()*+,;=%]+)$";

  static const ftpPattern =
      r"^(?:ftp://[a-zA-Z0-9\-._~:/?#[\]@!$&\'()*+,;=%]+)$";

  static const filePattern =
      r"^(?:file://[a-zA-Z0-9\-._~:/?#[\]@!$&\'()*+,;=%]+)$";

  final URLScheme scheme;
  final String value;

  URL({required this.scheme, required this.value}) {
    switch (scheme) {
      case URLScheme.http:
        Invariant.pattern(value: value, name: 'value', pattern: httpPattern);
        break;
      case URLScheme.https:
        Invariant.pattern(value: value, name: 'value', pattern: httpsPattern);
        break;
      case URLScheme.ftp:
        Invariant.pattern(value: value, name: 'value', pattern: ftpPattern);
        break;
      case URLScheme.file:
        Invariant.pattern(value: value, name: 'value', pattern: filePattern);
        break;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! URL) {
      return false;
    }

    return scheme == other.scheme && value == other.value;
  }

  @override
  int get hashCode => Object.hash(scheme, value);
}

class SignedURL implements ValueObject {
  final URL url;
  final DateTime expiresAt;

  SignedURL({required this.url, required this.expiresAt}) {
    if (url.scheme != URLScheme.https) {
      throw InvariantViolationError('SignedURL must use HTTPS scheme.');
    }

    final parsed = Uri.parse(url.value);

    final hasSignature =
        parsed.queryParameters.containsKey('Signature') ||
        parsed.queryParameters.containsKey('X-Amz-Signature') ||
        parsed.queryParameters.containsKey('sig') ||
        parsed.queryParameters.containsKey('X-Goog-Signature');

    if (!hasSignature) {
      throw InvariantViolationError('SignedURL must contain a signature.');
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! SignedURL) {
      return false;
    }

    return url == other.url && expiresAt == other.expiresAt;
  }

  @override
  int get hashCode => Object.hash(url, expiresAt);
}
