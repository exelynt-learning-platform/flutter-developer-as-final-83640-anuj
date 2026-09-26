import 'package:flutter/material.dart';

import '../providers/employee_provider.dart';

class FilterSheetResult {
  const FilterSheetResult(this.field, this.query);

  final EmployeeFilterField? field;
  final String query;
}

Future<FilterSheetResult?> showEmployeeFilterSheet(
  BuildContext context, {
  required EmployeeFilterField? initialField,
  required String initialQuery,
}) {
  return showModalBottomSheet<FilterSheetResult>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _FilterSheet(initialField: initialField, initialQuery: initialQuery),
  );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initialField, required this.initialQuery});

  final EmployeeFilterField? initialField;
  final String initialQuery;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late EmployeeFilterField _field;
  late final TextEditingController _queryController;

  @override
  void initState() {
    super.initState();
    _field = widget.initialField ?? EmployeeFilterField.name;
    _queryController = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  void _apply() {
    Navigator.of(context).pop(FilterSheetResult(_field, _queryController.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Filter employees', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          DropdownButtonFormField<EmployeeFilterField>(
            initialValue: _field,
            decoration: const InputDecoration(labelText: 'Filter by', filled: true),
            items: EmployeeFilterField.values
                .map((f) => DropdownMenuItem(value: f, child: Text(f.label)))
                .toList(),
            onChanged: (value) => setState(() => _field = value ?? _field),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _queryController,
            autofocus: true,
            keyboardType: switch (_field) {
              EmployeeFilterField.email => TextInputType.emailAddress,
              EmployeeFilterField.mobile => TextInputType.phone,
              _ => TextInputType.text,
            },
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(labelText: '${_field.label} contains', filled: true),
            onSubmitted: (_) => _apply(),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      Navigator.of(context).pop(const FilterSheetResult(null, '')),
                  child: const Text('Clear'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _apply,
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
