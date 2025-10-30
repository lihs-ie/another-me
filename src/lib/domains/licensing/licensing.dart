import 'dart:typed_data';

import 'package:another_me/domains/common/event.dart';
import 'package:another_me/domains/common/identifier.dart';
import 'package:another_me/domains/common/storage.dart';
import 'package:another_me/domains/common/transaction.dart';
import 'package:another_me/domains/common/url.dart';
import 'package:another_me/domains/common/value_object.dart';
import 'package:another_me/domains/common/variant.dart';
import 'package:another_me/domains/media/media.dart';
import 'package:ulid/ulid.dart';

class LicenseIdentifier extends ULIDBasedIdentifier {
  LicenseIdentifier({required Ulid value}) : super(value);

  factory LicenseIdentifier.generate() => LicenseIdentifier(value: Ulid());

  factory LicenseIdentifier.fromString(String value) =>
      LicenseIdentifier(value: Ulid.parse(value));

  factory LicenseIdentifier.fromBinary(Uint8List bytes) =>
      LicenseIdentifier(value: Ulid.fromBytes(bytes));

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! LicenseIdentifier) {
      return false;
    }

    return value == other.value;
  }

  @override
  int get hashCode => value.hashCode;
}

class LicensePolicy implements ValueObject {
  static const int maxCreditRequirementLength = 100;
  static const int maxMemoLength = 1000;

  final bool commercialUseAllowed;
  final bool redistributionAllowed;
  final String creditRequirement;
  final String? memo;

  LicensePolicy({
    required this.commercialUseAllowed,
    required this.redistributionAllowed,
    required this.creditRequirement,
    this.memo,
  }) {
    if (creditRequirement.isEmpty ||
        creditRequirement.length > maxCreditRequirementLength) {
      throw InvariantViolationError(
        'creditRequirement must be between 1 and $maxCreditRequirementLength characters.',
      );
    }

    if (memo != null && (memo!.isEmpty || memo!.length > maxMemoLength)) {
      throw InvariantViolationError(
        'memo must be between 1 and $maxMemoLength characters when provided.',
      );
    }

    if (!commercialUseAllowed && redistributionAllowed) {
      throw InvariantViolationError(
        'Cannot allow redistribution while disallowing commercial use.',
      );
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! LicensePolicy) {
      return false;
    }

    return commercialUseAllowed == other.commercialUseAllowed &&
        redistributionAllowed == other.redistributionAllowed &&
        creditRequirement == other.creditRequirement &&
        memo == other.memo;
  }

  @override
  int get hashCode => Object.hash(
    commercialUseAllowed,
    redistributionAllowed,
    creditRequirement,
    memo,
  );
}

class AttributionText implements ValueObject {
  static const int minLength = 1;
  static const int maxLength = 500;

  final String text;

  AttributionText({required String text})
    : text = text.replaceAll(RegExp(r'\r\n|\r'), '\n') {
    if (this.text.length < minLength || this.text.length > maxLength) {
      throw InvariantViolationError(
        'AttributionText must be between $minLength and $maxLength characters.',
      );
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! AttributionText) {
      return false;
    }

    return text == other.text;
  }

  @override
  int get hashCode => text.hashCode;
}

enum LicenseStatus { pending, active, revoked }

class LicenseStatusEntry implements ValueObject {
  final LicenseStatus status;
  final DateTime changedAt;
  final String reason;

  LicenseStatusEntry({
    required this.status,
    required this.changedAt,
    required this.reason,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! LicenseStatusEntry) {
      return false;
    }

    return status == other.status &&
        changedAt == other.changedAt &&
        reason == other.reason;
  }

  @override
  int get hashCode => Object.hash(status, changedAt, reason);
}

class LicenseRegistrationRequest implements ValueObject {
  final String trackTitle;
  final String licenseName;
  final URL licenseURL;
  final String attributionText;
  final String licenseText;
  final LicensePolicy policy;
  final URL sourceURL;

