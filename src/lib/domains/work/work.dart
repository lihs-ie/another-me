import 'package:another_me/domains/common/event.dart';
import 'package:another_me/domains/common/identifier.dart';
import 'package:another_me/domains/common/value_object.dart';
import 'package:another_me/domains/common/variant.dart';
import 'package:another_me/domains/profile/profile.dart';
import 'package:ulid/ulid.dart';

class PomodoroSessionIdentifier extends ULIDBasedIdentifier {
  PomodoroSessionIdentifier(super.value);

  factory PomodoroSessionIdentifier.generate() {
    return PomodoroSessionIdentifier(Ulid());
  }
}

enum PomodoroSessionStatus { idle, running, paused, completed }

enum SessionPhase { idle, work, break_, longBreak }

class PomodoroPolicySnapshot implements ValueObject {
  final int workMinutes;
  final int breakMinutes;
  final int longBreakMinutes;
  final int longBreakEvery;
  final bool longBreakEnabled;

  PomodoroPolicySnapshot({
    required this.workMinutes,
    required this.breakMinutes,
    required this.longBreakMinutes,
    required this.longBreakEvery,
    required this.longBreakEnabled,
  }) {
    Invariant.range(value: workMinutes, name: 'workMinutes', min: 1, max: 120);

    Invariant.range(
      value: breakMinutes,
      name: 'breakMinutes',
      min: 1,
      max: 120,
    );

    Invariant.range(
      value: longBreakMinutes,
      name: 'longBreakMinutes',
      min: 1,
      max: 120,
    );

    Invariant.range(value: longBreakEvery, name: 'longBreakEvery', min: 1);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! PomodoroPolicySnapshot) {
      return false;
    }

    return workMinutes == other.workMinutes &&
        breakMinutes == other.breakMinutes &&
        longBreakMinutes == other.longBreakMinutes &&
        longBreakEvery == other.longBreakEvery &&
        longBreakEnabled == other.longBreakEnabled;
  }

  @override
  int get hashCode => Object.hash(
    workMinutes,
    breakMinutes,
    longBreakMinutes,
    longBreakEvery,
    longBreakEnabled,
  );
}

class PhaseDuration implements ValueObject {
  final SessionPhase phase;
  final int totalMs;

  PhaseDuration({required this.phase, required this.totalMs}) {
    Invariant.range(value: totalMs, name: 'totalMs', min: 0);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! PhaseDuration) {
      return false;
    }

    return phase == other.phase && totalMs == other.totalMs;
  }

  @override
  int get hashCode => Object.hash(phase, totalMs);
}

class RemainingTime implements ValueObject {
  final int ms;

  RemainingTime({required this.ms}) {
    Invariant.range(value: ms, name: 'ms', min: 0);
  }

  RemainingTime subtract(int elapsedMs) {
    final newMs = ms - elapsedMs;
    return RemainingTime(ms: newMs < 0 ? 0 : newMs);
  }

  bool isExpired() {
    return ms == 0;
  }

  int toMinutes() {
    return (ms / 60000).ceil();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! RemainingTime) {
      return false;
    }

    return ms == other.ms;
  }

  @override
  int get hashCode => ms.hashCode;
}

class PhaseHistory implements ValueObject {
  final SessionPhase phase;
  final DateTime startedAt;
  final DateTime endedAt;
  final bool skipped;

  PhaseHistory({
    required this.phase,
    required this.startedAt,
    required this.endedAt,
    required this.skipped,
  }) {
    if (!startedAt.isBefore(endedAt)) {
      throw InvariantViolationError('startedAt must be before endedAt.');
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! PhaseHistory) {
      return false;
    }

    return phase == other.phase &&
        startedAt == other.startedAt &&
        endedAt == other.endedAt &&
        skipped == other.skipped;
  }

  @override
  int get hashCode => Object.hash(phase, startedAt, endedAt, skipped);
}

abstract class PomodoroSessionEvent extends BaseEvent {
  PomodoroSessionEvent(super.occurredAt);
}

