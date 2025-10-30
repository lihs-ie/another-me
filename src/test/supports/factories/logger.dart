import 'package:logger/logger.dart';

import 'common.dart';

class LoggerFactory extends Factory<Logger, void> {
  @override
  Logger create({void overrides, required int seed}) {
    return Logger();
  }

  @override
  Logger duplicate(Logger instance, void overrides) {
    throw UnimplementedError();
  }
}
