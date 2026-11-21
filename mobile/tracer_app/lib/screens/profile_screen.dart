import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_constants.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  final _auth = AuthService();
  bool _loading = false;
  late AnimationController _headerCtrl;
  late Animation<double> _headerAnim;

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _headerAnim =
        CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
    _refreshProfile();
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    super.dispose();
  }

  Future<void> _refreshProfile() async {
    setState(() => _loading = true);
    await _auth.fetchProfile();
    if (mounted) setState(() => _loading = false);
  }

  // ─── Edit Profile Sheet ───────────────────────────────────────────────────
  void _showEditSheet(User user) {
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
        builder: (ctx, setModal) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0D1525),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppConstants.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Edit Profile',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('Update your account information',
                  style: TextStyle(
                      color: AppConstants.textSecondary, fontSize: 13)),
              const SizedBox(height: 24),
              _sheetField(nameCtrl, 'Display Name', Icons.person_outline),
              const SizedBox(height: 14),
              _sheetField(
                  phoneCtrl, 'Phone Number', Icons.phone_outlined,
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 14),
              const Text('Role',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0A1220),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppConstants.divider),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedBadge,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF0D1525),
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13),
                    icon: Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppConstants.textSecondary),
                    items: badges
                        .map((b) =>
                            DropdownMenuItem(value: b, child: Text(b)))
                        .toList(),
                    onChanged: (v) => setModal(
                        () => selectedBadge = v ?? selectedBadge),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _auth.updateProfile(
                      fullName: nameCtrl.text.trim(),
                      phone: phoneCtrl.text.trim(),
                      badge: selectedBadge,
                    );
                    if (mounted) setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.accent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('Save Changes',
                      style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            prefixIcon:
                Icon(icon, color: AppConstants.accent, size: 18),
            filled: true,
            fillColor: const Color(0xFF0A1220),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppConstants.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: AppConstants.accent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Sign Out Dialog ──────────────────────────────────────────────────────
  void _confirmLogout() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (ctx) => _ActionDialog(
        icon: Icons.logout_rounded,
        iconColor: AppConstants.danger,
        title: 'Sign Out?',
        message:
            'You will be returned to the sign-in screen. Your local session will be cleared.',
        confirmLabel: 'Sign Out',
        confirmColor: AppConstants.danger,
        onConfirm: () async {
          Navigator.pop(ctx);
          await _auth.logout();
          if (!mounted) return;
          _goToLogin();
        },
      ),
    );
  }

  // ─── Delete Account Dialog ────────────────────────────────────────────────
  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => _ActionDialog(
        icon: Icons.delete_forever_rounded,
        iconColor: const Color(0xFFFF3B30),
        title: 'Delete Account?',
        message:
            'This will permanently delete your account and all associated data. This action cannot be undone.',
        confirmLabel: 'Delete Permanently',
        confirmColor: const Color(0xFFFF3B30),
        isDangerous: true,
        onConfirm: () async {
          Navigator.pop(ctx);
          await _performDeleteAccount();
        },
      ),
    );
  }

  Future<void> _performDeleteAccount() async {
    // Show deletion animation overlay
    if (!mounted) return;
    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.transparent,
        pageBuilder: (_, __, ___) =>
            const _AccountDeletedScreen(),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
    // After animation, clear session and go to login
    await _auth.deleteAccount();
    if (!mounted) return;
    _goToLogin();
  }

  void _goToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
      (route) => false,
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────
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
      backgroundColor: const Color(0xFF070B14),
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppConstants.accent.withValues(alpha: 0.07),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 230,
                pinned: true,
                backgroundColor: const Color(0xFF070B14),
                surfaceTintColor: Colors.transparent,
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: _loading
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppConstants.accent),
                          )
                        : Icon(Icons.refresh_rounded,
                            color: AppConstants.textSecondary),
                    onPressed: _refreshProfile,
                  ),
                  IconButton(
                    icon: Icon(Icons.edit_outlined,
                        color: AppConstants.accent),
                    onPressed: () => _showEditSheet(user),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  background: FadeTransition(
                    opacity: _headerAnim,
                    child: _buildProfileHeader(user),
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        AppConstants.accent.withValues(alpha: 0.4),
                        AppConstants.divider.withValues(alpha: 0.3),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildStatsRow(user),
                    const SizedBox(height: 20),
                    _buildInfoCard(user),
                    const SizedBox(height: 20),
                    _buildSettingsCard(),
                    const SizedBox(height: 20),
                    _buildDangerZone(),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(User user) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF070B14), Color(0xFF0D1525)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 70, 24, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [
                    AppConstants.accent.withValues(alpha: 0.3),
                    AppConstants.accentBlue.withValues(alpha: 0.2),
                  ], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  border: Border.all(
                      color: AppConstants.accent.withValues(alpha: 0.6),
                      width: 2),
                  boxShadow: [
                    BoxShadow(
                        color: AppConstants.accent.withValues(alpha: 0.25),
                        blurRadius: 24,
                        spreadRadius: 2),
                  ],
                ),
                child: Center(
                  child: Text(
                    user.initials,
                    style: TextStyle(
                        color: AppConstants.accent,
                        fontSize: 26,
                        fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: AppConstants.success,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: const Color(0xFF070B14), width: 2.5),
                  boxShadow: [
                    BoxShadow(
                        color: AppConstants.success.withValues(alpha: 0.5),
                        blurRadius: 8),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(user.fullName,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(user.email,
              style: TextStyle(
                  color: AppConstants.textSecondary, fontSize: 13)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: AppConstants.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                  color: AppConstants.accent.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_rounded,
                    color: AppConstants.accent, size: 13),
                const SizedBox(width: 6),
                Text(user.badge,
                    style: TextStyle(
                        color: AppConstants.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(User user) {
    return Row(
      children: [
        _statChip('Cases', '${user.reportsCount}',
            Icons.shield_outlined, AppConstants.accent),
        const SizedBox(width: 10),
        _statChip('Traps', '${user.trapsCount}',
            Icons.link_rounded, AppConstants.warning),
        const SizedBox(width: 10),
        _statChip('Hits', '${user.hitsCount}',
            Icons.track_changes_rounded, AppConstants.success),
      ],
    );
  }

  Widget _statChip(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1525),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.06), blurRadius: 12),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(
                          color: color.withValues(alpha: 0.5),
                          blurRadius: 10)
                    ])),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    color: AppConstants.textSecondary, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(User user) {
    return _card(
      'Account Information',
      Icons.person_outline_rounded,
      Column(
        children: [
          _infoTile(Icons.person_rounded, 'Full Name', user.fullName),
          _divider(),
          _infoTile(Icons.email_outlined, 'Email', user.email),
          _divider(),
          _infoTile(Icons.phone_outlined, 'Phone',
              (user.phone == null || user.phone!.isEmpty)
                  ? 'Not added'
                  : user.phone!),
          _divider(),
          _infoTile(
            Icons.vpn_key_outlined,
            'Session Token',
            _auth.token != null
                ? '${_auth.token!.substring(0, _auth.token!.length > 16 ? 16 : _auth.token!.length)}…'
                : 'No active session',
            trailing: _auth.token != null
                ? GestureDetector(
                    onTap: () {
                      Clipboard.setData(
                          ClipboardData(text: _auth.token ?? ''));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Token copied'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          margin: const EdgeInsets.all(16),
                          backgroundColor: AppConstants.cardBg,
                        ),
                      );
                    },
                    child: Icon(Icons.copy_rounded,
                        color: AppConstants.accent, size: 15),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    return _card(
      'Preferences',
      Icons.tune_rounded,
      Column(
        children: [
          _toggleTile(
            'Biometric Login',
            'Use fingerprint or Face ID',
            Icons.fingerprint_rounded,
            _auth.biometricEnabled,
            _auth.toggleBiometric,
          ),
          _divider(),
          _toggleTile(
            'Push Notifications',
            'Alert when honeypot is triggered',
            Icons.notifications_outlined,
            _auth.notificationsEnabled,
            _auth.toggleNotifications,
          ),
          _divider(),
          _toggleTile(
            'Auto Radar Sync',
            'Sync threat data every 4 seconds',
            Icons.radar_rounded,
            _auth.autoRadarSync,
            _auth.toggleAutoRadar,
          ),
        ],
      ),
    );
  }

  // ─── Danger Zone ──────────────────────────────────────────────────────────
  Widget _buildDangerZone() {
    return Column(
      children: [
        // Sign Out
        GestureDetector(
          onTap: _confirmLogout,
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: AppConstants.danger.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppConstants.danger.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout_rounded,
                    color: AppConstants.danger, size: 18),
                const SizedBox(width: 10),
                Text('Sign Out',
                    style: TextStyle(
                        color: AppConstants.danger,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Delete Account
        GestureDetector(
          onTap: _confirmDeleteAccount,
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: const Color(0xFFFF3B30).withValues(alpha: 0.5),
                  width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.delete_forever_rounded,
                    color: Color(0xFFFF3B30), size: 20),
                const SizedBox(width: 10),
                Text(
                  'Delete Account',
                  style: TextStyle(
                    color: const Color(0xFFFF3B30)
                        .withValues(alpha: 0.9),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Permanently removes your account and all data.',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: AppConstants.textMuted, fontSize: 11),
        ),
      ],
    );
  }

  Widget _card(String title, IconData icon, Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1525),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppConstants.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              children: [
                Icon(icon, color: AppConstants.accent, size: 18),
                const SizedBox(width: 10),
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Divider(color: AppConstants.divider, height: 1),
          Padding(padding: const EdgeInsets.all(4), child: child),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value,
      {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppConstants.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: AppConstants.accent, size: 15),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: AppConstants.textSecondary, fontSize: 11)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 10),
            trailing,
          ],
        ],
      ),
    );
  }

  Widget _toggleTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: (value ? AppConstants.accent : AppConstants.textMuted)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon,
                color: value
                    ? AppConstants.accent
                    : AppConstants.textMuted,
                size: 15),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        color: AppConstants.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: AppConstants.accent,
            activeTrackColor: AppConstants.accent.withValues(alpha: 0.25),
            inactiveThumbColor: AppConstants.textMuted,
            inactiveTrackColor: AppConstants.inputFill,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(
      color: AppConstants.divider.withValues(alpha: 0.6), height: 1);
}