class PomodoroPhaseStarted extends PomodoroSessionEvent {
  final PomodoroSessionIdentifier identifier;
  final SessionPhase phase;
  final DateTime startedAt;
  final RemainingTime remainingTime;

  PomodoroPhaseStarted({
    required this.identifier,
    required this.phase,
    required this.startedAt,
    required this.remainingTime,
    required DateTime occurredAt,
  }) : super(occurredAt);
}

class PomodoroPhaseCompleted extends PomodoroSessionEvent {
  final PomodoroSessionIdentifier identifier;
  final SessionPhase phase;
  final Duration actualDuration;
  final bool skipped;

  PomodoroPhaseCompleted({
    required this.identifier,
    required this.phase,
    required this.actualDuration,
    required this.skipped,
    required DateTime occurredAt,
  }) : super(occurredAt);
}

class PomodoroSessionCompleted extends PomodoroSessionEvent {
  final PomodoroSessionIdentifier identifier;
  final int totalWorkMs;
  final int totalBreakMs;
  final int cycles;
  final DateTime completedAt;

  PomodoroSessionCompleted({
    required this.identifier,
    required this.totalWorkMs,
    required this.totalBreakMs,
    required this.cycles,
    required this.completedAt,
    required DateTime occurredAt,
  }) : super(occurredAt);
}

class PomodoroSession with Publishable<PomodoroSessionEvent> {
  final PomodoroSessionIdentifier identifier;
  PomodoroSessionStatus status;
  SessionPhase phase;
  RemainingTime remainingTime;
  int elapsedCycles;
  final PomodoroPolicySnapshot policySnapshot;
  final List<PhaseHistory> phaseHistory;
  DateTime lastTickAt;

  PomodoroSession._({
    required this.identifier,
    required this.status,
    required this.phase,
    required this.remainingTime,
    required this.elapsedCycles,
    required this.policySnapshot,
    required this.phaseHistory,
    required this.lastTickAt,
  });

  factory PomodoroSession.create({
    required PomodoroSessionIdentifier identifier,
    required PomodoroPolicySnapshot policySnapshot,
  }) {
    return PomodoroSession._(
      identifier: identifier,
      status: PomodoroSessionStatus.idle,
      phase: SessionPhase.idle,
      remainingTime: RemainingTime(ms: 0),
      elapsedCycles: 0,
      policySnapshot: policySnapshot,
      phaseHistory: [],
      lastTickAt: DateTime.now(),
    );
  }

  void start({
    required PomodoroPolicySnapshot policySnapshot,
    required DateTime startedAt,
  }) {
    if (status != PomodoroSessionStatus.idle) {
      throw StateError('Cannot start session from status: $status');
    }

    status = PomodoroSessionStatus.running;
    phase = SessionPhase.work;
    remainingTime = RemainingTime(ms: policySnapshot.workMinutes * 60000);
    lastTickAt = startedAt;
    elapsedCycles = 0;

    publish(
      PomodoroPhaseStarted(
        identifier: identifier,
        phase: phase,
        startedAt: startedAt,
        remainingTime: remainingTime,
        occurredAt: startedAt,
      ),
    );
  }

  void pause({required DateTime pausedAt}) {
    if (status != PomodoroSessionStatus.running) {
      throw StateError('Cannot pause session from status: $status');
    }

    if (phase == SessionPhase.idle) {
      throw StateError('Cannot pause from idle phase');
    }

    status = PomodoroSessionStatus.paused;
    lastTickAt = pausedAt;
  }

  void resume({required DateTime resumedAt}) {
    if (status != PomodoroSessionStatus.paused) {
      throw StateError('Cannot resume session from status: $status');
    }

    status = PomodoroSessionStatus.running;
    lastTickAt = resumedAt;
  }

