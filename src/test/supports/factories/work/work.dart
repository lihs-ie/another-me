import 'package:another_me/domains/common/error.dart';
import 'package:another_me/domains/profile/profile.dart';
import 'package:another_me/domains/work/work.dart';
import 'package:ulid/ulid.dart';

import '../common.dart';
import '../common/identifier.dart';
import '../enum.dart';
import '../profile/profile.dart';

class PomodoroSessionIdentifierFactory
    extends ULIDBasedIdentifierFactory<PomodoroSessionIdentifier> {
  PomodoroSessionIdentifierFactory()
    : super((Ulid value) => PomodoroSessionIdentifier(value));
}

class PomodoroSessionStatusFactory extends EnumFactory<PomodoroSessionStatus> {
  PomodoroSessionStatusFactory() : super(PomodoroSessionStatus.values);
}

class SessionPhaseFactory extends EnumFactory<SessionPhase> {
  SessionPhaseFactory() : super(SessionPhase.values);
}

typedef PomodoroPolicySnapshotOverrides = ({
  int? workMinutes,
  int? breakMinutes,
  int? longBreakMinutes,
  int? longBreakEvery,
  bool? longBreakEnabled,
});

class PomodoroPolicySnapshotFactory
    extends Factory<PomodoroPolicySnapshot, PomodoroPolicySnapshotOverrides> {
  @override
  PomodoroPolicySnapshot create({
    PomodoroPolicySnapshotOverrides? overrides,
    required int seed,
  }) {
    final workMinutes = overrides?.workMinutes ?? ((seed % 120) + 1);

    final breakMinutes = overrides?.breakMinutes ?? ((seed % 30) + 1);

    final longBreakMinutes = overrides?.longBreakMinutes ?? ((seed % 60) + 1);

    final longBreakEvery = overrides?.longBreakEvery ?? ((seed % 10) + 1);

    final longBreakEnabled = overrides?.longBreakEnabled ?? (seed % 2 == 0);

    return PomodoroPolicySnapshot(
      workMinutes: workMinutes,
      breakMinutes: breakMinutes,
      longBreakMinutes: longBreakMinutes,
      longBreakEvery: longBreakEvery,
      longBreakEnabled: longBreakEnabled,
    );
  }

  @override
  PomodoroPolicySnapshot duplicate(
    PomodoroPolicySnapshot instance,
    PomodoroPolicySnapshotOverrides? overrides,
  ) {
    final workMinutes = overrides?.workMinutes ?? instance.workMinutes;

    final breakMinutes = overrides?.breakMinutes ?? instance.breakMinutes;

    final longBreakMinutes =
        overrides?.longBreakMinutes ?? instance.longBreakMinutes;

    final longBreakEvery = overrides?.longBreakEvery ?? instance.longBreakEvery;

    final longBreakEnabled =
        overrides?.longBreakEnabled ?? instance.longBreakEnabled;

    return PomodoroPolicySnapshot(
      workMinutes: workMinutes,
      breakMinutes: breakMinutes,
      longBreakMinutes: longBreakMinutes,
      longBreakEvery: longBreakEvery,
      longBreakEnabled: longBreakEnabled,
    );
  }
}

typedef RemainingTimeOverrides = ({int? ms});

class RemainingTimeFactory
    extends Factory<RemainingTime, RemainingTimeOverrides> {
  @override
  RemainingTime create({RemainingTimeOverrides? overrides, required int seed}) {
    final ms = overrides?.ms ?? ((seed % 3600000) + 1000);

    return RemainingTime(ms: ms);
  }

  @override
  RemainingTime duplicate(
    RemainingTime instance,
    RemainingTimeOverrides? overrides,
  ) {
    final ms = overrides?.ms ?? instance.ms;

    return RemainingTime(ms: ms);
  }
}

typedef PhaseHistoryOverrides = ({
  SessionPhase? phase,
  DateTime? startedAt,
  DateTime? endedAt,
  bool? skipped,
});

class PhaseHistoryFactory extends Factory<PhaseHistory, PhaseHistoryOverrides> {
  @override
  PhaseHistory create({PhaseHistoryOverrides? overrides, required int seed}) {
    final phase =
        overrides?.phase ??
        Builder(SessionPhaseFactory()).buildWith(seed: seed);

    final startedAt =
        overrides?.startedAt ??
        DateTime(2025, 1, 1).add(Duration(minutes: seed));

    final endedAt =
        overrides?.endedAt ?? startedAt.add(Duration(minutes: (seed % 60) + 1));

    final skipped = overrides?.skipped ?? (seed % 3 == 0);

    return PhaseHistory(
      phase: phase,
      startedAt: startedAt,
      endedAt: endedAt,
      skipped: skipped,
    );
  }

