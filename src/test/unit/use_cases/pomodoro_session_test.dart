import 'package:another_me/domains/common/error.dart';
import 'package:another_me/domains/work/work.dart' as work_domain;
import 'package:another_me/use_cases/pomodoro_session.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../supports/factories/common.dart';
import '../../supports/factories/common/transaction.dart'
    as transaction_factory;
import '../../supports/factories/logger.dart';
import '../../supports/factories/profile/profile.dart' as profile_factory;
import '../../supports/factories/work/work.dart' as work_factory;

void main() {
  group('PomodoroSession', () {
    group('execute', () {
      test('creates and starts new pomodoro session.', () async {
        final profileIdentifier = Builder(
          profile_factory.ProfileIdentifierFactory(),
        ).build();

        final userProfile = Builder(profile_factory.UserProfileFactory())
            .buildWith(
              seed: 1,
              overrides: (
                identifier: profileIdentifier,
                appearance: null,
                language: null,
                playback: null,
                pomodoro: Builder(profile_factory.PomodoroPolicyFactory())
                    .buildWith(
                      seed: 1,
                      overrides: (
                        workMinutes: 25,
                        breakMinutes: 5,
                        longBreakMinutes: 15,
                        longBreakEvery: 4,
                        longBreakEnabled: true,
                      ),
                    ),
                restoreOnLaunch: null,
                notification: null,
                isDefault: true,
              ),
            );

        final userProfileRepository =
            Builder(profile_factory.UserProfileRepositoryFactory()).buildWith(
              seed: 1,
              overrides: (instances: [userProfile], onPersist: null),
            );

        final sessions = <work_domain.PomodoroSession>[];

        final pomodoroSessionRepository =
            Builder(work_factory.PomodoroSessionRepositoryFactory()).buildWith(
              seed: 1,
              overrides: (
                instances: [],
                onPersist: (session) {
                  sessions.add(session);
                },
              ),
            );

        final sessionLogRepository = Builder(
          work_factory.SessionLogRepositoryFactory(),
        ).buildWith(seed: 1, overrides: (instances: [], onAppend: null));

        final logger = Builder(LoggerFactory()).buildWith(seed: 1);

        final useCase = PomodoroSession(
          userProfileRepository: userProfileRepository,
          pomodoroSessionRepository: pomodoroSessionRepository,
          sessionLogRepository: sessionLogRepository,
          transaction: Builder(
            transaction_factory.TransactionFactory(),
          ).build(),
          logger: logger,
        );

        final identifier = await useCase.execute(profile: profileIdentifier);

        expect(sessions.length, equals(1));

        final session = sessions.first;

        expect(session.identifier, equals(identifier));
        expect(
          session.status,
          equals(work_domain.PomodoroSessionStatus.running),
        );
        expect(session.phase, equals(work_domain.SessionPhase.work));
        expect(session.policySnapshot.workMinutes, equals(25));
        expect(session.policySnapshot.breakMinutes, equals(5));
        expect(session.policySnapshot.longBreakMinutes, equals(15));
        expect(session.policySnapshot.longBreakEvery, equals(4));
        expect(session.policySnapshot.longBreakEnabled, equals(true));
      });

      test('throws AggregateNotFoundError when profile not found.', () async {
        final profileIdentifier = Builder(
          profile_factory.ProfileIdentifierFactory(),
        ).build();

        final userProfileRepository = Builder(
          profile_factory.UserProfileRepositoryFactory(),
        ).buildWith(seed: 1);

        final pomodoroSessionRepository = Builder(
          work_factory.PomodoroSessionRepositoryFactory(),
        ).buildWith(seed: 1, overrides: (instances: [], onPersist: null));

        final sessionLogRepository = Builder(
          work_factory.SessionLogRepositoryFactory(),
        ).buildWith(seed: 1, overrides: (instances: [], onAppend: null));

        final logger = Builder(LoggerFactory()).buildWith(seed: 1);

        final useCase = PomodoroSession(
          userProfileRepository: userProfileRepository,
          pomodoroSessionRepository: pomodoroSessionRepository,
          sessionLogRepository: sessionLogRepository,
          transaction: Builder(
            transaction_factory.TransactionFactory(),
          ).build(),
          logger: logger,
        );

        expect(
          () async => await useCase.execute(profile: profileIdentifier),
          throwsA(isA<AggregateNotFoundError>()),
        );
      });
    });

    group('update', () {
      test('ticks session and persists state.', () async {
        final identifier = Builder(
          work_factory.PomodoroSessionIdentifierFactory(),
        ).build();

        final policySnapshot =
            Builder(work_factory.PomodoroPolicySnapshotFactory()).buildWith(
              seed: 1,
              overrides: (
                workMinutes: 25,
                breakMinutes: 5,
                longBreakMinutes: 15,
                longBreakEvery: 4,
                longBreakEnabled: false,
              ),
            );

        final session = work_domain.PomodoroSession.create(
          identifier: identifier,
          policySnapshot: policySnapshot,
        );

        session.start(
          policySnapshot: policySnapshot,
          startedAt: DateTime(2025, 1, 1, 10, 0),
        );

        var persistCallCount = 0;

        final pomodoroSessionRepository =
            Builder(work_factory.PomodoroSessionRepositoryFactory()).buildWith(
              seed: 1,
              overrides: (
                instances: [session],
                onPersist: (_) {
                  persistCallCount++;
                },
              ),
            );

        final sessionLogRepository = Builder(
          work_factory.SessionLogRepositoryFactory(),
        ).buildWith(seed: 1, overrides: (instances: [], onAppend: null));

        final userProfileRepository = Builder(
          profile_factory.UserProfileRepositoryFactory(),
        ).buildWith(seed: 1);

        final logger = Builder(LoggerFactory()).buildWith(seed: 1);

        final useCase = PomodoroSession(
          userProfileRepository: userProfileRepository,
          pomodoroSessionRepository: pomodoroSessionRepository,
          sessionLogRepository: sessionLogRepository,
          transaction: Builder(
            transaction_factory.TransactionFactory(),
          ).build(),
          logger: logger,
        );

        final isCompleted = await useCase.update(
          identifier: identifier,
          current: DateTime(2025, 1, 1, 10, 0, 1),
        );

        expect(isCompleted, isFalse);
        expect(persistCallCount, equals(1));
      });

      test('returns true when phase completes.', () async {
        final identifier = Builder(
          work_factory.PomodoroSessionIdentifierFactory(),
        ).build();

        final policySnapshot =
            Builder(work_factory.PomodoroPolicySnapshotFactory()).buildWith(
              seed: 1,
              overrides: (
                workMinutes: 25,
                breakMinutes: 5,
                longBreakMinutes: 15,
                longBreakEvery: 4,
                longBreakEnabled: false,
              ),
            );

        final session = work_domain.PomodoroSession.create(
          identifier: identifier,
          policySnapshot: policySnapshot,
        );

        session.start(
          policySnapshot: policySnapshot,
          startedAt: DateTime(2025, 1, 1, 10, 0),
        );

        final pomodoroSessionRepository =
            Builder(work_factory.PomodoroSessionRepositoryFactory()).buildWith(
              seed: 1,
              overrides: (instances: [session], onPersist: null),
            );

        final sessionLogRepository = Builder(
          work_factory.SessionLogRepositoryFactory(),
        ).buildWith(seed: 1, overrides: (instances: [], onAppend: null));

        final userProfileRepository = Builder(
          profile_factory.UserProfileRepositoryFactory(),
        ).buildWith(seed: 1);

        final logger = Builder(LoggerFactory()).buildWith(seed: 1);

        final useCase = PomodoroSession(
          userProfileRepository: userProfileRepository,
          pomodoroSessionRepository: pomodoroSessionRepository,
          sessionLogRepository: sessionLogRepository,
          transaction: Builder(
            transaction_factory.TransactionFactory(),
          ).build(),
          logger: logger,
        );

        final isCompleted = await useCase.update(
          identifier: identifier,
          current: DateTime(2025, 1, 1, 10, 25),
        );

        expect(isCompleted, isTrue);
        expect(session.phase, equals(work_domain.SessionPhase.break_));
      });

      test('throws AggregateNotFoundError when session not found.', () async {
        final identifier = Builder(
          work_factory.PomodoroSessionIdentifierFactory(),
        ).build();

        final pomodoroSessionRepository = Builder(
          work_factory.PomodoroSessionRepositoryFactory(),
        ).buildWith(seed: 1, overrides: (instances: [], onPersist: null));

        final sessionLogRepository = Builder(
          work_factory.SessionLogRepositoryFactory(),
        ).buildWith(seed: 1, overrides: (instances: [], onAppend: null));

        final userProfileRepository = Builder(
          profile_factory.UserProfileRepositoryFactory(),
        ).buildWith(seed: 1);

        final logger = Builder(LoggerFactory()).buildWith(seed: 1);

        final useCase = PomodoroSession(
          userProfileRepository: userProfileRepository,
          pomodoroSessionRepository: pomodoroSessionRepository,
          sessionLogRepository: sessionLogRepository,
          transaction: Builder(
            transaction_factory.TransactionFactory(),
          ).build(),
          logger: logger,
        );

        expect(
          () async => await useCase.update(
            identifier: identifier,
            current: DateTime(2025, 1, 1, 10, 5),
          ),
          throwsA(isA<AggregateNotFoundError>()),
        );
      });
    });

    group('pause', () {
      test('pauses running session.', () async {
        final identifier = Builder(
          work_factory.PomodoroSessionIdentifierFactory(),
        ).build();

        final policySnapshot =
            Builder(work_factory.PomodoroPolicySnapshotFactory()).buildWith(
              seed: 1,
              overrides: (
                workMinutes: 25,
                breakMinutes: 5,
                longBreakMinutes: 15,
                longBreakEvery: 4,
                longBreakEnabled: false,
              ),
            );

        final session = work_domain.PomodoroSession.create(
          identifier: identifier,
          policySnapshot: policySnapshot,
        );

        session.start(
          policySnapshot: policySnapshot,
          startedAt: DateTime(2025, 1, 1, 10, 0),
        );

        final sessions = <work_domain.PomodoroSession>[];

        final pomodoroSessionRepository =
            Builder(work_factory.PomodoroSessionRepositoryFactory()).buildWith(
              seed: 1,
              overrides: (
                instances: [session],
                onPersist: (s) {
                  sessions.add(s);
                },
              ),
            );

        final sessionLogRepository = Builder(
          work_factory.SessionLogRepositoryFactory(),
        ).buildWith(seed: 1, overrides: (instances: [], onAppend: null));

        final userProfileRepository = Builder(
          profile_factory.UserProfileRepositoryFactory(),
        ).buildWith(seed: 1);

        final logger = Builder(LoggerFactory()).buildWith(seed: 1);

        final useCase = PomodoroSession(
          userProfileRepository: userProfileRepository,
          pomodoroSessionRepository: pomodoroSessionRepository,
          sessionLogRepository: sessionLogRepository,
          transaction: Builder(
            transaction_factory.TransactionFactory(),
          ).build(),
          logger: logger,
        );

        await useCase.pause(identifier: identifier);

        expect(sessions.length, equals(1));
        expect(
          sessions.first.status,
          equals(work_domain.PomodoroSessionStatus.paused),
        );
      });

      test('throws AggregateNotFoundError when session not found.', () async {
        final identifier = Builder(
          work_factory.PomodoroSessionIdentifierFactory(),
        ).build();

        final pomodoroSessionRepository = Builder(
          work_factory.PomodoroSessionRepositoryFactory(),
        ).buildWith(seed: 1, overrides: (instances: [], onPersist: null));

        final sessionLogRepository = Builder(
          work_factory.SessionLogRepositoryFactory(),
        ).buildWith(seed: 1, overrides: (instances: [], onAppend: null));

        final userProfileRepository = Builder(
          profile_factory.UserProfileRepositoryFactory(),
        ).buildWith(seed: 1);

        final logger = Builder(LoggerFactory()).buildWith(seed: 1);

        final useCase = PomodoroSession(
          userProfileRepository: userProfileRepository,
          pomodoroSessionRepository: pomodoroSessionRepository,
          sessionLogRepository: sessionLogRepository,
          transaction: Builder(
            transaction_factory.TransactionFactory(),
          ).build(),
          logger: logger,
        );

        expect(
          () async => await useCase.pause(identifier: identifier),
          throwsA(isA<AggregateNotFoundError>()),
        );
      });
    });

    group('resume', () {
      test('resumes paused session.', () async {
        final identifier = Builder(
          work_factory.PomodoroSessionIdentifierFactory(),
        ).build();

        final policySnapshot =
            Builder(work_factory.PomodoroPolicySnapshotFactory()).buildWith(
              seed: 1,
              overrides: (
                workMinutes: 25,
                breakMinutes: 5,
                longBreakMinutes: 15,
                longBreakEvery: 4,
                longBreakEnabled: false,
              ),
            );

        final session = work_domain.PomodoroSession.create(
          identifier: identifier,
          policySnapshot: policySnapshot,
        );

        session.start(
          policySnapshot: policySnapshot,
          startedAt: DateTime(2025, 1, 1, 10, 0),
        );

        session.pause(pausedAt: DateTime(2025, 1, 1, 10, 5));

        final sessions = <work_domain.PomodoroSession>[];

        final pomodoroSessionRepository =
            Builder(work_factory.PomodoroSessionRepositoryFactory()).buildWith(
              seed: 1,
              overrides: (
                instances: [session],
                onPersist: (s) {
                  sessions.add(s);
                },
              ),
            );

        final sessionLogRepository = Builder(
          work_factory.SessionLogRepositoryFactory(),
        ).buildWith(seed: 1, overrides: (instances: [], onAppend: null));

        final userProfileRepository = Builder(
          profile_factory.UserProfileRepositoryFactory(),
        ).buildWith(seed: 1);

        final logger = Builder(LoggerFactory()).buildWith(seed: 1);

        final useCase = PomodoroSession(
          userProfileRepository: userProfileRepository,
          pomodoroSessionRepository: pomodoroSessionRepository,
          sessionLogRepository: sessionLogRepository,
          transaction: Builder(
            transaction_factory.TransactionFactory(),
          ).build(),
          logger: logger,
        );

        await useCase.resume(identifier: identifier);

        expect(sessions.length, equals(1));
        expect(
          sessions.first.status,
          equals(work_domain.PomodoroSessionStatus.running),
        );
      });

      test('throws AggregateNotFoundError when session not found.', () async {
        final identifier = Builder(
          work_factory.PomodoroSessionIdentifierFactory(),
        ).build();

        final pomodoroSessionRepository = Builder(
          work_factory.PomodoroSessionRepositoryFactory(),
        ).buildWith(seed: 1, overrides: (instances: [], onPersist: null));

        final sessionLogRepository = Builder(
          work_factory.SessionLogRepositoryFactory(),
        ).buildWith(seed: 1, overrides: (instances: [], onAppend: null));

        final userProfileRepository = Builder(
          profile_factory.UserProfileRepositoryFactory(),
        ).buildWith(seed: 1);

        final logger = Builder(LoggerFactory()).buildWith(seed: 1);

        final useCase = PomodoroSession(
          userProfileRepository: userProfileRepository,
          pomodoroSessionRepository: pomodoroSessionRepository,
          sessionLogRepository: sessionLogRepository,
          transaction: Builder(
            transaction_factory.TransactionFactory(),
          ).build(),
          logger: logger,
        );

        expect(
          () async => await useCase.resume(identifier: identifier),
          throwsA(isA<AggregateNotFoundError>()),
        );
      });
    });

    group('skip', () {
      test('skips current phase.', () async {
        final identifier = Builder(
          work_factory.PomodoroSessionIdentifierFactory(),
        ).build();

        final policySnapshot =
            Builder(work_factory.PomodoroPolicySnapshotFactory()).buildWith(
              seed: 1,
              overrides: (
                workMinutes: 25,
                breakMinutes: 5,
                longBreakMinutes: 15,
                longBreakEvery: 4,
                longBreakEnabled: false,
              ),
            );

        final session = work_domain.PomodoroSession.create(
          identifier: identifier,
          policySnapshot: policySnapshot,
        );

        session.start(
          policySnapshot: policySnapshot,
          startedAt: DateTime(2025, 1, 1, 10, 0),
        );

        final sessions = <work_domain.PomodoroSession>[];

        final pomodoroSessionRepository =
            Builder(work_factory.PomodoroSessionRepositoryFactory()).buildWith(
              seed: 1,
              overrides: (
                instances: [session],
                onPersist: (s) {
                  sessions.add(s);
                },
              ),
            );

        final sessionLogRepository = Builder(
          work_factory.SessionLogRepositoryFactory(),
        ).buildWith(seed: 1, overrides: (instances: [], onAppend: null));

        final userProfileRepository = Builder(
          profile_factory.UserProfileRepositoryFactory(),
        ).buildWith(seed: 1);

        final logger = Builder(LoggerFactory()).buildWith(seed: 1);

        final useCase = PomodoroSession(
          userProfileRepository: userProfileRepository,
          pomodoroSessionRepository: pomodoroSessionRepository,
          sessionLogRepository: sessionLogRepository,
          transaction: Builder(
            transaction_factory.TransactionFactory(),
          ).build(),
          logger: logger,
        );

        await useCase.skip(identifier: identifier);

        expect(sessions.length, equals(1));
        expect(sessions.first.phase, equals(work_domain.SessionPhase.break_));
        expect(sessions.first.phaseHistory.last.skipped, isTrue);
      });

      test('throws AggregateNotFoundError when session not found.', () async {
        final identifier = Builder(
          work_factory.PomodoroSessionIdentifierFactory(),
        ).build();

        final pomodoroSessionRepository = Builder(
          work_factory.PomodoroSessionRepositoryFactory(),
        ).buildWith(seed: 1, overrides: (instances: [], onPersist: null));

        final sessionLogRepository = Builder(
          work_factory.SessionLogRepositoryFactory(),
        ).buildWith(seed: 1, overrides: (instances: [], onAppend: null));

        final userProfileRepository = Builder(
          profile_factory.UserProfileRepositoryFactory(),
        ).buildWith(seed: 1);

        final logger = Builder(LoggerFactory()).buildWith(seed: 1);

        final useCase = PomodoroSession(
          userProfileRepository: userProfileRepository,
          pomodoroSessionRepository: pomodoroSessionRepository,
          sessionLogRepository: sessionLogRepository,
          transaction: Builder(
            transaction_factory.TransactionFactory(),
          ).build(),
          logger: logger,
        );

        expect(
          () async => await useCase.skip(identifier: identifier),
          throwsA(isA<AggregateNotFoundError>()),
        );
      });
    });

    group('abandon', () {
      test('abandons session and records session log.', () async {
        final profileIdentifier = Builder(
          profile_factory.ProfileIdentifierFactory(),
        ).build();

        final sessionIdentifier = Builder(
          work_factory.PomodoroSessionIdentifierFactory(),
        ).build();

        final policySnapshot =
            Builder(work_factory.PomodoroPolicySnapshotFactory()).buildWith(
              seed: 1,
              overrides: (
                workMinutes: 25,
                breakMinutes: 5,
                longBreakMinutes: 15,
                longBreakEvery: 4,
                longBreakEnabled: false,
              ),
            );

        final session = work_domain.PomodoroSession.create(
          identifier: sessionIdentifier,
          policySnapshot: policySnapshot,
        );

        session.start(
          policySnapshot: policySnapshot,
          startedAt: DateTime(2025, 1, 1, 10, 0),
        );

        final sessions = <work_domain.PomodoroSession>[];
        final logs = <work_domain.SessionLog>[];

        final pomodoroSessionRepository =
            Builder(work_factory.PomodoroSessionRepositoryFactory()).buildWith(
              seed: 1,
              overrides: (
                instances: [session],
                onPersist: (s) {
                  sessions.add(s);
                },
              ),
            );

        final sessionLogRepository =
            Builder(work_factory.SessionLogRepositoryFactory()).buildWith(
              seed: 1,
              overrides: (
                instances: [],
                onAppend: (log) {
                  logs.add(log);
                },
              ),
            );

        final userProfileRepository = Builder(
          profile_factory.UserProfileRepositoryFactory(),
        ).buildWith(seed: 1);

        final logger = Builder(LoggerFactory()).buildWith(seed: 1);

        final useCase = PomodoroSession(
          userProfileRepository: userProfileRepository,
          pomodoroSessionRepository: pomodoroSessionRepository,
          sessionLogRepository: sessionLogRepository,
          transaction: Builder(
            transaction_factory.TransactionFactory(),
          ).build(),
          logger: logger,
        );

        final logIdentifier = await useCase.abandon(
          identifier: sessionIdentifier,
          profile: profileIdentifier,
        );

        expect(sessions.length, equals(1));
        expect(
          sessions.first.status,
          equals(work_domain.PomodoroSessionStatus.completed),
        );
        expect(sessions.first.phase, equals(work_domain.SessionPhase.idle));

        expect(logs.length, equals(1));
        expect(logs.first.identifier, equals(logIdentifier));
        expect(logs.first.session, equals(sessionIdentifier));
        expect(logs.first.profile, equals(profileIdentifier));
        expect(logs.first.cycleCount, equals(0));
        expect(logs.first.phaseSummaries.length, equals(1));
      });

      test('calculates work and break time correctly.', () async {
        final profileIdentifier = Builder(
          profile_factory.ProfileIdentifierFactory(),
        ).build();

        final sessionIdentifier = Builder(
          work_factory.PomodoroSessionIdentifierFactory(),
        ).build();

        final policySnapshot =
            Builder(work_factory.PomodoroPolicySnapshotFactory()).buildWith(
              seed: 1,
              overrides: (
                workMinutes: 25,
                breakMinutes: 5,
                longBreakMinutes: 15,
                longBreakEvery: 4,
                longBreakEnabled: false,
              ),
            );

        final session = work_domain.PomodoroSession.create(
          identifier: sessionIdentifier,
          policySnapshot: policySnapshot,
        );

        session.start(
          policySnapshot: policySnapshot,
          startedAt: DateTime(2025, 1, 1, 10, 0),
        );

        for (var i = 1; i <= 25 * 60; i++) {
          final completed = session.tick(
            currentTime: DateTime(2025, 1, 1, 10, 0, i),
          );
          if (completed) break;
        }

        for (var i = 0; i < 5 * 60; i++) {
          final completed = session.tick(
            currentTime: DateTime(2025, 1, 1, 10, 25, i + 1),
          );
          if (completed) break;
        }

        final logs = <work_domain.SessionLog>[];

        final pomodoroSessionRepository =
            Builder(work_factory.PomodoroSessionRepositoryFactory()).buildWith(
              seed: 1,
              overrides: (instances: [session], onPersist: null),
            );

        final sessionLogRepository =
            Builder(work_factory.SessionLogRepositoryFactory()).buildWith(
              seed: 1,
              overrides: (
                instances: [],
                onAppend: (log) {
                  logs.add(log);
                },
              ),
            );

        final userProfileRepository = Builder(
          profile_factory.UserProfileRepositoryFactory(),
        ).buildWith(seed: 1);

        final logger = Builder(LoggerFactory()).buildWith(seed: 1);

        final useCase = PomodoroSession(
          userProfileRepository: userProfileRepository,
          pomodoroSessionRepository: pomodoroSessionRepository,
          sessionLogRepository: sessionLogRepository,
          transaction: Builder(
            transaction_factory.TransactionFactory(),
          ).build(),
          logger: logger,
        );

        await useCase.abandon(
          identifier: sessionIdentifier,
          profile: profileIdentifier,
        );

        expect(logs.length, equals(1));

        final log = logs.first;

        expect(log.cycleCount, equals(1));
        expect(log.phaseSummaries.length, equals(3));
        expect(
          log.phaseSummaries[0].phase,
          equals(work_domain.SessionPhase.work),
        );
        expect(log.phaseSummaries[0].skipped, isFalse);
        expect(
          log.phaseSummaries[1].phase,
          equals(work_domain.SessionPhase.break_),
        );
        expect(log.phaseSummaries[1].skipped, isFalse);
        expect(
          log.phaseSummaries[2].phase,
          equals(work_domain.SessionPhase.work),
        );
        expect(log.phaseSummaries[2].skipped, isTrue);
      });

      test('throws AggregateNotFoundError when session not found.', () async {
        final profileIdentifier = Builder(
          profile_factory.ProfileIdentifierFactory(),
        ).build();

        final sessionIdentifier = Builder(
          work_factory.PomodoroSessionIdentifierFactory(),
        ).build();

        final pomodoroSessionRepository = Builder(
          work_factory.PomodoroSessionRepositoryFactory(),
        ).buildWith(seed: 1, overrides: (instances: [], onPersist: null));

        final sessionLogRepository = Builder(
          work_factory.SessionLogRepositoryFactory(),
        ).buildWith(seed: 1, overrides: (instances: [], onAppend: null));

        final userProfileRepository = Builder(
          profile_factory.UserProfileRepositoryFactory(),
        ).buildWith(seed: 1);

        final logger = Builder(LoggerFactory()).buildWith(seed: 1);

        final useCase = PomodoroSession(
          userProfileRepository: userProfileRepository,
          pomodoroSessionRepository: pomodoroSessionRepository,
          sessionLogRepository: sessionLogRepository,
          transaction: Builder(
            transaction_factory.TransactionFactory(),
          ).build(),
          logger: logger,
        );

        expect(
          () async => await useCase.abandon(
            identifier: sessionIdentifier,
            profile: profileIdentifier,
          ),
          throwsA(isA<AggregateNotFoundError>()),
        );
      });
    });
  });
}
