import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../widgets/custom_button.dart';
import 'trap_link_screen.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();

  final _phoneCtrl = TextEditingController();
  final _upiCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _victimCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _utrCtrl = TextEditingController();

  String _countryCode = '+91';
  String _paymentMethod = AppConstants.paymentMethods[0];
  String? _scamCategory;
  String? _riskLevel;
  bool _loading = false;
  bool _analyzing = false;
  Map<String, dynamic>? _aiResult;

  static const List<String> _scamCategories = [
    'Electricity Bill Scam',
    'Task / WFH Fraud',
    'KYC / Bank Phishing',
    'Courier / Digital Arrest',
    'Job Offer Scam',
    'Investment / Stock Scam',
    'Romance Scam',
    'Lottery / Prize Scam',
    'Other',
  ];

  final List<String> _countryCodes = [
    '+91', '+1', '+44', '+61', '+971', '+65', '+60',
    '+880', '+92', '+94', '+977', '+66'
  ];

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _upiCtrl.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _victimCtrl.dispose();
    _amountCtrl.dispose();
    _utrCtrl.dispose();
    super.dispose();
  }

  Future<void> _analyzeScam() async {
    final text = _descCtrl.text.trim();
    if (text.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please describe the scam first (min 10 chars)'),
          backgroundColor: AppConstants.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() { _analyzing = true; _aiResult = null; });
    try {
      final result = await _api.analyzeScamText(text);
      setState(() {
        _aiResult = result;
        // Auto-fill category & risk from AI
        final cat = result['category'] as String?;
        final risk = result['risk_level'] as String?;
        if (cat != null && _scamCategories.contains(cat)) {
          _scamCategory = cat;
        }
        if (risk != null) _riskLevel = risk;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Analysis failed: $e'),
          backgroundColor: AppConstants.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final rawPhone = _phoneCtrl.text.trim();
      final fullPhone = rawPhone.isNotEmpty ? '$_countryCode$rawPhone' : '';
      final upi = _upiCtrl.text.trim();

      final result = await _api.submitReport(
        phoneNumber: fullPhone,
        upiId: upi,
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        victimName: _victimCtrl.text.trim(),
        amountLost: double.tryParse(_amountCtrl.text.trim()) ?? 0,
        paymentMethod: _paymentMethod,
        utrNumber: _utrCtrl.text.trim(),
        scamCategory: _scamCategory,
        riskLevel: _riskLevel,
      );

      final reportId = result['id']?.toString() ?? '';
      final scammerId = result['scammer_id']?.toString() ?? '';

      await _storage.addMyReport({
        'report_id': reportId,
        'scammer_id': scammerId,
        'phone': fullPhone,
        'upi': upi,
        'amount': _amountCtrl.text.trim(),
        'filed_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      _showSuccessDialog(scammerId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: ${e.toString()}'),
          backgroundColor: AppConstants.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSuccessDialog(String scammerId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppConstants.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle,
                  color: AppConstants.success, size: 40),
            ),
            const SizedBox(height: 10),
            const Text('Report Filed!',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Your report has been submitted successfully.\n\nWould you like to generate a Trap Link to track this scammer\'s location?',
          style: TextStyle(color: AppConstants.textSecondary, height: 1.5),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _resetForm();
            },
            child: const Text('No, Thanks',
                style: TextStyle(color: AppConstants.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.danger,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
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
                    content: Text('Failed to generate link: $e'),
                    backgroundColor: AppConstants.danger,
                  ),
                );
              }
              _resetForm();
            },
            child: const Text('Yes, Generate Link!'),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _phoneCtrl.clear();
    _upiCtrl.clear();
    _nameCtrl.clear();
    _descCtrl.clear();
    _victimCtrl.clear();
    _amountCtrl.clear();
    _utrCtrl.clear();
    setState(() {
      _countryCode = '+91';
      _paymentMethod = AppConstants.paymentMethods[0];
      _scamCategory = null;
      _riskLevel = null;
      _aiResult = null;
    });
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
                gradient: AppConstants.dangerGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.report_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'FILE REPORT',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 17,
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Scammer Info Section ───────────────────────────────────
              _sectionHeader('Scammer Information', Icons.person_off),
              const SizedBox(height: 12),

              _label('Phone Number'),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppConstants.inputFill,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppConstants.divider),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _countryCode,
                        dropdownColor: AppConstants.cardBg,
                        style: const TextStyle(color: Colors.white),
                        items: _countryCodes
                            .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(c,
                                    style: const TextStyle(color: Colors.white))))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _countryCode = v ?? '+91'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _inputField(
                      controller: _phoneCtrl,
                      hint: '9876543210',
                      icon: Icons.phone,
                      keyboard: TextInputType.phone,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          if (_upiCtrl.text.trim().isEmpty) {
                            return 'Phone or UPI is required';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _label('UPI ID'),
              _inputField(
                controller: _upiCtrl,
                hint: 'example@upi',
                icon: Icons.account_balance_wallet,
              ),
              const SizedBox(height: 12),

              _label('Scammer\'s Name (optional)'),
              _inputField(
                controller: _nameCtrl,
                hint: 'John Doe',
                icon: Icons.badge,
              ),
              const SizedBox(height: 12),

              // Description + AI Analyze ─────────────────────────────────
              _label('Description of Scam *'),
              _inputField(
                controller: _descCtrl,
                hint: 'Describe what happened — mention any threats, calls, messages...',
                icon: Icons.description,
                maxLines: 4,
                validator: (v) =>
                    (v == null || v.trim().length < 10)
                        ? 'Please describe the scam (min 10 chars)'
                        : null,
              ),
              const SizedBox(height: 10),

              // 🤖 AI Analyze Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _analyzing ? null : _analyzeScam,
                  icon: _analyzing
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppConstants.accent))
                      : const Icon(Icons.psychology, color: AppConstants.accent, size: 18),
                  label: Text(
                    _analyzing
                        ? '🧠 AI Scanning Threat Patterns...'
                        : '🤖 Run AI Scam Pattern Analysis',
                    style: const TextStyle(
                      color: AppConstants.accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: _analyzing
                          ? AppConstants.warning
                          : AppConstants.accent,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: _analyzing
                        ? AppConstants.accent.withValues(alpha: 0.1)
                        : Colors.transparent,
                  ),
                ),
              ),

              // Animated Scanning In Progress Banner
              if (_analyzing) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppConstants.cardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppConstants.accent.withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppConstants.accent,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Matching threat patterns against Cybercrime database...',
                          style: TextStyle(
                            color: AppConstants.textSecondary,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // AI Result Card
              if (_aiResult != null && !_analyzing) ...[
                const SizedBox(height: 14),
                _AiResultCard(result: _aiResult!),
              ],

              const SizedBox(height: 20),

              // ── Evidence Section ──────────────────────────────────────
              _sectionHeader('Evidence Details', Icons.gavel),
              const SizedBox(height: 12),

              _label('UTR / Transaction Reference (optional)'),
              _inputField(
                controller: _utrCtrl,
                hint: 'e.g. 123456789012',
                icon: Icons.receipt_long,
                keyboard: TextInputType.text,
              ),
              const SizedBox(height: 12),

              _label('Scam Category'),
              Container(
                decoration: BoxDecoration(
                  color: AppConstants.inputFill,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppConstants.divider),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _scamCategory,
                    isExpanded: true,
                    hint: const Text('Select category',
                        style: TextStyle(color: AppConstants.textSecondary)),
                    dropdownColor: AppConstants.cardBg,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    icon: const Icon(Icons.arrow_drop_down,
                        color: AppConstants.textSecondary),
                    items: _scamCategories
                        .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c,
                                style: const TextStyle(color: Colors.white))))
                        .toList(),
                    onChanged: (v) => setState(() => _scamCategory = v),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Risk Level badges
              _label('Risk Level'),
              Row(
                children: [
                  for (final level in ['Low', 'Medium', 'High', 'Critical'])
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _riskLevel = level),
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _riskLevel == level
                                ? _riskColor(level).withValues(alpha: 0.2)
                                : AppConstants.inputFill,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _riskLevel == level
                                  ? _riskColor(level)
                                  : AppConstants.divider,
                              width: _riskLevel == level ? 1.5 : 1,
                            ),
                          ),
                          child: Text(
                            level,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _riskLevel == level
                                  ? _riskColor(level)
                                  : AppConstants.textSecondary,
                              fontSize: 12,
                              fontWeight: _riskLevel == level
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Your Info Section ─────────────────────────────────────
              _sectionHeader('Your Information', Icons.person),
              const SizedBox(height: 12),

              _label('Your Name *'),
              _inputField(
                controller: _victimCtrl,
                hint: 'Your full name',
                icon: Icons.person,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 12),

              _label('Amount Lost (₹)'),
              _inputField(
                controller: _amountCtrl,
                hint: '0',
                icon: Icons.currency_rupee,
                keyboard: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),

              _label('Payment Method'),
              Container(
                decoration: BoxDecoration(
                  color: AppConstants.inputFill,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppConstants.divider),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _paymentMethod,
                    isExpanded: true,
                    dropdownColor: AppConstants.cardBg,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    icon: const Icon(Icons.arrow_drop_down,
                        color: AppConstants.textSecondary),
                    items: AppConstants.paymentMethods
                        .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text(m,
                                style: const TextStyle(color: Colors.white))))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _paymentMethod = v ?? 'UPI'),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                child: CustomButton.danger(
                  label: 'Submit Report',
                  icon: Icons.send,
                  isLoading: _loading,
                  onPressed: _loading ? null : _submit,
                ),
              ),

              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'Your information is kept confidential.',
                  style: TextStyle(
                      color: AppConstants.textSecondary, fontSize: 12),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Color _riskColor(String level) {
    switch (level) {
      case 'Low': return AppConstants.success;
      case 'Medium': return AppConstants.warning;
      case 'High': return Colors.orange;
      case 'Critical': return AppConstants.danger;
      default: return AppConstants.textSecondary;
    }
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            gradient: AppConstants.accentGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Icon(icon, color: AppConstants.accent, size: 16),
        const SizedBox(width: 6),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: AppConstants.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppConstants.accent.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: const TextStyle(
              color: AppConstants.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500)),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboard,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            TextStyle(color: AppConstants.textSecondary.withValues(alpha: 0.5)),
        prefixIcon: Icon(icon, color: AppConstants.accent, size: 18),
        filled: true,
        fillColor: AppConstants.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppConstants.divider, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppConstants.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppConstants.danger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppConstants.danger, width: 1.5),
        ),
        errorStyle: const TextStyle(color: AppConstants.danger),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      ),
    );
  }
}

