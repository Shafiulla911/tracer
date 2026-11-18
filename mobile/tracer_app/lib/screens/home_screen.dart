import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../services/api_service.dart';
import '../widgets/stat_card.dart';
import '../widgets/scammer_card.dart';
import '../widgets/pulsing_banner.dart';
import '../widgets/floating_nav_bar.dart';
import '../widgets/glass_card.dart';
import '../models/scammer.dart';
import 'report_screen.dart';
import 'search_screen.dart';
import 'my_reports_screen.dart';
import 'scammer_detail_screen.dart';
import 'trap_link_screen.dart';

// ─── CyberStatusIndicator (shared widget used here) ────────────────────────
class CyberStatusIndicator extends StatefulWidget {
  final String label;
  const CyberStatusIndicator({super.key, required this.label});

  @override
  State<CyberStatusIndicator> createState() => _CyberStatusIndicatorState();
}

class _CyberStatusIndicatorState extends State<CyberStatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppConstants.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: AppConstants.success.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppConstants.success
                    .withValues(alpha: _pulse.value),
                boxShadow: [
                  BoxShadow(
                    color: AppConstants.success.withValues(alpha: 0.5),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 5),
            Text(
              widget.label,
              style: const TextStyle(
                color: AppConstants.success,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Main HomeScreen Shell ─────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    _HomePage(),
    SearchScreen(),
    ReportScreen(),
    MyReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.background,
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: FloatingNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ─── Home Tab ───────────────────────────────────────────────────────────────
class _HomePage extends StatefulWidget {
  const _HomePage();

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _stats;
  List<Scammer> _recent = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final stats = await _api.getStats();
      final recent = await _api.search('');
      if (mounted) {
        setState(() {
          _stats = stats;
          _recent = recent.take(5).toList();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.background,
      body: CustomScrollView(
        slivers: [
          _buildHeroHeader(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              child: _loading
                  ? _buildLoading()
                  : _error != null
                      ? _buildError()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStats(),
                            const SizedBox(height: 20),
                            _buildActionButtons(context),
                            const SizedBox(height: 28),
                            _buildRecentSection(context),
                          ],
                        ),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildHeroHeader() {
    final scammerCount = _stats?['total_scammers'] as int? ?? 0;
    final threat = AppConstants.threatLevel(scammerCount);
    final threatClr = AppConstants.threatColor(scammerCount);

    return SliverAppBar(
      expandedHeight: 130,
      floating: false,
      pinned: true,
      backgroundColor: AppConstants.background,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0D1A2E), Color(0xFF0A0F1D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Subtle grid pattern overlay
              Positioned.fill(
                child: Opacity(
                  opacity: 0.04,
                  child: CustomPaint(painter: _GridPainter()),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 55, 20, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        // Logo
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            gradient: AppConstants.accentGradient,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: AppConstants.accent.withValues(alpha: 0.4),
                                blurRadius: 14,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.security_rounded,
                              color: Colors.black, size: 20),
                        ),
                        const SizedBox(width: 10),
                        ShaderMask(
                          shaderCallback: (bounds) =>
                              AppConstants.accentGradient.createShader(bounds),
                          child: const Text(
                            'TRACER',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const CyberStatusIndicator(label: 'GRID LIVE'),
                        const Spacer(),
                        // Threat level badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: threatClr.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: threatClr.withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.shield_moon_rounded,
                                  color: threatClr, size: 11),
                              const SizedBox(width: 5),
                              Text(
                                threat,
                                style: TextStyle(
                                  color: threatClr,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _load,
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppConstants.divider,
                                width: 1,
                              ),
                            ),
                            child: const Icon(Icons.refresh_rounded,
                                color: AppConstants.textSecondary, size: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Cyber Threat Intelligence Platform',
                      style: TextStyle(
                        color: AppConstants.textSecondary,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
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

  Widget _buildLoading() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(60),
        child: Column(
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                color: AppConstants.accent,
                strokeWidth: 2,
              ),
            ),
            SizedBox(height: 14),
            Text(
              'Loading intelligence...',
              style: TextStyle(
                color: AppConstants.textSecondary,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return GlassCard(
      glowColor: AppConstants.danger,
      glowOpacity: 0.12,
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.wifi_off_rounded,
              color: AppConstants.textSecondary, size: 44),
          const SizedBox(height: 12),
          Text(_error!,
              style: const TextStyle(
                  color: AppConstants.textSecondary, fontSize: 12),
              textAlign: TextAlign.center),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded,
                color: AppConstants.accent, size: 16),
            label: const Text('Retry',
                style: TextStyle(color: AppConstants.accent)),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildStats() {
    final total  = _stats?['total_scammers']?.toString() ?? '—';
    final reports = _stats?['total_reports']?.toString() ?? '—';
    final traced  = _stats?['total_traced']?.toString() ?? '—';

    return Column(
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
              'LIVE INTELLIGENCE RADAR',
              style: TextStyle(
                color: AppConstants.textSecondary,
                fontSize: 10,
                letterSpacing: 1.8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'Suspects',
                value: total,
                icon: Icons.person_off_rounded,
                iconColor: AppConstants.danger,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatCard(
                label: 'Reports',
                value: reports,
                icon: Icons.report_rounded,
                iconColor: AppConstants.warning,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatCard(
                label: 'Trap Hits',
                value: traced,
                icon: Icons.track_changes_rounded,
                iconColor: AppConstants.success,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Visual Quick Trap Modal ─────────────────────────────────────────────
  void _showQuickTrapDialog(BuildContext context) {
    final phoneCtrl = TextEditingController();
    final upiCtrl   = TextEditingController();
    String selectedTemplate = 'payment_receipt';
    bool generating = false;

    // Template definitions with preview metadata
    const templates = [
      _TrapTemplate(
        key: 'payment_receipt',
        icon: Icons.payments_rounded,
        title: 'Payment Receipt',
        desc: 'Fake UPI ₹18,500 confirmation',
        color: Color(0xFF10B981),
      ),
      _TrapTemplate(
        key: 'courier_tracking',
        icon: Icons.local_shipping_rounded,
        title: 'Express Courier',
        desc: 'Delivery notice with tracking',
        color: Color(0xFFF59E0B),
      ),
      _TrapTemplate(
        key: 'warning',
        icon: Icons.gavel_rounded,
        title: 'Cyber Crime Notice',
        desc: 'Official government warning',
        color: Color(0xFFF43F5E),
      ),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF0D1526),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(
                top: BorderSide(
                    color: Color(0xFF1E2D45), width: 1),
              ),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppConstants.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: AppConstants.dangerGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppConstants.danger.withValues(alpha: 0.4),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.flash_on_rounded,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'INSTANT QUICK TRAP',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'Deploy honeypot link in 1 second',
                          style: TextStyle(
                              color: AppConstants.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Input fields
                _StyledTextField(
                  controller: phoneCtrl,
                  hint: 'Suspect Phone Number (optional)',
                  icon: Icons.phone_rounded,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 10),
                _StyledTextField(
                  controller: upiCtrl,
                  hint: 'Suspect UPI ID (optional)',
                  icon: Icons.account_balance_wallet_rounded,
                ),
                const SizedBox(height: 18),

                // Visual template selector
                const Text(
                  'SELECT DECOY TYPE',
                  style: TextStyle(
                    color: AppConstants.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: templates.map((t) {
                    final sel = selectedTemplate == t.key;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setModalState(() => selectedTemplate = t.key),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 12),
                          decoration: BoxDecoration(
                            color: sel
                                ? t.color.withValues(alpha: 0.14)
                                : AppConstants.inputFill,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: sel
                                  ? t.color
                                  : AppConstants.divider,
                              width: sel ? 1.5 : 1,
                            ),
                            boxShadow: sel
                                ? [
                                    BoxShadow(
                                      color: t.color.withValues(alpha: 0.25),
                                      blurRadius: 12,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            children: [
                              Icon(t.icon,
                                  color: sel
                                      ? t.color
                                      : AppConstants.textSecondary,
                                  size: 24),
                              const SizedBox(height: 6),
                              Text(
                                t.title,
                                style: TextStyle(
                                  color: sel
                                      ? t.color
                                      : AppConstants.textSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                t.desc,
                                style: const TextStyle(
                                  color: AppConstants.textMuted,
                                  fontSize: 8,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Deploy button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: GestureDetector(
                    onTap: generating
                        ? null
                        : () async {
                            final phone = phoneCtrl.text.trim();
                            final upi   = upiCtrl.text.trim();
                            if (phone.isEmpty && upi.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Enter at least a phone number or UPI ID'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }
                            setModalState(() => generating = true);
                            try {
                              final res = await _api.generateQuickTrap(
                                phoneNumber:
                                    phone.isNotEmpty ? phone : null,
                                upiId: upi.isNotEmpty ? upi : null,
                                templateType: selectedTemplate,
                              );
                              if (!mounted) return;
                              Navigator.pop(ctx);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TrapLinkScreen(
                                    linkId: res['link_id']?.toString() ?? '',
                                    trapUrl: res['trap_url']?.toString() ?? '',
                                    scammerId:
                                        res['scammer_id']?.toString() ?? '',
                                    templateType: selectedTemplate,
                                  ),
                                ),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              setModalState(() => generating = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: AppConstants.danger,
                                ),
                              );
                            }
                          },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      decoration: BoxDecoration(
                        gradient: generating
                            ? null
                            : AppConstants.dangerGradient,
                        color: generating
                            ? AppConstants.divider
                            : null,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: generating
                            ? null
                            : [
                                BoxShadow(
                                  color: AppConstants.danger
                                      .withValues(alpha: 0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                      ),
                      child: Center(
                        child: generating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.bolt_rounded,
                                      color: Colors.white, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'DEPLOY TRAP LINK',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        PulsingQuickTrapBanner(onTap: () => _showQuickTrapDialog(context)),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _ActionBtn(
                label: 'Search Number',
                subtitle: 'Lookup fraud history',
                icon: Icons.search_rounded,
                gradient: AppConstants.accentGradient,
                glowColor: AppConstants.accent,
                onTap: () {
                  final state =
                      context.findAncestorStateOfType<_HomeScreenState>();
                  state?.setState(() => state._currentIndex = 1);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionBtn(
                label: 'Report Scammer',
                subtitle: 'File forensic evidence',
                icon: Icons.report_problem_rounded,
                gradient: AppConstants.dangerGradient,
                glowColor: AppConstants.danger,
                onTap: () {
                  final state =
                      context.findAncestorStateOfType<_HomeScreenState>();
                  state?.setState(() => state._currentIndex = 2);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 14,
              decoration: BoxDecoration(
                gradient: AppConstants.dangerGradient,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'RECENTLY INTERCEPTED TARGETS',
              style: TextStyle(
                color: AppConstants.textSecondary,
                fontSize: 10,
                letterSpacing: 1.8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_recent.isEmpty)
          _emptyState('No reports yet. Be the first to report a scammer.')
        else
          ..._recent.map(
            (s) => ScammerCard(
              scammer: s,
              compact: true,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ScammerDetailScreen(scammer: s),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _emptyState(String msg) {
    return GlassCard(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.radar_rounded,
                color: AppConstants.accent.withValues(alpha: 0.4), size: 36),
            const SizedBox(height: 10),
            Text(msg,
                style: const TextStyle(
                  color: AppConstants.textSecondary,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ─── Trap Template Model ───────────────────────────────────────────────────
class _TrapTemplate {
  final String key;
  final IconData icon;
  final String title;
  final String desc;
  final Color color;
  const _TrapTemplate({
    required this.key,
    required this.icon,
    required this.title,
    required this.desc,
    required this.color,
  });
}

// ─── Shared Styled TextField ───────────────────────────────────────────────
class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;

  const _StyledTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 13),
        prefixIcon: Icon(icon, color: AppConstants.accent, size: 18),
        filled: true,
        fillColor: AppConstants.inputFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: AppConstants.divider, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: AppConstants.accent.withValues(alpha: 0.6), width: 1.5),
        ),
      ),
    );
  }
}

// ─── Action Button with Sentinel Styling ──────────────────────────────────
class _ActionBtn extends StatefulWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final Color glowColor;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.glowColor,
    required this.onTap,
  });

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> {
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit:  (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown:   (_) => setState(() => _isPressed = true),
        onTapUp:     (_) => setState(() => _isPressed = false),
        onTapCancel: ()  => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.95 : (_isHovered ? 1.03 : 1.0),
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeInOut,
          child: Container(
            height: 90,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: widget.gradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: widget.glowColor.withValues(
                      alpha: _isHovered ? 0.5 : 0.28),
                  blurRadius: _isHovered ? 20 : 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(widget.icon, color: Colors.white, size: 18),
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_forward_rounded,
                        color: Colors.white.withValues(alpha: 0.6), size: 14),
                  ],
                ),
                const Spacer(),
                Text(
                  widget.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                Text(
                  widget.subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Subtle Grid Background Painter ───────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00F2FE)
      ..strokeWidth = 0.5;
    const step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter _) => false;
}
