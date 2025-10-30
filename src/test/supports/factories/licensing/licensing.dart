import 'package:another_me/domains/common/error.dart';
import 'package:another_me/domains/common/storage.dart';
import 'package:another_me/domains/common/transaction.dart';
import 'package:another_me/domains/common/url.dart';
import 'package:another_me/domains/licensing/licensing.dart';
import 'package:another_me/domains/media/media.dart';
import 'package:logger/logger.dart';

import '../common.dart';
import '../common/identifier.dart';
import '../common/storage.dart';
import '../common/transaction.dart';
import '../common/url.dart';
import '../enum.dart';
import '../logger.dart';
import '../media/media.dart';
import '../string.dart';

class LicenseIdentifierFactory
    extends ULIDBasedIdentifierFactory<LicenseIdentifier> {
  LicenseIdentifierFactory()
    : super((value) => LicenseIdentifier(value: value));
}

typedef LicensePolicyOverrides = ({
  bool? commercialUseAllowed,
  bool? redistributionAllowed,
  String? creditRequirement,
  String? memo,
});

class LicensePolicyFactory
    extends Factory<LicensePolicy, LicensePolicyOverrides> {
  @override
  LicensePolicy create({LicensePolicyOverrides? overrides, required int seed}) {
    final commercialUseAllowed =
        overrides?.commercialUseAllowed ?? (seed % 2 == 0);

    final redistributionAllowed =
        overrides?.redistributionAllowed ??
        (commercialUseAllowed ? (seed % 3 == 0) : false);

    final creditRequirement =
        overrides?.creditRequirement ??
        StringFactory.create(
          seed: seed,
          min: 1,
          max: LicensePolicy.maxCreditRequirementLength,
        );

    final memo =
        overrides?.memo ??
        (seed % 2 == 0
            ? StringFactory.create(
                seed: seed,
                min: 1,
                max: LicensePolicy.maxMemoLength,
              )
            : null);

    return LicensePolicy(
      commercialUseAllowed: commercialUseAllowed,
      redistributionAllowed: redistributionAllowed,
      creditRequirement: creditRequirement,
      memo: memo,
    );
  }

  @override
  LicensePolicy duplicate(
    LicensePolicy instance,
    LicensePolicyOverrides? overrides,
  ) {
    final commercialUseAllowed =
        overrides?.commercialUseAllowed ?? instance.commercialUseAllowed;

    final redistributionAllowed =
        overrides?.redistributionAllowed ?? instance.redistributionAllowed;

    final creditRequirement =
        overrides?.creditRequirement ?? instance.creditRequirement;

    final memo = overrides?.memo ?? instance.memo;

    return LicensePolicy(
      commercialUseAllowed: commercialUseAllowed,
      redistributionAllowed: redistributionAllowed,
      creditRequirement: creditRequirement,
      memo: memo,
    );
  }
}

typedef AttributionTextOverrides = ({String? text});

class AttributionTextFactory
    extends Factory<AttributionText, AttributionTextOverrides> {
  @override
  AttributionText create({
    AttributionTextOverrides? overrides,
    required int seed,
  }) {
    final text =
        overrides?.text ??
        StringFactory.create(
          seed: seed,
          min: AttributionText.minLength,
          max: AttributionText.maxLength,
        );

    return AttributionText(text: text);
  }

  @override
  AttributionText duplicate(
    AttributionText instance,
    AttributionTextOverrides? overrides,
  ) {
    final text = overrides?.text ?? instance.text;

    return AttributionText(text: text);
  }
}

class LicenseStatusFactory extends EnumFactory<LicenseStatus> {
  LicenseStatusFactory() : super(LicenseStatus.values);
}

typedef LicenseStatusEntryOverrides = ({
  LicenseStatus? status,
  DateTime? changedAt,
  String? reason,
});

