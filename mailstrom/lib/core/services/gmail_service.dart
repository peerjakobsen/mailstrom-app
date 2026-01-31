import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis/gmail/v1.dart';

import '../exceptions/gmail_api_exception.dart';
import '../utils/rate_limiter.dart';
import '../utils/retry.dart';
import '../../features/auth/providers/auth_provider.dart';

final gmailServiceProvider = Provider<GmailService>((ref) {
  return GmailService(ref);
});

class MessageListResult {
  final List<String> ids;
  final String? nextPageToken;

  const MessageListResult({required this.ids, this.nextPageToken});
}

class HistoryResult {
  final List<History> histories;
  final String? nextPageToken;
  final String? latestHistoryId;

  const HistoryResult({
    required this.histories,
    this.nextPageToken,
    this.latestHistoryId,
  });
}

class GmailService {
  final Ref _ref;
  final RateLimiter _rateLimiter = RateLimiter(unitsPerSecond: 250);

  GmailService(this._ref);

  Future<GmailApi> _getApi() async {
    final client = await _ref.read(authenticatedClientProvider.future);
    if (client == null) {
      throw const GmailApiException(
        'Not authenticated',
        statusCode: 401,
      );
    }
    return GmailApi(client);
  }

  Future<MessageListResult> listMessageIds({
    String? pageToken,
    int maxResults = 500,
    String? query,
  }) async {
    return retryWithBackoff(() async {
      await _rateLimiter.acquire(5);
      final api = await _getApi();
      final response = await api.users.messages.list(
        'me',
        pageToken: pageToken,
        maxResults: maxResults,
        q: query,
      );
      final ids = response.messages
              ?.map((m) => m.id)
              .whereType<String>()
              .toList() ??
          [];
      return MessageListResult(
        ids: ids,
        nextPageToken: response.nextPageToken,
      );
    });
  }

  Future<List<Message>> getMessageMetadata(List<String> ids) async {
    final api = await _getApi();
    final results = <Message>[];

    for (final id in ids) {
      await _rateLimiter.acquire(5);
      try {
        final message = await retryWithBackoff(() async {
          return api.users.messages.get(
            'me',
            id,
            format: 'metadata',
            metadataHeaders: ['From', 'Subject', 'Date', 'List-Unsubscribe'],
          );
        });
        results.add(message);
      } on GmailApiException catch (e) {
        if (e.isNotFound) continue;
        rethrow;
      } catch (_) {
        continue;
      }
    }

    return results;
  }

  Future<Message> getFullMessage(String id) async {
    return retryWithBackoff(() async {
      await _rateLimiter.acquire(5);
      final api = await _getApi();
      return api.users.messages.get('me', id, format: 'full');
    });
  }

  Future<void> trashMessages(
    List<String> ids, {
    void Function(int completed, int total)? onProgress,
    bool Function()? shouldCancel,
  }) async {
    final api = await _getApi();
    for (var i = 0; i < ids.length; i++) {
      if (shouldCancel?.call() == true) break;
      await _rateLimiter.acquire(5);
      await retryWithBackoff(() async {
        await api.users.messages.trash('me', ids[i]);
      });
      onProgress?.call(i + 1, ids.length);
    }
  }

  Future<void> archiveMessages(
    List<String> ids, {
    void Function(int completed, int total)? onProgress,
  }) async {
    final api = await _getApi();
    for (var i = 0; i < ids.length; i++) {
      await _rateLimiter.acquire(5);
      await retryWithBackoff(() async {
        await api.users.messages.modify(
          ModifyMessageRequest(removeLabelIds: ['INBOX']),
          'me',
          ids[i],
        );
      });
      onProgress?.call(i + 1, ids.length);
    }
  }

  Future<void> markAsRead(
    List<String> ids, {
    void Function(int completed, int total)? onProgress,
  }) async {
    final api = await _getApi();
    for (var i = 0; i < ids.length; i++) {
      await _rateLimiter.acquire(5);
      await retryWithBackoff(() async {
        await api.users.messages.modify(
          ModifyMessageRequest(removeLabelIds: ['UNREAD']),
          'me',
          ids[i],
        );
      });
      onProgress?.call(i + 1, ids.length);
    }
  }

  Future<HistoryResult> getHistory(
    String startHistoryId, {
    String? pageToken,
  }) async {
    return retryWithBackoff(() async {
      await _rateLimiter.acquire(5);
      final api = await _getApi();
      final response = await api.users.history.list(
        'me',
        startHistoryId: startHistoryId,
        pageToken: pageToken,
        historyTypes: ['messageAdded', 'messageDeleted'],
      );
      return HistoryResult(
        histories: response.history ?? [],
        nextPageToken: response.nextPageToken,
        latestHistoryId: response.historyId,
      );
    });
  }

  Future<Profile> getUserProfile() async {
    return retryWithBackoff(() async {
      await _rateLimiter.acquire(5);
      final api = await _getApi();
      return api.users.getProfile('me');
    });
  }
}