  LicenseRegistrationRequest({
    required this.trackTitle,
    required this.licenseName,
    required this.licenseURL,
    required this.attributionText,
    required this.licenseText,
    required this.policy,
    required this.sourceURL,
  }) {
    if (trackTitle.isEmpty ||
        licenseName.isEmpty ||
        attributionText.isEmpty ||
        licenseText.isEmpty) {
      throw InvariantViolationError('All fields must be non-empty.');
    }

    if (licenseURL.scheme != URLScheme.http &&
        licenseURL.scheme != URLScheme.https) {
      throw InvariantViolationError(
        'licenseURL must use HTTP or HTTPS scheme.',
      );
    }

    if (sourceURL.scheme != URLScheme.http &&
        sourceURL.scheme != URLScheme.https) {
      throw InvariantViolationError('sourceURL must use HTTP or HTTPS scheme.');
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! LicenseRegistrationRequest) {
      return false;
    }

    return trackTitle == other.trackTitle &&
        licenseName == other.licenseName &&
        licenseURL == other.licenseURL &&
        attributionText == other.attributionText &&
        licenseText == other.licenseText &&
        policy == other.policy &&
        sourceURL == other.sourceURL;
  }

  @override
  int get hashCode => Object.hash(
    trackTitle,
    licenseName,
    licenseURL,
    attributionText,
    licenseText,
    policy,
    sourceURL,
  );
}

class LicenseSnapshot implements ValueObject {
  final LicenseIdentifier identifier;
  final TrackIdentifier track;
  final String trackTitle;
  final String licenseName;
  final URL licenseURL;
  final AttributionText attributionText;
  final LicensePolicy policy;
  final URL sourceURL;
  final List<LicenseStatusEntry> statusHistory;
  final FilePath? licenseFilePath;
  final Checksum? licenseFileChecksum;

  LicenseSnapshot({
    required this.identifier,
    required this.track,
    required this.trackTitle,
    required this.licenseName,
    required this.licenseURL,
    required this.attributionText,
    required this.policy,
    required this.sourceURL,
    required this.statusHistory,
    this.licenseFilePath,
    this.licenseFileChecksum,
  }) {
    if (licenseURL.scheme != URLScheme.http &&
        licenseURL.scheme != URLScheme.https) {
      throw InvariantViolationError(
        'licenseURL must use HTTP or HTTPS scheme.',
      );
    }

    if (sourceURL.scheme != URLScheme.http &&
        sourceURL.scheme != URLScheme.https) {
      throw InvariantViolationError('sourceURL must use HTTP or HTTPS scheme.');
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! LicenseSnapshot) {
      return false;
    }

    return identifier == other.identifier &&
        track == other.track &&
        trackTitle == other.trackTitle &&
        licenseName == other.licenseName &&
        licenseURL == other.licenseURL &&
        attributionText == other.attributionText &&
        policy == other.policy &&
        sourceURL == other.sourceURL &&
        _listEquals(statusHistory, other.statusHistory) &&
        licenseFilePath == other.licenseFilePath &&
        licenseFileChecksum == other.licenseFileChecksum;
  }

  @override
  int get hashCode => Object.hash(
    identifier,
    track,
    trackTitle,
    licenseName,
    licenseURL,
    attributionText,
    policy,
    sourceURL,
    Object.hashAll(statusHistory),
    licenseFilePath,
    licenseFileChecksum,
  );

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) {
      return false;
    }

    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }

    return true;
  }
}

class LicenseRecordSearchCriteria implements ValueObject {
  final Set<LicenseStatus>? statuses;
  final bool allowOfflineOnly;

  LicenseRecordSearchCriteria({this.statuses, this.allowOfflineOnly = false}) {
    if (statuses != null && statuses!.isEmpty) {
      throw InvariantViolationError(
        'statuses must not be empty when provided.',
      );
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! LicenseRecordSearchCriteria) {
      return false;
    }

    return _setEquals(statuses, other.statuses) &&
        allowOfflineOnly == other.allowOfflineOnly;
  }