  @override
  PhaseHistory duplicate(
    PhaseHistory instance,
    PhaseHistoryOverrides? overrides,
  ) {
    final phase =
        overrides?.phase ??
        Builder(
          SessionPhaseFactory(),
        ).duplicate(instance: instance.phase, overrides: null);

    final startedAt = overrides?.startedAt ?? instance.startedAt;

    final endedAt = overrides?.endedAt ?? instance.endedAt;

    final skipped = overrides?.skipped ?? instance.skipped;

    return PhaseHistory(
      phase: phase,
      startedAt: startedAt,
      endedAt: endedAt,
      skipped: skipped,
    );
  }
}

typedef PomodoroSessionOverrides = ({
  PomodoroSessionIdentifier? identifier,
  PomodoroSessionStatus? status,
  SessionPhase? phase,
  RemainingTime? remainingTime,
  int? elapsedCycles,
  PomodoroPolicySnapshot? policySnapshot,
  List<PhaseHistory>? phaseHistory,
  DateTime? lastTickAt,
});

class PomodoroSessionFactory
    extends Factory<PomodoroSession, PomodoroSessionOverrides> {
  @override
  PomodoroSession create({
    PomodoroSessionOverrides? overrides,
    required int seed,
  }) {
    final identifier =
        overrides?.identifier ??
        Builder(PomodoroSessionIdentifierFactory()).buildWith(seed: seed);

    final policySnapshot =
        overrides?.policySnapshot ??
        Builder(PomodoroPolicySnapshotFactory()).buildWith(seed: seed);

    return PomodoroSession.create(
      identifier: identifier,
      policySnapshot: policySnapshot,
    );
  }

  @override
  PomodoroSession duplicate(
    PomodoroSession instance,
    PomodoroSessionOverrides? overrides,
  ) {
    throw UnimplementedError();
  }
}

typedef PomodoroSessionSearchCriteriaOverrides = ({
  ProfileIdentifier? profile,
  PomodoroSessionStatus? status,
});

class PomodoroSessionSearchCriteriaFactory
    extends
        Factory<
          PomodoroSessionSearchCriteria,
          PomodoroSessionSearchCriteriaOverrides
        > {
  @override
  PomodoroSessionSearchCriteria create({
    PomodoroSessionSearchCriteriaOverrides? overrides,
    required int seed,
  }) {
    final profile =
        overrides?.profile ??
        Builder(ProfileIdentifierFactory()).buildWith(seed: seed);

    final status =
        overrides?.status ??
        Builder(PomodoroSessionStatusFactory()).buildWith(seed: seed);

    return PomodoroSessionSearchCriteria(profile: profile, status: status);
  }

  @override
  PomodoroSessionSearchCriteria duplicate(
    PomodoroSessionSearchCriteria instance,
    PomodoroSessionSearchCriteriaOverrides? overrides,
  ) {
    final profile = overrides?.profile ?? instance.profile;

    final status =
        overrides?.status ??
        Builder(
          PomodoroSessionStatusFactory(),
        ).duplicate(instance: instance.status, overrides: null);

    return PomodoroSessionSearchCriteria(profile: profile, status: status);
  }
}

typedef PomodoroSessionRepositoryOverrides = ({
  List<PomodoroSession>? instances,
  void Function(PomodoroSession)? onPersist,
});

class _PomodoroSessionRepository implements PomodoroSessionRepository {
  final Map<PomodoroSessionIdentifier, PomodoroSession> _instances;
  final void Function(PomodoroSession)? _onPersist;

  _PomodoroSessionRepository({
    required List<PomodoroSession> instances,
    void Function(PomodoroSession)? onPersist,
  }) : _instances = {},
       _onPersist = onPersist {
    for (final instance in instances) {
      _instances[instance.identifier] = instance;
    }
  }

  @override
  Future<PomodoroSession> search(PomodoroSessionSearchCriteria criteria) {
    final instance = _instances.values.firstWhere(
      (session) => session.status == criteria.status,
      orElse: () => throw AggregateNotFoundError(
        'PomodoroSession with status ${criteria.status} not found.',
      ),
    );

    return Future.value(instance);
  }

