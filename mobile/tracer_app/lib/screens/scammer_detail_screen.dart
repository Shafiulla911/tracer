import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_constants.dart';
import '../services/api_service.dart';
import '../models/scammer.dart';
import '../models/report.dart';
import '../models/track_log.dart';
import '../utils/helpers.dart';
import '../widgets/custom_button.dart';
import '../widgets/track_log_card.dart';
import '../widgets/threat_badge.dart';
import '../widgets/glass_card.dart';
import 'trap_link_screen.dart';

class ScammerDetailScreen extends StatefulWidget {
  final Scammer scammer;

  const ScammerDetailScreen({super.key, required this.scammer});

  @override
  State<ScammerDetailScreen> createState() => _ScammerDetailScreenState();
}

class _ScammerDetailScreenState extends State<ScammerDetailScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  late TabController _tabCtrl;

  List<Report> _reports = [];
  List<TrackLog> _trackLogs = [];
  bool _loading = true;
  bool _generatingLink = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(() {
      if (mounted) setState(() {});
    });
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.getScammerDetails(widget.scammer.id);
      final reportsList =
          (data['reports'] as List? ?? []).map((e) => Report.fromJson(e)).toList();
      final logsList =
          (data['track_logs'] as List? ?? []).map((e) => TrackLog.fromJson(e)).toList();
      if (mounted) {
        setState(() {
          _reports = reportsList;
          _trackLogs = logsList;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _generateLink() async {
    setState(() => _generatingLink = true);
    try {
      final linkData = await _api.generateTrapLink(widget.scammer.id);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TrapLinkScreen(
            linkId: linkData['link_id']?.toString() ?? '',
            trapUrl: linkData['trap_url']?.toString() ?? '',
            scammerId: widget.scammer.id,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate link: $e'),
          backgroundColor: AppConstants.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _generatingLink = false);
    }
  }

  Future<void> _openPoliceDocket() async {
    final uri = Uri.parse('${AppConstants.reportsEndpoint}/${widget.scammer.id}/docket');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open police docket')),
        );
      }
    }
  }

  String get _initials {
    final name = widget.scammer.name ?? widget.scammer.phoneNumber ?? '??';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  Color get _threatColor {
    final count = widget.scammer.reportedCount;
    if (count >= 10) return AppConstants.danger;
    if (count >= 5) return const Color(0xFFF97316);
    if (count >= 2) return AppConstants.warning;
    return AppConstants.success;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.background,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppConstants.background,
            surfaceTintColor: Colors.transparent,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 12),
                child: TextButton.icon(
                  onPressed: _openPoliceDocket,
                  icon: const Icon(Icons.picture_as_pdf_rounded,
                      color: Color(0xFFF59E0B), size: 16),
                  label: const Text(
                    'POLICE DOCKET',
                    style: TextStyle(
                      color: Color(0xFFF59E0B),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                      side: BorderSide(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeroHeader(),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: _buildSegmentedTabs(),
            ),
          ),
        ],
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppConstants.accent))
            : _error != null
                ? _buildError()
                : TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _ProfileTab(
                        scammer: widget.scammer,
                        onGenerateLink: _generateLink,
                        generatingLink: _generatingLink,
                        onOpenDocket: _openPoliceDocket,
                      ),
                      _ReportsTab(reports: _reports),
                      _TrackLogsTab(logs: _trackLogs),
                    ],
                  ),
      ),
    );
  }

  Widget _buildSegmentedTabs() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppConstants.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppConstants.divider),
      ),
      child: TabBar(
        controller: _tabCtrl,
        indicator: BoxDecoration(
          gradient: AppConstants.accentGradient,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: AppConstants.accent.withValues(alpha: 0.3),
              blurRadius: 8,
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.black,
        unselectedLabelColor: AppConstants.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        tabs: const [
          Tab(text: 'PROFILE'),
          Tab(text: 'REPORTS'),
          Tab(text: 'TRACK LOGS'),
        ],
      ),
    );
  }

  Widget _buildHeroHeader() {
    final count = widget.scammer.reportedCount;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D1C30), Color(0xFF0A0F1D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 60),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      _threatColor.withValues(alpha: 0.3),
                      _threatColor.withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: _threatColor.withValues(alpha: 0.6),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _threatColor.withValues(alpha: 0.3),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _initials,
                    style: TextStyle(
                      color: _threatColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.scammer.name?.isNotEmpty == true
                          ? widget.scammer.name!
                          : 'Target #${widget.scammer.id.substring(0, widget.scammer.id.length > 8 ? 8 : widget.scammer.id.length)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.scammer.displayIdentifier,
                      style: const TextStyle(
                        color: AppConstants.textSecondary,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ThreatBadge.fromCount(count, mini: true),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppConstants.danger.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: AppConstants.danger.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            '$count ${count == 1 ? "Report" : "Reports"}',
                            style: const TextStyle(
                              color: AppConstants.danger,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppConstants.textSecondary, size: 48),
          const SizedBox(height: 12),
          Text(_error!,
              style: const TextStyle(color: AppConstants.textSecondary)),
          TextButton(
              onPressed: _load,
              child: const Text('Retry',
                  style: TextStyle(color: AppConstants.accent))),
        ],
      ),
    );
  }
}

