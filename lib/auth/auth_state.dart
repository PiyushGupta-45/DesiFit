import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

/// Keeps URL building correct whether the configured Render URL ends in `/`
/// or not. Render can take a few seconds to wake a sleeping instance.
String get _apiOrigin =>
    (dotenv.env['API_ORIGIN']?.trim() ?? '').replaceFirst(RegExp(r'/+$'), '');
String get _googleWebClientId => dotenv.env['GOOGLE_WEB_CLIENT_ID']?.trim() ?? '';

class AuthState extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  late final _google = GoogleSignIn(
    scopes: const ['email'],
    serverClientId: _googleWebClientId.isEmpty ? null : _googleWebClientId,
  );

  bool initialized = false;
  bool backendOnline = false;
  bool busy = false;
  String? error;
  String? token;
  String? name;
  String? email;
  bool hasPassword = false;

  bool get signedIn => token != null;
  String get apiOrigin => _apiOrigin;

  Future<void> initialize() async {
    // Do not make first app paint wait for a Render cold start. The status
    // refresh notifies the login UI as soon as the service becomes reachable.
    _refreshBackendStatus();
    final savedToken = await _storage.read(key: 'jwt_token');
    if (savedToken != null) {
      token = savedToken;
      try {
        final response = await _request('GET', '/api/v1/auth/me');
        if (response.statusCode == 200) _applyUser(_json(response)['user']);
        else await _clearSession();
      } catch (_) {
        // Keep the token for offline app use; sign-in can be verified later.
      }
    }
    initialized = true;
    notifyListeners();
  }

  Future<void> _refreshBackendStatus() async {
    await _checkBackend();
    notifyListeners();
    if (backendOnline) return;

    // Free/idle Render services sometimes need more than one connection
    // attempt before their public endpoint is ready.
    await Future<void>.delayed(const Duration(seconds: 5));
    await _checkBackend();
    notifyListeners();
  }

  Future<void> register({required String name, required String email, required String password}) =>
      _authenticate('/api/v1/auth/register', {'name': name, 'email': email, 'password': password});

  Future<void> login({required String email, required String password}) =>
      _authenticate('/api/v1/auth/login', {'email': email, 'password': password});

  Future<void> signInWithGoogle() async {
    if (_googleWebClientId.isEmpty) {
      error = 'Google Web Client ID is not configured yet.';
      notifyListeners();
      return;
    }
    await _run(() async {
      final account = await _google.signIn();
      if (account == null) return;
      final idToken = (await account.authentication).idToken;
      if (idToken == null) throw Exception('Google did not return an ID token.');
      final response = await _request('POST', '/api/v1/auth/google', body: {'idToken': idToken});
      await _readSession(response);
    });
  }

  Future<void> logout() async {
    await _google.signOut();
    await _clearSession();
    notifyListeners();
  }

  Future<void> updateName(String value) => _run(() async {
        final response = await _put('/api/v1/auth/profile', {'name': value.trim()});
        final body = _json(response);
        if (response.statusCode != 200) throw Exception(body['error'] ?? 'Could not update profile.');
        _applyUser(body['user']);
      });

  Future<void> savePassword({required String newPassword, String currentPassword = ''}) =>
      _run(() async {
        final response = await _request('POST', '/api/v1/auth/password', body: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        });
        final body = _json(response);
        if (response.statusCode != 200) throw Exception(body['error'] ?? 'Could not save password.');
        _applyUser(body['user']);
      });

  Future<Map<String, dynamic>?> downloadCloudData() async {
    if (!signedIn || !backendOnline) return null;
    try {
      final response = await _request('GET', '/api/v1/data');
      final body = _json(response);
      if (response.statusCode == 200 && body['data'] is Map) {
        return Map<String, dynamic>.from(body['data'] as Map);
      }
    } catch (_) {}
    return null;
  }

  /// Public global food catalogue. It is deliberately independent from a
  /// user's data document, so catalogue updates reach every signed-in app.
  Future<List<Map<String, dynamic>>?> downloadFoodCatalog({
    bool refreshConnection = false,
  }) async {
    // A manual catalogue refresh should not be blocked by an old offline
    // status left over from a Render cold start.
    if (refreshConnection) {
      await _checkBackend();
      notifyListeners();
    }
    if (!backendOnline || _apiOrigin.isEmpty) return null;
    try {
      final response = await http
          .get(Uri.parse('$_apiOrigin/api/v1/foods'))
          .timeout(const Duration(seconds: 15));
      final body = _json(response);
      if (response.statusCode != 200 || body['foods'] is! List) return null;
      return (body['foods'] as List)
          .whereType<Map>()
          .map((food) => Map<String, dynamic>.from(food))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<bool> uploadCloudData(Map<String, dynamic> snapshot) async {
    if (!signedIn || !backendOnline) return false;
    try {
      final response = await _put('/api/v1/data', snapshot);
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  Future<void> _authenticate(String path, Map<String, String> body) => _run(() async {
        final response = await _request('POST', path, body: body);
        await _readSession(response);
      });

  Future<void> _run(Future<void> Function() action) async {
    busy = true;
    error = null;
    await _checkBackend();
    notifyListeners();
    try {
      await action();
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> _readSession(http.Response response) async {
    final body = _json(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(body['error'] ?? 'Sign-in failed.');
    }
    token = body['token'] as String?;
    if (token == null) throw Exception('Server did not return a token.');
    _applyUser(body['user']);
    await _storage.write(key: 'jwt_token', value: token);
  }

  void _applyUser(dynamic user) {
    if (user is! Map) return;
    name = user['name']?.toString();
    email = user['email']?.toString();
    hasPassword = user['hasPassword'] == true;
  }

  Future<void> _clearSession() async {
    token = null;
    name = null;
    email = null;
    hasPassword = false;
    await _storage.delete(key: 'jwt_token');
  }

  Future<void> _checkBackend() async {
    if (_apiOrigin.isEmpty) {
      backendOnline = false;
      return;
    }
    try {
      final response = await http
          .get(Uri.parse('$_apiOrigin/health'))
          // Render may need a few seconds to wake after an idle period.
          .timeout(const Duration(seconds: 12));
      backendOnline = response.statusCode == 200;
    } catch (_) {
      backendOnline = false;
    }
  }

  Future<http.Response> _request(String method, String path, {Map<String, dynamic>? body}) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    final url = Uri.parse('$_apiOrigin$path');
    return switch (method) {
      'GET' => http.get(url, headers: headers).timeout(const Duration(seconds: 12)),
      'POST' => http.post(url, headers: headers, body: jsonEncode(body)).timeout(const Duration(seconds: 12)),
      _ => throw UnsupportedError(method),
    };
  }

  Future<http.Response> _put(String path, Map<String, dynamic> body) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return http
        .put(Uri.parse('$_apiOrigin$path'), headers: headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 15));
  }

  Map<String, dynamic> _json(http.Response response) {
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return {'error': 'Invalid response from backend.'};
    }
  }
}