  @override
  int get hashCode => Object.hash(
    statuses != null ? Object.hashAll(statuses!) : null,
    allowOfflineOnly,
  );

  bool _setEquals<T>(Set<T>? left, Set<T>? right) {
    if (left == null && right == null) {
      return true;
    }

    if (left == null || right == null) {
      return false;
    }

    if (left.length != right.length) {
      return false;
    }

    return left.containsAll(right);
  }
}

abstract class LicenseRecordEvent extends BaseEvent {
  LicenseRecordEvent(super.occurredAt);
}

class LicenseRecordRegistered extends LicenseRecordEvent {
  final LicenseIdentifier identifier;
  final TrackIdentifier track;
  final String trackTitle;
  final LicensePolicy policy;

  LicenseRecordRegistered({
    required this.identifier,
    required this.track,
    required this.trackTitle,
    required this.policy,
    required DateTime occurredAt,
  }) : super(occurredAt);
}

class LicenseRecordStatusChanged extends LicenseRecordEvent {
  final LicenseIdentifier identifier;
  final LicenseStatus oldStatus;
  final LicenseStatus newStatus;

  LicenseRecordStatusChanged({
    required this.identifier,
    required this.oldStatus,
    required this.newStatus,
    required DateTime occurredAt,
  }) : super(occurredAt);
}

class LicensePolicyUpdated extends LicenseRecordEvent {
  final LicenseIdentifier identifier;
  final LicensePolicy oldPolicy;
  final LicensePolicy newPolicy;

  LicensePolicyUpdated({
    required this.identifier,
    required this.oldPolicy,
    required this.newPolicy,
    required DateTime occurredAt,
  }) : super(occurredAt);
}

class LicenseRecordRevoked extends LicenseRecordEvent {
  final LicenseIdentifier identifier;
  final TrackIdentifier track;
  final String reason;

  LicenseRecordRevoked({
    required this.identifier,
    required this.track,
    required this.reason,
    required DateTime occurredAt,
  }) : super(occurredAt);
}

class LicenseRecord with Publishable<LicenseRecordEvent> {
  final LicenseIdentifier identifier;
  final TrackIdentifier track;
  final String trackTitle;
  final String licenseName;
  final URL licenseURL;
  final AttributionText attributionText;
  final URL sourceURL;
  final FilePath? licenseFilePath;
  final Checksum? licenseFileChecksum;

  LicensePolicy _policy;
  List<LicenseStatusEntry> _statusHistory;

  LicenseRecord._({
    required this.identifier,
    required this.track,
    required this.trackTitle,
    required this.licenseName,
    required this.licenseURL,
    required this.attributionText,
    required LicensePolicy policy,
    required this.sourceURL,
    required List<LicenseStatusEntry> statusHistory,
    this.licenseFilePath,
    this.licenseFileChecksum,
  }) : _policy = policy,
       _statusHistory = statusHistory {
    if (licenseURL.scheme != URLScheme.http &&
        licenseURL.scheme != URLScheme.https) {
      throw InvariantViolationError(
        'licenseURL must use HTTP or HTTPS scheme.',
      );
    }

    if (sourceURL.scheme != URLScheme.http &&
        sourceURL.scheme != URLScheme.https) {
      throw InvariantViolationError('sourceURL must use HTTP or HTTPS scheme.');
    }

    if (_statusHistory.isEmpty) {
      throw InvariantViolationError('statusHistory must not be empty.');
    }

    for (var i = 1; i < _statusHistory.length; i++) {
      if (_statusHistory[i].changedAt.isBefore(
        _statusHistory[i - 1].changedAt,
      )) {
        throw InvariantViolationError(
          'statusHistory must be in chronological order.',
        );
      }
    }

    final currentStatus = _statusHistory.last.status;

    if (currentStatus == LicenseStatus.revoked &&
        _policy.redistributionAllowed) {
      throw InvariantViolationError(
        'redistributionAllowed must be false when status is revoked.',
      );
    }

    if (licenseFilePath != null && licenseFileChecksum == null) {
      throw InvariantViolationError(
        'licenseFileChecksum is required when licenseFilePath is provided.',
      );
    }
  }

