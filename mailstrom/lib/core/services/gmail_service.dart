import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis/gmail/v1.dart';
import 'package:googleapis_auth/googleapis_auth.dart';

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

  Future<AuthClient> _getAuthClient() async {
    final client = await _ref.read(authenticatedClientProvider.future);
    if (client == null) {
      throw const GmailApiException(
        'Not authenticated',
        statusCode: 401,
      );
    }
    return client;
  }

  static const _batchUrl = 'https://www.googleapis.com/batch/gmail/v1';
  static const _metadataHeaders = ['From', 'Subject', 'Date', 'List-Unsubscribe'];

  Future<List<Message>> getMessageMetadata(List<String> ids) async {
    if (ids.isEmpty) return [];

    final client = await _getAuthClient();
    await _rateLimiter.acquire(ids.length * 5);

    return retryWithBackoff(() async {
      final boundary = 'batch_${DateTime.now().microsecondsSinceEpoch}';
      final body = _buildBatchBody(ids, boundary);

      final response = await client.post(
        Uri.parse(_batchUrl),
        headers: {'Content-Type': 'multipart/mixed; boundary=$boundary'},
        body: body,
      );

      if (response.statusCode == 429 || response.statusCode >= 500) {
        throw GmailApiException(
          'Batch request failed: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }

      if (response.statusCode != 200) {
        throw GmailApiException(
          'Batch request failed: ${response.statusCode} ${response.body}',
          statusCode: response.statusCode,
        );
      }

      final contentType = response.headers['content-type'] ?? '';
      final responseBoundary = RegExp(r'boundary=(.+)')
          .firstMatch(contentType)
          ?.group(1);

      if (responseBoundary == null) {
        throw const GmailApiException(
          'Missing boundary in batch response',
          statusCode: 500,
        );
      }

      return _parseBatchResponse(response.body, responseBoundary);
    });
  }

  String _buildBatchBody(List<String> ids, String boundary) {
    final headerParams = _metadataHeaders
        .map((h) => 'metadataHeaders=${Uri.encodeComponent(h)}')
        .join('&');

    final buffer = StringBuffer();
    for (final id in ids) {
      buffer.writeln('--$boundary');
      buffer.writeln('Content-Type: application/http');
      buffer.writeln('Content-ID: <$id>');
      buffer.writeln();
      buffer.writeln(
        'GET /gmail/v1/users/me/messages/$id?format=metadata&$headerParams',
      );
      buffer.writeln();
    }
    buffer.writeln('--$boundary--');
    return buffer.toString();
  }

  List<Message> _parseBatchResponse(String body, String boundary) {
    final parts = body.split('--$boundary');
    final results = <Message>[];
    final statusRegex = RegExp(r'HTTP/1\.1 (\d+)');

    for (final part in parts) {
      if (part.trim() == '--' || part.trim().isEmpty) continue;

      final statusMatch = statusRegex.firstMatch(part);
      if (statusMatch == null) continue;

      final status = int.parse(statusMatch.group(1)!);

      if (status == 404) continue;

      final jsonStart = part.indexOf('{');
      final jsonEnd = part.lastIndexOf('}');
      if (jsonStart == -1 || jsonEnd == -1 || jsonEnd <= jsonStart) {
        debugPrint('Batch sub-request: no JSON body (status $status)');
        continue;
      }

      if (status != 200) {
        debugPrint('Batch sub-request failed with status $status');
        continue;
      }

      try {
        final json = jsonDecode(part.substring(jsonStart, jsonEnd + 1))
            as Map<String, dynamic>;
        results.add(Message.fromJson(json));
      } catch (e) {
        debugPrint('Failed to parse batch sub-response: $e');
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
    await _batchModify(
      ids,
      addLabelIds: ['TRASH'],
      onProgress: onProgress,
      shouldCancel: shouldCancel,
    );
  }

  Future<void> archiveMessages(
    List<String> ids, {
    void Function(int completed, int total)? onProgress,
    bool Function()? shouldCancel,
  }) async {
    await _batchModify(
      ids,
      removeLabelIds: ['INBOX'],
      onProgress: onProgress,
      shouldCancel: shouldCancel,
    );
  }

  Future<void> markAsRead(
    List<String> ids, {
    void Function(int completed, int total)? onProgress,
    bool Function()? shouldCancel,
  }) async {
    await _batchModify(
      ids,
      removeLabelIds: ['UNREAD'],
      onProgress: onProgress,
      shouldCancel: shouldCancel,
    );
  }

  static const _batchChunkSize = 1000;

  Future<void> _batchModify(
    List<String> ids, {
    List<String>? addLabelIds,
    List<String>? removeLabelIds,
    void Function(int completed, int total)? onProgress,
    bool Function()? shouldCancel,
  }) async {
    final api = await _getApi();
    var processed = 0;

    for (var i = 0; i < ids.length; i += _batchChunkSize) {
      if (shouldCancel?.call() == true) break;

      final end = (i + _batchChunkSize).clamp(0, ids.length);
      final chunk = ids.sublist(i, end);

      await _rateLimiter.acquire(25);
      await retryWithBackoff(() async {
        await api.users.messages.batchModify(
          BatchModifyMessagesRequest(
            ids: chunk,
            addLabelIds: addLabelIds,
            removeLabelIds: removeLabelIds,
          ),
          'me',
        );
      });

      processed += chunk.length;
      onProgress?.call(processed, ids.length);
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
