import 'package:another_me/domains/profile/profile.dart';
import 'package:another_me/domains/work/work.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../supports/factories/common.dart';
import '../../../supports/factories/profile/profile.dart';
import '../../../supports/factories/work/work.dart';
import '../common/value_object.dart';

void main() {
  group('PomodoroSessionIdentifier', () {
    test('generate creates unique identifier.', () {
      final id1 = PomodoroSessionIdentifier.generate();
      final id2 = PomodoroSessionIdentifier.generate();

      expect(id1, isNot(equals(id2)));
    });
  });

  group('SessionLogIdentifier', () {
    test('generate creates unique identifier.', () {
      final id1 = SessionLogIdentifier.generate();
      final id2 = SessionLogIdentifier.generate();

      expect(id1, isNot(equals(id2)));
    });
  });

  group('PhaseDuration', () {
    valueObjectTest(
      constructor: (({SessionPhase phase, int totalMs}) props) =>
          PhaseDuration(phase: props.phase, totalMs: props.totalMs),
      generator: () => (phase: SessionPhase.work, totalMs: 1500000),
      variations: (({SessionPhase phase, int totalMs}) props) => [
        (phase: SessionPhase.break_, totalMs: props.totalMs),
        (phase: props.phase, totalMs: props.totalMs + 1000),
      ],
      invalids: (({SessionPhase phase, int totalMs}) props) => [
        (phase: props.phase, totalMs: -1),
      ],
    );
  });

  group('PomodoroSessionSearchCriteria', () {
    valueObjectTest(
      constructor:
          (({ProfileIdentifier profile, PomodoroSessionStatus status}) props) =>
              PomodoroSessionSearchCriteria(
                profile: props.profile,
                status: props.status,
              ),
      generator: () => (
        profile: Builder(ProfileIdentifierFactory()).build(),
        status: PomodoroSessionStatus.running,
      ),
      variations:
          (({ProfileIdentifier profile, PomodoroSessionStatus status}) props) =>
              [
                (
                  profile: Builder(ProfileIdentifierFactory()).build(),
                  status: props.status,
                ),
                (profile: props.profile, status: PomodoroSessionStatus.idle),
              ],
      invalids:
          (({ProfileIdentifier profile, PomodoroSessionStatus status}) props) =>
              [],
    );
  });

  group('PomodoroPolicySnapshot', () {
    valueObjectTest(
      constructor:
          (
            ({
              int workMinutes,
              int breakMinutes,
              int longBreakMinutes,
              int longBreakEvery,
              bool longBreakEnabled,
            })
            props,
          ) => PomodoroPolicySnapshot(
            workMinutes: props.workMinutes,
            breakMinutes: props.breakMinutes,
            longBreakMinutes: props.longBreakMinutes,
            longBreakEvery: props.longBreakEvery,
            longBreakEnabled: props.longBreakEnabled,
          ),
      generator: () => (
        workMinutes: 25,
        breakMinutes: 5,
        longBreakMinutes: 15,
        longBreakEvery: 4,
        longBreakEnabled: true,
      ),
      variations:
          (
            ({
              int workMinutes,
              int breakMinutes,
              int longBreakMinutes,
              int longBreakEvery,
              bool longBreakEnabled,
            })
            props,
          ) => [
            (
              workMinutes: props.workMinutes + 1,
              breakMinutes: props.breakMinutes,
              longBreakMinutes: props.longBreakMinutes,
              longBreakEvery: props.longBreakEvery,
              longBreakEnabled: props.longBreakEnabled,
            ),
            (
              workMinutes: props.workMinutes,
              breakMinutes: props.breakMinutes + 1,
              longBreakMinutes: props.longBreakMinutes,
              longBreakEvery: props.longBreakEvery,
              longBreakEnabled: props.longBreakEnabled,
            ),
            (
              workMinutes: props.workMinutes,
              breakMinutes: props.breakMinutes,
              longBreakMinutes: props.longBreakMinutes + 1,
              longBreakEvery: props.longBreakEvery,
              longBreakEnabled: props.longBreakEnabled,
            ),
            (
              workMinutes: props.workMinutes,
              breakMinutes: props.breakMinutes,
              longBreakMinutes: props.longBreakMinutes,
              longBreakEvery: props.longBreakEvery + 1,
              longBreakEnabled: props.longBreakEnabled,
            ),
            (
              workMinutes: props.workMinutes,
              breakMinutes: props.breakMinutes,
              longBreakMinutes: props.longBreakMinutes,
              longBreakEvery: props.longBreakEvery,
              longBreakEnabled: !props.longBreakEnabled,
            ),
          ],
      invalids:
          (
            ({
              int workMinutes,
              int breakMinutes,
              int longBreakMinutes,
              int longBreakEvery,
              bool longBreakEnabled,
            })
            props,
          ) => [
            (
              workMinutes: 0,
              breakMinutes: props.breakMinutes,
              longBreakMinutes: props.longBreakMinutes,
              longBreakEvery: props.longBreakEvery,
              longBreakEnabled: props.longBreakEnabled,
            ),
            (
              workMinutes: 121,
              breakMinutes: props.breakMinutes,
              longBreakMinutes: props.longBreakMinutes,
              longBreakEvery: props.longBreakEvery,
              longBreakEnabled: props.longBreakEnabled,
            ),
            (
              workMinutes: props.workMinutes,
              breakMinutes: 0,
              longBreakMinutes: props.longBreakMinutes,
              longBreakEvery: props.longBreakEvery,
              longBreakEnabled: props.longBreakEnabled,
            ),
            (
              workMinutes: props.workMinutes,
              breakMinutes: props.breakMinutes,
              longBreakMinutes: 0,
              longBreakEvery: props.longBreakEvery,
              longBreakEnabled: props.longBreakEnabled,
            ),
            (
              workMinutes: props.workMinutes,
              breakMinutes: props.breakMinutes,
              longBreakMinutes: props.longBreakMinutes,
              longBreakEvery: 0,
              longBreakEnabled: props.longBreakEnabled,
            ),
          ],
    );
  });

  group('RemainingTime', () {
    valueObjectTest(
      constructor: (({int ms}) props) => RemainingTime(ms: props.ms),
      generator: () => (ms: 1500000),
      variations: (({int ms}) props) => [
        (ms: props.ms + 1000),
        (ms: props.ms - 1000),
      ],
      invalids: (({int ms}) props) => [(ms: -1)],
      additionalTests: () {
        group('subtract', () {
          test('subtracts elapsed time from remaining time.', () {
            final remaining = RemainingTime(ms: 10000);

            final result = remaining.subtract(3000);

            expect(result.ms, equals(7000));
          });

          test('clamps to 0 when elapsed time exceeds remaining time.', () {
            final remaining = RemainingTime(ms: 5000);

            final result = remaining.subtract(7000);

            expect(result.ms, equals(0));
          });
        });

        group('isExpired', () {
          test('returns true when ms is 0.', () {
            final remaining = RemainingTime(ms: 0);

            expect(remaining.isExpired(), isTrue);
          });

          test('returns false when ms is greater than 0.', () {
            final remaining = RemainingTime(ms: 1);

            expect(remaining.isExpired(), isFalse);
          });
        });

        group('toMinutes', () {
          test('converts ms to minutes, rounding up.', () {
            final remaining = RemainingTime(ms: 90000);

            expect(remaining.toMinutes(), equals(2));
          });

          test('returns 1 for less than 1 minute.', () {
            final remaining = RemainingTime(ms: 30000);

            expect(remaining.toMinutes(), equals(1));
          });

          test('returns 0 for 0 ms.', () {
            final remaining = RemainingTime(ms: 0);

            expect(remaining.toMinutes(), equals(0));
          });
        });
      },
    );
  });

  group('PhaseHistory', () {
    valueObjectTest(
      constructor:
          (
            ({
              SessionPhase phase,
              DateTime startedAt,
              DateTime endedAt,
              bool skipped,
            })
            props,
          ) => PhaseHistory(
            phase: props.phase,
            startedAt: props.startedAt,
            endedAt: props.endedAt,
            skipped: props.skipped,
          ),
      generator: () => (
        phase: SessionPhase.work,
        startedAt: DateTime(2025, 1, 1, 10, 0),
        endedAt: DateTime(2025, 1, 1, 10, 25),
        skipped: false,
      ),
      variations:
          (
            ({
              SessionPhase phase,
              DateTime startedAt,
              DateTime endedAt,
              bool skipped,
            })
            props,
          ) => [
            (
              phase: SessionPhase.break_,
              startedAt: props.startedAt,
              endedAt: props.endedAt,
              skipped: props.skipped,
            ),
            (
              phase: props.phase,
              startedAt: props.startedAt.add(const Duration(minutes: 1)),
              endedAt: props.endedAt,
              skipped: props.skipped,
            ),
            (
              phase: props.phase,
              startedAt: props.startedAt,
              endedAt: props.endedAt.add(const Duration(minutes: 1)),
              skipped: props.skipped,
            ),
            (
              phase: props.phase,
              startedAt: props.startedAt,
              endedAt: props.endedAt,
              skipped: !props.skipped,
            ),
          ],
      invalids:
          (
            ({
              SessionPhase phase,
              DateTime startedAt,
              DateTime endedAt,
              bool skipped,
            })
            props,
          ) => [
            (
              phase: props.phase,
              startedAt: props.endedAt,
              endedAt: props.startedAt,
              skipped: props.skipped,
            ),
          ],
    );
  });

  group('PhaseSummary', () {
    valueObjectTest(
      constructor:
          (
            ({
              SessionPhase phase,
              int actualDurationMs,
              bool skipped,
              DateTime startedAt,
              DateTime endedAt,
            })
            props,
          ) => PhaseSummary(
            phase: props.phase,
            actualDurationMs: props.actualDurationMs,
            skipped: props.skipped,
            startedAt: props.startedAt,
            endedAt: props.endedAt,
          ),
      generator: () {
        final startedAt = DateTime(2025, 1, 1, 10, 0);
        final endedAt = DateTime(2025, 1, 1, 10, 25);
        final actualDurationMs = endedAt.difference(startedAt).inMilliseconds;

        return (
          phase: SessionPhase.work,
          actualDurationMs: actualDurationMs,
          skipped: false,
          startedAt: startedAt,
          endedAt: endedAt,
        );
      },
      variations:
          (
            ({
              SessionPhase phase,
              int actualDurationMs,
              bool skipped,
              DateTime startedAt,
              DateTime endedAt,
            })
            props,
          ) => [
            (
              phase: SessionPhase.break_,
              actualDurationMs: props.actualDurationMs,
              skipped: props.skipped,
              startedAt: props.startedAt,
              endedAt: props.endedAt,
            ),
            (
              phase: props.phase,
              actualDurationMs: props.actualDurationMs,
              skipped: !props.skipped,
              startedAt: props.startedAt,
              endedAt: props.endedAt,
            ),
          ],
      invalids:
          (
            ({
              SessionPhase phase,
              int actualDurationMs,
              bool skipped,
              DateTime startedAt,
              DateTime endedAt,
            })
            props,
          ) => [
            (
              phase: props.phase,
              actualDurationMs: props.actualDurationMs,
              skipped: props.skipped,
              startedAt: props.endedAt,
              endedAt: props.startedAt,
            ),
            (
              phase: props.phase,
              actualDurationMs: props.actualDurationMs + 2000,
              skipped: props.skipped,
              startedAt: props.startedAt,
              endedAt: props.endedAt,
            ),
          ],
    );
  });

  group('WorkBreakRatio', () {
    valueObjectTest(
      constructor: (({int workMs, int breakMs}) props) =>
          WorkBreakRatio(workMs: props.workMs, breakMs: props.breakMs),
      generator: () => (workMs: 1500000, breakMs: 300000),
      variations: (({int workMs, int breakMs}) props) => [
        (workMs: props.workMs + 1000, breakMs: props.breakMs),
        (workMs: props.workMs, breakMs: props.breakMs + 1000),
      ],
      invalids: (({int workMs, int breakMs}) props) => [
        (workMs: -1, breakMs: props.breakMs),
        (workMs: props.workMs, breakMs: -1),
      ],
    );
  });

  group('DateRange', () {
    valueObjectTest(
      constructor: (({DateTime start, DateTime end}) props) =>
          DateRange(start: props.start, end: props.end),
      generator: () =>
          (start: DateTime(2025, 1, 1), end: DateTime(2025, 1, 31)),
      variations: (({DateTime start, DateTime end}) props) => [
        (start: props.start.add(const Duration(days: 1)), end: props.end),
        (start: props.start, end: props.end.add(const Duration(days: 1))),
      ],
      invalids: (({DateTime start, DateTime end}) props) => [
        (start: props.end, end: props.start),
      ],
    );
  });

  group('PomodoroSession', () {
    group('create', () {
      test('creates new pomodoro session in idle state.', () {
        final identifier = Builder(PomodoroSessionIdentifierFactory()).build();

        final policySnapshot = Builder(PomodoroPolicySnapshotFactory()).build();

        final session = PomodoroSession.create(
          identifier: identifier,
          policySnapshot: policySnapshot,
        );

        expect(session.identifier, equals(identifier));
        expect(session.status, equals(PomodoroSessionStatus.idle));
        expect(session.phase, equals(SessionPhase.idle));
        expect(session.elapsedCycles, equals(0));
        expect(session.phaseHistory, isEmpty);
      });
    });

    group('start', () {
      test('starts session and transitions to work phase.', () {
        final session = Builder(PomodoroSessionFactory()).build();

        final policySnapshot = Builder(PomodoroPolicySnapshotFactory())
            .buildWith(
              seed: 1,
              overrides: (
                workMinutes: 25,
                breakMinutes: null,
                longBreakMinutes: null,
                longBreakEvery: null,
                longBreakEnabled: null,
              ),
            );

        final startedAt = DateTime(2025, 1, 1, 10, 0);

        session.start(policySnapshot: policySnapshot, startedAt: startedAt);

        expect(session.status, equals(PomodoroSessionStatus.running));
        expect(session.phase, equals(SessionPhase.work));
        expect(session.remainingTime.ms, equals(25 * 60000));
        expect(session.lastTickAt, equals(startedAt));

        final events = session.events();
        expect(events.length, equals(1));
        expect(events.first, isA<PomodoroPhaseStarted>());

        final event = events.first as PomodoroPhaseStarted;
        expect(event.phase, equals(SessionPhase.work));
        expect(event.startedAt, equals(startedAt));
      });

      test('throws StateError when starting from non-idle status.', () {
        final session = Builder(PomodoroSessionFactory()).build();

        final policySnapshot = Builder(PomodoroPolicySnapshotFactory()).build();

        final startedAt = DateTime(2025, 1, 1, 10, 0);

        session.start(policySnapshot: policySnapshot, startedAt: startedAt);

        expect(
          () => session.start(
            policySnapshot: policySnapshot,
            startedAt: startedAt,
          ),
          throwsStateError,
        );
      });
    });

    group('pause', () {
      test('pauses running session.', () {
        final session = Builder(PomodoroSessionFactory()).build();

        final policySnapshot = Builder(PomodoroPolicySnapshotFactory()).build();

        session.start(
          policySnapshot: policySnapshot,
          startedAt: DateTime(2025, 1, 1, 10, 0),
        );

        final pausedAt = DateTime(2025, 1, 1, 10, 10);

        session.pause(pausedAt: pausedAt);

        expect(session.status, equals(PomodoroSessionStatus.paused));
        expect(session.lastTickAt, equals(pausedAt));
      });

      test('throws StateError when pausing from non-running status.', () {
        final session = Builder(PomodoroSessionFactory()).build();

        expect(
          () => session.pause(pausedAt: DateTime(2025, 1, 1, 10, 0)),
          throwsStateError,
        );
      });
    });

    group('resume', () {
      test('resumes paused session.', () {
        final session = Builder(PomodoroSessionFactory()).build();

        final policySnapshot = Builder(PomodoroPolicySnapshotFactory()).build();

        session.start(
          policySnapshot: policySnapshot,
          startedAt: DateTime(2025, 1, 1, 10, 0),
        );

        session.pause(pausedAt: DateTime(2025, 1, 1, 10, 10));

        final resumedAt = DateTime(2025, 1, 1, 10, 15);

        session.resume(resumedAt: resumedAt);

        expect(session.status, equals(PomodoroSessionStatus.running));
        expect(session.lastTickAt, equals(resumedAt));
      });

      test('throws StateError when resuming from non-paused status.', () {
        final session = Builder(PomodoroSessionFactory()).build();

        expect(
          () => session.resume(resumedAt: DateTime(2025, 1, 1, 10, 0)),
          throwsStateError,
        );
      });
    });

    group('skip', () {
      test('skips current phase and transitions to next phase.', () {
        final policySnapshot = Builder(PomodoroPolicySnapshotFactory())
            .buildWith(
              seed: 1,
              overrides: (
                workMinutes: 25,
                breakMinutes: 5,
                longBreakMinutes: 15,
                longBreakEvery: 4,
                longBreakEnabled: false,
              ),
            );

        final identifier = Builder(PomodoroSessionIdentifierFactory()).build();

        final session = PomodoroSession.create(
          identifier: identifier,
          policySnapshot: policySnapshot,
        );

        session.start(
          policySnapshot: policySnapshot,
          startedAt: DateTime(2025, 1, 1, 10, 0),
        );

        final skippedAt = DateTime(2025, 1, 1, 10, 10);

        session.skip(skippedAt: skippedAt);

        expect(session.status, equals(PomodoroSessionStatus.running));
        expect(session.phase, equals(SessionPhase.break_));
        expect(session.phaseHistory.length, equals(1));
        expect(session.phaseHistory.first.skipped, isTrue);

        final events = session.events();
        expect(events.length, equals(3));
        expect(events[1], isA<PomodoroPhaseCompleted>());

        final completedEvent = events[1] as PomodoroPhaseCompleted;
        expect(completedEvent.skipped, isTrue);
      });
    });

    group('tick', () {
      test('progresses timer and returns false when phase not complete.', () {
        final session = Builder(PomodoroSessionFactory()).build();

        final policySnapshot = Builder(PomodoroPolicySnapshotFactory())
            .buildWith(
              seed: 1,
              overrides: (
                workMinutes: 25,
                breakMinutes: null,
                longBreakMinutes: null,
                longBreakEvery: null,
                longBreakEnabled: null,
              ),
            );

        session.start(
          policySnapshot: policySnapshot,
          startedAt: DateTime(2025, 1, 1, 10, 0, 0),
        );

        final currentTime = DateTime(2025, 1, 1, 10, 0, 1);

        final isComplete = session.tick(currentTime: currentTime);

        expect(isComplete, isFalse);
        expect(session.remainingTime.ms, equals((25 * 60000) - 1000));
        expect(session.lastTickAt, equals(currentTime));
      });

      test('completes phase and returns true when time expires.', () {
        final policySnapshot = Builder(PomodoroPolicySnapshotFactory())
            .buildWith(
              seed: 1,
              overrides: (
                workMinutes: 1,
                breakMinutes: null,
                longBreakMinutes: null,
                longBreakEvery: null,
                longBreakEnabled: null,
              ),
            );

        final identifier = Builder(PomodoroSessionIdentifierFactory()).build();

        final session = PomodoroSession.create(
          identifier: identifier,
          policySnapshot: policySnapshot,
        );

        session.start(
          policySnapshot: policySnapshot,
          startedAt: DateTime(2025, 1, 1, 10, 0, 0),
        );

        var currentTime = DateTime(2025, 1, 1, 10, 0, 0);
        var isComplete = false;

        for (var i = 0; i < 60; i++) {
          currentTime = currentTime.add(const Duration(seconds: 1));
          isComplete = session.tick(currentTime: currentTime);
          if (isComplete) {
            break;
          }
        }

        expect(isComplete, isTrue);
        expect(session.phase, equals(SessionPhase.break_));
        expect(session.phaseHistory.length, equals(1));
        expect(session.phaseHistory.first.phase, equals(SessionPhase.work));

        final events = session.events();
        expect(events.any((event) => event is PomodoroPhaseCompleted), isTrue);
      });

      test('completes phase immediately when sleep resume detected.', () {
        final policySnapshot = Builder(PomodoroPolicySnapshotFactory())
            .buildWith(
              seed: 1,
              overrides: (
                workMinutes: 25,
                breakMinutes: 5,
                longBreakMinutes: 15,
                longBreakEvery: 4,
                longBreakEnabled: false,
              ),
            );

        final identifier = Builder(PomodoroSessionIdentifierFactory()).build();

        final session = PomodoroSession.create(
          identifier: identifier,
          policySnapshot: policySnapshot,
        );

        session.start(
          policySnapshot: policySnapshot,
          startedAt: DateTime(2025, 1, 1, 10, 0, 0),
        );

        final currentTime = DateTime(2025, 1, 1, 10, 5, 0);

        final isComplete = session.tick(currentTime: currentTime);

        expect(isComplete, isTrue);
        expect(session.phase, equals(SessionPhase.break_));
        expect(session.remainingTime.ms, equals(5 * 60000));
        expect(session.phaseHistory.length, equals(1));
        expect(session.phaseHistory.first.phase, equals(SessionPhase.work));

        final events = session.events();
        expect(events.any((event) => event is PomodoroPhaseCompleted), isTrue);
        expect(events.any((event) => event is PomodoroPhaseStarted), isTrue);
      });
    });
  });

  group('SessionLog', () {
    group('record', () {
      test('records session log with valid data.', () {
        final identifier = Builder(SessionLogIdentifierFactory()).build();

        final session = Builder(PomodoroSessionIdentifierFactory()).build();

        final profile = Builder(ProfileIdentifierFactory()).build();

        final startedAt = DateTime(2025, 1, 1, 10, 0);

        final endedAt = DateTime(2025, 1, 1, 12, 0);

        final phaseSummaries = [
          PhaseSummary(
            phase: SessionPhase.work,
            actualDurationMs: 25 * 60000,
            skipped: false,
            startedAt: startedAt,
            endedAt: startedAt.add(const Duration(minutes: 25)),
          ),
          PhaseSummary(
            phase: SessionPhase.break_,
            actualDurationMs: 5 * 60000,
            skipped: false,
            startedAt: startedAt.add(const Duration(minutes: 25)),
            endedAt: startedAt.add(const Duration(minutes: 30)),
          ),
        ];

        final totalWorkMs = 25 * 60000;

        final totalBreakMs = 5 * 60000;

        final cycleCount = 1;

        final log = SessionLog.record(
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

        expect(log.identifier, equals(identifier));
        expect(log.session, equals(session));
        expect(log.profile, equals(profile));
        expect(log.totalWorkMs, equals(totalWorkMs));
        expect(log.totalBreakMs, equals(totalBreakMs));
        expect(log.cycleCount, equals(cycleCount));

        final events = log.events();
        expect(events.length, equals(1));
        expect(events.first, isA<SessionLogRecorded>());
      });

      test('throws when totalWorkMs does not match phase summaries.', () {
        final identifier = Builder(SessionLogIdentifierFactory()).build();

        final session = Builder(PomodoroSessionIdentifierFactory()).build();

        final profile = Builder(ProfileIdentifierFactory()).build();

        final startedAt = DateTime(2025, 1, 1, 10, 0);

        final endedAt = DateTime(2025, 1, 1, 12, 0);

        final phaseSummaries = [
          PhaseSummary(
            phase: SessionPhase.work,
            actualDurationMs: 25 * 60000,
            skipped: false,
            startedAt: startedAt,
            endedAt: startedAt.add(const Duration(minutes: 25)),
          ),
        ];

        expect(
          () => SessionLog.record(
            identifier: identifier,
            session: session,
            profile: profile,
            startedAt: startedAt,
            endedAt: endedAt,
            totalWorkMs: 30 * 60000,
            totalBreakMs: 0,
            cycleCount: 1,
            phaseSummaries: phaseSummaries,
            occurredAt: endedAt,
          ),
          throwsA(isA<Object>()),
        );
      });

      test('throws when totalBreakMs does not match phase summaries.', () {
        final identifier = Builder(SessionLogIdentifierFactory()).build();

        final session = Builder(PomodoroSessionIdentifierFactory()).build();

        final profile = Builder(ProfileIdentifierFactory()).build();

        final startedAt = DateTime(2025, 1, 1, 10, 0);

        final endedAt = DateTime(2025, 1, 1, 12, 0);

        final phaseSummaries = [
          PhaseSummary(
            phase: SessionPhase.break_,
            actualDurationMs: 5 * 60000,
            skipped: false,
            startedAt: startedAt,
            endedAt: startedAt.add(const Duration(minutes: 5)),
          ),
        ];

        expect(
          () => SessionLog.record(
            identifier: identifier,
            session: session,
            profile: profile,
            startedAt: startedAt,
            endedAt: endedAt,
            totalWorkMs: 0,
            totalBreakMs: 10 * 60000,
            cycleCount: 0,
            phaseSummaries: phaseSummaries,
            occurredAt: endedAt,
          ),
          throwsA(isA<Object>()),
        );
      });

      test('throws when cycleCount does not match phase summaries.', () {
        final identifier = Builder(SessionLogIdentifierFactory()).build();

        final session = Builder(PomodoroSessionIdentifierFactory()).build();

        final profile = Builder(ProfileIdentifierFactory()).build();

        final startedAt = DateTime(2025, 1, 1, 10, 0);

        final endedAt = DateTime(2025, 1, 1, 12, 0);

        final phaseSummaries = [
          PhaseSummary(
            phase: SessionPhase.work,
            actualDurationMs: 25 * 60000,
            skipped: false,
            startedAt: startedAt,
            endedAt: startedAt.add(const Duration(minutes: 25)),
          ),
        ];

        expect(
          () => SessionLog.record(
            identifier: identifier,
            session: session,
            profile: profile,
            startedAt: startedAt,
            endedAt: endedAt,
            totalWorkMs: 25 * 60000,
            totalBreakMs: 0,
            cycleCount: 2,
            phaseSummaries: phaseSummaries,
            occurredAt: endedAt,
          ),
          throwsA(isA<Object>()),
        );
      });

      test('throws when startedAt is not before endedAt.', () {
        final identifier = Builder(SessionLogIdentifierFactory()).build();

        final session = Builder(PomodoroSessionIdentifierFactory()).build();

        final profile = Builder(ProfileIdentifierFactory()).build();

        final startedAt = DateTime(2025, 1, 1, 10, 0);

        final endedAt = DateTime(2025, 1, 1, 9, 0);

        final phaseSummaries = [
          PhaseSummary(
            phase: SessionPhase.work,
            actualDurationMs: 25 * 60000,
            skipped: false,
            startedAt: startedAt,
            endedAt: startedAt.add(const Duration(minutes: 25)),
          ),
        ];

        expect(
          () => SessionLog.record(
            identifier: identifier,
            session: session,
            profile: profile,
            startedAt: startedAt,
            endedAt: endedAt,
            totalWorkMs: 25 * 60000,
            totalBreakMs: 0,
            cycleCount: 1,
            phaseSummaries: phaseSummaries,
            occurredAt: endedAt,
          ),
          throwsA(isA<Object>()),
        );
      });
    });
  });

  group('PomodoroSession edge cases', () {
    group('pause', () {
      test('throws StateError when pausing from idle phase.', () {
        final policySnapshot = Builder(PomodoroPolicySnapshotFactory()).build();

        final identifier = Builder(PomodoroSessionIdentifierFactory()).build();

        final session = PomodoroSession.create(
          identifier: identifier,
          policySnapshot: policySnapshot,
        );

        expect(
          () => session.pause(pausedAt: DateTime(2025, 1, 1, 10, 0)),
          throwsStateError,
        );
      });

      test('throws StateError when pausing from paused status.', () {
        final policySnapshot = Builder(PomodoroPolicySnapshotFactory()).build();

        final identifier = Builder(PomodoroSessionIdentifierFactory()).build();

        final session = PomodoroSession.create(
          identifier: identifier,
          policySnapshot: policySnapshot,
        );

        session.start(
          policySnapshot: policySnapshot,
          startedAt: DateTime(2025, 1, 1, 10, 0),
        );

        session.pause(pausedAt: DateTime(2025, 1, 1, 10, 10));

        expect(
          () => session.pause(pausedAt: DateTime(2025, 1, 1, 10, 15)),
          throwsStateError,
        );
      });
    });

    group('tick', () {
      test('throws StateError when ticking from paused status.', () {
        final policySnapshot = Builder(PomodoroPolicySnapshotFactory()).build();

        final identifier = Builder(PomodoroSessionIdentifierFactory()).build();

        final session = PomodoroSession.create(
          identifier: identifier,
          policySnapshot: policySnapshot,
        );

        session.start(
          policySnapshot: policySnapshot,
          startedAt: DateTime(2025, 1, 1, 10, 0),
        );

        session.pause(pausedAt: DateTime(2025, 1, 1, 10, 10));

        expect(
          () => session.tick(currentTime: DateTime(2025, 1, 1, 10, 11)),
          throwsStateError,
        );
      });
    });

    group('skip', () {
      test('throws StateError when skipping from non-running status.', () {
        final policySnapshot = Builder(PomodoroPolicySnapshotFactory()).build();

        final identifier = Builder(PomodoroSessionIdentifierFactory()).build();

        final session = PomodoroSession.create(
          identifier: identifier,
          policySnapshot: policySnapshot,
        );

        expect(
          () => session.skip(skippedAt: DateTime(2025, 1, 1, 10, 0)),
          throwsStateError,
        );
      });
    });

    group('complete session', () {
      test('completes full session with multiple cycles.', () {
        final policySnapshot = Builder(PomodoroPolicySnapshotFactory())
            .buildWith(
              seed: 1,
              overrides: (
                workMinutes: 1,
                breakMinutes: 1,
                longBreakMinutes: 1,
                longBreakEvery: 2,
                longBreakEnabled: true,
              ),
            );

        final identifier = Builder(PomodoroSessionIdentifierFactory()).build();

        final session = PomodoroSession.create(
          identifier: identifier,
          policySnapshot: policySnapshot,
        );

        session.start(
          policySnapshot: policySnapshot,
          startedAt: DateTime(2025, 1, 1, 10, 0, 0),
        );

        session.tick(currentTime: DateTime(2025, 1, 1, 10, 1, 0));

        expect(session.phase, equals(SessionPhase.break_));
        expect(session.elapsedCycles, equals(1));

        session.tick(currentTime: DateTime(2025, 1, 1, 10, 2, 0));

        expect(session.phase, equals(SessionPhase.work));

        session.tick(currentTime: DateTime(2025, 1, 1, 10, 3, 0));

        expect(session.phase, equals(SessionPhase.longBreak));
        expect(session.elapsedCycles, equals(2));

        final events = session.events();
        expect(events.any((event) => event is PomodoroPhaseStarted), isTrue);
        expect(events.any((event) => event is PomodoroPhaseCompleted), isTrue);
      });

      test('completes long break phase with small tick intervals.', () {
        final policySnapshot = Builder(PomodoroPolicySnapshotFactory())
            .buildWith(
              seed: 1,
              overrides: (
                workMinutes: 1,
                breakMinutes: 1,
                longBreakMinutes: 1,
                longBreakEvery: 2,
                longBreakEnabled: true,
              ),
            );

        final identifier = Builder(PomodoroSessionIdentifierFactory()).build();

        final session = PomodoroSession.create(
          identifier: identifier,
          policySnapshot: policySnapshot,
        );

        session.start(
          policySnapshot: policySnapshot,
          startedAt: DateTime(2025, 1, 1, 10, 0, 0),
        );

        session.tick(currentTime: DateTime(2025, 1, 1, 10, 1, 0));

        expect(session.phase, equals(SessionPhase.break_));

        session.tick(currentTime: DateTime(2025, 1, 1, 10, 2, 0));

        expect(session.phase, equals(SessionPhase.work));

        session.tick(currentTime: DateTime(2025, 1, 1, 10, 3, 0));

        expect(session.phase, equals(SessionPhase.longBreak));

        var currentTime = DateTime(2025, 1, 1, 10, 3, 0);
        var isComplete = false;

        for (var i = 0; i < 60; i++) {
          currentTime = currentTime.add(const Duration(seconds: 1));
          isComplete = session.tick(currentTime: currentTime);
          if (isComplete) {
            break;
          }
        }

        expect(isComplete, isTrue);
        expect(session.phase, equals(SessionPhase.work));
      });
    });
  });
}