  void skip({required DateTime skippedAt}) {
    if (status != PomodoroSessionStatus.running) {
      throw StateError('Cannot skip from status: $status');
    }

    final phaseStartTime = _calculatePhaseStartTime(skippedAt);

    phaseHistory.add(
      PhaseHistory(
        phase: phase,
        startedAt: phaseStartTime,
        endedAt: skippedAt,
        skipped: true,
      ),
    );

    final actualDuration = skippedAt.difference(phaseStartTime);

    publish(
      PomodoroPhaseCompleted(
        identifier: identifier,
        phase: phase,
        actualDuration: actualDuration,
        skipped: true,
        occurredAt: skippedAt,
      ),
    );

    _transitionToNextPhase(completedAt: skippedAt);
  }

  bool tick({required DateTime currentTime}) {
    if (status != PomodoroSessionStatus.running) {
      throw StateError('Cannot tick from status: $status');
    }

    final elapsedMs = currentTime.difference(lastTickAt).inMilliseconds;

    if (elapsedMs > 2000) {
      remainingTime = RemainingTime(ms: 0);
      lastTickAt = currentTime;
      _completePhase(completedAt: currentTime);
      return true;
    }

    remainingTime = remainingTime.subtract(elapsedMs);
    lastTickAt = currentTime;

    if (remainingTime.isExpired()) {
      _completePhase(completedAt: currentTime);
      return true;
    }

    return false;
  }

  void _completePhase({required DateTime completedAt}) {
    if (status != PomodoroSessionStatus.running) {
      throw StateError('Cannot complete phase from status: $status');
    }

    if (!remainingTime.isExpired()) {
      throw StateError('Cannot complete phase with remaining time');
    }

    final phaseStartTime = _calculatePhaseStartTime(completedAt);

    phaseHistory.add(
      PhaseHistory(
        phase: phase,
        startedAt: phaseStartTime,
        endedAt: completedAt,
        skipped: false,
      ),
    );

    if (phase == SessionPhase.work) {
      elapsedCycles++;
    }

    final actualDuration = completedAt.difference(phaseStartTime);

    publish(
      PomodoroPhaseCompleted(
        identifier: identifier,
        phase: phase,
        actualDuration: actualDuration,
        skipped: false,
        occurredAt: completedAt,
      ),
    );

    _transitionToNextPhase(completedAt: completedAt);
  }

  void _transitionToNextPhase({required DateTime completedAt}) {
    final nextPhase = _determineNextPhase();

    if (nextPhase == null) {
      status = PomodoroSessionStatus.completed;

      final stats = _calculateSessionStats();

      publish(
        PomodoroSessionCompleted(
          identifier: identifier,
          totalWorkMs: stats.totalWorkMs,
          totalBreakMs: stats.totalBreakMs,
          cycles: elapsedCycles,
          completedAt: completedAt,
          occurredAt: completedAt,
        ),
      );

      return;
    }

    phase = nextPhase;
    remainingTime = _calculateRemainingTimeForPhase(nextPhase);
    lastTickAt = completedAt;

    publish(
      PomodoroPhaseStarted(
        identifier: identifier,
        phase: phase,
        startedAt: completedAt,
        remainingTime: remainingTime,
        occurredAt: completedAt,
      ),
    );
  }

  SessionPhase? _determineNextPhase() {
    if (phase == SessionPhase.work) {
      if (policySnapshot.longBreakEnabled &&
          elapsedCycles % policySnapshot.longBreakEvery == 0) {
        return SessionPhase.longBreak;
      }
      return SessionPhase.break_;
    }

    if (phase == SessionPhase.break_ || phase == SessionPhase.longBreak) {
      return SessionPhase.work;
    }

    return null;
  }

  RemainingTime _calculateRemainingTimeForPhase(SessionPhase nextPhase) {
    switch (nextPhase) {
      case SessionPhase.work:
        return RemainingTime(ms: policySnapshot.workMinutes * 60000);
      case SessionPhase.break_:
        return RemainingTime(ms: policySnapshot.breakMinutes * 60000);
      case SessionPhase.longBreak:
        return RemainingTime(ms: policySnapshot.longBreakMinutes * 60000);
      case SessionPhase.idle:
        return RemainingTime(ms: 0);
    }
  }

