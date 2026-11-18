import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  // ─── My Reports (local list of report IDs with metadata) ──────────────────
  Future<List<Map<String, dynamic>>> getMyReports() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(AppConstants.myReportsKey) ?? [];
    return raw
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList()
        .reversed
        .toList();
  }

  Future<void> addMyReport(Map<String, dynamic> reportMeta) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(AppConstants.myReportsKey) ?? [];
    raw.add(jsonEncode(reportMeta));
    await prefs.setStringList(AppConstants.myReportsKey, raw);
  }

  Future<bool> hasReport(String reportId) async {
    final reports = await getMyReports();
    return reports.any((r) => r['report_id'] == reportId);
  }

  Future<void> clearMyReports() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.myReportsKey);
  }
}
