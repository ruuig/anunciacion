import 'package:flutter/material.dart';

/// Generic empty state widget for when there's no data to display
class EmptyState extends StatelessWidget {
  final String title;
  final String? description;
  final Widget? icon;
  final double? verticalPadding;

  const EmptyState({
    super.key,
    required this.title,
    this.description,
    this.icon,
    this.verticalPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: verticalPadding ?? 28),
      child: Column(
        children: [
          const SizedBox(height: 10),
          CircleAvatar(
            radius: 34,
            backgroundColor: const Color(0xFFF0F1F3),
            child: icon ?? const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.black45,
              size: 36,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (description != null) ...[
            const SizedBox(height: 6),
            Text(
              description!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
