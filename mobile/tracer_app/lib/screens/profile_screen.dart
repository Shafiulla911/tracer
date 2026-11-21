import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_constants.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../widgets/glass_card.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = AuthService();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _refreshProfile();
  }

  Future<void> _refreshProfile() async {
    setState(() => _loading = true);
    await _auth.fetchProfile();
    if (mounted) setState(() => _loading = false);
  }

  void _showEditProfileDialog(User user) {
    final nameCtrl = TextEditingController(text: user.fullName);
    final phoneCtrl = TextEditingController(text: user.phone ?? '');
    String selectedBadge = user.badge;

    final badges = [
      'Field Investigator • Level 1',
      'Cyber Threat Hunter',
      'Senior Forensic Analyst',
      'Honeypot Specialist',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0D1526),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: Color(0xFF1E2D45), width: 1)),
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
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppConstants.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.manage_accounts_rounded,
                        color: AppConstants.accent, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'EDIT AGENT PROFILE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text('Agent Codename',
                  style: TextStyle(color: AppConstants.textSecondary, fontSize: 11)),
              const SizedBox(height: 6),
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppConstants.inputFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppConstants.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppConstants.accent, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Phone Number',
                  style: TextStyle(color: AppConstants.textSecondary, fontSize: 11)),
              const SizedBox(height: 6),
              TextField(
                controller: phoneCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppConstants.inputFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppConstants.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppConstants.accent, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Rank & Specialization',
                  style: TextStyle(color: AppConstants.textSecondary, fontSize: 11)),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: AppConstants.inputFill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppConstants.divider),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedBadge,
                    isExpanded: true,
                    dropdownColor: AppConstants.cardBg,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    items: badges
                        .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                        .toList(),
                    onChanged: (v) =>
                        setModalState(() => selectedBadge = v ?? selectedBadge),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _auth.updateProfile(
                      fullName: nameCtrl.text.trim(),
                      phone: phoneCtrl.text.trim(),
                      badge: selectedBadge,
                    );
                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.accent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'SAVE CREDENTIALS',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppConstants.divider),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppConstants.danger.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.power_settings_new_rounded,
                  color: AppConstants.danger, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'Terminate Session?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to disconnect from Sentinel Grid? Your local agent token will be cleared.',
          style: TextStyle(color: AppConstants.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppConstants.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.danger,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _auth.logout();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                PageRouteBuilder(
                  transitionDuration: const Duration(milliseconds: 500),
                  pageBuilder: (_, __, ___) => const LoginScreen(),
                  transitionsBuilder: (_, anim, __, child) =>
                      FadeTransition(opacity: anim, child: child),
                ),
                (route) => false,
              );
            },
            child: const Text(
              'Disconnect',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser ??
        User(
          id: 1,
          fullName: 'Field Agent',
          email: 'agent@tracer.network',
          badge: 'Field Investigator • Level 1',
        );

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
                gradient: AppConstants.accentGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.security_rounded,
                  color: Colors.black, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'AGENT PROFILE',
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
          IconButton(
            icon: _loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppConstants.accent),
                  )
                : const Icon(Icons.refresh_rounded,
                    color: AppConstants.textSecondary),
            tooltip: 'Refresh Profile',
            onPressed: _refreshProfile,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppConstants.accent.withValues(alpha: 0.5),
                  AppConstants.divider.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Agent Avatar & Identity Header ───────────────────────────
            _buildAgentHeader(user),
            const SizedBox(height: 18),

            // ─── Operational Statistics ──────────────────────────────────
            _buildStatsRibbon(user),
            const SizedBox(height: 18),

            // ─── Dossier Information Card ────────────────────────────────
            _buildDossierCard(user),
            const SizedBox(height: 18),

            // ─── Security & Grid Controls ────────────────────────────────
            _buildSecurityControls(),
            const SizedBox(height: 24),

            // ─── Action Buttons ──────────────────────────────────────────
            _buildActionButtons(user),
          ],
        ),
      ),
    );
  }

  Widget _buildAgentHeader(User user) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              // Large Avatar with glowing cyber ring
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppConstants.accent.withValues(alpha: 0.35),
                        width: 2,
                      ),
                    ),
                  ),
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppConstants.accent.withValues(alpha: 0.25),
                          const Color(0xFF0D253E),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: AppConstants.accent,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppConstants.accent.withValues(alpha: 0.4),
                          blurRadius: 16,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        user.initials,
                        style: const TextStyle(
                          color: AppConstants.accent,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppConstants.success,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppConstants.background, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppConstants.success.withValues(alpha: 0.6),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
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
                      user.email,
                      style: const TextStyle(
                        color: AppConstants.textSecondary,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppConstants.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: AppConstants.accent.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_rounded,
                              color: AppConstants.accent, size: 12),
                          const SizedBox(width: 5),
                          Text(
                            user.badge.toUpperCase(),
                            style: const TextStyle(
                              color: AppConstants.accent,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_note_rounded,
                    color: AppConstants.accent, size: 24),
                tooltip: 'Edit Profile',
                onPressed: () => _showEditProfileDialog(user),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRibbon(User user) {
    return Row(
      children: [
        Expanded(
          child: _statPill(
            label: 'Cases Filed',
            value: '${user.reportsCount}',
            icon: Icons.shield_outlined,
            color: AppConstants.accent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statPill(
            label: 'Traps Armed',
            value: '${user.trapsCount}',
            icon: Icons.link_rounded,
            color: AppConstants.warning,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statPill(
            label: 'Intercepts',
            value: '${user.hitsCount}',
            icon: Icons.track_changes_rounded,
            color: AppConstants.success,
          ),
        ),
      ],
    );
  }

  Widget _statPill({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppConstants.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
              shadows: [
                Shadow(color: color.withValues(alpha: 0.6), blurRadius: 8),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppConstants.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDossierCard(User user) {
    return GlassCard(
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
                'AGENT SECURITY DOSSIER',
                style: TextStyle(
                  color: AppConstants.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _infoRow(Icons.person_rounded, 'Agent Name', user.fullName),
          _infoRow(Icons.email_rounded, 'Encrypted Mail', user.email),
          _infoRow(
              Icons.phone_rounded, 'Direct Comms', user.phone ?? 'Not registered'),
          _infoRow(
            Icons.vpn_key_rounded,
            'Token Hash',
            _auth.token != null
                ? '${_auth.token!.substring(0, _auth.token!.length > 12 ? 12 : _auth.token!.length)}...'
                : 'Offline Session',
            canCopy: true,
            copyValue: _auth.token ?? '',
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value,
      {bool canCopy = false, String copyValue = ''}) {
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
            child: Icon(icon, color: AppConstants.accent, size: 14),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: AppConstants.textSecondary,
              fontSize: 12,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
          if (canCopy) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: copyValue));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Agent Token copied to clipboard!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Icon(Icons.copy_rounded,
                  color: AppConstants.accent, size: 14),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSecurityControls() {
    return GlassCard(
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
                  gradient: AppConstants.successGradient,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'SECURITY & GRID CONTROLS',
                style: TextStyle(
                  color: AppConstants.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _switchTile(
            title: 'Biometric Fast Authorization',
            subtitle: 'Fingerprint / Face ID for honeypot deployment',
            icon: Icons.fingerprint_rounded,
            value: _auth.biometricEnabled,
            onChanged: (v) => _auth.toggleBiometric(v),
          ),
          const Divider(color: AppConstants.divider, height: 16),
          _switchTile(
            title: 'Real-Time Intercept Alerts',
            subtitle: 'Immediate ping when scammer clicks honeypot',
            icon: Icons.notifications_active_rounded,
            value: _auth.notificationsEnabled,
            onChanged: (v) => _auth.toggleNotifications(v),
          ),
          const Divider(color: AppConstants.divider, height: 16),
          _switchTile(
            title: 'Tactical Radar Auto-Sync',
            subtitle: 'Synchronize 4-second surveillance stream',
            icon: Icons.radar_rounded,
            value: _auth.autoRadarSync,
            onChanged: (v) => _auth.toggleAutoRadar(v),
          ),
        ],
      ),
    );
  }

  Widget _switchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppConstants.accent, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppConstants.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          activeThumbColor: AppConstants.accent,
          activeTrackColor: AppConstants.accent.withValues(alpha: 0.3),
          inactiveThumbColor: AppConstants.textSecondary,
          inactiveTrackColor: AppConstants.inputFill,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildActionButtons(User user) {
    return Column(
      children: [
        // Export Dossier
        OutlinedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    '📄 Agent Credential Dossier compiled and encrypted.'),
                backgroundColor: AppConstants.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          icon: const Icon(Icons.download_rounded,
              color: AppConstants.accent, size: 18),
          label: const Text(
            'EXPORT AGENT DOSSIER',
            style: TextStyle(
              color: AppConstants.accent,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppConstants.accent, width: 1.2),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            minimumSize: const Size.fromHeight(48),
          ),
        ),
        const SizedBox(height: 12),

        // Disconnect / Logout
        ElevatedButton.icon(
          onPressed: _handleLogout,
          icon: const Icon(Icons.power_settings_new_rounded,
              color: Colors.white, size: 18),
          label: const Text(
            'TERMINATE SESSION / LOG OUT',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.danger.withValues(alpha: 0.15),
            foregroundColor: AppConstants.danger,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppConstants.danger, width: 1),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
            minimumSize: const Size.fromHeight(48),
            elevation: 0,
          ),
        ),
      ],
    );
  }
}
