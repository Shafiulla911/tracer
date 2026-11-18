import 'package:intl/intl.dart';

class Helpers {
  /// Format a currency amount in Indian Rupees.
  static String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  /// Format an ISO8601 date string to a human-readable form.
  static String formatDate(String? isoDate) {
    if (isoDate == null) return 'Unknown date';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
    } catch (_) {
      return isoDate;
    }
  }

  /// Relative time (e.g. "2 hours ago").
  static String timeAgo(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inDays > 365) return '${(diff.inDays / 365).floor()} year(s) ago';
      if (diff.inDays > 30) return '${(diff.inDays / 30).floor()} month(s) ago';
      if (diff.inDays > 0) return '${diff.inDays} day(s) ago';
      if (diff.inHours > 0) return '${diff.inHours} hour(s) ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes} minute(s) ago';
      return 'Just now';
    } catch (_) {
      return '';
    }
  }

  /// Validate basic phone number.
  static bool isValidPhone(String phone) {
    final clean = phone.replaceAll(RegExp(r'[\s\-\+\(\)]'), '');
    return RegExp(r'^\d{7,15}$').hasMatch(clean);
  }

  /// Validate UPI ID.
  static bool isValidUpi(String upi) {
    return RegExp(r'^[\w.\-]+@[\w]+$').hasMatch(upi);
  }

  /// Capitalize first letter.
  static String capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  /// Return a masked IP (for display).
  static String maskIp(String? ip) {
    if (ip == null) return 'Hidden';
    final parts = ip.split('.');
    if (parts.length == 4) {
      return '${parts[0]}.${parts[1]}.***.***';
    }
    return ip;
  }
}
