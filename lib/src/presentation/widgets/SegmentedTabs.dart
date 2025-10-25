// lib/src/presentation/components/segmented_tabs.dart
import 'package:flutter/material.dart';

class SegmentedTabs extends StatelessWidget implements PreferredSizeWidget {
  final List<String> labels;
  final TabController controller;
  const SegmentedTabs(
      {super.key, required this.labels, required this.controller});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.all(8),
      child: TabBar(
        controller: controller,
        tabs: labels
            .map((t) => Tab(
                child: Text(t,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w900))))
            .toList(),
        indicator: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(14),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.black87,
        indicatorSize: TabBarIndicatorSize.tab,
        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
        splashFactory: NoSplash.splashFactory,
        overlayColor: MaterialStateProperty.all(Colors.transparent),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F2F4),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
