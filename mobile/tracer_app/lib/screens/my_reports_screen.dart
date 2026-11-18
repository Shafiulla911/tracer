import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../utils/helpers.dart';
import 'trap_link_screen.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  final StorageService _storage = StorageService();
  final ApiService _api = ApiService();

  List<Map<String, dynamic>> _reports = [];
  bool _loading = true;
  Map<String, bool> _generatingLink = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final reports = await _storage.getMyReports();
    if (mounted) setState(() { _reports = reports; _loading = false; });
  }

  Future<void> _generateLink(String scammerId, int index) async {
    setState(() => _generatingLink[scammerId] = true);
    try {
      final linkData = await _api.generateTrapLink(scammerId);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TrapLinkScreen(
            linkId: linkData['link_id']?.toString() ?? '',
            trapUrl: linkData['trap_url']?.toString() ?? '',
            scammerId: scammerId,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppConstants.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _generatingLink[scammerId] = false);
    }
  }

  Future<void> _confirmClear() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.cardBg,
        title: const Text('Clear All Reports?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will remove all locally stored report records. The reports will still exist on the server.',
          style: TextStyle(color: AppConstants.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppConstants.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _storage.clearMyReports();
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.background,
      appBar: AppBar(
        backgroundColor: AppConstants.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: AppConstants.successGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.list_alt_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'MY CASES',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 17,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          if (_reports.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppConstants.textSecondary),
              tooltip: 'Clear local records',
              onPressed: _confirmClear,
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: AppConstants.textSecondary),
            onPressed: _load,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppConstants.success.withValues(alpha: 0.4),
                  AppConstants.divider.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppConstants.accent))
          : _reports.isEmpty
              ? _buildEmpty()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: _reports.length,
                  itemBuilder: (ctx, i) => _buildReportCard(_reports[i], i),
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox,
              size: 64, color: AppConstants.textSecondary.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text(
            'No reports filed yet.',
            style: TextStyle(
                color: AppConstants.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text(
            'Reports you file will appear here\nso you can track them.',
            style: TextStyle(color: AppConstants.textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report, int index) {
    final scammerId = report['scammer_id']?.toString() ?? '';
    final phone = report['phone']?.toString() ?? '';
    final upi = report['upi']?.toString() ?? '';
    final amount = report['amount']?.toString() ?? '0';
    final filedAt = report['filed_at']?.toString();
    final isGenerating = _generatingLink[scammerId] == true;

    final identifier = phone.isNotEmpty ? phone : upi;
    final amountNum = double.tryParse(amount) ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppConstants.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.divider),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppConstants.danger.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12)),
              border: Border(
                  bottom: BorderSide(color: AppConstants.divider, width: 1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.report, color: AppConstants.danger, size: 16),
                const SizedBox(width: 8),
                Text(
                  identifier.isNotEmpty ? identifier : 'Report #${index + 1}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14),
                ),
                const Spacer(),
                Text(
                  Helpers.timeAgo(filedAt),
                  style: const TextStyle(
                      color: AppConstants.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (phone.isNotEmpty)
                  _infoRow(Icons.phone, 'Phone', phone),
                if (upi.isNotEmpty)
                  _infoRow(Icons.account_balance_wallet, 'UPI', upi),
                if (amountNum > 0)
                  _infoRow(Icons.currency_rupee, 'Amount Lost',
                      Helpers.formatCurrency(amountNum)),
                if (filedAt != null)
                  _infoRow(Icons.calendar_today, 'Filed',
                      Helpers.formatDate(filedAt)),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppConstants.accent,
                      side: const BorderSide(color: AppConstants.accent),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: isGenerating
                        ? null
                        : () => _generateLink(scammerId, index),
                    icon: isGenerating
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppConstants.accent))
                        : const Icon(Icons.link, size: 16),
                    label: Text(
                        isGenerating ? 'Generating...' : 'Generate Trap Link'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppConstants.accent),
          const SizedBox(width: 8),
          Text('$label: ',
              style: const TextStyle(
                  color: AppConstants.textSecondary, fontSize: 12)),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
