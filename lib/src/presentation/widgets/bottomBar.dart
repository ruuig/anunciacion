import 'package:flutter/material.dart';

class BottomBar extends StatelessWidget {
  const BottomBar({
    super.key,
    required this.index,
    required this.onChanged,
  });

  final int index;
  final ValueChanged<int> onChanged;

  static const Color selected = Color(0xFF60A5FA); // celestito
  static const Color unselected = Color(0xFF9CA3AF);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(15, 0, 0, 0).withOpacity(0.07),
              blurRadius: 24,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _Item(
              icon: Icons.home_rounded,
              label: 'Inicio',
              selected: index == 0,
              onTap: () => onChanged(0),
            ),
            _Item(
              icon: Icons.search_rounded,
              label: 'Buscar',
              selected: index == 1,
              onTap: () => onChanged(1),
            ),
            _Item(
              icon: Icons.bar_chart_rounded,
              label: 'Reportes',
              selected: index == 2,
              onTap: () => onChanged(2),
            ),
            _Item(
              icon: Icons.person_rounded,
              label: 'Perfil',
              selected: index == 3,
              onTap: () => onChanged(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
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
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon,
              size: 26,
              color: selected ? BottomBar.selected : BottomBar.unselected),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: selected ? BottomBar.selected : BottomBar.unselected,
            ),
          ),
        ],
      ),
    );
  }
}
