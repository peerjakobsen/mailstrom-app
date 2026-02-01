import 'package:flutter_riverpod/flutter_riverpod.dart';

enum LogLevel { info, warning, error }

class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String? source;

  const LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.source,
  });
}

final logNotifierProvider =
    NotifierProvider<LogNotifier, List<LogEntry>>(LogNotifier.new);

final logPanelVisibleProvider = StateProvider<bool>((ref) => false);

class LogNotifier extends Notifier<List<LogEntry>> {
  static const _maxEntries = 500;

  @override
  List<LogEntry> build() => [];

  void add(LogLevel level, String message, {String? source}) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      source: source,
    );
    final updated = [...state, entry];
    if (updated.length > _maxEntries) {
      state = updated.sublist(updated.length - _maxEntries);
    } else {
      state = updated;
    }
  }

  void clear() {
    state = [];
  }
}