  DateTime _calculatePhaseStartTime(DateTime endTime) {
    final elapsedMs = endTime.difference(lastTickAt).inMilliseconds;
    final totalElapsed =
        (_getPhaseExpectedDuration(phase) - remainingTime.ms) + elapsedMs;
    return endTime.subtract(Duration(milliseconds: totalElapsed));
  }

  int _getPhaseExpectedDuration(SessionPhase phase) {
    switch (phase) {
      case SessionPhase.work:
        return policySnapshot.workMinutes * 60000;
      case SessionPhase.break_:
        return policySnapshot.breakMinutes * 60000;
      case SessionPhase.longBreak:
        return policySnapshot.longBreakMinutes * 60000;
      case SessionPhase.idle:
        return 0;
    }
  }

  ({int totalWorkMs, int totalBreakMs}) _calculateSessionStats() {
    var totalWorkMs = 0;
    var totalBreakMs = 0;

    for (final history in phaseHistory) {
      final durationMs = history.endedAt
          .difference(history.startedAt)
          .inMilliseconds;

      if (history.phase == SessionPhase.work) {
        totalWorkMs += durationMs;
      } else if (history.phase == SessionPhase.break_ ||
          history.phase == SessionPhase.longBreak) {
        totalBreakMs += durationMs;
      }
    }

    return (totalWorkMs: totalWorkMs, totalBreakMs: totalBreakMs);
  }
}

class PomodoroSessionSearchCriteria implements ValueObject {
  final ProfileIdentifier profile;
  final PomodoroSessionStatus status;

  PomodoroSessionSearchCriteria({
    required this.profile,
    this.status = PomodoroSessionStatus.running,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! PomodoroSessionSearchCriteria) {
      return false;
    }

    return profile == other.profile && status == other.status;
  }

  @override
  int get hashCode => Object.hash(profile, status);
}

abstract class PomodoroSessionRepository {
  Future<PomodoroSession> search(PomodoroSessionSearchCriteria criteria);
  Future<void> persist(PomodoroSession session);
  Future<void> terminate(PomodoroSessionIdentifier identifier);
}

class SessionLogIdentifier extends ULIDBasedIdentifier {
  SessionLogIdentifier(super.value);

  factory SessionLogIdentifier.generate() {
    return SessionLogIdentifier(Ulid());
  }
}

class PhaseSummary implements ValueObject {
  final SessionPhase phase;
  final int actualDurationMs;
  final bool skipped;
  final DateTime startedAt;
  final DateTime endedAt;

  PhaseSummary({
    required this.phase,
    required this.actualDurationMs,
    required this.skipped,
    required this.startedAt,
    required this.endedAt,
  }) {
    if (!startedAt.isBefore(endedAt)) {
      throw InvariantViolationError('startedAt must be before endedAt');
    }

    final expectedDuration = endedAt.difference(startedAt).inMilliseconds;

    if ((actualDurationMs - expectedDuration).abs() > 1000) {
      throw InvariantViolationError(
        'actualDurationMs must match the period between startedAt and endedAt',
      );
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! PhaseSummary) {
      return false;
    }

    return phase == other.phase &&
        actualDurationMs == other.actualDurationMs &&
        skipped == other.skipped &&
        startedAt == other.startedAt &&
        endedAt == other.endedAt;
  }

  @override
  int get hashCode =>
      Object.hash(phase, actualDurationMs, skipped, startedAt, endedAt);
}

class WorkBreakRatio implements ValueObject {
  final int workMs;
  final int breakMs;

  WorkBreakRatio({required this.workMs, required this.breakMs}) {
    Invariant.range(value: workMs, name: 'workMs', min: 0);
    Invariant.range(value: breakMs, name: 'breakMs', min: 0);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! WorkBreakRatio) {
      return false;
    }

    return workMs == other.workMs && breakMs == other.breakMs;
  }

  @override
  int get hashCode => Object.hash(workMs, breakMs);
}

abstract class SessionLogEvent extends BaseEvent {
  SessionLogEvent(super.occurredAt);
}

