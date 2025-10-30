import 'package:another_me/domains/common/identifier.dart';
import 'package:ulid/ulid.dart';
import 'dart:typed_data';
import 'package:crypto/crypto.dart' show sha256;

import '../common.dart';

abstract class ULIDBasedIdentifierFactory<T extends ULIDBasedIdentifier>
    extends Factory<T, ({Ulid? value})> {
  T Function(Ulid value) creator;

  ULIDBasedIdentifierFactory(this.creator);

  @override
  T create({({Ulid? value})? overrides, required int seed}) {
    final value = overrides?.value ?? _valueFromSeed(seed);

    return creator(value);
  }

  @override
  T duplicate(T instance, ({Ulid? value})? overrides) {
    final value = overrides?.value ?? instance.value;

    return creator(value);
  }

  Ulid _valueFromSeed(int seed) {
    const int mask32 = 0xFFFFFFFF;
    final int normalized = seed & mask32;
    final double fraction = normalized / mask32;
    final DateTime min = DateTime.utc(1970, 1, 1);
    final DateTime max = DateTime.utc(2106, 1, 1);
    final int spanMs = max.millisecondsSinceEpoch - min.millisecondsSinceEpoch;
    final int tsMs = min.millisecondsSinceEpoch + (fraction * spanMs).floor();

    final bytes = Uint8List(16);

    final tbd = ByteData(8)..setInt64(0, tsMs);
    for (var i = 0; i < 6; i++) {
      bytes[i] = tbd.getUint8(i + 2);
    }

    final seedBytes = ByteData(8)..setInt64(0, seed);
    final input = Uint8List(16)
      ..setAll(0, tbd.buffer.asUint8List())
      ..setAll(8, seedBytes.buffer.asUint8List());

    final digest = sha256.convert(input).bytes;
    for (var i = 0; i < 10; i++) {
      bytes[6 + i] = digest[i];
    }

    return Ulid.fromBytes(bytes);
  }
}
