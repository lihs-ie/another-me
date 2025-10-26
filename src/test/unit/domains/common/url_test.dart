import 'package:another_me/domains/common/url.dart';
import 'package:flutter_test/flutter_test.dart';

import 'value_object.dart';

void main() {
  group('Package domains/common/url', () {
    valueObjectTest(
      constructor: (({URLScheme scheme, String value}) props) =>
          URL(scheme: props.scheme, value: props.value),
      generator: () =>
          (scheme: URLScheme.https, value: 'https://example.com/path'),
      variations: (({URLScheme scheme, String value}) props) => [
        (scheme: URLScheme.http, value: 'http://example.com/path'),
        (scheme: props.scheme, value: 'https://example.com/different-path'),
      ],
      invalids: (({URLScheme scheme, String value}) props) => [
        (scheme: URLScheme.http, value: 'https://example.com'),
        (scheme: URLScheme.http, value: 'ftp://example.com'),
        (scheme: URLScheme.https, value: 'http://example.com'),
        (scheme: URLScheme.https, value: 'file:///path'),
        (scheme: URLScheme.ftp, value: 'http://example.com'),
        (scheme: URLScheme.ftp, value: 'https://example.com'),
        (scheme: URLScheme.file, value: 'http://example.com'),
        (scheme: URLScheme.file, value: 'https://example.com'),
        (scheme: URLScheme.http, value: 'invalid-url'),
        (scheme: URLScheme.https, value: 'not-a-url'),
      ],
    );

    valueObjectTest(
      constructor: (({URL url, DateTime expiresAt}) props) =>
          SignedURL(url: props.url, expiresAt: props.expiresAt),
      generator: () {
        final now = DateTime.now();
        return (
          url: URL(
            scheme: URLScheme.https,
            value: 'https://example.com/resource?Signature=abc123',
          ),
          expiresAt: now.add(const Duration(hours: 1)),
        );
      },
      variations: (({URL url, DateTime expiresAt}) props) => [
        (
          url: URL(
            scheme: URLScheme.https,
            value: 'https://example.com/resource?Signature=different',
          ),
          expiresAt: props.expiresAt,
        ),
        (
          url: props.url,
          expiresAt: props.expiresAt.add(const Duration(hours: 1)),
        ),
      ],
      invalids: (({URL url, DateTime expiresAt}) props) => [
        (
          url: URL(
            scheme: URLScheme.http,
            value: 'http://example.com/resource?Signature=abc123',
          ),
          expiresAt: props.expiresAt,
        ),
        (
          url: URL(
            scheme: URLScheme.https,
            value: 'https://example.com/resource',
          ),
          expiresAt: props.expiresAt,
        ),
        (
          url: URL(
            scheme: URLScheme.https,
            value: 'https://example.com/resource?param=value',
          ),
          expiresAt: props.expiresAt,
        ),
      ],
    );
  });
}
