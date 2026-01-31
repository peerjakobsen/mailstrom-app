import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis/gmail/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../exceptions/auth_exception.dart';
import 'token_storage.dart';

const _scopes = [GmailApi.gmailReadonlyScope, GmailApi.gmailModifyScope];
const _tokenKey = 'oauth_credentials';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

class AuthService {
  final _storage = TokenStorage();

  ClientId? _cachedClientId;

  Future<ClientId> _loadClientId() async {
    if (_cachedClientId != null) return _cachedClientId!;
    try {
      final jsonString = await rootBundle.loadString(
        'assets/google_oauth_credentials.json',
      );
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final installed = json['installed'] as Map<String, dynamic>;
      final clientId = installed['client_id'] as String;
      final clientSecret = installed['client_secret'] as String?;
      _cachedClientId = ClientId(
        clientId,
        (clientSecret != null && clientSecret.isNotEmpty)
            ? clientSecret
            : null,
      );
      return _cachedClientId!;
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(
        'Could not load OAuth credentials. '
        'Ensure assets/google_oauth_credentials.json exists.',
        cause: e,
      );
    }
  }

  Future<AuthClient> signIn() async {
    try {
      final clientId = await _loadClientId();

      // Start a local HTTP server to handle the OAuth redirect
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final port = server.port;
      final redirectUri = 'http://localhost:$port';

      // Build the authorization URL
      final authUrl = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
        'client_id': clientId.identifier,
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'scope': _scopes.join(' '),
        'access_type': 'offline',
        'prompt': 'consent',
      });

      // Open browser for user consent
      if (await canLaunchUrl(authUrl)) {
        await launchUrl(authUrl);
      } else {
        await server.close();
        throw const AuthException('Could not open browser for sign-in');
      }

      // Wait for the redirect with the auth code
      String? code;
      try {
        final request = await server.first;
        code = request.uri.queryParameters['code'];
        final error = request.uri.queryParameters['error'];

        if (error != null) {
          request.response
            ..statusCode = 200
            ..headers.contentType = ContentType.html
            ..write('<html><body><h2>Authorization denied.</h2>'
                '<p>You can close this window.</p></body></html>');
          await request.response.close();
          await server.close();
          throw AuthException('Authorization denied: $error');
        }

        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType.html
          ..write('<html><body><h2>Signed in to Mailstrom!</h2>'
              '<p>You can close this window and return to the app.</p>'
              '</body></html>');
        await request.response.close();
      } finally {
        await server.close();
      }

      if (code == null) {
        throw const AuthException('No authorization code received');
      }

      // Exchange the auth code for tokens
      final tokenResponse = await http.post(
        Uri.https('oauth2.googleapis.com', '/token'),
        body: {
          'code': code,
          'client_id': clientId.identifier,
          'client_secret': clientId.secret ?? '',
          'redirect_uri': redirectUri,
          'grant_type': 'authorization_code',
        },
      );

      if (tokenResponse.statusCode != 200) {
        throw AuthException(
          'Token exchange failed: ${tokenResponse.body}',
        );
      }

      final tokenData =
          jsonDecode(tokenResponse.body) as Map<String, dynamic>;
      final accessToken = AccessToken(
        'Bearer',
        tokenData['access_token'] as String,
        DateTime.now().toUtc().add(
              Duration(seconds: tokenData['expires_in'] as int),
            ),
      );
      final refreshToken = tokenData['refresh_token'] as String?;

      final credentials = AccessCredentials(
        accessToken,
        refreshToken,
        _scopes,
      );

      await _saveCredentials(credentials);
      return authenticatedClient(http.Client(), credentials);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Sign in failed: $e', cause: e);
    }
  }

  Future<AuthClient?> restoreSession() async {
    try {
      final json = await _storage.read(_tokenKey);
      if (json == null) return null;

      final credentials = AccessCredentials.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );

      if (credentials.accessToken.hasExpired) {
        if (credentials.refreshToken == null) {
          await _storage.delete(_tokenKey);
          return null;
        }
        final clientId = await _loadClientId();
        final client = http.Client();
        try {
          final newCredentials = await refreshCredentials(
            clientId,
            credentials,
            client,
          );
          await _saveCredentials(newCredentials);
          return authenticatedClient(client, newCredentials);
        } catch (e) {
          client.close();
          await _storage.delete(_tokenKey);
          return null;
        }
      }

      return authenticatedClient(http.Client(), credentials);
    } catch (e) {
      return null;
    }
  }

  Future<String> getUserEmail(AuthClient client) async {
    final gmail = GmailApi(client);
    final profile = await gmail.users.getProfile('me');
    return profile.emailAddress ?? 'unknown';
  }

  Future<void> signOut() async {
    await _storage.delete(_tokenKey);
  }

  Future<void> _saveCredentials(AccessCredentials credentials) async {
    await _storage.write(
      _tokenKey,
      jsonEncode(credentials.toJson()),
    );
  }
}
