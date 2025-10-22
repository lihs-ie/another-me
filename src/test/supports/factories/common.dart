import 'random.dart';

abstract class Factory<T, O> {
  T create({O? overrides, required int seed});
  T duplicate(T instance, O? overrides);
}

class Builder<T, O> {
  final Set<int> _seeds;
  final Factory<T, O> _factory;

  Builder(this._factory) : _seeds = <int>{};

  List<int> _nextSeeds({required int size}) {
    final next = Randomizer.uniqueNumbers(
      count: _seeds.length + size,
    ).where((int value) => !_seeds.contains(value)).toList();

    _seeds.addAll(next.take(size));

    return next;
  }

  int _nextSeed() {
    return _nextSeeds(size: 1).first;
  }

  T build({O? overrides}) {
    return _factory.create(overrides: overrides, seed: _nextSeed());
  }

  List<T> buildList({required int count, O? overrides}) {
    return _nextSeeds(size: count)
        .map((int seed) => _factory.create(overrides: overrides, seed: seed))
        .toList();
  }

  T duplicate(T instance, O? overrides) {
    return _factory.duplicate(instance, overrides);
  }

  List<T> duplicateList({required List<T> instances, O? overrides}) {
    return instances
        .map((T instance) => _factory.duplicate(instance, overrides))
        .toList();
  }
}