// ─── Profile Tab ───────────────────────────────────────────────────────────
class _ProfileTab extends StatelessWidget {
  final Scammer scammer;
  final VoidCallback onGenerateLink;
  final bool generatingLink;
  final VoidCallback onOpenDocket;

  const _ProfileTab({
    required this.scammer,
    required this.onGenerateLink,
    required this.generatingLink,
    required this.onOpenDocket,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        GlassCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 3,
                    height: 14,
                    decoration: BoxDecoration(
                      gradient: AppConstants.accentGradient,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'FORENSIC IDENTITY DOSSIER',
                    style: TextStyle(
                      color: AppConstants.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (scammer.phoneNumber?.isNotEmpty == true)
                _row(Icons.phone_rounded, 'Phone Number', scammer.phoneNumber!),
              if (scammer.upiId?.isNotEmpty == true)
                _row(Icons.account_balance_wallet_rounded, 'UPI Identity', scammer.upiId!),
              if (scammer.name?.isNotEmpty == true)
                _row(Icons.badge_rounded, 'Associated Name', scammer.name!),
              _row(Icons.report_problem_rounded, 'Total Verified Reports', '${scammer.reportedCount}'),
              if (scammer.createdAt != null)
                _row(Icons.calendar_today_rounded, 'First Detected',
                    Helpers.formatDate(scammer.createdAt)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        CustomButton.danger(
          label: 'Deploy Honeypot Trap Link',
          icon: Icons.bolt_rounded,
          isLoading: generatingLink,
          onPressed: generatingLink ? null : onGenerateLink,
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onOpenDocket,
            icon: const Icon(Icons.picture_as_pdf_rounded,
                color: Color(0xFFF59E0B), size: 18),
            label: const Text(
              'EXPORT POLICE EVIDENCE DOCKET',
              style: TextStyle(
                color: Color(0xFFF59E0B),
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.6),
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.06),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Send the trap link to this suspect. When clicked, TRACER captures geolocation coordinates and ISP records in real-time.',
          style: TextStyle(color: AppConstants.textSecondary, fontSize: 11, height: 1.4),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppConstants.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: AppConstants.accent),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: AppConstants.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── Reports Tab ──────────────────────────────────────────────────────────
class _ReportsTab extends StatelessWidget {
  final List<Report> reports;
  const _ReportsTab({required this.reports});

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) {
      return const Center(
        child: Text('No detailed reports filed yet.',
            style: TextStyle(color: AppConstants.textSecondary)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      itemCount: reports.length,
      itemBuilder: (ctx, i) {
        final r = reports[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppConstants.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppConstants.divider),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppConstants.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: AppConstants.accent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      'CASE #${i + 1}',
                      style: const TextStyle(
                        color: AppConstants.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    Helpers.timeAgo(r.createdAt),
                    style: const TextStyle(
                      color: AppConstants.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              if (r.description?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                Text(
                  r.description!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  if (r.amountLost != null && r.amountLost! > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppConstants.danger.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppConstants.danger.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.currency_rupee_rounded,
                              color: AppConstants.danger, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            Helpers.formatCurrency(r.amountLost!),
                            style: const TextStyle(
                              color: AppConstants.danger,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (r.paymentMethod?.isNotEmpty == true)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppConstants.inputFill,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppConstants.divider),
                      ),
                      child: Text(
                        'Method: ${r.paymentMethod}',
                        style: const TextStyle(
                          color: AppConstants.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Track Logs Tab ──────────────────────────────────────────────────────
class _TrackLogsTab extends StatelessWidget {
  final List<TrackLog> logs;
  const _TrackLogsTab({required this.logs});

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off_rounded,
                size: 48, color: AppConstants.textSecondary.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            const Text(
              'No tracking intercepts recorded yet.',
              style: TextStyle(color: AppConstants.textSecondary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Deploy a trap link and share it to start geolocation tracking.',
              style: TextStyle(color: AppConstants.textMuted, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final hasCoords = logs.any((l) => l.latitude != null && l.longitude != null);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        if (hasCoords) ...[
          _buildMap(),
          const SizedBox(height: 18),
        ],
        ...logs
            .asMap()
            .entries
            .map((e) => TrackLogCard(log: e.value, index: e.key + 1)),
      ],
    );
  }

  Widget _buildMap() {
    final points = logs
        .where((l) => l.latitude != null && l.longitude != null)
        .map((l) => LatLng(l.latitude!, l.longitude!))
        .toList();

    final center = points.isNotEmpty ? points.first : const LatLng(20, 77);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppConstants.accent.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppConstants.accent.withValues(alpha: 0.15),
            blurRadius: 16,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: SizedBox(
          height: 220,
          child: FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: 5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.tracer.app',
              ),
              MarkerLayer(
                markers: points
                    .map(
                      (p) => Marker(
                        point: p,
                        width: 38,
                        height: 38,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppConstants.danger.withValues(alpha: 0.25),
                                border: Border.all(
                                  color: AppConstants.danger,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppConstants.danger.withValues(alpha: 0.7),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.my_location_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
