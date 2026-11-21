import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../models/user.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String _tokenKey = 'tracer_auth_token';
  static const String _userKey = 'tracer_user_data';
  static const String _biometricKey = 'tracer_biometric_enabled';
  static const String _notificationsKey = 'tracer_notifications_enabled';
  static const String _autoRadarKey = 'tracer_auto_radar_sync';

  String? _token;
  User? _currentUser;
  bool _initialized = false;
  bool _biometricEnabled = true;
  bool _notificationsEnabled = true;
  bool _autoRadarSync = true;

  String? get token => _token;
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  bool get isInitialized => _initialized;
  bool get biometricEnabled => _biometricEnabled;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get autoRadarSync => _autoRadarSync;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<void> init() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(_tokenKey);
      final userJson = prefs.getString(_userKey);
      if (userJson != null) {
        _currentUser = User.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      }
      _biometricEnabled = prefs.getBool(_biometricKey) ?? true;
      _notificationsEnabled = prefs.getBool(_notificationsKey) ?? true;
      _autoRadarSync = prefs.getBool(_autoRadarKey) ?? true;

      // If token exists, refresh profile in background
      if (_token != null) {
        fetchProfile().ignore();
      }
    } catch (e) {
      debugPrint('AuthService init error: $e');
    } finally {
      _initialized = true;
      notifyListeners();
    }
  }

  Future<User> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async {
    final body = jsonEncode({
      'full_name': fullName.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
    });

    try {
      final res = await http
          .post(Uri.parse(AppConstants.registerEndpoint),
              headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
              body: body)
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final token = data['token']?.toString() ?? '';
        final user = User.fromJson(data['user'] as Map<String, dynamic>);
        await _saveSession(token, user);
        return user;
      } else {
        final err = jsonDecode(res.body);
        throw err['detail'] ?? 'Registration failed with status ${res.statusCode}';
      }
    } catch (e) {
      // Offline fallback: covers all network errors (SocketException, ClientException on web, TimeoutException, etc.)
      final err = e.toString();
      if (e is! String && (
        err.contains('Failed host lookup') ||
        err.contains('Connection refused') ||
        err.contains('SocketException') ||
        err.contains('TimeoutException') ||
        err.contains('ClientException') ||
        err.contains('Failed to fetch') ||
        err.contains('NetworkException') ||
        err.contains('XMLHttpRequest')
      )) {
        final offlineUser = User(
          id: DateTime.now().millisecondsSinceEpoch % 10000,
          fullName: fullName.trim(),
          email: email.trim().toLowerCase(),
          phone: phone,
          badge: 'Field Investigator • Level 1',
          role: 'Agent (Offline)',
          createdAt: DateTime.now(),
        );
        final offlineToken = 'offline_token_${DateTime.now().millisecondsSinceEpoch}';
        await _saveSession(offlineToken, offlineUser);
        return offlineUser;
      }
      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    // Clear local session regardless of backend reachability
    _token = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    // If token existed, try to delete on server (best-effort)
    if (_token != null) {
      try {
        await http
            .delete(Uri.parse('${AppConstants.authEndpoint}/me'),
                headers: _headers)
            .timeout(const Duration(seconds: 5));
      } catch (_) {
        // Silently ignore — local session already cleared
      }
    }
    notifyListeners();
  }

  Future<User> login({
    required String email,
    required String password,
  }) async {
    final body = jsonEncode({
      'email': email.trim().toLowerCase(),
      'password': password,
    });

    try {
      final res = await http
          .post(Uri.parse(AppConstants.loginEndpoint),
              headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
              body: body)
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final token = data['token']?.toString() ?? '';
        final user = User.fromJson(data['user'] as Map<String, dynamic>);
        await _saveSession(token, user);
        return user;
      } else {
        final err = jsonDecode(res.body);
        throw err['detail'] ?? 'Invalid credentials';
      }
    } catch (e) {
      // Offline fallback: covers all network errors (SocketException, ClientException on web, TimeoutException, etc.)
      final err = e.toString();
      if (e is! String && (
        err.contains('Failed host lookup') ||
        err.contains('Connection refused') ||
        err.contains('SocketException') ||
        err.contains('TimeoutException') ||
        err.contains('ClientException') ||
        err.contains('Failed to fetch') ||
        err.contains('NetworkException') ||
        err.contains('XMLHttpRequest')
      )) {
        if (_currentUser != null && _currentUser!.email.toLowerCase() == email.trim().toLowerCase()) {
          return _currentUser!;
        }
        final offlineUser = User(
          id: 101,
          fullName: email.split('@').first.toUpperCase(),
          email: email.trim().toLowerCase(),
          badge: 'Field Investigator • Level 1',
          role: 'Agent',
          createdAt: DateTime.now(),
        );
        final offlineToken = 'offline_token_${DateTime.now().millisecondsSinceEpoch}';
        await _saveSession(offlineToken, offlineUser);
        return offlineUser;
      }
      rethrow;
    }
  }

  Future<void> loginAsGuest() async {
    final guestUser = User(
      id: 999,
      fullName: 'Special Agent Guest',
      email: 'guest.agent@tracer.sentinel',
      phone: '+91 90000 00000',
      badge: 'Guest Investigator • Provisional',
      role: 'Guest Analyst',
      createdAt: DateTime.now(),
    );
    await _saveSession('guest_session_token', guestUser);
  }

  Future<User?> fetchProfile() async {
    if (_token == null) return null;
    try {
      final res = await http
          .get(Uri.parse(AppConstants.profileEndpoint), headers: _headers)
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final updatedUser = User.fromJson(data);
        _currentUser = updatedUser;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userKey, jsonEncode(updatedUser.toJson()));
        notifyListeners();
        return updatedUser;
      }
    } catch (e) {
      debugPrint('Profile refresh warning: $e');
    }
    return _currentUser;
  }

  Future<User?> updateProfile({String? fullName, String? phone, String? badge}) async {
    if (_token == null) return null;
    final body = jsonEncode({
      if (fullName != null) 'full_name': fullName.trim(),
      if (phone != null) 'phone': phone.trim(),
      if (badge != null) 'badge': badge.trim(),
    });

    try {
      final res = await http
          .put(Uri.parse('${AppConstants.authEndpoint}/profile'),
              headers: _headers, body: body)
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final updatedUser = User.fromJson(data);
        _currentUser = updatedUser;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userKey, jsonEncode(updatedUser.toJson()));
        notifyListeners();
        return updatedUser;
      }
    } catch (e) {
      // Local update fallback
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(
          fullName: fullName,
          phone: phone,
          badge: badge,
        );
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));
        notifyListeners();
        return _currentUser;
      }
    }
    return _currentUser;
  }

  Future<void> toggleBiometric(bool val) async {
    _biometricEnabled = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricKey, val);
    notifyListeners();
  }

  Future<void> toggleNotifications(bool val) async {
    _notificationsEnabled = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, val);
    notifyListeners();
  }

  Future<void> toggleAutoRadar(bool val) async {
    _autoRadarSync = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoRadarKey, val);
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    notifyListeners();
  }

  Future<void> _saveSession(String token, User user) async {
    _token = token;
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    notifyListeners();
  }
}
