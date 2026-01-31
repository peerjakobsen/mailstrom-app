import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../../../core/database/daos/email_dao.dart';
import '../../../core/database/daos/sender_dao.dart';
import '../../../core/database/daos/sync_state_dao.dart';
import '../../../core/models/sync_progress.dart';
import '../../../core/services/gmail_service.dart';
import '../../../core/utils/category_engine.dart';
import '../../../core/utils/email_parser.dart';

final syncNotifierProvider =
    AsyncNotifierProvider<SyncNotifier, SyncProgress>(SyncNotifier.new);

class SyncNotifier extends AsyncNotifier<SyncProgress> {
  bool _hasCompletedInitialSync = false;
  bool _hasStartedFetching = false;

  bool get hasCompletedInitialSync => _hasCompletedInitialSync;

  /// True once the fetching phase begins (senders start appearing).
  /// Used by routing to show HomeScreen instead of InitialSyncScreen.
  bool get hasStartedFetching => _hasStartedFetching;

  @override
  FutureOr<SyncProgress> build() async {
    final syncStateDao = ref.read(syncStateDaoProvider);
    final emailDao = ref.read(emailDaoProvider);
    final syncState = await syncStateDao.getSyncState();

    if (syncState?.lastSyncTime != null) {
      _hasCompletedInitialSync = true;
      _hasStartedFetching = true;
      // Re-categorize senders once after upgrade to smart engine
      _recategorizeSenders();
      // Start incremental sync in background
      _runIncrementalSync(syncState!.historyId);
      return const SyncProgress(phase: SyncPhase.complete);
    }

    // Check if a partial sync exists (emails in DB but no lastSyncTime)
    final existingIds = await emailDao.getAllEmailIds();
    if (existingIds.isNotEmpty) {
      _hasStartedFetching = true;
      _resumeInitialSync(existingIds);
      return SyncProgress(
        phase: SyncPhase.fetching,
        totalMessages: 0,
        processedMessages: existingIds.length,
      );
    }

    // No previous sync — run initial sync
    _runInitialSync();
    return const SyncProgress.listing();
  }

  /// One-time re-categorization of existing senders using the smart engine.
  /// Runs only when senders with 'unknown' category exist and could be
  /// better categorized by the new engine's domain/pattern/subject heuristics.
  Future<void> _recategorizeSenders() async {
    try {
      final senderDao = ref.read(senderDaoProvider);
      final emailDao = ref.read(emailDaoProvider);

      final senders = await senderDao.getAllSenders();
      // Only re-categorize senders that the old engine couldn't classify well
      final candidates = senders.where(
        (s) => s.category == 'unknown' || s.category == 'newsletter',
      );

      for (final sender in candidates) {
        // Get one email to use subject for categorization
        final emails = await emailDao.getEmailsBySender(sender.email);
        final subject = emails.isNotEmpty ? emails.first.subject : '';

        final newCategory = CategoryEngine.categorize(
          senderEmail: sender.email,
          domain: sender.domain,
          subject: subject,
          unsubscribeHeader: sender.unsubscribeLink,
        );

        if (newCategory != sender.category) {
          await senderDao.updateCategory(sender.email, newCategory);
        }
      }
    } catch (_) {
      // Non-critical — don't block app startup
    }
  }

