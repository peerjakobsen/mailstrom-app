class RateLimiter {
  final int unitsPerSecond;
  int _availableUnits;
  DateTime _lastRefill;

  RateLimiter({required this.unitsPerSecond})
      : _availableUnits = unitsPerSecond,
        _lastRefill = DateTime.now();

  Future<void> acquire(int units) async {
    _refill();
    while (_availableUnits < units) {
      final waitMs = ((units - _availableUnits) / unitsPerSecond * 1000).ceil();
      await Future<void>.delayed(Duration(milliseconds: waitMs));
      _refill();
    }
    _availableUnits -= units;
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
