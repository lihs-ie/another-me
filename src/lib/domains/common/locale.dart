enum Language {
  japanese('ja'),
  english('en');

  final String code;
  const Language(this.code);

  static Language from(String code) =>
      Language.values.firstWhere((candidate) => candidate.code == code);
}

typedef I18nMap<T> = Map<Language, T>;
