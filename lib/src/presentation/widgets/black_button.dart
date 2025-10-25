import 'package:flutter/material.dart';

class BlackButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;

  const BlackButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 8),
        ],
        Text(
          busy ? 'Guardando…' : label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );

    return ElevatedButton(
      onPressed: busy ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        disabledBackgroundColor: Colors.black.withOpacity(.4),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      child: busy
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2),
            )
          : child,
    );
  }
}