  LicensePolicy get policy => _policy;

  List<LicenseStatusEntry> get statusHistory =>
      List.unmodifiable(_statusHistory);

  LicenseStatus get currentStatus => _statusHistory.last.status;

  factory LicenseRecord.register({
    required LicenseRegistrationRequest request,
    required TrackIdentifier trackIdentifier,
    required FilePath licenseFilePath,
    required Checksum licenseFileChecksum,
  }) {
    final identifier = LicenseIdentifier.generate();

    final attributionText = AttributionText(text: request.attributionText);

    final statusEntry = LicenseStatusEntry(
      status: LicenseStatus.pending,
      changedAt: DateTime.now(),
      reason: 'Initial registration',
    );

    final record = LicenseRecord._(
      identifier: identifier,
      track: trackIdentifier,
      trackTitle: request.trackTitle,
      licenseName: request.licenseName,
      licenseURL: request.licenseURL,
      attributionText: attributionText,
      policy: request.policy,
      sourceURL: request.sourceURL,
      statusHistory: [statusEntry],
      licenseFilePath: licenseFilePath,
      licenseFileChecksum: licenseFileChecksum,
    );

    record.publish(
      LicenseRecordRegistered(
        identifier: identifier,
        track: trackIdentifier,
        trackTitle: request.trackTitle,
        policy: request.policy,
        occurredAt: DateTime.now(),
      ),
    );

    return record;
  }

  void updateStatus(LicenseStatusEntry entry) {
    final currentStatus = _statusHistory.last.status;

    if (currentStatus == LicenseStatus.pending &&
        entry.status != LicenseStatus.active) {
      throw InvariantViolationError(
        'Status can only transition from pending to active.',
      );
    }

    if (currentStatus == LicenseStatus.active &&
        entry.status != LicenseStatus.revoked) {
      throw InvariantViolationError(
        'Status can only transition from active to revoked.',
      );
    }

    if (currentStatus == LicenseStatus.revoked) {
      throw InvariantViolationError('Cannot update status from revoked.');
    }

    final oldStatus = currentStatus;

    _statusHistory = [..._statusHistory, entry];

    if (entry.status == LicenseStatus.revoked) {
      _policy = LicensePolicy(
        commercialUseAllowed: _policy.commercialUseAllowed,
        redistributionAllowed: false,
        creditRequirement: _policy.creditRequirement,
        memo: _policy.memo,
      );
    }

    publish(
      LicenseRecordStatusChanged(
        identifier: identifier,
        oldStatus: oldStatus,
        newStatus: entry.status,
        occurredAt: entry.changedAt,
      ),
    );
  }

  void updatePolicy(LicensePolicy newPolicy) {
    if (currentStatus != LicenseStatus.active) {
      throw InvariantViolationError(
        'Policy can only be updated when status is active.',
      );
    }

    final oldPolicy = _policy;

    _policy = newPolicy;

    publish(
      LicensePolicyUpdated(
        identifier: identifier,
        oldPolicy: oldPolicy,
        newPolicy: newPolicy,
        occurredAt: DateTime.now(),
      ),
    );
  }

  void revoke(String reason) {
    if (currentStatus != LicenseStatus.active) {
      throw InvariantViolationError('Can only revoke active licenses.');
    }

    final entry = LicenseStatusEntry(
      status: LicenseStatus.revoked,
      changedAt: DateTime.now(),
      reason: reason,
    );

    _statusHistory = [..._statusHistory, entry];

    _policy = LicensePolicy(
      commercialUseAllowed: _policy.commercialUseAllowed,
      redistributionAllowed: false,
      creditRequirement: _policy.creditRequirement,
      memo: _policy.memo,
    );

    publish(
      LicenseRecordRevoked(
        identifier: identifier,
        track: track,
        reason: reason,
        occurredAt: DateTime.now(),
      ),
    );
  }

