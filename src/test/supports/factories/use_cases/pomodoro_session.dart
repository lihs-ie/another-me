import 'package:another_me/domains/common/transaction.dart';
import 'package:another_me/domains/profile/profile.dart';
import 'package:another_me/domains/work/work.dart';
import 'package:another_me/use_cases/pomodoro_session.dart' as use_case;
import 'package:logger/logger.dart';

import '../common.dart';
import '../common/transaction.dart' as transaction_factory;
import '../logger.dart';
import '../profile/profile.dart' as profile_factory;
import '../work/work.dart' as work_factory;

typedef PomodoroSessionUseCaseOverrides = ({
  UserProfileRepository? userProfileRepository,
  PomodoroSessionRepository? pomodoroSessionRepository,
  SessionLogRepository? sessionLogRepository,
  Transaction? transaction,
  Logger? logger,
});

class PomodoroSessionUseCaseFactory
    extends Factory<use_case.PomodoroSession, PomodoroSessionUseCaseOverrides> {
  @override
  use_case.PomodoroSession create({
    PomodoroSessionUseCaseOverrides? overrides,
    required int seed,
  }) {
    final userProfileRepository =
        overrides?.userProfileRepository ??
        Builder(
          profile_factory.UserProfileRepositoryFactory(),
        ).buildWith(seed: seed);

    final pomodoroSessionRepository =
        overrides?.pomodoroSessionRepository ??
        Builder(
          work_factory.PomodoroSessionRepositoryFactory(),
        ).buildWith(seed: seed);

    final sessionLogRepository =
        overrides?.sessionLogRepository ??
        Builder(
          work_factory.SessionLogRepositoryFactory(),
        ).buildWith(seed: seed);

    final transaction =
        overrides?.transaction ??
        Builder(transaction_factory.TransactionFactory()).buildWith(seed: seed);

    final logger =
        overrides?.logger ?? Builder(LoggerFactory()).buildWith(seed: seed);

    return use_case.PomodoroSession(
      userProfileRepository: userProfileRepository,
      pomodoroSessionRepository: pomodoroSessionRepository,
      sessionLogRepository: sessionLogRepository,
      transaction: transaction,
      logger: logger,
    );
  }

  @override
  use_case.PomodoroSession duplicate(
    use_case.PomodoroSession instance,
    PomodoroSessionUseCaseOverrides? overrides,
  ) {
    throw UnimplementedError();
  }
}
