import 'package:flutter/material.dart';

class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;

  const SectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