  LicenseSnapshot snapshot() {
    return LicenseSnapshot(
      identifier: identifier,
      track: track,
      trackTitle: trackTitle,
      licenseName: licenseName,
      licenseURL: licenseURL,
      attributionText: attributionText,
      policy: _policy,
      sourceURL: sourceURL,
      statusHistory: _statusHistory,
      licenseFilePath: licenseFilePath,
      licenseFileChecksum: licenseFileChecksum,
    );
  }
}

abstract class LicenseRecordRepository {
  Future<LicenseRecord> find(LicenseIdentifier identifier);

  Future<void> persist(LicenseRecord record);

  Future<List<LicenseRecord>> search(LicenseRecordSearchCriteria criteria);
}

class AttributionBookIdentifier extends ULIDBasedIdentifier {
  AttributionBookIdentifier({required Ulid value}) : super(value);

  factory AttributionBookIdentifier.generate() =>
      AttributionBookIdentifier(value: Ulid());

  factory AttributionBookIdentifier.fromString(String value) =>
      AttributionBookIdentifier(value: Ulid.parse(value));

  factory AttributionBookIdentifier.fromBinary(Uint8List bytes) =>
      AttributionBookIdentifier(value: Ulid.fromBytes(bytes));

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! AttributionBookIdentifier) {
      return false;
    }

    return value == other.value;
  }

  @override
  int get hashCode => value.hashCode;
}

class AttributionResourceIdentifier extends ULIDBasedIdentifier {
  AttributionResourceIdentifier({required Ulid value}) : super(value);

  factory AttributionResourceIdentifier.generate() =>
      AttributionResourceIdentifier(value: Ulid());

  factory AttributionResourceIdentifier.fromString(String value) =>
      AttributionResourceIdentifier(value: Ulid.parse(value));

  factory AttributionResourceIdentifier.fromBinary(Uint8List bytes) =>
      AttributionResourceIdentifier(value: Ulid.fromBytes(bytes));

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! AttributionResourceIdentifier) {
      return false;
    }

    return value == other.value;
  }

  @override
  int get hashCode => value.hashCode;
}

class AttributionEntry implements ValueObject {
  final AttributionResourceIdentifier resource;
  final String displayName;
  final AttributionText attributionText;
  final LicenseIdentifier license;
  final bool isValid;

  AttributionEntry({
    required this.resource,
    required this.displayName,
    required this.attributionText,
    required this.license,
    this.isValid = true,
  });

  AttributionEntry copyWith({bool? isValid}) {
    return AttributionEntry(
      resource: resource,
      displayName: displayName,
      attributionText: attributionText,
      license: license,
      isValid: isValid ?? this.isValid,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! AttributionEntry) {
      return false;
    }

    return resource == other.resource &&
        displayName == other.displayName &&
        attributionText == other.attributionText &&
        license == other.license &&
        isValid == other.isValid;
  }

  @override
  int get hashCode =>
      Object.hash(resource, displayName, attributionText, license, isValid);
}

abstract class AttributionBookEvent extends BaseEvent {
  AttributionBookEvent(super.occurredAt);
}

class AttributionEntryAppended extends AttributionBookEvent {
  final AttributionResourceIdentifier resource;
  final LicenseIdentifier license;

  AttributionEntryAppended({
    required this.resource,
    required this.license,
    required DateTime occurredAt,
  }) : super(occurredAt);
}

class AttributionEntriesInvalidated extends AttributionBookEvent {
  final LicenseIdentifier license;
  final List<AttributionResourceIdentifier> affectedResources;

  AttributionEntriesInvalidated({
    required this.license,
    required this.affectedResources,
    required DateTime occurredAt,
  }) : super(occurredAt);
}

class AttributionBookPublished extends AttributionBookEvent {
  final AttributionBookIdentifier identifier;
  final int version;

  AttributionBookPublished({
    required this.identifier,
    required this.version,
    required DateTime occurredAt,
  }) : super(occurredAt);
}

