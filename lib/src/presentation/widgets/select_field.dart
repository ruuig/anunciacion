import 'package:flutter/material.dart';

/// ----------------------------------------------------
///  SELECTOR BONITO (FIELD + BOTTOM SHEET CON BÚSQUEDA)
/// ----------------------------------------------------
class SelectField<T> extends StatelessWidget {
  final String label;
  final String placeholder;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T> onSelected;
  final bool enabled;

  const SelectField({
    super.key,
    required this.label,
    required this.placeholder,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onSelected,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final text = value == null ? placeholder : itemLabel(value as T);
    final isPlaceholder = value == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        InkWell(
          onTap: !enabled
              ? null
              : () async {
                  final picked = await showModalBottomSheet<T>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    backgroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (_) => SelectSheet<T>(
                      title: label,
                      items: items,
                      itemLabel: itemLabel,
                      initial: value,
                    ),
                  );
                  if (picked != null) onSelected(picked);
                },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F5F7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE6E7EA)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          isPlaceholder ? FontWeight.w500 : FontWeight.w700,
                      color: isPlaceholder ? Colors.black54 : Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    color: Colors.black87),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class SelectSheet<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final String Function(T) itemLabel;
  final T? initial;

  const SelectSheet({
    super.key,
    required this.title,
    required this.items,
    required this.itemLabel,
    this.initial,
  });

  @override
  State<SelectSheet<T>> createState() => _SelectSheetState<T>();
}

class _SelectSheetState<T> extends State<SelectSheet<T>> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.items
        .where((e) =>
            widget.itemLabel(e).toLowerCase().contains(query.toLowerCase()))
        .toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .9,
      minChildSize: .5,
      maxChildSize: .95,
      builder: (context, controller) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(2)),
              ),
              Text(widget.title,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              TextField(
                onChanged: (v) => setState(() => query = v),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Buscar…',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: const Color(0xFFF4F5F7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  controller: controller,
                  itemBuilder: (context, i) {
                    final e = filtered[i];
                    final selected =
                        widget.initial != null && e == widget.initial;
                    return ListTile(
                      onTap: () => Navigator.pop<T>(context, e),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      title: Text(
                        widget.itemLabel(e),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              selected ? FontWeight.w800 : FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: selected
                          ? const Icon(Icons.check,
                              color: Colors.black, size: 22)
                          : null,
                    );
                  },
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: Color(0xFFECEDEF)),
                  itemCount: filtered.length,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
