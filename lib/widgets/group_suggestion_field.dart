import 'package:flutter/material.dart';

class GroupSuggestionField extends StatelessWidget {
  const GroupSuggestionField({
    super.key,
    required this.initialValue,
    required this.suggestions,
    required this.onChanged,
    this.requiredField = false,
    this.hintText = '例：AQUA PLANET',
  });

  final String initialValue;
  final List<String> suggestions;
  final ValueChanged<String> onChanged;
  final bool requiredField;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    final uniqueSuggestions = suggestions
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return Autocomplete<String>(
      initialValue: TextEditingValue(text: initialValue),
      optionsBuilder: (TextEditingValue value) {
        final query = value.text.trim().toLowerCase();
        if (query.isEmpty) {
          return uniqueSuggestions.take(6);
        }

        return uniqueSuggestions
            .where((option) => option.toLowerCase().contains(query))
            .take(6);
      },
      displayStringForOption: (option) => option,
      onSelected: onChanged,
      fieldViewBuilder: (
        context,
        controller,
        focusNode,
        onFieldSubmitted,
      ) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          onFieldSubmitted: (_) => onFieldSubmitted(),
          decoration: InputDecoration(
            labelText: 'グループ名',
            hintText: hintText,
            prefixIcon: const Icon(Icons.groups_outlined),
            suffixIcon: uniqueSuggestions.isEmpty
                ? null
                : const Icon(Icons.arrow_drop_down_rounded),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          validator: requiredField
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'グループ名を入力してください';
                  }
                  return null;
                }
              : null,
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        final optionList = options.toList(growable: false);
        if (optionList.isEmpty) return const SizedBox.shrink();

        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(14),
            color: Colors.white,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 394,
                maxHeight: 260,
              ),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 6),
                shrinkWrap: true,
                itemCount: optionList.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final option = optionList[index];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.history_rounded, size: 19),
                    title: Text(option),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