class LicenseStatusEntryFactory
    extends Factory<LicenseStatusEntry, LicenseStatusEntryOverrides> {
  @override
  LicenseStatusEntry create({
    LicenseStatusEntryOverrides? overrides,
    required int seed,
  }) {
    final status =
        overrides?.status ??
        Builder(LicenseStatusFactory()).buildWith(seed: seed);

    final changedAt =
        overrides?.changedAt ?? DateTime.now().add(Duration(seconds: seed));

    final reason =
        overrides?.reason ?? StringFactory.create(seed: seed, min: 1, max: 100);

    return LicenseStatusEntry(
      status: status,
      changedAt: changedAt,
      reason: reason,
    );
  }

  @override
  LicenseStatusEntry duplicate(
    LicenseStatusEntry instance,
    LicenseStatusEntryOverrides? overrides,
  ) {
    final status = overrides?.status ?? instance.status;

    final changedAt = overrides?.changedAt ?? instance.changedAt;

    final reason = overrides?.reason ?? instance.reason;

    return LicenseStatusEntry(
      status: status,
      changedAt: changedAt,
      reason: reason,
    );
  }
}

typedef LicenseRegistrationRequestOverrides = ({
  String? trackTitle,
  String? licenseName,
  URL? licenseURL,
  String? attributionText,
  String? licenseText,
  LicensePolicy? policy,
  URL? sourceURL,
});

class LicenseRegistrationRequestFactory
    extends
        Factory<
          LicenseRegistrationRequest,
          LicenseRegistrationRequestOverrides
        > {
  @override
  LicenseRegistrationRequest create({
    LicenseRegistrationRequestOverrides? overrides,
    required int seed,
  }) {
    final trackTitle =
        overrides?.trackTitle ??
        StringFactory.create(seed: seed, min: 1, max: 100);

    final licenseName =
        overrides?.licenseName ??
        StringFactory.create(seed: seed, min: 1, max: 100);

    final licenseURL =
        overrides?.licenseURL ??
        Builder(URLFactory()).build(
          overrides: (
            scheme: URLScheme.https,
            value: 'https://example.com/license/${seed % 1000}',
          ),
        );

    final attributionText =
        overrides?.attributionText ??
        StringFactory.create(seed: seed, min: 1, max: 500);

    final licenseText =
        overrides?.licenseText ??
        StringFactory.create(seed: seed, min: 1, max: 1000);

    final policy =
        overrides?.policy ??
        Builder(LicensePolicyFactory()).buildWith(seed: seed);

    final sourceURL =
        overrides?.sourceURL ??
        Builder(URLFactory()).build(
          overrides: (
            scheme: URLScheme.https,
            value: 'https://example.com/source/${seed % 1000}',
          ),
        );

    return LicenseRegistrationRequest(
      trackTitle: trackTitle,
      licenseName: licenseName,
      licenseURL: licenseURL,
      attributionText: attributionText,
      licenseText: licenseText,
      policy: policy,
      sourceURL: sourceURL,
    );
  }

  @override
  LicenseRegistrationRequest duplicate(
    LicenseRegistrationRequest instance,
    LicenseRegistrationRequestOverrides? overrides,
  ) {
    final trackTitle = overrides?.trackTitle ?? instance.trackTitle;

    final licenseName = overrides?.licenseName ?? instance.licenseName;

    final licenseURL =
        overrides?.licenseURL ??
        Builder(
          URLFactory(),
        ).duplicate(instance: instance.licenseURL, overrides: null);

    final attributionText =
        overrides?.attributionText ?? instance.attributionText;

    final licenseText = overrides?.licenseText ?? instance.licenseText;

    final policy =
        overrides?.policy ??
        Builder(
          LicensePolicyFactory(),
        ).duplicate(instance: instance.policy, overrides: null);

    final sourceURL =
        overrides?.sourceURL ??
        Builder(
          URLFactory(),
        ).duplicate(instance: instance.sourceURL, overrides: null);

    return LicenseRegistrationRequest(
      trackTitle: trackTitle,
      licenseName: licenseName,
      licenseURL: licenseURL,
      attributionText: attributionText,
      licenseText: licenseText,
      policy: policy,
      sourceURL: sourceURL,
    );
  }
}

typedef LicenseSnapshotOverrides = ({
  LicenseIdentifier? identifier,
  TrackIdentifier? track,
  String? trackTitle,
  String? licenseName,
  URL? licenseURL,
  AttributionText? attributionText,
  LicensePolicy? policy,
  URL? sourceURL,
  List<LicenseStatusEntry>? statusHistory,
  FilePath? licenseFilePath,
  Checksum? licenseFileChecksum,
});