// ─── AI Result Card ──────────────────────────────────────────────────────────
class _AiResultCard extends StatelessWidget {
  final Map<String, dynamic> result;
  const _AiResultCard({required this.result});

  Color _riskColor(String? level) {
    switch (level) {
      case 'Low': return AppConstants.success;
      case 'Medium': return AppConstants.warning;
      case 'High': return Colors.orange;
      case 'Critical': return AppConstants.danger;
      default: return AppConstants.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = result['category'] as String? ?? 'Unknown';
    final risk = result['risk_level'] as String? ?? 'Unknown';
    final confidence = ((result['confidence'] as num?) ?? 0).toStringAsFixed(0);
    final indicators = (result['indicators'] as List?)?.cast<String>() ?? [];
    final actions = (result['actions'] as List?)?.cast<String>() ?? [];
    final helpline = result['helpline'] as String? ?? '';
    final riskColor = _riskColor(risk);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppConstants.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              const Icon(Icons.psychology, color: AppConstants.accent, size: 18),
              const SizedBox(width: 8),
              const Text('AI Analysis Result',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: riskColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  '⚠ $risk Risk',
                  style: TextStyle(
                      color: riskColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Category & Confidence
          Row(
            children: [
              const Icon(Icons.category, color: AppConstants.textSecondary, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(category,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              Text('$confidence% confident',
                  style: TextStyle(
                      color: riskColor, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          // Animated Confidence Risk Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(
                  begin: 0.0,
                  end: (((result['confidence'] as num?) ?? 50) / 100.0).clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 6,
                  backgroundColor: AppConstants.inputFill,
                  valueColor: AlwaysStoppedAnimation<Color>(riskColor),
                );
              },
            ),
          ),

          if (indicators.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text('🔍 Indicators:',
                style: TextStyle(
                    color: AppConstants.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            ...indicators.map((i) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ',
                          style: TextStyle(
                              color: AppConstants.warning, fontSize: 12)),
                      Expanded(
                        child: Text(i,
                            style: const TextStyle(
                                color: AppConstants.textSecondary,
                                fontSize: 12)),
                      ),
                    ],
                  ),
                )),
          ],

          if (actions.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text('✅ Recommended Actions:',
                style: TextStyle(
                    color: AppConstants.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            ...actions.map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('→ ',
                          style: TextStyle(
                              color: AppConstants.success, fontSize: 12)),
                      Expanded(
                        child: Text(a,
                            style: const TextStyle(
                                color: AppConstants.textSecondary,
                                fontSize: 12)),
                      ),
                    ],
                  ),
                )),
          ],

          if (helpline.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppConstants.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone_in_talk,
                      color: AppConstants.danger, size: 14),
                  const SizedBox(width: 6),
                  Text('Helpline: $helpline',
                      style: const TextStyle(
                          color: AppConstants.danger,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
