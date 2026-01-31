enum SyncPhase { idle, listing, fetching, processing, complete, error }

class SyncProgress {
  final SyncPhase phase;
  final int totalMessages;
  final int processedMessages;
  final String? errorMessage;

  const SyncProgress({
    this.phase = SyncPhase.idle,
    this.totalMessages = 0,
    this.processedMessages = 0,
    this.errorMessage,
  });

  const SyncProgress.idle() : this();

  const SyncProgress.listing()
      : phase = SyncPhase.listing,
        totalMessages = 0,
        processedMessages = 0,
        errorMessage = null;

  SyncProgress copyWith({
    SyncPhase? phase,
    int? totalMessages,
    int? processedMessages,
    String? errorMessage,
  }) {
    return SyncProgress(
      phase: phase ?? this.phase,
      totalMessages: totalMessages ?? this.totalMessages,
      processedMessages: processedMessages ?? this.processedMessages,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  double get progress =>
      totalMessages > 0 ? processedMessages / totalMessages : 0.0;

  String get phaseLabel {
    switch (phase) {
      case SyncPhase.idle:
        return 'Ready';
      case SyncPhase.listing:
        return 'Discovering emails...';
      case SyncPhase.fetching:
        return 'Fetching email details...';
      case SyncPhase.processing:
        return 'Processing senders...';
      case SyncPhase.complete:
        return 'Sync complete';
      case SyncPhase.error:
        return 'Sync failed';
    }
  }

  bool get isActive =>
      phase == SyncPhase.listing ||
      phase == SyncPhase.fetching ||
      phase == SyncPhase.processing;
}
