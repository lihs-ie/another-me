import 'common.dart';

abstract class MapFactory<K, KO, V, VO>
    extends Factory<Map<K, V>, ({KO? key, VO? value})> {
  final Factory<K, KO> keyFactory;
  final Factory<V, VO> valueFactory;

  MapFactory(this.keyFactory, this.valueFactory);

  @override
  Map<K, V> create({({KO? key, VO? value})? overrides, required int seed}) {
    return List.generate((seed % 10) + 1, (int index) => index).fold<Map<K, V>>(
      {},
      (Map<K, V> carry, int current) {
        final key = keyFactory.create(
          overrides: overrides?.key,
          seed: seed + current,
        );
        final value = valueFactory.create(
          overrides: overrides?.value,
          seed: seed + current,
        );

        return carry..[key] = value;
      },
    );
  }

  @override
  Map<K, V> duplicate(Map<K, V> instance, ({KO? key, VO? value})? overrides) {
    return instance.map<K, V>(
      (K key, V value) => MapEntry<K, V>(
        keyFactory.duplicate(key, overrides?.key),
        valueFactory.duplicate(value, overrides?.value),
      ),
    );
  }
}