class AttributionBook with Publishable<AttributionBookEvent> {
  final AttributionBookIdentifier identifier;

  List<AttributionEntry> _entries;
  int _publishedVersion;

  AttributionBook({
    required this.identifier,
    required List<AttributionEntry> entries,
    required int publishedVersion,
  }) : _entries = entries,
       _publishedVersion = publishedVersion {
    final resourceSet = <AttributionResourceIdentifier>{};

    for (final entry in _entries) {
      if (resourceSet.contains(entry.resource)) {
        throw InvariantViolationError(
          'Duplicate resource in attribution entries.',
        );
      }

      resourceSet.add(entry.resource);
    }
  }

  List<AttributionEntry> get entries => List.unmodifiable(_entries);

  int get publishedVersion => _publishedVersion;

  Future<void> appendEntry(
    AttributionEntry entry,
    LicenseRecordRepository licenseRecordRepository,
  ) async {
    final licenseRecord = await licenseRecordRepository.find(entry.license);

    if (licenseRecord.currentStatus != LicenseStatus.active) {
      throw InvariantViolationError('Referenced license is not active.');
    }

    if (_entries.any(
      (existingEntry) => existingEntry.resource == entry.resource,
    )) {
      throw InvariantViolationError(
        'Resource already exists in attribution book.',
      );
    }

    _entries = [..._entries, entry];

    publish(
      AttributionEntryAppended(
        resource: entry.resource,
        license: entry.license,
        occurredAt: DateTime.now(),
      ),
    );
  }

  void invalidateEntriesByLicense(LicenseIdentifier licenseIdentifier) {
    final affectedResources = <AttributionResourceIdentifier>[];

    _entries = _entries.map((entry) {
      if (entry.license == licenseIdentifier && entry.isValid) {
        affectedResources.add(entry.resource);

        return entry.copyWith(isValid: false);
      }

      return entry;
    }).toList();

    if (affectedResources.isNotEmpty) {
      publish(
        AttributionEntriesInvalidated(
          license: licenseIdentifier,
          affectedResources: affectedResources,
          occurredAt: DateTime.now(),
        ),
      );
    }
  }

  void publishVersion(int version) {
    if (version <= _publishedVersion) {
      throw InvariantViolationError(
        'Version must be greater than current published version.',
      );
    }

    _publishedVersion = version;

    publish(
      AttributionBookPublished(
        identifier: identifier,
        version: version,
        occurredAt: DateTime.now(),
      ),
    );
  }
}

abstract class AttributionBookRepository {
  Future<AttributionBook> current();

  Future<void> persist(AttributionBook book);
}

class AttributionPublishSubscriber implements EventSubscriber {
  final LicenseRecordRepository _licenseRepository;
  final AttributionBookRepository _attributionBookRepository;
  final Transaction _transaction;

  AttributionPublishSubscriber({
    required LicenseRecordRepository licenseRepository,
    required AttributionBookRepository attributionBookRepository,
    required Transaction transaction,
  }) : _licenseRepository = licenseRepository,
       _attributionBookRepository = attributionBookRepository,
       _transaction = transaction;

  @override
  void subscribe(EventBroker broker) {
    broker.listen<LicenseRecordRegistered>(_onLicenseRecordRegistered(broker));
  }

  void Function(LicenseRecordRegistered event) _onLicenseRecordRegistered(
    EventBroker broker,
  ) {
    return (LicenseRecordRegistered event) {
      _transaction.execute(() async {
        final licenseRecord = await _licenseRepository.find(event.identifier);
        final attributionBook = await _attributionBookRepository.current();

        final entry = AttributionEntry(
          resource: AttributionResourceIdentifier.generate(),
          displayName: event.trackTitle,
          attributionText: licenseRecord.attributionText,
          license: licenseRecord.identifier,
          isValid: true,
        );

        await attributionBook.appendEntry(entry, _licenseRepository);

        await _attributionBookRepository.persist(attributionBook);

        broker.publishAll(attributionBook.events());
      });
    };
  }
}