  @override
  Future<void> persist(PomodoroSession session) {
    _instances[session.identifier] = session;

    if (_onPersist != null) {
      _onPersist(session);
    }

    return Future.value();
  }

  @override
  Future<void> terminate(PomodoroSessionIdentifier identifier) {
    _instances.remove(identifier);
    return Future.value();
  }
}

class PomodoroSessionRepositoryFactory
    extends
        Factory<PomodoroSessionRepository, PomodoroSessionRepositoryOverrides> {
  @override
  PomodoroSessionRepository create({
    PomodoroSessionRepositoryOverrides? overrides,
    required int seed,
  }) {
    final instances =
        overrides?.instances ??
        Builder(
          PomodoroSessionFactory(),
        ).buildListWith(count: (seed % 5) + 1, seed: seed);

    return _PomodoroSessionRepository(
      instances: instances,
      onPersist: overrides?.onPersist,
    );
  }

  @override
  PomodoroSessionRepository duplicate(
    PomodoroSessionRepository instance,
    PomodoroSessionRepositoryOverrides? overrides,
  ) {
    throw UnimplementedError();
  }
}

class SessionLogIdentifierFactory
    extends ULIDBasedIdentifierFactory<SessionLogIdentifier> {
  SessionLogIdentifierFactory()
    : super((Ulid value) => SessionLogIdentifier(value));
}

typedef PhaseSummaryOverrides = ({
  SessionPhase? phase,
  int? actualDurationMs,
  bool? skipped,
  DateTime? startedAt,
  DateTime? endedAt,
});

class PhaseSummaryFactory extends Factory<PhaseSummary, PhaseSummaryOverrides> {
  @override
  PhaseSummary create({PhaseSummaryOverrides? overrides, required int seed}) {
    final phase =
        overrides?.phase ??
        Builder(SessionPhaseFactory()).buildWith(seed: seed);

    final startedAt =
        overrides?.startedAt ??
        DateTime(2025, 1, 1).add(Duration(minutes: seed));

    final endedAt =
        overrides?.endedAt ?? startedAt.add(Duration(minutes: (seed % 60) + 1));

    final actualDurationMs =
        overrides?.actualDurationMs ??
        endedAt.difference(startedAt).inMilliseconds;

    final skipped = overrides?.skipped ?? (seed % 3 == 0);

    return PhaseSummary(
      phase: phase,
      actualDurationMs: actualDurationMs,
      skipped: skipped,
      startedAt: startedAt,
      endedAt: endedAt,
    );
  }

  @override
  PhaseSummary duplicate(
    PhaseSummary instance,
    PhaseSummaryOverrides? overrides,
  ) {
    final phase =
        overrides?.phase ??
        Builder(
          SessionPhaseFactory(),
        ).duplicate(instance: instance.phase, overrides: null);

    final actualDurationMs =
        overrides?.actualDurationMs ?? instance.actualDurationMs;

    final skipped = overrides?.skipped ?? instance.skipped;

    final startedAt = overrides?.startedAt ?? instance.startedAt;

    final endedAt = overrides?.endedAt ?? instance.endedAt;

    return PhaseSummary(
      phase: phase,
      actualDurationMs: actualDurationMs,
      skipped: skipped,
      startedAt: startedAt,
      endedAt: endedAt,
    );
  }
}

typedef SessionLogOverrides = ({
  SessionLogIdentifier? identifier,
  PomodoroSessionIdentifier? session,
  ProfileIdentifier? profile,
  DateTime? startedAt,
  DateTime? endedAt,
  int? totalWorkMs,
  int? totalBreakMs,
  int? cycleCount,
  List<PhaseSummary>? phaseSummaries,
});

