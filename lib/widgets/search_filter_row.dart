import 'package:flutter/material.dart';

class SearchFilterRow extends StatelessWidget {
  final void Function(String) onSearch;
  final List<String> types;
  final String selectedType;
  final void Function(String) onTypeChanged;

  const SearchFilterRow({
    super.key,
    required this.onSearch,
    required this.types,
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextField(
            onChanged: onSearch,
            decoration: const InputDecoration(
              labelText: "Search Resources",
              hintText: "Search by item / description / city...",
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: selectedType,
            decoration: const InputDecoration(labelText: "Type Filter"),
            items: types.map((t) {
              return DropdownMenuItem(
                value: t,
                child: Text(t),
              );
            }).toList(),
            onChanged: (v) {
              if (v != null) onTypeChanged(v);
            },
          ),
        )
      ],
    );
  }
}