class LicenseSnapshotFactory
    extends Factory<LicenseSnapshot, LicenseSnapshotOverrides> {
  @override
  LicenseSnapshot create({
    LicenseSnapshotOverrides? overrides,
    required int seed,
  }) {
    final identifier =
        overrides?.identifier ??
        Builder(LicenseIdentifierFactory()).buildWith(seed: seed);

    final track =
        overrides?.track ??
        Builder(TrackIdentifierFactory()).buildWith(seed: seed);

    final trackTitle =
        overrides?.trackTitle ??
        StringFactory.create(seed: seed, min: 1, max: 100);

    final licenseName =
        overrides?.licenseName ??
        StringFactory.create(seed: seed, min: 1, max: 100);

    final licenseURL =
        overrides?.licenseURL ??
        Builder(URLFactory()).build(
          overrides: (
            scheme: URLScheme.https,
            value: 'https://example.com/license/${seed % 1000}',
          ),
        );

    final attributionText =
        overrides?.attributionText ??
        Builder(AttributionTextFactory()).buildWith(seed: seed);

    final policy =
        overrides?.policy ??
        Builder(LicensePolicyFactory()).buildWith(seed: seed);

    final sourceURL =
        overrides?.sourceURL ??
        Builder(URLFactory()).build(
          overrides: (
            scheme: URLScheme.https,
            value: 'https://example.com/source/${seed % 1000}',
          ),
        );

    final statusHistory =
        overrides?.statusHistory ??
        Builder(
          LicenseStatusEntryFactory(),
        ).buildListWith(count: (seed % 3) + 1, seed: seed);

    final licenseFilePath =
        overrides?.licenseFilePath ??
        (seed % 2 == 0
            ? Builder(FilePathFactory()).buildWith(seed: seed)
            : null);

    final licenseFileChecksum =
        overrides?.licenseFileChecksum ??
        (licenseFilePath != null
            ? Builder(ChecksumFactory()).buildWith(seed: seed)
            : null);

    return LicenseSnapshot(
      identifier: identifier,
      track: track,
      trackTitle: trackTitle,
      licenseName: licenseName,
      licenseURL: licenseURL,
      attributionText: attributionText,
      policy: policy,
      sourceURL: sourceURL,
      statusHistory: statusHistory,
      licenseFilePath: licenseFilePath,
      licenseFileChecksum: licenseFileChecksum,
    );
  }

  @override
  LicenseSnapshot duplicate(
    LicenseSnapshot instance,
    LicenseSnapshotOverrides? overrides,
  ) {
    throw UnimplementedError();
  }
}

typedef LicenseRecordSearchCriteriaOverrides = ({
  Set<LicenseStatus>? statuses,
  bool? allowOfflineOnly,
});

class LicenseRecordSearchCriteriaFactory
    extends
        Factory<
          LicenseRecordSearchCriteria,
          LicenseRecordSearchCriteriaOverrides
        > {
  @override
  LicenseRecordSearchCriteria create({
    LicenseRecordSearchCriteriaOverrides? overrides,
    required int seed,
  }) {
    final statuses =
        overrides?.statuses ??
        (seed % 2 == 0
            ? {LicenseStatus.values[seed % LicenseStatus.values.length]}
            : null);

    final allowOfflineOnly = overrides?.allowOfflineOnly ?? (seed % 2 == 0);

    return LicenseRecordSearchCriteria(
      statuses: statuses,
      allowOfflineOnly: allowOfflineOnly,
    );
  }

  @override
  LicenseRecordSearchCriteria duplicate(
    LicenseRecordSearchCriteria instance,
    LicenseRecordSearchCriteriaOverrides? overrides,
  ) {
    final statuses = overrides?.statuses ?? instance.statuses;

    final allowOfflineOnly =
        overrides?.allowOfflineOnly ?? instance.allowOfflineOnly;

    return LicenseRecordSearchCriteria(
      statuses: statuses,
      allowOfflineOnly: allowOfflineOnly,
    );
  }
}

class AttributionBookIdentifierFactory
    extends ULIDBasedIdentifierFactory<AttributionBookIdentifier> {
  AttributionBookIdentifierFactory()
    : super((value) => AttributionBookIdentifier(value: value));
}

