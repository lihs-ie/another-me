import 'package:another_me/domains/licensing.dart' as licensing_domain;

class AttributionViewing {
  final licensing_domain.AttributionBookRepository _attributionBookRepository;
  final licensing_domain.LicenseRecordRepository _licenseRecordRepository;

  AttributionViewing({
    required licensing_domain.AttributionBookRepository
    attributionBookRepository,
    required licensing_domain.LicenseRecordRepository licenseRecordRepository,
  }) : _attributionBookRepository = attributionBookRepository,
       _licenseRecordRepository = licenseRecordRepository;

  Future<List<licensing_domain.AttributionEntry>> viewCredits() async {
    final book = await _attributionBookRepository.current();

    return book.entries;
  }

  Future<licensing_domain.LicenseRecord> viewLicenseDetail({
    required licensing_domain.LicenseIdentifier licenseIdentifier,
  }) async {
    return await _licenseRecordRepository.find(licenseIdentifier);
  }

  Future<List<licensing_domain.AttributionEntry>> searchCredits({
    String? searchText,
  }) async {
    final book = await _attributionBookRepository.current();

    if (searchText == null || searchText.isEmpty) {
      return book.entries;
    }

    final lowerSearchText = searchText.toLowerCase();

    final matchedEntries = <licensing_domain.AttributionEntry>[];

    for (final entry in book.entries) {
      final licenseRecord = await _licenseRecordRepository.find(entry.license);

      final displayNameMatches = entry.displayName.toLowerCase().contains(
        lowerSearchText,
      );

      final attributionTextMatches = entry.attributionText.text
          .toLowerCase()
          .contains(lowerSearchText);

      final licenseNameMatches = licenseRecord.licenseName
          .toLowerCase()
          .contains(lowerSearchText);

      if (displayNameMatches || attributionTextMatches || licenseNameMatches) {
        matchedEntries.add(entry);
      }
    }

    return matchedEntries;
  }
}
