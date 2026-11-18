import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/scammer.dart';
import '../models/track_log.dart';

class AppProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  // ─── Stats ─────────────────────────────────────────────────────────────────
  Map<String, dynamic> _stats = {};
  bool _statsLoading = false;
  String? _statsError;

  Map<String, dynamic> get stats => _stats;
  bool get statsLoading => _statsLoading;
  String? get statsError => _statsError;

  Future<void> loadStats() async {
    _statsLoading = true;
    _statsError = null;
    notifyListeners();
    try {
      _stats = await _api.getStats();
    } catch (e) {
      _statsError = e.toString();
    } finally {
      _statsLoading = false;
      notifyListeners();
    }
  }

  // ─── Search ────────────────────────────────────────────────────────────────
  List<Scammer> _searchResults = [];
  bool _searchLoading = false;
  String? _searchError;
  String _lastQuery = '';

  List<Scammer> get searchResults => _searchResults;
  bool get searchLoading => _searchLoading;
  String? get searchError => _searchError;
  String get lastQuery => _lastQuery;

  Future<void> search(String query) async {
    _lastQuery = query;
    if (query.trim().isEmpty) {
      _searchResults = [];
      _searchError = null;
      notifyListeners();
      return;
    }
    _searchLoading = true;
    _searchError = null;
    notifyListeners();
    try {
      _searchResults = await _api.search(query.trim());
    } catch (e) {
      _searchError = e.toString();
      _searchResults = [];
    } finally {
      _searchLoading = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _searchResults = [];
    _searchError = null;
    _lastQuery = '';
    notifyListeners();
  }

  // ─── Trap Link Logs ────────────────────────────────────────────────────────
  List<TrackLog> _trackLogs = [];
  bool _logsLoading = false;
  String? _logsError;

  List<TrackLog> get trackLogs => _trackLogs;
  bool get logsLoading => _logsLoading;
  String? get logsError => _logsError;

  Future<void> loadLinkLogs(String linkId) async {
    _logsLoading = true;
    _logsError = null;
    notifyListeners();
    try {
      _trackLogs = await _api.getLinkLogs(linkId);
    } catch (e) {
      _logsError = e.toString();
      _trackLogs = [];
    } finally {
      _logsLoading = false;
      notifyListeners();
    }
  }

  void clearLogs() {
    _trackLogs = [];
    _logsError = null;
    notifyListeners();
  }
}