class AttributionResourceIdentifierFactory
    extends ULIDBasedIdentifierFactory<AttributionResourceIdentifier> {
  AttributionResourceIdentifierFactory()
    : super((value) => AttributionResourceIdentifier(value: value));
}

typedef AttributionEntryOverrides = ({
  AttributionResourceIdentifier? resource,
  String? displayName,
  AttributionText? attributionText,
  LicenseIdentifier? license,
  bool? isValid,
});

class AttributionEntryFactory
    extends Factory<AttributionEntry, AttributionEntryOverrides> {
  @override
  AttributionEntry create({
    AttributionEntryOverrides? overrides,
    required int seed,
  }) {
    final resource =
        overrides?.resource ??
        Builder(AttributionResourceIdentifierFactory()).buildWith(seed: seed);

    final displayName =
        overrides?.displayName ??
        StringFactory.create(seed: seed, min: 1, max: 100);

    final attributionText =
        overrides?.attributionText ??
        Builder(AttributionTextFactory()).buildWith(seed: seed);

    final license =
        overrides?.license ??
        Builder(LicenseIdentifierFactory()).buildWith(seed: seed);

    final isValid = overrides?.isValid ?? true;

    return AttributionEntry(
      resource: resource,
      displayName: displayName,
      attributionText: attributionText,
      license: license,
      isValid: isValid,
    );
  }

  @override
  AttributionEntry duplicate(
    AttributionEntry instance,
    AttributionEntryOverrides? overrides,
  ) {
    final resource =
        overrides?.resource ??
        Builder(
          AttributionResourceIdentifierFactory(),
        ).duplicate(instance: instance.resource, overrides: null);

    final displayName = overrides?.displayName ?? instance.displayName;

    final attributionText =
        overrides?.attributionText ??
        Builder(
          AttributionTextFactory(),
        ).duplicate(instance: instance.attributionText, overrides: null);

    final license =
        overrides?.license ??
        Builder(
          LicenseIdentifierFactory(),
        ).duplicate(instance: instance.license, overrides: null);

    final isValid = overrides?.isValid ?? instance.isValid;

    return AttributionEntry(
      resource: resource,
      displayName: displayName,
      attributionText: attributionText,
      license: license,
      isValid: isValid,
    );
  }
}

typedef AttributionBookOverrides = ({
  AttributionBookIdentifier? identifier,
  List<AttributionEntry>? entries,
  int? publishedVersion,
});

class AttributionBookFactory
    extends Factory<AttributionBook, AttributionBookOverrides> {
  @override
  AttributionBook create({
    AttributionBookOverrides? overrides,
    required int seed,
  }) {
    final identifier =
        overrides?.identifier ??
        Builder(AttributionBookIdentifierFactory()).buildWith(seed: seed);

    final entries =
        overrides?.entries ??
        Builder(
          AttributionEntryFactory(),
        ).buildListWith(count: (seed % 5), seed: seed);

    final publishedVersion = overrides?.publishedVersion ?? (seed % 10);

    return AttributionBook(
      identifier: identifier,
      entries: entries,
      publishedVersion: publishedVersion,
    );
  }

  @override
  AttributionBook duplicate(
    AttributionBook instance,
    AttributionBookOverrides? overrides,
  ) {
    throw UnimplementedError();
  }
}

typedef LicenseRecordRepositoryOverrides = ({
  List<LicenseRecord>? instances,
  void Function(LicenseRecord)? onPersist,
});

class _LicenseRecordRepository implements LicenseRecordRepository {
  final Map<LicenseIdentifier, LicenseRecord> _instances;
  final void Function(LicenseRecord)? _onPersist;

  _LicenseRecordRepository({
    required List<LicenseRecord> instances,
    void Function(LicenseRecord)? onPersist,
  }) : _instances = {
         for (final instance in instances) instance.identifier: instance,
       },
       _onPersist = onPersist;

  @override
  Future<LicenseRecord> find(LicenseIdentifier identifier) {
    final instance = _instances[identifier];

    if (instance == null) {
      throw AggregateNotFoundError(
        'LicenseRecord with identifier ${identifier.value} not found.',
      );
    }

    return Future.value(instance);
  }

  @override
  Future<void> persist(LicenseRecord record) {
    _instances[record.identifier] = record;

    if (_onPersist != null) {
      _onPersist(record);
    }

    return Future.value();
  }