// ═══════════════════════════════════════════════════════════════════════════
// Generic Action Confirm Dialog
// ═══════════════════════════════════════════════════════════════════════════
class _ActionDialog extends StatelessWidget {
  const _ActionDialog({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.confirmColor,
    required this.onConfirm,
    this.isDangerous = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String confirmLabel;
  final Color confirmColor;
  final VoidCallback onConfirm;
  final bool isDangerous;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0D1525),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
            color: isDangerous
                ? iconColor.withValues(alpha: 0.3)
                : AppConstants.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                    color: iconColor.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 18),
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppConstants.textSecondary,
                    fontSize: 13,
                    height: 1.5)),
            const SizedBox(height: 26),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppConstants.divider),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('Cancel',
                        style: TextStyle(
                            color: AppConstants.textSecondary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: confirmColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                    child: Text(confirmLabel,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Account Deleted Animation Screen
// ═══════════════════════════════════════════════════════════════════════════
class _AccountDeletedScreen extends StatefulWidget {
  const _AccountDeletedScreen();

  @override
  State<_AccountDeletedScreen> createState() =>
      _AccountDeletedScreenState();
}

class _AccountDeletedScreenState extends State<_AccountDeletedScreen>
    with TickerProviderStateMixin {
  late AnimationController _bgCtrl;
  late AnimationController _iconCtrl;
  late AnimationController _textCtrl;
  late AnimationController _particleCtrl;

  late Animation<double> _bgAnim;
  late Animation<double> _iconScaleAnim;
  late Animation<double> _iconOpacityAnim;
  late Animation<double> _textAnim;
  late Animation<double> _particleAnim;

  @override
  void initState() {
    super.initState();

    _bgCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400))
      ..forward();
    _bgAnim = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeOut);

    _iconCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _iconScaleAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: _iconCtrl, curve: Curves.elasticOut));
    _iconOpacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _iconCtrl, curve: Curves.easeOut));

    _textCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _textAnim = CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut);

    _particleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
    _particleAnim =
        CurvedAnimation(parent: _particleCtrl, curve: Curves.linear);

    // Sequence: bg → icon → text → auto-pop after 2.5s
    Future.delayed(const Duration(milliseconds: 300),
        () => _iconCtrl.forward());
    Future.delayed(const Duration(milliseconds: 800),
        () => _textCtrl.forward());
    Future.delayed(
        const Duration(milliseconds: 2800), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _iconCtrl.dispose();
    _textCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _bgAnim,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0010),
        body: Stack(
          alignment: Alignment.center,
          children: [
            // Animated particle burst
            AnimatedBuilder(
              animation: _particleAnim,
              builder: (_, __) => CustomPaint(
                size: MediaQuery.of(context).size,
                painter:
                    _ParticlePainter(_particleAnim.value),
              ),
            ),

            // Red radial glow
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFF3B30).withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                  radius: 0.6,
                ),
              ),
            ),

            // Centre content
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon with scale + bounce
                ScaleTransition(
                  scale: _iconScaleAnim,
                  child: FadeTransition(
                    opacity: _iconOpacityAnim,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFF3B30)
                            .withValues(alpha: 0.12),
                        border: Border.all(
                          color: const Color(0xFFFF3B30)
                              .withValues(alpha: 0.5),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF3B30)
                                .withValues(alpha: 0.4),
                            blurRadius: 40,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.delete_forever_rounded,
                        color: Color(0xFFFF3B30),
                        size: 50,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Text
                FadeTransition(
                  opacity: _textAnim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                            begin: const Offset(0, 0.3),
                            end: Offset.zero)
                        .animate(_textAnim),
                    child: Column(
                      children: [
                        const Text(
                          'Account Deleted',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Your account has been permanently\nremoved from TRACER.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white
                                .withValues(alpha: 0.5),
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 7),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: const Color(0xFFFF3B30)
                                    .withValues(alpha: 0.4)),
                            borderRadius:
                                BorderRadius.circular(100),
                          ),
                          child: const Text(
                            'ALL DATA ERASED PERMANENTLY',
                            style: TextStyle(
                              color: Color(0xFFFF3B30),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Particle painter for deletion animation ──────────────────────────────
class _ParticlePainter extends CustomPainter {
  _ParticlePainter(this.progress);
  final double progress;

  static final _rng = math.Random(42);
  static final _particles = List.generate(24, (i) {
    final angle = (i / 24) * 2 * math.pi;
    final speed = 0.3 + _rng.nextDouble() * 0.7;
    final size = 2.0 + _rng.nextDouble() * 4;
    return (angle: angle, speed: speed, size: size);
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxR = size.shortestSide * 0.45;

    for (final p in _particles) {
      final r = p.speed * maxR * progress;
      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      final paint = Paint()
        ..color =
            const Color(0xFFFF3B30).withValues(alpha: opacity * 0.8)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(cx + r * math.cos(p.angle),
            cy + r * math.sin(p.angle)),
        p.size * (1.0 - progress * 0.5),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) =>
      old.progress != progress;
}
