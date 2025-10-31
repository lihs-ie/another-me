import 'package:another_me/domains/common/transaction.dart';
import 'package:another_me/domains/profile/profile.dart' as profile_domain;
import 'package:another_me/domains/work/work.dart' as work_domain;
import 'package:logger/logger.dart';

class PomodoroSession {
  final profile_domain.UserProfileRepository _userProfileRepository;
  final work_domain.PomodoroSessionRepository _pomodoroSessionRepository;
  final work_domain.SessionLogRepository _sessionLogRepository;
  final Transaction _transaction;
  final Logger _logger;

  PomodoroSession({
    required profile_domain.UserProfileRepository userProfileRepository,
    required work_domain.PomodoroSessionRepository pomodoroSessionRepository,
    required work_domain.SessionLogRepository sessionLogRepository,
    required Transaction transaction,
    required Logger logger,
  }) : _userProfileRepository = userProfileRepository,
       _pomodoroSessionRepository = pomodoroSessionRepository,
       _sessionLogRepository = sessionLogRepository,
       _transaction = transaction,
       _logger = logger;

  Future<work_domain.PomodoroSessionIdentifier> execute({
    required profile_domain.ProfileIdentifier profile,
  }) async {
    return await _transaction.execute(() async {
      final userProfile = await _userProfileRepository.find(profile);

      final policySnapshot = work_domain.PomodoroPolicySnapshot(
        workMinutes: userProfile.pomodoro.workMinutes,
        breakMinutes: userProfile.pomodoro.breakMinutes,
        longBreakMinutes: userProfile.pomodoro.longBreakMinutes,
        longBreakEvery: userProfile.pomodoro.longBreakEvery,
        longBreakEnabled: userProfile.pomodoro.longBreakEnabled,
      );

      final startedAt = DateTime.now();

      final identifier = work_domain.PomodoroSessionIdentifier.generate();

      final session = work_domain.PomodoroSession.create(
        identifier: identifier,
        policySnapshot: policySnapshot,
      );

      session.start(policySnapshot: policySnapshot, startedAt: startedAt);

      await _pomodoroSessionRepository.persist(session);

      _logger.i(
        'Pomodoro session started: ${session.identifier.value} for profile ${profile.value}',
      );

      return session.identifier;
    });
  }

  Future<bool> update({
    required work_domain.PomodoroSessionIdentifier identifier,
    required DateTime current,
  }) async {
    return await _transaction.execute(() async {
      final session = await _pomodoroSessionRepository.find(identifier);

      final isCompleted = session.tick(currentTime: current);

      await _pomodoroSessionRepository.persist(session);

      if (isCompleted) {
        _logger.d(
          'Pomodoro session ticked: ${session.identifier.value} at $current',
        );
      }

      return isCompleted;
    });
  }

  Future<void> pause({
    required work_domain.PomodoroSessionIdentifier identifier,
  }) async {
    await _transaction.execute(() async {
      final session = await _pomodoroSessionRepository.find(identifier);

      session.pause(pausedAt: DateTime.now());

      await _pomodoroSessionRepository.persist(session);

      _logger.i('Pomodoro session paused: ${session.identifier.value}');
    });
  }

  Future<void> resume({
    required work_domain.PomodoroSessionIdentifier identifier,
  }) async {
    await _transaction.execute(() async {
      final session = await _pomodoroSessionRepository.find(identifier);

      session.resume(resumedAt: DateTime.now());

      await _pomodoroSessionRepository.persist(session);

      _logger.i('Pomodoro session resumed: ${session.identifier.value}');
    });
  }

  Future<void> skip({
    required work_domain.PomodoroSessionIdentifier identifier,
  }) async {
    await _transaction.execute(() async {
      final session = await _pomodoroSessionRepository.find(identifier);

      session.skip(skippedAt: DateTime.now());

      await _pomodoroSessionRepository.persist(session);

      _logger.i('Pomodoro session skipped: ${session.identifier.value}');
    });
  }

  Future<work_domain.SessionLogIdentifier> abandon({
    required work_domain.PomodoroSessionIdentifier identifier,
    required profile_domain.ProfileIdentifier profile,
  }) async {
    return await _transaction.execute(() async {
      final session = await _pomodoroSessionRepository.find(identifier);

      final abandonedAt = DateTime.now();

      session.abandon(abandonedAt: abandonedAt);

      await _pomodoroSessionRepository.persist(session);

      _logger.i('Pomodoro session abandoned: ${session.identifier.value}');

      var totalWorkMs = 0;
      var totalBreakMs = 0;

      for (final history in session.phaseHistory) {
        final durationMs = history.endedAt
            .difference(history.startedAt)
            .inMilliseconds;

        if (history.phase == work_domain.SessionPhase.work) {
          totalWorkMs += durationMs;
        } else if (history.phase == work_domain.SessionPhase.break_ ||
            history.phase == work_domain.SessionPhase.longBreak) {
          totalBreakMs += durationMs;
        }
      }

      final phaseSummaries = session.phaseHistory.map((history) {
        final actualDurationMs = history.endedAt
            .difference(history.startedAt)
            .inMilliseconds;

        return work_domain.PhaseSummary(
          phase: history.phase,
          actualDurationMs: actualDurationMs,
          skipped: history.skipped,
          startedAt: history.startedAt,
          endedAt: history.endedAt,
        );
      }).toList();

      final log = work_domain.SessionLog.record(
        identifier: work_domain.SessionLogIdentifier.generate(),
        session: session.identifier,
        profile: profile,
        startedAt: session.phaseHistory.first.startedAt,
        endedAt: abandonedAt,
        totalWorkMs: totalWorkMs,
        totalBreakMs: totalBreakMs,
        cycleCount: session.elapsedCycles,
        phaseSummaries: phaseSummaries,
        occurredAt: abandonedAt,
      );

      await _sessionLogRepository.append(log);

      _logger.i(
        'Session log recorded: ${log.identifier.value} for session ${session.identifier.value}',
      );

      return log.identifier;
    });
  }
}