class SessionLogRecorded extends SessionLogEvent {
  final SessionLogIdentifier identifier;
  final PomodoroSessionIdentifier session;
  final int cycleCount;
  final int totalWorkMs;
  final int totalBreakMs;

  SessionLogRecorded({
    required this.identifier,
    required this.session,
    required this.cycleCount,
    required this.totalWorkMs,
    required this.totalBreakMs,
    required DateTime occurredAt,
  }) : super(occurredAt);
}

class SessionLog with Publishable<SessionLogEvent> {
  final SessionLogIdentifier identifier;
  final PomodoroSessionIdentifier session;
  final ProfileIdentifier profile;
  final DateTime startedAt;
  final DateTime endedAt;
  final int totalWorkMs;
  final int totalBreakMs;
  final int cycleCount;
  final List<PhaseSummary> phaseSummaries;

  SessionLog._({
    required this.identifier,
    required this.session,
    required this.profile,
    required this.startedAt,
    required this.endedAt,
    required this.totalWorkMs,
    required this.totalBreakMs,
    required this.cycleCount,
    required this.phaseSummaries,
  }) {
    if (!startedAt.isBefore(endedAt)) {
      throw InvariantViolationError('startedAt must be before endedAt');
    }

    final calculatedWorkMs = phaseSummaries
        .where((summary) => summary.phase == SessionPhase.work)
        .fold<int>(0, (sum, summary) => sum + summary.actualDurationMs);

    final calculatedBreakMs = phaseSummaries
        .where(
          (summary) =>
              summary.phase == SessionPhase.break_ ||
              summary.phase == SessionPhase.longBreak,
        )
        .fold<int>(0, (sum, summary) => sum + summary.actualDurationMs);

    if (totalWorkMs != calculatedWorkMs) {
      throw InvariantViolationError(
        'totalWorkMs must match sum of work phase durations',
      );
    }

    if (totalBreakMs != calculatedBreakMs) {
      throw InvariantViolationError(
        'totalBreakMs must match sum of break phase durations',
      );
    }

    final calculatedCycles = phaseSummaries
        .where(
          (summary) => summary.phase == SessionPhase.work && !summary.skipped,
        )
        .length;

    if (cycleCount != calculatedCycles) {
      throw InvariantViolationError(
        'cycleCount must match number of completed work phases',
      );
    }
  }

  factory SessionLog.record({
    required SessionLogIdentifier identifier,
    required PomodoroSessionIdentifier session,
    required ProfileIdentifier profile,
    required DateTime startedAt,
    required DateTime endedAt,
    required int totalWorkMs,
    required int totalBreakMs,
    required int cycleCount,
    required List<PhaseSummary> phaseSummaries,
    required DateTime occurredAt,
  }) {
    final log = SessionLog._(
      identifier: identifier,
      session: session,
      profile: profile,
      startedAt: startedAt,
      endedAt: endedAt,
      totalWorkMs: totalWorkMs,
      totalBreakMs: totalBreakMs,
      cycleCount: cycleCount,
      phaseSummaries: phaseSummaries,
    );

    log.publish(
      SessionLogRecorded(
        identifier: identifier,
        session: session,
        cycleCount: cycleCount,
        totalWorkMs: totalWorkMs,
        totalBreakMs: totalBreakMs,
        occurredAt: occurredAt,
      ),
    );

    return log;
  }
}

class DateRange implements ValueObject {
  final DateTime start;
  final DateTime end;

  DateRange({required this.start, required this.end}) {
    if (!start.isBefore(end)) {
      throw InvariantViolationError('start must be before end');
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! DateRange) {
      return false;
    }

    return start == other.start && end == other.end;
  }

  @override
  int get hashCode => Object.hash(start, end);
}

abstract class SessionLogRepository {
  Future<void> append(SessionLog log);
  Future<List<SessionLog>> findRange({
    required ProfileIdentifier profile,
    required DateRange byDateRange,
  });
  Future<List<SessionLog>> findLatest({
    required ProfileIdentifier profile,
    required int limit,
  });
}
