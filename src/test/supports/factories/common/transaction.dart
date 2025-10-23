import 'package:another_me/domains/common/transaction.dart';

import '../common.dart';

class _TransactionStrategy implements TransactionStrategy {
  @override
  void begin() {}

  @override
  void commit() {}

  @override
  void rollback() {}
}

class TransactionStrategyFactory extends Factory<TransactionStrategy, void> {
  @override
  TransactionStrategy create({void overrides, required int seed}) {
    return _TransactionStrategy();
  }

  @override
  TransactionStrategy duplicate(TransactionStrategy instance, void overrides) {
    return _TransactionStrategy();
  }
}

typedef TransactionOverrides = ({TransactionStrategy? strategy});

class TransactionFactory extends Factory<Transaction, TransactionOverrides> {
  @override
  Transaction create({TransactionOverrides? overrides, required int seed}) {
    return Transaction(
      strategy:
          overrides?.strategy ??
          Builder(TransactionStrategyFactory()).buildWith(seed: seed),
    );
  }

  @override
  Transaction duplicate(Transaction instance, TransactionOverrides? overrides) {
    throw UnimplementedError();
  }
}
