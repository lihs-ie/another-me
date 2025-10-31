abstract interface class PeriodicTaskScheduler {
  void schedule({
    required Duration interval,
    required Future<void> Function() task,
  });

  void cancel();
}