  Future<void> _runInitialSync() async {
    try {
      final gmailService = ref.read(gmailServiceProvider);
      final senderDao = ref.read(senderDaoProvider);
      final emailDao = ref.read(emailDaoProvider);
      final syncStateDao = ref.read(syncStateDaoProvider);

      state = const AsyncValue.data(SyncProgress.listing());

      // Get user profile for historyId
      final profile = await gmailService.getUserProfile();
      final historyId = profile.historyId;

      // List all message IDs
      final allMessageIds = <String>[];
      String? pageToken;
      do {
        final result = await gmailService.listMessageIds(
          pageToken: pageToken,
        );
        allMessageIds.addAll(result.ids);
        pageToken = result.nextPageToken;
        state = AsyncValue.data(
          SyncProgress(
            phase: SyncPhase.listing,
            totalMessages: allMessageIds.length,
            processedMessages: 0,
          ),
        );
      } while (pageToken != null);

      // Fetch metadata in batches
      _hasStartedFetching = true;
      await _fetchAndStoreMessages(
        allMessageIds: allMessageIds,
        historyId: historyId,
        gmailService: gmailService,
        emailDao: emailDao,
        senderDao: senderDao,
        syncStateDao: syncStateDao,
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Resume a partial initial sync by re-listing IDs and fetching only missing.
  Future<void> _resumeInitialSync(List<String> existingIds) async {
    try {
      final gmailService = ref.read(gmailServiceProvider);
      final senderDao = ref.read(senderDaoProvider);
      final emailDao = ref.read(emailDaoProvider);
      final syncStateDao = ref.read(syncStateDaoProvider);

      // Get user profile for historyId
      final profile = await gmailService.getUserProfile();
      final historyId = profile.historyId;

      // Re-list all message IDs (fast — just IDs, no metadata)
      state = const AsyncValue.data(SyncProgress.listing());
      final allMessageIds = <String>[];
      String? pageToken;
      do {
        final result = await gmailService.listMessageIds(
          pageToken: pageToken,
        );
        allMessageIds.addAll(result.ids);
        pageToken = result.nextPageToken;
      } while (pageToken != null);

      // Diff: only fetch IDs not already in the database
      final existingSet = existingIds.toSet();
      final missingIds = allMessageIds
          .where((id) => !existingSet.contains(id))
          .toList();

      // Fetch only the missing messages
      await _fetchAndStoreMessages(
        allMessageIds: missingIds,
        historyId: historyId,
        gmailService: gmailService,
        emailDao: emailDao,
        senderDao: senderDao,
        syncStateDao: syncStateDao,
        alreadyProcessed: existingIds.length,
        totalOverride: allMessageIds.length,
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Shared fetch logic for initial and resumed syncs.
  /// Writes senders incrementally per batch.
  Future<void> _fetchAndStoreMessages({
    required List<String> allMessageIds,
    required String? historyId,
    required GmailService gmailService,
    required EmailDao emailDao,
    required SenderDao senderDao,
    required SyncStateDao syncStateDao,
    int alreadyProcessed = 0,
    int? totalOverride,
  }) async {
    final total = totalOverride ?? allMessageIds.length;

    state = AsyncValue.data(
      SyncProgress(
        phase: SyncPhase.fetching,
        totalMessages: total,
        processedMessages: alreadyProcessed,
      ),
    );

    final senderMap = <String, _SenderAccumulator>{};
    var processed = alreadyProcessed;

    for (var i = 0; i < allMessageIds.length; i += 100) {
      final batchIds = allMessageIds.sublist(
        i,
        (i + 100).clamp(0, allMessageIds.length),
      );
      final messages = await gmailService.getMessageMetadata(batchIds);

      final batchEmailCompanions = <EmailSummaryTableCompanion>[];
      final batchSenderKeys = <String>{};

      for (final message in messages) {
        final parsed = EmailParser.parseMessage(message);
        if (parsed == null) continue;

        // Accumulate sender data
        final key = parsed.senderEmail.toLowerCase();
        final acc = senderMap.putIfAbsent(
          key,
          () => _SenderAccumulator(
            email: parsed.senderEmail,
            displayName: parsed.senderName,
            domain: parsed.domain,
          ),
        );
        acc.emailCount++;
        if (parsed.date.isAfter(acc.mostRecent)) {
          acc.mostRecent = parsed.date;
        }
        if (parsed.unsubscribeLink != null) {
          acc.unsubscribeLink = parsed.unsubscribeLink;
        }
        if (parsed.category != null) {
          acc.category = parsed.category!;
        }

        batchEmailCompanions.add(
          EmailSummaryTableCompanion.insert(
            id: parsed.messageId,
            senderEmail: key,
            subject: parsed.subject,
            date: parsed.date,
            snippet: Value(parsed.snippet),
            isRead: Value(parsed.isRead),
            unsubscribeLink: Value(parsed.unsubscribeLink),
          ),
        );
        batchSenderKeys.add(key);
      }

      // Store emails for this batch
      if (batchEmailCompanions.isNotEmpty) {
        await emailDao.insertEmails(batchEmailCompanions);
      }

      // Upsert senders touched by this batch
      if (batchSenderKeys.isNotEmpty) {
        final batchSenderCompanions = batchSenderKeys.map((key) {
          final acc = senderMap[key]!;
          return SenderTableCompanion.insert(
            email: acc.email,
            displayName: Value(acc.displayName),
            domain: acc.domain,
            emailCount: Value(acc.emailCount),
            mostRecent: acc.mostRecent,
            category: Value(acc.category),
            unsubscribeLink: Value(acc.unsubscribeLink),
          );
        }).toList();

        await senderDao.upsertSenders(batchSenderCompanions);
      }

      processed += batchIds.length;
      state = AsyncValue.data(
        SyncProgress(
          phase: SyncPhase.fetching,
          totalMessages: total,
          processedMessages: processed,
        ),
      );
    }

    // Reconcile sender email counts with actual email rows
    await senderDao.reconcileEmailCounts();

    // Save sync state — marks initial sync as complete
    await syncStateDao.updateSyncState(
      SyncStateTableCompanion.insert(
        lastSyncTime: Value(DateTime.now()),
        historyId: Value(historyId),
        totalEmails: Value(total),
        processedEmails: Value(processed),
      ),
    );

    _hasCompletedInitialSync = true;
    state = AsyncValue.data(
      SyncProgress(
        phase: SyncPhase.complete,
        totalMessages: total,
        processedMessages: processed,
      ),
    );
  }

  Future<void> _runIncrementalSync(String? startHistoryId) async {
    if (startHistoryId == null) return;
    var historyId = startHistoryId;

    try {
      final gmailService = ref.read(gmailServiceProvider);
      final senderDao = ref.read(senderDaoProvider);
      final emailDao = ref.read(emailDaoProvider);
      final syncStateDao = ref.read(syncStateDaoProvider);

      String? pageToken;
      final addedIds = <String>[];
      final deletedIds = <String>[];

      do {
        try {
          final result = await gmailService.getHistory(
            historyId,
            pageToken: pageToken,
          );
          for (final history in result.histories) {
            if (history.messagesAdded != null) {
              for (final added in history.messagesAdded!) {
                if (added.message?.id != null) {
                  addedIds.add(added.message!.id!);
                }
              }
            }
            if (history.messagesDeleted != null) {
              for (final deleted in history.messagesDeleted!) {
                if (deleted.message?.id != null) {
                  deletedIds.add(deleted.message!.id!);
                }
              }
            }
          }
          pageToken = result.nextPageToken;
          historyId = result.latestHistoryId ?? historyId;
        } catch (e) {
          // historyId expired — fallback to full sync
          _hasCompletedInitialSync = false;
          _hasStartedFetching = false;
          await syncStateDao.clearSyncState();
          await emailDao.deleteAllEmails();
          await senderDao.deleteAllSenders();
          _runInitialSync();
          return;
        }
      } while (pageToken != null);

      // Process added messages
      if (addedIds.isNotEmpty) {
        for (var i = 0; i < addedIds.length; i += 100) {
          final batchIds = addedIds.sublist(
            i,
            (i + 100).clamp(0, addedIds.length),
          );
          final messages = await gmailService.getMessageMetadata(batchIds);

          for (final message in messages) {
            final parsed = EmailParser.parseMessage(message);
            if (parsed == null) continue;

            final key = parsed.senderEmail.toLowerCase();
            await emailDao.insertEmails([
              EmailSummaryTableCompanion.insert(
                id: parsed.messageId,
                senderEmail: key,
                subject: parsed.subject,
                date: parsed.date,
                snippet: Value(parsed.snippet),
                isRead: Value(parsed.isRead),
                unsubscribeLink: Value(parsed.unsubscribeLink),
              ),
            ]);

            // Update sender
            final existing = await senderDao.getSenderByEmail(key);
            if (existing != null) {
              await senderDao.upsertSender(
                SenderTableCompanion.insert(
                  email: key,
                  displayName: Value(parsed.senderName),
                  domain: parsed.domain,
                  emailCount: Value(existing.emailCount + 1),
                  mostRecent: parsed.date.isAfter(existing.mostRecent)
                      ? parsed.date
                      : existing.mostRecent,
                  category: Value(existing.category),
                  unsubscribeLink: Value(
                    parsed.unsubscribeLink ?? existing.unsubscribeLink,
                  ),
                ),
              );
            } else {
              await senderDao.upsertSender(
                SenderTableCompanion.insert(
                  email: key,
                  displayName: Value(parsed.senderName),
                  domain: parsed.domain,
                  emailCount: const Value(1),
                  mostRecent: parsed.date,
                  category: Value(parsed.category ?? 'unknown'),
                  unsubscribeLink: Value(parsed.unsubscribeLink),
                ),
              );
            }
          }
        }
      }

      // Process deleted messages
      if (deletedIds.isNotEmpty) {
        await emailDao.deleteEmailsByIds(deletedIds);
      }

      // Reconcile sender email counts with actual email rows
      if (addedIds.isNotEmpty || deletedIds.isNotEmpty) {
        await senderDao.reconcileEmailCounts();
      }

      // Update sync state
      await syncStateDao.updateSyncState(
        SyncStateTableCompanion.insert(
          lastSyncTime: Value(DateTime.now()),
          historyId: Value(historyId),
        ),
      );
    } catch (e) {
      // Incremental sync failed silently — user can manually refresh
    }
  }

  Future<void> refresh() async {
    final syncStateDao = ref.read(syncStateDaoProvider);
    final syncState = await syncStateDao.getSyncState();
    if (syncState?.historyId != null) {
      await _runIncrementalSync(syncState!.historyId);
    } else {
      await _runInitialSync();
    }
  }
}

class _SenderAccumulator {
  final String email;
  final String? displayName;
  final String domain;
  int emailCount = 0;
  DateTime mostRecent = DateTime(2000);
  String? unsubscribeLink;
  String category = 'unknown';

  _SenderAccumulator({
    required this.email,
    this.displayName,
    required this.domain,
  });
}
