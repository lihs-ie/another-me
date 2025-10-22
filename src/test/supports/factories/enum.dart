import 'common.dart';

typedef Overrides<T extends Enum> = ({List<T>? exclusion});

abstract class EnumFactory<T extends Enum> extends Factory<T, Overrides<T>> {
  final Set<T> _choices;

  EnumFactory(List<T> choices) : _choices = choices.toSet();

  @override
  T create({Overrides<T>? overrides, required int seed}) {
    final candidates = _candidates(overrides: overrides).toList();

    return candidates[seed % candidates.length];
  }

  Set<T> _candidates({Overrides<T>? overrides}) {
    var candidates = Set<T>.from(_choices);

    final exclusion = overrides?.exclusion != null
        ? overrides!.exclusion!.toSet()
        : <T>{};

    candidates.removeWhere((T choice) => exclusion.contains(choice));

    if (candidates.isEmpty) {
      throw StateError('No candidates available for enum factory.');
    }

    return candidates;
  }

  @override
  T duplicate(T instance, Overrides<T>? overrides) => instance;
}
