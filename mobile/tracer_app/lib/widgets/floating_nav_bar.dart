import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    _NavItem(icon: Icons.home_outlined,       activeIcon: Icons.home_rounded,          label: 'Home'),
    _NavItem(icon: Icons.search_outlined,     activeIcon: Icons.search_rounded,        label: 'Search'),
    _NavItem(icon: Icons.report_gmailerrorred_outlined, activeIcon: Icons.report_rounded, label: 'Report'),
    _NavItem(icon: Icons.list_alt_outlined,   activeIcon: Icons.list_alt_rounded,      label: 'My Cases'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              gradient: AppConstants.navGradient,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: AppConstants.accent.withValues(alpha: 0.15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: AppConstants.accent.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(_items.length, (i) {
                final item = _items[i];
                final selected = i == currentIndex;
                return _NavTile(
                  item: item,
                  selected: selected,
                  onTap: () => onTap(i),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}

class _NavTile extends StatefulWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;
  const _NavTile({required this.item, required this.selected, required this.onTap});

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _glowAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    if (widget.selected) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_NavTile old) {
    super.didUpdateWidget(old);
    if (widget.selected && !old.selected) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.selected && old.selected) {
      _ctrl.stop();
      _ctrl.reset();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sel = widget.selected;
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        width: sel ? 76 : 52,
        height: 68,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _glowAnim,
              builder: (_, __) => Container(
                width: 44,
                height: 32,
                decoration: sel
                    ? BoxDecoration(
                        color: AppConstants.accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppConstants.accent
                                .withValues(alpha: 0.3 * _glowAnim.value),
                            blurRadius: 12,
                          ),
                        ],
                      )
                    : null,
                child: Center(
                  child: Icon(
                    sel ? widget.item.activeIcon : widget.item.icon,
                    color: sel ? AppConstants.accent : AppConstants.textSecondary,
                    size: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: sel ? AppConstants.accent : AppConstants.textMuted,
                fontSize: sel ? 10 : 9,
                fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                letterSpacing: sel ? 0.4 : 0,
              ),
              child: Text(widget.item.label),
            ),
          ],
        ),
      ),
    );
  }
}

