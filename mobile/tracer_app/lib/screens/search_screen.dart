import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../providers/app_provider.dart';
import '../widgets/scammer_card.dart';
import '../models/scammer.dart';
import 'scammer_detail_screen.dart';
import 'package:provider/provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  bool _searched = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String val) {
    setState(() => _searched = val.trim().isNotEmpty);
    if (val.trim().length >= 3) {
      context.read<AppProvider>().search(val);
    } else if (val.trim().isEmpty) {
      context.read<AppProvider>().clearSearch();
    }
  }

  void _onSubmit(String val) {
    if (val.trim().isNotEmpty) {
      context.read<AppProvider>().search(val);
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
                gradient: AppConstants.accentGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.search_rounded,
                  color: Colors.black, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'SEARCH',
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
                  AppConstants.accent.withValues(alpha: 0.5),
                  AppConstants.divider.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: AppConstants.background,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: _ctrl,
              style: const TextStyle(color: Colors.white),
              onChanged: _onChanged,
              onSubmitted: _onSubmit,
              autofocus: false,
              decoration: InputDecoration(
                hintText: 'Enter phone number or UPI ID...',
                hintStyle: TextStyle(
                    color: AppConstants.textSecondary.withValues(alpha: 0.5)),
                prefixIcon:
                    const Icon(Icons.search, color: AppConstants.accent),
                suffixIcon: _ctrl.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _ctrl.clear();
                          context.read<AppProvider>().clearSearch();
                          setState(() => _searched = false);
                        },
                        child: const Icon(Icons.clear,
                            color: AppConstants.textSecondary),
                      )
                    : null,
                filled: true,
                fillColor: AppConstants.inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: AppConstants.accent, width: 1.5),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
              ),
            ),
          ),

          // Results
          Expanded(
            child: Consumer<AppProvider>(
              builder: (ctx, provider, _) {
                if (!_searched) return _buildInstructions();
                if (provider.searchLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppConstants.accent),
                  );
                }
                if (provider.searchError != null) {
                  return _buildError(provider.searchError!);
                }
                if (provider.searchResults.isEmpty) {
                  return _buildNotFound();
                }
                return _buildResults(ctx, provider.searchResults);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.manage_search,
                size: 64, color: AppConstants.textSecondary.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            const Text(
              'Enter a phone number or UPI ID',
              style: TextStyle(
                  color: AppConstants.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Find out if someone has been reported as a scammer in our database.',
              style:
                  TextStyle(color: AppConstants.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFound() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppConstants.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppConstants.success.withValues(alpha: 0.4), width: 1.5),
            ),
            child: Column(
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
                const SizedBox(height: 14),
                const Text(
                  '✅ No reports found',
                  style: TextStyle(
                    color: AppConstants.success,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'No reports found for "${_ctrl.text}".\nThis number/ID appears to be clean.',
                  style: const TextStyle(
                      color: AppConstants.textSecondary, height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context, List<Scammer> results) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        Row(
          children: [
            const Icon(Icons.warning, color: AppConstants.danger, size: 16),
            const SizedBox(width: 6),
            Text(
              '${results.length} result(s) found',
              style: const TextStyle(
                  color: AppConstants.danger,
                  fontWeight: FontWeight.w600,
                  fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...results.map(
          (s) => ScammerCard(
            scammer: s,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ScammerDetailScreen(scammer: s)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off,
              color: AppConstants.textSecondary, size: 48),
          const SizedBox(height: 12),
          Text(msg,
              style: const TextStyle(color: AppConstants.textSecondary),
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => _onSubmit(_ctrl.text),
            child: const Text('Retry',
                style: TextStyle(color: AppConstants.accent)),
          ),
        ],
      ),
    );
  }
}
