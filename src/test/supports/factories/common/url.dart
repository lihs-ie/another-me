import 'package:another_me/domains/common/url.dart';

import '../common.dart';
import '../enum.dart';
import 'date.dart';

class URLSchemaFactory extends EnumFactory<URLScheme> {
  URLSchemaFactory() : super(URLScheme.values);
}

class URLFactory extends Factory<URL, ({String? value, URLScheme? scheme})> {
  @override
  URL create({
    ({String? value, URLScheme? scheme})? overrides,
    required int seed,
  }) {
    final schema =
        overrides?.scheme ?? Builder(URLSchemaFactory()).buildWith(seed: seed);
    final value =
        overrides?.value ??
        '${schema.name}://www.example.com/resource/${seed % 1000}';

    return URL(scheme: schema, value: value);
  }

  @override
  URL duplicate(URL instance, ({String? value, URLScheme? scheme})? overrides) {
    final value = overrides?.value ?? instance.value;
    final schema = overrides?.scheme ?? instance.scheme;

    return URL(scheme: schema, value: value);
  }
}

class SignedURLFactory
    extends Factory<SignedURL, ({URL? url, DateTime? expiredAt})> {
  @override
  SignedURL create({
    ({URL? url, DateTime? expiredAt})? overrides,
    required int seed,
  }) {
    final url =
        overrides?.url ??
        Builder(URLFactory()).build(
          overrides: (
            value:
                'https://www.example.com/${seed % 100000000}?Signature=$seed',
            scheme: URLScheme.https,
          ),
        );
    final expiredAt =
        overrides?.expiredAt ??
        Builder(DateTimeFactory()).buildWith(seed: seed);

    return SignedURL(url: url, expiresAt: expiredAt);
  }

  @override
  SignedURL duplicate(
    SignedURL instance,
    ({URL? url, DateTime? expiredAt})? overrides,
  ) {
    final url =
        overrides?.url ??
        Builder(URLFactory()).duplicate(instance: instance.url);
    final expiredAt =
        overrides?.expiredAt ??
        Builder(DateTimeFactory()).duplicate(instance: instance.expiresAt);

    return SignedURL(url: url, expiresAt: expiredAt);
  }
}
