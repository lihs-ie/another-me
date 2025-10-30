abstract interface class TransactionStrategy {
  void begin();
  void commit();
  void rollback();
}

class Transaction {
  final TransactionStrategy _strategy;
  int _level = 0;

  Transaction({required TransactionStrategy strategy}) : _strategy = strategy;

  void begin() {
    if (_level++ == 0) {
      _strategy.begin();
    }
  }

  void commit() {
    if (--_level == 0) {
      _strategy.commit();
    }
  }

  void rollback() {
    if (_level == 0) {
      return;
    }
    _level = 0;
    _strategy.rollback();
  }

  Future<T> execute<T>(Future<T> Function() runner) async {
    _strategy.begin();

    try {
      final result = await runner();

      _strategy.commit();

      return result;
    } catch (error) {
      _strategy.rollback();
      rethrow;
    }
  }
}
