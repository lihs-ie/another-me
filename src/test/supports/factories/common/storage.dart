import 'package:another_me/domains/common/storage.dart';

import '../common.dart';
import '../enum.dart';
import '../string.dart';

class OperatingSystemFactory extends EnumFactory<OperatingSystem> {
  OperatingSystemFactory() : super(OperatingSystem.values);
}

class FilePathFactory
    extends Factory<FilePath, ({String? value, OperatingSystem? os})> {
  @override
  FilePath create({
    ({String? value, OperatingSystem? os})? overrides,
    required int seed,
  }) {
    final os =
        overrides?.os ??
        Builder(OperatingSystemFactory()).buildWith(seed: seed);

    final valueLength = ((seed % 50).truncate() + 5).clamp(5, 100);

    final extension = [
      'png',
      'json',
      'aac',
      'm4a',
      'mp3',
      'wav',
      'txt',
    ].elementAt(seed % 6);

    final pattern = switch (os) {
      OperatingSystem.macOS => FilePath.macOSValuePattern,
      OperatingSystem.iOS => FilePath.iOSValuePattern,
      OperatingSystem.android => FilePath.androidValuePattern,
      OperatingSystem.windows => FilePath.windowsValuePattern,
    };

    final nonExtensionLength = valueLength - extension.length - 1;

    final value =
        overrides?.value ??
        '${StringFactory.createFromPattern(pattern: pattern, seed: seed, minimumLength: nonExtensionLength, maximumLength: nonExtensionLength)}.$extension';

    return FilePath(value: value, os: os);
  }

  @override
  FilePath duplicate(
    FilePath instance,
    ({String? value, OperatingSystem? os})? overrides,
  ) {
    final value = overrides?.value ?? instance.value;
    final os = overrides?.os ?? instance.os;

    return FilePath(value: value, os: os);
  }
}
