import 'package:another_me/domains/common/locale.dart';

import '../common.dart';
import '../enum.dart';

class LanguageFactory extends EnumFactory<Language> {
  LanguageFactory() : super(Language.values);
}

typedef I18nMapOverrides<T> = ({List<T>? values});

class I18nMapFactory<T> extends Factory<I18nMap<T>, ({List<T>? values})> {
  final Factory<T, dynamic> _valueFactory;

  I18nMapFactory(this._valueFactory);

  @override
  I18nMap<T> create({({List<T>? values})? overrides, required int seed}) {
    final size = (seed % Language.values.length).truncate() + 1;

    return List.generate(size, (int index) => index).fold(<Language, T>{}, (
      I18nMap<T> carry,
      int current,
    ) {
      final key = Builder(LanguageFactory()).buildWith(seed: seed + current);

      final value = overrides?.values != null
          ? overrides!.values![current % overrides.values!.length]
          : _valueFactory.create(seed: seed + current);

      return carry..[key] = value;
    });
  }

  @override
  I18nMap<T> duplicate(I18nMap<T> instance, ({List<T>? values})? overrides) {
    return instance.map<Language, T>((Language key, T value) {
      final newValue = overrides?.values != null
          ? overrides!.values![0]
          : _valueFactory.duplicate(value, null);
      return MapEntry<Language, T>(key, newValue);
    });
  }
}
