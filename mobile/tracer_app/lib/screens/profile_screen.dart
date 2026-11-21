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
    with SingleTickerProviderStateMixin {
  final _auth = AuthService();
  bool _loading = false;
  late AnimationController _headerCtrl;
  late Animation<double> _headerAnim;

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
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
              // Handle
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
              const Text(
                'Edit Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Update your agent information',
                style: TextStyle(
                    color: AppConstants.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 24),
              _sheetField(nameCtrl, 'Display Name', Icons.person_outline),
              const SizedBox(height: 14),
              _sheetField(phoneCtrl, 'Phone Number', Icons.phone_outlined,
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 14),
              Text(
                'Role',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0A1220),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppConstants.divider),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedBadge,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF0D1525),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    icon: Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppConstants.textSecondary),
                    items: badges
                        .map((b) => DropdownMenuItem(
                              value: b,
                              child: Text(b),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setModal(() => selectedBadge = v ?? selectedBadge),
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
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
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
              fontWeight: FontWeight.w600,
            )),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppConstants.accent, size: 18),
            filled: true,
            fillColor: const Color(0xFF0A1220),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

  void _confirmLogout() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF0D1525),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppConstants.divider),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppConstants.danger.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppConstants.danger.withValues(alpha: 0.3)),
                ),
                child: Icon(Icons.logout_rounded,
                    color: AppConstants.danger, size: 26),
              ),
              const SizedBox(height: 16),
              const Text(
                'Sign Out?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You will be returned to the sign-in screen. Your local session will be cleared.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppConstants.textSecondary,
                    fontSize: 13,
                    height: 1.5),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
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
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _auth.logout();
                        if (!mounted) return;
                        Navigator.of(context).pushAndRemoveUntil(
                          PageRouteBuilder(
                            transitionDuration:
                                const Duration(milliseconds: 500),
                            pageBuilder: (_, __, ___) =>
                                const LoginScreen(),
                            transitionsBuilder:
                                (_, anim, __, child) =>
                                    FadeTransition(
                                        opacity: anim, child: child),
                          ),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.danger,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Sign Out',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
      backgroundColor: const Color(0xFF070B14),
      body: Stack(
        children: [
          // Top cyan radial glow
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppConstants.accent.withValues(alpha: 0.07),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          CustomScrollView(
            slivers: [
              // ── Collapsing header ──
              SliverAppBar(
                expandedHeight: 220,
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
                              color: AppConstants.accent,
                            ),
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

              // ── Body sections ──
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
                    _buildSignOutButton(),
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF070B14),
            const Color(0xFF0D1525),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Avatar
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppConstants.accent.withValues(alpha: 0.3),
                      AppConstants.accentBlue.withValues(alpha: 0.2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: AppConstants.accent.withValues(alpha: 0.6),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppConstants.accent.withValues(alpha: 0.25),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    user.initials,
                    style: TextStyle(
                      color: AppConstants.accent,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
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
          Text(
            user.fullName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            style: TextStyle(
                color: AppConstants.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
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
                Text(
                  user.badge,
                  style: TextStyle(
                    color: AppConstants.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
        _statChip('Cases', '${user.reportsCount}', Icons.shield_outlined,
            AppConstants.accent),
        const SizedBox(width: 10),
        _statChip('Traps', '${user.trapsCount}', Icons.link_rounded,
            AppConstants.warning),
        const SizedBox(width: 10),
        _statChip(
            'Hits', '${user.hitsCount}', Icons.track_changes_rounded, AppConstants.success),
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
              color: color.withValues(alpha: 0.06),
              blurRadius: 12,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                shadows: [
                  Shadow(color: color.withValues(alpha: 0.5), blurRadius: 10)
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: AppConstants.textSecondary,
                fontSize: 11,
              ),
            ),
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
              user.phone?.isEmpty ?? true ? 'Not added' : user.phone!),
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
                          content: const Text('Token copied to clipboard'),
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

  Widget _buildSignOutButton() {
    return GestureDetector(
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
            Text(
              'Sign Out',
              style: TextStyle(
                color: AppConstants.danger,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
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
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
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
                        color: AppConstants.textSecondary,
                        fontSize: 11)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
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

  Widget _divider() =>
      Divider(color: AppConstants.divider.withValues(alpha: 0.6), height: 1);
}