class SessionLogFactory extends Factory<SessionLog, SessionLogOverrides> {
  @override
  SessionLog create({SessionLogOverrides? overrides, required int seed}) {
    final identifier =
        overrides?.identifier ??
        Builder(SessionLogIdentifierFactory()).buildWith(seed: seed);

    final session =
        overrides?.session ??
        Builder(PomodoroSessionIdentifierFactory()).buildWith(seed: seed);

    final profile =
        overrides?.profile ??
        Builder(ProfileIdentifierFactory()).buildWith(seed: seed);

    final startedAt =
        overrides?.startedAt ??
        DateTime(2025, 1, 1).add(Duration(minutes: seed));

    final endedAt =
        overrides?.endedAt ?? startedAt.add(Duration(hours: (seed % 8) + 1));

    final phaseSummaries =
        overrides?.phaseSummaries ??
        Builder(
          PhaseSummaryFactory(),
        ).buildListWith(count: (seed % 10) + 2, seed: seed);

    final totalWorkMs =
        overrides?.totalWorkMs ??
        phaseSummaries
            .where((summary) => summary.phase == SessionPhase.work)
            .fold<int>(0, (sum, summary) => sum + summary.actualDurationMs);

    final totalBreakMs =
        overrides?.totalBreakMs ??
        phaseSummaries
            .where(
              (summary) =>
                  summary.phase == SessionPhase.break_ ||
                  summary.phase == SessionPhase.longBreak,
            )
            .fold<int>(0, (sum, summary) => sum + summary.actualDurationMs);

    final cycleCount =
        overrides?.cycleCount ??
        phaseSummaries
            .where(
              (summary) =>
                  summary.phase == SessionPhase.work && !summary.skipped,
            )
            .length;

    return SessionLog.record(
      identifier: identifier,
      session: session,
      profile: profile,
      startedAt: startedAt,
      endedAt: endedAt,
      totalWorkMs: totalWorkMs,
      totalBreakMs: totalBreakMs,
      cycleCount: cycleCount,
      phaseSummaries: phaseSummaries,
      occurredAt: endedAt,
    );
  }

  @override
  SessionLog duplicate(SessionLog instance, SessionLogOverrides? overrides) {
    throw UnimplementedError();
  }
}

typedef DateRangeOverrides = ({DateTime? start, DateTime? end});

class DateRangeFactory extends Factory<DateRange, DateRangeOverrides> {
  @override
  DateRange create({DateRangeOverrides? overrides, required int seed}) {
    final start =
        overrides?.start ?? DateTime(2025, 1, 1).add(Duration(days: seed));

    final end = overrides?.end ?? start.add(Duration(days: (seed % 30) + 1));

    return DateRange(start: start, end: end);
  }

  @override
  DateRange duplicate(DateRange instance, DateRangeOverrides? overrides) {
    final start = overrides?.start ?? instance.start;

    final end = overrides?.end ?? instance.end;

    return DateRange(start: start, end: end);
  }
}

typedef SessionLogRepositoryOverrides = ({
  List<SessionLog>? instances,
  void Function(SessionLog)? onAppend,
});

class _SessionLogRepository implements SessionLogRepository {
  final List<SessionLog> _instances;
  final void Function(SessionLog)? _onAppend;

  _SessionLogRepository({
    required List<SessionLog> instances,
    void Function(SessionLog)? onAppend,
  }) : _instances = List.from(instances),
       _onAppend = onAppend;

  @override
  Future<void> append(SessionLog log) {
    _instances.add(log);

    if (_onAppend != null) {
      _onAppend(log);
    }

    return Future.value();
  }

  @override
  Future<List<SessionLog>> findRange({
    required ProfileIdentifier profile,
    required DateRange byDateRange,
  }) {
    final filtered = _instances.where((log) {
      return log.profile == profile &&
          !log.startedAt.isBefore(byDateRange.start) &&
          log.endedAt.isBefore(byDateRange.end);
    }).toList();

    return Future.value(filtered);
  }

  @override
  Future<List<SessionLog>> findLatest({
    required ProfileIdentifier profile,
    required int limit,
  }) {
    final filtered = _instances.where((log) => log.profile == profile).toList()
      ..sort((a, b) => b.endedAt.compareTo(a.endedAt));

    final limited = filtered.take(limit).toList();

    return Future.value(limited);
  }
}

class SessionLogRepositoryFactory
    extends Factory<SessionLogRepository, SessionLogRepositoryOverrides> {
  @override
  SessionLogRepository create({
    SessionLogRepositoryOverrides? overrides,
    required int seed,
  }) {
    final instances =
        overrides?.instances ??
        Builder(
          SessionLogFactory(),
        ).buildListWith(count: (seed % 20) + 1, seed: seed);

    return _SessionLogRepository(
      instances: instances,
      onAppend: overrides?.onAppend,
    );
  }

  @override
  SessionLogRepository duplicate(
    SessionLogRepository instance,
    SessionLogRepositoryOverrides? overrides,
  ) {
    throw UnimplementedError();
  }
}
