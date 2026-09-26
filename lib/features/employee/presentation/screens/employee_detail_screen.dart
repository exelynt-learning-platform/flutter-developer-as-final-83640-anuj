import 'package:flutter/material.dart';

import '../../domain/entities/employee_entity.dart';
import 'employee_form_screen.dart';

class EmployeeDetailScreen extends StatelessWidget {
  const EmployeeDetailScreen({super.key, required this.employee});

  final EmployeeEntity employee;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => EmployeeFormScreen(employee: employee)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: (employee.avatarUrl?.isNotEmpty ?? false)
                      ? NetworkImage(employee.avatarUrl!)
                      : null,
                  child: (employee.avatarUrl?.isNotEmpty ?? false)
                      ? null
                      : Text(
                          employee.name.isNotEmpty ? employee.name[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 28),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(employee.name, style: Theme.of(context).textTheme.titleLarge),
              ),
              const SizedBox(height: 24),
              _DetailRow(icon: Icons.badge_outlined, label: 'ID', value: employee.id),
              _DetailRow(icon: Icons.email_outlined, label: 'Email', value: employee.email),
              _DetailRow(icon: Icons.phone_outlined, label: 'Mobile', value: employee.mobile),
              _DetailRow(icon: Icons.public_outlined, label: 'Country', value: employee.country),
              _DetailRow(icon: Icons.map_outlined, label: 'State', value: employee.state),
              _DetailRow(
                icon: Icons.location_city_outlined,
                label: 'District',
                value: employee.district,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelSmall),
                Text(value.isEmpty ? '—' : value, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
