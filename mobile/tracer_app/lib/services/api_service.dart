import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../models/scammer.dart';
import '../models/track_log.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ─── Stats ─────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getStats() async {
    final res = await http
        .get(Uri.parse(AppConstants.statsEndpoint), headers: _headers)
        .timeout(const Duration(seconds: 10));
    _checkStatus(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ─── Report Scammer ────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> submitReport({
    required String phoneNumber,
    required String upiId,
    required String name,
    required String description,
    required String victimName,
    required double amountLost,
    required String paymentMethod,
    String? utrNumber,
    String? scamCategory,
    String? riskLevel,
  }) async {
    final cleanPhone = phoneNumber.trim();
    final cleanUpi = upiId.trim();
    final body = jsonEncode({
      'phone_number': cleanPhone.isNotEmpty ? cleanPhone : null,
      'upi_id': cleanUpi.isNotEmpty ? cleanUpi : null,
      'name': name.trim().isNotEmpty ? name.trim() : null,
      'description': description,
      'victim_name': victimName,
      'amount_lost': amountLost,
      'payment_method': paymentMethod,
      if (utrNumber != null && utrNumber.isNotEmpty) 'utr_number': utrNumber,
      if (scamCategory != null) 'scam_category': scamCategory,
      if (riskLevel != null) 'risk_level': riskLevel,
    });
    final res = await http
        .post(Uri.parse(AppConstants.reportsEndpoint),
            headers: _headers, body: body)
        .timeout(const Duration(seconds: 10));
    _checkStatus(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ─── Search ────────────────────────────────────────────────────────────────
  Future<List<Scammer>> search(String query) async {
    final uri = Uri.parse(AppConstants.searchEndpoint)
        .replace(queryParameters: {'q': query});
    final res = await http
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 10));
    _checkStatus(res);
    final data = jsonDecode(res.body);
    final list = data is List ? data : ((data as Map<String, dynamic>)['results'] ?? []) as List;
    return list.map((e) => Scammer.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ─── Scammer Details ───────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getScammerDetails(String scammerId) async {
    final res = await http
        .get(Uri.parse('${AppConstants.reportsEndpoint}/$scammerId'),
            headers: _headers)
        .timeout(const Duration(seconds: 10));
    _checkStatus(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ─── Trap Link ─────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> generateTrapLink(String scammerId, {String templateType = 'warning'}) async {
    final numericId = int.tryParse(scammerId);
    final body = jsonEncode({
      'scammer_id': numericId ?? scammerId,
      'template_type': templateType,
    });
    final res = await http
        .post(Uri.parse('${AppConstants.linksEndpoint}/generate'),
            headers: _headers, body: body)
        .timeout(const Duration(seconds: 10));
    _checkStatus(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ─── Quick Trap Link (1-Click) ──────────────────────────────────────────────
  Future<Map<String, dynamic>> generateQuickTrap({
    String? phoneNumber,
    String? upiId,
    String? name,
    String templateType = 'payment_receipt',
  }) async {
    final body = jsonEncode({
      'phone_number': phoneNumber,
      'upi_id': upiId,
      'name': name,
      'template_type': templateType,
    });
    final res = await http
        .post(Uri.parse(AppConstants.quickTrapEndpoint),
            headers: _headers, body: body)
        .timeout(const Duration(seconds: 10));
    _checkStatus(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ─── AI Scam Analyzer ───────────────────────────────────────────────────────
  Future<Map<String, dynamic>> analyzeScamText(String text) async {
    final body = jsonEncode({'text': text});
    final res = await http
        .post(Uri.parse(AppConstants.analyzeEndpoint),
            headers: _headers, body: body)
        .timeout(const Duration(seconds: 10));
    _checkStatus(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<List<TrackLog>> getLinkLogs(String linkId) async {
    final res = await http
        .get(Uri.parse('${AppConstants.linksEndpoint}/$linkId/logs'),
            headers: _headers)
        .timeout(const Duration(seconds: 10));
    _checkStatus(res);
    final data = jsonDecode(res.body);
    final list = data is List ? data : ((data as Map<String, dynamic>)['logs'] ?? []) as List;
    return list.map((e) => TrackLog.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ─── Helper ────────────────────────────────────────────────────────────────
  void _checkStatus(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      String msg = 'Request failed (${res.statusCode})';
      try {
        final body = jsonDecode(res.body);
        msg = body['detail'] ?? body['message'] ?? msg;
      } catch (_) {}
      throw ApiException(msg, res.statusCode);
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}
