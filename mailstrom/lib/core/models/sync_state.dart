class SyncState {
  final DateTime? lastSyncTime;
  final String? historyId;
  final int totalEmails;
  final int processedEmails;

  const SyncState({
    this.lastSyncTime,
    this.historyId,
    this.totalEmails = 0,
    this.processedEmails = 0,
  });

  SyncState copyWith({
    DateTime? lastSyncTime,
    String? historyId,
    int? totalEmails,
    int? processedEmails,
  }) {
    return SyncState(
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      historyId: historyId ?? this.historyId,
      totalEmails: totalEmails ?? this.totalEmails,
      processedEmails: processedEmails ?? this.processedEmails,
    );
  }

  bool get hasCompletedInitialSync => lastSyncTime != null;

  double get progress =>
      totalEmails > 0 ? processedEmails / totalEmails : 0.0;
}
