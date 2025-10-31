import 'package:another_me/domains/licensing.dart';
import 'package:another_me/use_cases/attribution.dart' as use_case;

import '../common.dart';
import '../licensing/licensing.dart' as licensing_factory;

typedef AttributionViewingOverrides = ({
  AttributionBookRepository? attributionBookRepository,
  LicenseRecordRepository? licenseRecordRepository,
});

class AttributionViewingFactory
    extends Factory<use_case.AttributionViewing, AttributionViewingOverrides> {
  @override
  use_case.AttributionViewing create({
    AttributionViewingOverrides? overrides,
    required int seed,
  }) {
    final attributionBookRepository =
        overrides?.attributionBookRepository ??
        Builder(
          licensing_factory.AttributionBookRepositoryFactory(),
        ).buildWith(seed: seed);

    final licenseRecordRepository =
        overrides?.licenseRecordRepository ??
        Builder(
          licensing_factory.LicenseRecordRepositoryFactory(),
        ).buildWith(seed: seed);

    return use_case.AttributionViewing(
      attributionBookRepository: attributionBookRepository,
      licenseRecordRepository: licenseRecordRepository,
    );
  }

  @override
  use_case.AttributionViewing duplicate(
    use_case.AttributionViewing instance,
    AttributionViewingOverrides? overrides,
  ) {
    throw UnimplementedError();
  }
}
