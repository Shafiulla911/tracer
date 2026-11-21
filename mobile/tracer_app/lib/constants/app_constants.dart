import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppConstants {
  // ─── API ───────────────────────────────────────────────────────────────────
  static String get baseUrl {
    if (kIsWeb) {
      final host = Uri.base.host;
      if (host.isNotEmpty) return 'http://$host:8000';
      return 'http://localhost:8000';
    }
    return 'http://172.16.27.199:8000';
  }

  static String get apiBase => '$baseUrl/api';
  static String get reportsEndpoint => '$apiBase/reports';
  static String get searchEndpoint => '$apiBase/search';
  static String get linksEndpoint => '$apiBase/links';
  static String get statsEndpoint => '$apiBase/stats';
  static String get analyzeEndpoint => '$apiBase/reports/analyze';
  static String get quickTrapEndpoint => '$apiBase/links/quick';
  static String get authEndpoint => '$apiBase/auth';
  static String get loginEndpoint => '$authEndpoint/login';
  static String get registerEndpoint => '$authEndpoint/register';
  static String get profileEndpoint => '$authEndpoint/me';

  // ─── App Info ──────────────────────────────────────────────────────────────
  static const String appName = 'TRACER';
  static const String tagline = 'Track. Report. Protect.';

  // ─── Sentinel Cyber-FinTech Color Palette ──────────────────────────────────
  static const Color primary     = Color(0xFF00F2FE); // Electric cyan
  static const Color secondary   = Color(0xFF111827); // Dark navy
  static const Color accent      = Color(0xFF00F2FE); // Electric cyan (primary accent)
  static const Color accentBlue  = Color(0xFF4F8EF7); // Ice blue secondary
  static const Color background  = Color(0xFF0A0F1D); // Deep obsidian
  static const Color cardBg      = Color(0xFF0D1526); // Slightly lighter obsidian
  static const Color surfaceAlt  = Color(0xFF111827); // Dark navy surface
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8B9DC3); // Blue-grey text
  static const Color textMuted   = Color(0xFF4A5568);
  static const Color success     = Color(0xFF10B981); // Neon emerald
  static const Color warning     = Color(0xFFF59E0B); // Amber
  static const Color danger      = Color(0xFFF43F5E); // Ruby rose
  static const Color divider     = Color(0xFF1E2D45); // Subtle blue-grey
  static const Color inputFill   = Color(0xFF0F1A2E); // Dark input bg
  static const Color glowCyan    = Color(0xFF00F2FE);
  static const Color glowGreen   = Color(0xFF10B981);
  static const Color glowRed     = Color(0xFFF43F5E);

  // ─── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFF43F5E), Color(0xFFBE123C)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF00F2FE), Color(0xFF4F8EF7)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient actionGradient = LinearGradient(
    colors: [Color(0xFF4F8EF7), Color(0xFF1D4ED8)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF0A0F1D), Color(0xFF111827)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF0D1526), Color(0xFF0A0F1D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient navGradient = LinearGradient(
    colors: [Color(0xFF0D1A30), Color(0xFF0A1220)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── SharedPreferences Keys ────────────────────────────────────────────────
  static const String myReportsKey = 'my_report_ids';

  // ─── Payment Methods ───────────────────────────────────────────────────────
  static const List<String> paymentMethods = [
    'UPI',
    'QR Code',
    'Bank Transfer',
    'Other',
  ];

  // ─── Threat Level Helper ───────────────────────────────────────────────────
  static String threatLevel(int scammerCount) {
    if (scammerCount >= 100) return 'CRITICAL';
    if (scammerCount >= 50)  return 'HIGH';
    if (scammerCount >= 20)  return 'ELEVATED';
    return 'LOW';
  }

  static Color threatColor(int scammerCount) {
    if (scammerCount >= 100) return danger;
    if (scammerCount >= 50)  return const Color(0xFFF97316);
    if (scammerCount >= 20)  return warning;
    return success;
  }
}
