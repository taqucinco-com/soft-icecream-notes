import 'package:flutter/material.dart';

/// Figma 01/02/05フレーム共通の BottomNav（メモ一覧 / メモ作成(+) / 設定）。
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onCreateTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onCreateTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Column(
        children: [
          const Divider(height: 1),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _NavItem(
                  icon: Icons.list_alt,
                  label: 'メモ一覧',
                  selected: currentIndex == 0,
                  onTap: () => onTabSelected(0),
                ),
                _CreateButton(onTap: onCreateTap),
                _NavItem(
                  icon: Icons.settings,
                  label: '設定',
                  selected: currentIndex == 1,
                  onTap: () => onTabSelected(1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
    );
  }
}

class _CreateButton extends StatelessWidget {
  const _CreateButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 52,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.add,
          color: Theme.of(context).colorScheme.onPrimary,
          size: 28,
        ),
      ),
    );
  }
}
