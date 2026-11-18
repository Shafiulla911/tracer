import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../constants/app_constants.dart';
import '../services/api_service.dart';
import '../models/track_log.dart';
import '../widgets/custom_button.dart';
import '../widgets/track_log_card.dart';
import '../widgets/radar_scanner.dart';

class TrapLinkScreen extends StatefulWidget {
  final String linkId;
  final String trapUrl;
  final String scammerId;
  final String templateType;

  const TrapLinkScreen({
    super.key,
    required this.linkId,
    required this.trapUrl,
    required this.scammerId,
    this.templateType = 'warning',
  });

  @override
  State<TrapLinkScreen> createState() => _TrapLinkScreenState();
}

class _TrapLinkScreenState extends State<TrapLinkScreen> {
  final ApiService _api = ApiService();
  List<TrackLog> _logs = [];
  bool _logsLoading = false;
  String? _logsError;
  bool _copied = false;
  bool _autoRefresh = true;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _fetchLogs(silent: true);
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    if (_autoRefresh) {
      _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (mounted && _autoRefresh) {
          _fetchLogs(silent: true);
        }
      });
    }
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: widget.trapUrl));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Honeypot link copied to clipboard!'),
          backgroundColor: AppConstants.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _shareLink() async {
    String msg = '⚠️ Official Notice: Check your case verification:\n${widget.trapUrl}';
    if (widget.templateType == 'payment_receipt') {
      msg = '✅ Payment confirmation receipt for ₹18,500 has been generated. View/download slip here:\n${widget.trapUrl}';
    } else if (widget.templateType == 'courier_tracking') {
      msg = '📦 Express Consignment Out for Delivery. Track your parcel status here:\n${widget.trapUrl}';
    }
    await Share.share(
      msg,
      subject: 'Verification Link',
    );
  }

  Future<void> _fetchLogs({bool silent = false}) async {
    if (!silent) {
      setState(() { _logsLoading = true; _logsError = null; });
    }
    try {
      final logs = await _api.getLinkLogs(widget.linkId);
      if (mounted) {
        setState(() {
          _logs = logs;
          _logsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (!silent) _logsError = e.toString();
          _logsLoading = false;
        });
      }
    }
  }

  String _getTemplateLabel() {
    switch (widget.templateType) {
      case 'payment_receipt':
        return '💰 Decoy: Fake UPI ₹18,500 Receipt';
      case 'courier_tracking':
        return '📦 Decoy: Courier Parcel Delivery Notice';
      default:
        return '⚠️ Decoy: Cyber Crime Warning Notice';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasHits = _logs.isNotEmpty;

    return Scaffold(
      backgroundColor: AppConstants.background,
      appBar: AppBar(
        backgroundColor: AppConstants.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: AppConstants.dangerGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'HONEYPOT RADAR',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppConstants.danger.withValues(alpha: 0.5),
                  AppConstants.divider.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppConstants.accent),
            tooltip: 'Check for hits now',
            onPressed: () => _fetchLogs(silent: false),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Radar surveillance section
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: RadarScanner(
                  size: 170,
                  hasTarget: hasHits,
                  beamColor: hasHits ? AppConstants.success : AppConstants.danger,
                  statusText: hasHits
                      ? 'TARGET INTERCEPTED: ${_logs.length} HIT(S)'
                      : 'RADAR SURVEILLANCE ACTIVE • WAITING FOR CLICK',
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Decoy template tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppConstants.inputFill,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppConstants.accent.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.masks, color: AppConstants.accent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getTemplateLabel(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Trap link card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppConstants.cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppConstants.danger.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppConstants.danger.withValues(alpha: 0.15),
                    blurRadius: 14,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.link, color: AppConstants.danger, size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        'Generated Trap URL',
                        style: TextStyle(
                          color: AppConstants.danger,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      const CyberStatusIndicator(label: 'ARMED'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppConstants.inputFill,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppConstants.divider),
                    ),
                    child: SelectableText(
                      widget.trapUrl,
                      style: const TextStyle(
                        color: AppConstants.accent,
                        fontSize: 13,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    label: _copied ? 'Copied!' : 'Copy Link',
                    icon: _copied ? Icons.check : Icons.copy,
                    gradient: _copied
                        ? const LinearGradient(
                            colors: [AppConstants.success, AppConstants.success])
                        : AppConstants.actionGradient,
                    onPressed: _copyLink,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CustomButton.danger(
                    label: 'Share Decoy',
                    icon: Icons.share,
                    onPressed: _shareLink,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Live Auto-Radar Polling Toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppConstants.cardBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppConstants.divider),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.radar,
                    color: _autoRefresh
                        ? AppConstants.success
                        : AppConstants.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Live Intercept Radar',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Auto-scans for scammer clicks every 4 seconds',
                          style: TextStyle(
                            color: AppConstants.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _autoRefresh,
                    activeThumbColor: AppConstants.success,
                    onChanged: (val) {
                      setState(() => _autoRefresh = val);
                      _startPolling();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Logs Section Header
            Row(
              children: [
                Icon(
                  Icons.my_location,
                  color: hasHits ? AppConstants.success : AppConstants.accent,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  hasHits
                      ? 'TARGET INTERCEPTIONS (${_logs.length})'
                      : 'INTERCEPT LOGS',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1.0,
                  ),
                ),
                const Spacer(),
                if (_logsLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppConstants.accent,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Logs or Empty state
            if (_logsError != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppConstants.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppConstants.danger),
                ),
                child: Text(
                  _logsError!,
                  style: const TextStyle(color: AppConstants.danger, fontSize: 13),
                ),
              )
            else if (hasHits)
              ..._logs.asMap().entries.map(
                    (e) => TrackLogCard(log: e.value, index: e.key + 1),
                  )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppConstants.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppConstants.divider),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.cell_tower,
                      size: 42,
                      color: AppConstants.textSecondary.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Honeypot is Armed & Waiting',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'When the fraudster clicks the decoy link in their browser or WhatsApp, their exact IP, browser signature, device model, and GPS coordinates will appear here instantly.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppConstants.textSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
