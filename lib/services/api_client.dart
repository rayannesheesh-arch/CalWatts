import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiConnectionException implements Exception {
  const ApiConnectionException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CalWattApiClient {
  CalWattApiClient._();

  static final CalWattApiClient instance = CalWattApiClient._();
  static const _apiBase = String.fromEnvironment(
    'CALWATT_API_BASE_URL',
    defaultValue: 'http://127.0.0.1:4000/api',
  );
  static const _sessionKey = 'calwatt.session_cookie';
  static const _userKey = 'calwatt.authenticated_user';

  final http.Client _client = http.Client();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  String? _csrfToken;
  String? _sessionCookie;

  Future<Map<String, dynamic>?> readSavedUser() async {
    final value = await _secureStorage.read(key: _userKey);
    if (value == null) return null;
    return Map<String, dynamic>.from(jsonDecode(value) as Map);
  }

  Future<bool> hasSession() async =>
      _sessionCookie != null ||
      await _secureStorage.read(key: _sessionKey) != null;

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    await _fetchCsrfToken();
    final response = await _send(
      'POST',
      '/auth/register',
      body: {'fullName': fullName, 'email': email, 'password': password},
    );
    _csrfToken = null;
    return _acceptUser(response['user'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    await _fetchCsrfToken();
    final response = await _send(
      'POST',
      '/auth/login',
      body: {'email': email, 'password': password},
    );
    _csrfToken = null;
    return _acceptUser(response['user'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> restoreSession() async {
    final response = await _send('GET', '/auth/me');
    final user = Map<String, dynamic>.from(response['user'] as Map);
    return _acceptUser(user);
  }

  Future<void> logout() async {
    try {
      await _fetchCsrfToken();
      await _send('POST', '/auth/logout');
    } finally {
      await clearCredentials();
    }
  }

  Future<void> clearCredentials() async {
    _csrfToken = null;
    _sessionCookie = null;
    await _secureStorage.delete(key: _sessionKey);
    await _secureStorage.delete(key: _userKey);
  }

  Future<List<Map<String, dynamic>>> getAppliances() async {
    final response = await _send('GET', '/appliances');
    return List<Map<String, dynamic>>.from(
      (response['appliances'] as List).map(
        (item) => Map<String, dynamic>.from(item as Map),
      ),
    );
  }

  Future<Map<String, dynamic>> createAppliance(
    Map<String, dynamic> appliance,
  ) async {
    final response = await _send('POST', '/appliances', body: appliance);
    return Map<String, dynamic>.from(response['appliance'] as Map);
  }

  Future<Map<String, dynamic>> updateAppliance(
    String id,
    Map<String, dynamic> appliance,
  ) async {
    final response = await _send('PUT', '/appliances/$id', body: appliance);
    return Map<String, dynamic>.from(response['appliance'] as Map);
  }

  Future<void> deleteAppliance(String id) async {
    await _send('DELETE', '/appliances/$id');
  }

  Future<Map<String, dynamic>> getDashboard() => _send('GET', '/dashboard');

  Future<List<Map<String, dynamic>>> getSimulation() async {
    final response = await _send('GET', '/simulation');
    return List<Map<String, dynamic>>.from(
      (response['days'] as List).map(
        (item) => Map<String, dynamic>.from(item as Map),
      ),
    );
  }

  Future<void> saveSimulationDay(
    int day,
    List<Map<String, dynamic>> usages,
  ) async {
    await _send('PUT', '/simulation/$day', body: {'usages': usages});
  }

  Future<void> deleteSimulationDay(int day) async {
    await _send('DELETE', '/simulation/$day');
  }

  Future<List<Map<String, dynamic>>> getConsumptionHistory() async {
    final response = await _send(
      'GET',
      '/consumption',
      query: {'page': '1', 'limit': '100'},
    );
    return List<Map<String, dynamic>>.from(
      (response['records'] as List).map(
        (item) => Map<String, dynamic>.from(item as Map),
      ),
    );
  }

  Future<Map<String, dynamic>> _acceptUser(Map<String, dynamic> user) async {
    if (user['role'] != 'user') {
      await clearCredentials();
      throw const ApiException(
        'Use the CalWatt web portal to sign in as an administrator.',
      );
    }
    final normalized = Map<String, dynamic>.from(user);
    normalized['id'] = user['id'].toString();
    await _secureStorage.write(key: _userKey, value: jsonEncode(normalized));
    return normalized;
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
  }) async {
    if (!const {'GET', 'HEAD', 'OPTIONS'}.contains(method)) {
      await _fetchCsrfToken();
    }
    final uri = Uri.parse('$_apiBase$path').replace(queryParameters: query);
    final headers = <String, String>{'Accept': 'application/json'};
    final session =
        _sessionCookie ?? await _secureStorage.read(key: _sessionKey);
    _sessionCookie = session;
    if (session != null) headers['Cookie'] = 'calwatts.sid=$session';
    if (body != null) headers['Content-Type'] = 'application/json';
    if (_csrfToken != null) headers['X-CSRF-Token'] = _csrfToken!;

    late http.Response response;
    try {
      response = await _client
          .send(
            http.Request(method, uri)
              ..headers.addAll(headers)
              ..body = body == null ? '' : jsonEncode(body),
          )
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 10));
    } on SocketException catch (error) {
      throw ApiConnectionException(error.message);
    } on http.ClientException catch (error) {
      throw ApiConnectionException(error.message);
    } on TimeoutException {
      throw const ApiConnectionException(
        'The CalWatt server did not respond in time.',
      );
    }

    final setCookies = response.headersSplitValues['set-cookie'] ?? const [];
    for (final setCookie in setCookies) {
      final cookie = RegExp(r'(?:^|;)\s*calwatts\.sid=([^;]*)')
          .firstMatch(setCookie);
      if (cookie == null) continue;
      _sessionCookie = cookie.group(1);
      if (_sessionCookie!.isEmpty) {
        await _secureStorage.delete(key: _sessionKey);
      } else {
        await _secureStorage.write(key: _sessionKey, value: _sessionCookie!);
      }
      break;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'CalWatt request failed (${response.statusCode}).';
      try {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        if (error['error'] is String) message = error['error'] as String;
      } on FormatException {
        if (response.body.isNotEmpty) message = response.body;
      }
      if (response.statusCode == 401) {
        _csrfToken = null;
        _sessionCookie = null;
        await _secureStorage.delete(key: _sessionKey);
        await _secureStorage.delete(key: _userKey);
      }
      if (response.statusCode == 403) _csrfToken = null;
      throw ApiException(message, statusCode: response.statusCode);
    }

    if (response.statusCode == 204 || response.body.isEmpty) return {};
    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }

  Future<void> _fetchCsrfToken() async {
    if (_csrfToken != null) return;
    final response = await _send('GET', '/auth/csrf');
    _csrfToken = response['csrfToken'] as String;
  }
}
