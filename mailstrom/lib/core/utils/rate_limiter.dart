class RateLimiter {
  final int unitsPerSecond;
  final void Function(int requested, int available, int waitMs)? onWait;
  int _availableUnits;
  DateTime _lastRefill;

  RateLimiter({required this.unitsPerSecond, this.onWait})
      : _availableUnits = unitsPerSecond,
        _lastRefill = DateTime.now();

  Future<void> acquire(int units) async {
    var remaining = units;
    while (remaining > 0) {
      final chunk = remaining.clamp(0, unitsPerSecond);
      _refill();
      while (_availableUnits < chunk) {
        final waitMs =
            ((chunk - _availableUnits) / unitsPerSecond * 1000).ceil();
        onWait?.call(chunk, _availableUnits, waitMs);
        await Future<void>.delayed(Duration(milliseconds: waitMs));
        _refill();
      }
      _availableUnits -= chunk;
      remaining -= chunk;
    }
  }

  void _refill() {
    final now = DateTime.now();
    final elapsed = now.difference(_lastRefill).inMilliseconds;
    if (elapsed > 0) {
      final newUnits = (elapsed * unitsPerSecond / 1000).floor();
      _availableUnits = (_availableUnits + newUnits).clamp(0, unitsPerSecond);
      _lastRefill = now;
    }
  }
}
