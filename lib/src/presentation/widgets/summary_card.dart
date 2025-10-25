import 'package:flutter/material.dart';

/// Generic summary widget to display statistics in a row format
class SummaryCard extends StatelessWidget {
  final List<SummaryItem> items;
  final MainAxisAlignment mainAxisAlignment;

  const SummaryCard({
    super.key,
    required this.items,
    this.mainAxisAlignment = MainAxisAlignment.spaceEvenly,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      children: items.map((item) => _SummaryCell(
        label: item.label,
        value: item.value,
        labelStyle: item.labelStyle,
        valueStyle: item.valueStyle,
      )).toList(),
    );
  }
}

/// Individual summary item data
class SummaryItem {
  final String label;
  final int value;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  const SummaryItem({
    required this.label,
    required this.value,
    this.labelStyle,
    this.valueStyle,
  });
}

/// Individual cell widget for summary display
class _SummaryCell extends StatelessWidget {
  final String label;
  final int value;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  const _SummaryCell({
    required this.label,
    required this.value,
    this.labelStyle,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: labelStyle ?? const TextStyle(
            fontSize: 14,
            color: Colors.black54,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$value',
          style: valueStyle ?? const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