  @override
  Future<List<LicenseRecord>> search(LicenseRecordSearchCriteria criteria) {
    var results = _instances.values.toList();

    if (criteria.statuses != null) {
      results = results
          .where((record) => criteria.statuses!.contains(record.currentStatus))
          .toList();
    }

    if (criteria.allowOfflineOnly) {
      results = results
          .where((record) => record.policy.redistributionAllowed)
          .toList();
    }

    return Future.value(results);
  }
}

class LicenseRecordRepositoryFactory
    extends Factory<LicenseRecordRepository, LicenseRecordRepositoryOverrides> {
  @override
  LicenseRecordRepository create({
    LicenseRecordRepositoryOverrides? overrides,
    required int seed,
  }) {
    final instances = overrides?.instances ?? <LicenseRecord>[];

    return _LicenseRecordRepository(
      instances: instances,
      onPersist: overrides?.onPersist,
    );
  }

  @override
  LicenseRecordRepository duplicate(
    LicenseRecordRepository instance,
    LicenseRecordRepositoryOverrides? overrides,
  ) {
    throw UnimplementedError();
  }
}

typedef AttributionBookRepositoryOverrides = ({
  AttributionBook? book,
  void Function(AttributionBook)? onPersist,
});

class _AttributionBookRepository implements AttributionBookRepository {
  AttributionBook _book;
  final void Function(AttributionBook)? _onPersist;

  _AttributionBookRepository({
    required AttributionBook book,
    void Function(AttributionBook)? onPersist,
  }) : _book = book,
       _onPersist = onPersist;

  @override
  Future<AttributionBook> current() {
    return Future.value(_book);
  }

  @override
  Future<void> persist(AttributionBook book) {
    _book = book;

    if (_onPersist != null) {
      _onPersist(book);
    }

    return Future.value();
  }
}

class AttributionBookRepositoryFactory
    extends
        Factory<AttributionBookRepository, AttributionBookRepositoryOverrides> {
  @override
  AttributionBookRepository create({
    AttributionBookRepositoryOverrides? overrides,
    required int seed,
  }) {
    final book =
        overrides?.book ??
        Builder(AttributionBookFactory()).buildWith(seed: seed);

    return _AttributionBookRepository(
      book: book,
      onPersist: overrides?.onPersist,
    );
  }

  @override
  AttributionBookRepository duplicate(
    AttributionBookRepository instance,
    AttributionBookRepositoryOverrides? overrides,
  ) {
    throw UnimplementedError();
  }
}

typedef LicenseRevocationSubscriberOverrides = ({
  LicenseRecordRepository? licenseRepository,
  TrackRepository? trackRepository,
  AttributionBookRepository? attributionBookRepository,
  Transaction? transaction,
  Logger? logger,
});

class LicenseRevocationSubscriberFactory
    extends
        Factory<
          LicenseRevocationSubscriber,
          LicenseRevocationSubscriberOverrides
        > {
  @override
  LicenseRevocationSubscriber create({
    LicenseRevocationSubscriberOverrides? overrides,
    required int seed,
  }) {
    final licenseRepository =
        overrides?.licenseRepository ??
        Builder(LicenseRecordRepositoryFactory()).buildWith(seed: seed);

    final trackRepository =
        overrides?.trackRepository ??
        Builder(TrackRepositoryFactory()).buildWith(seed: seed);

    final attributionBookRepository =
        overrides?.attributionBookRepository ??
        Builder(AttributionBookRepositoryFactory()).buildWith(seed: seed);

    final transaction =
        overrides?.transaction ??
        Builder(TransactionFactory()).buildWith(seed: seed);

    final logger =
        overrides?.logger ?? Builder(LoggerFactory()).buildWith(seed: seed);

    return LicenseRevocationSubscriber(
      licenseRepository: licenseRepository,
      trackRepository: trackRepository,
      attributionBookRepository: attributionBookRepository,
      transaction: transaction,
      logger: logger,
    );
  }

  @override
  LicenseRevocationSubscriber duplicate(
    LicenseRevocationSubscriber instance,
    LicenseRevocationSubscriberOverrides? overrides,
  ) {
    throw UnimplementedError();
  }
}
