import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/employee_entity.dart';
import '../providers/country_provider.dart';
import '../providers/employee_provider.dart';

class EmployeeFormScreen extends StatefulWidget {
  const EmployeeFormScreen({super.key, this.employee});

  final EmployeeEntity? employee;

  bool get isEditing => employee != null;

  @override
  State<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends State<EmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _mobileController;
  late final TextEditingController _stateController;
  late final TextEditingController _districtController;
  String? _selectedCountry;

  @override
  void initState() {
    super.initState();
    final employee = widget.employee;
    _nameController = TextEditingController(text: employee?.name ?? '');
    _emailController = TextEditingController(text: employee?.email ?? '');
    _mobileController = TextEditingController(text: employee?.mobile ?? '');
    _stateController = TextEditingController(text: employee?.state ?? '');
    _districtController = TextEditingController(text: employee?.district ?? '');
    _selectedCountry = employee?.country;
    context.read<CountryProvider>().loadCountries();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _stateController.dispose();
    _districtController.dispose();
    super.dispose();
  }

  Future<void> _submit(EmployeeProvider employeeProvider) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCountry == null || _selectedCountry!.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please select a country')));
      return;
    }

    final employee = EmployeeEntity(
      id: widget.employee?.id ?? '',
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      mobile: _mobileController.text.trim(),
      country: _selectedCountry!,
      state: _stateController.text.trim(),
      district: _districtController.text.trim(),
      avatarUrl: widget.employee?.avatarUrl,
    );

    final success = widget.isEditing
        ? await employeeProvider.editEmployee(employee)
        : await employeeProvider.addEmployee(employee);

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.isEditing ? 'Employee updated' : 'Employee added')),
      );
      Navigator.of(context).pop(true);
    } else if (employeeProvider.errorMessage != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(employeeProvider.errorMessage!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final employeeProvider = context.watch<EmployeeProvider>();
    final countryProvider = context.watch<CountryProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? 'Edit employee' : 'Add employee')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  label: 'Name',
                  controller: _nameController,
                  prefixIcon: Icons.person_outline,
                  textInputAction: TextInputAction.next,
                  validator: (v) => Validators.required(v, field: 'Name'),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Email',
                  controller: _emailController,
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: Validators.email,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Mobile',
                  controller: _mobileController,
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 10,
                  validator: Validators.mobile,
                ),
                const SizedBox(height: 16),
                _buildCountryField(countryProvider),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'State',
                  controller: _stateController,
                  prefixIcon: Icons.map_outlined,
                  textInputAction: TextInputAction.next,
                  validator: (v) => Validators.required(v, field: 'State'),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'District',
                  controller: _districtController,
                  prefixIcon: Icons.location_city_outlined,
                  textInputAction: TextInputAction.done,
                  validator: (v) => Validators.required(v, field: 'District'),
                ),
                const SizedBox(height: 28),
                PrimaryButton(
                  label: widget.isEditing ? 'Save changes' : 'Add employee',
                  isLoading: employeeProvider.isMutating,
                  onPressed: () => _submit(employeeProvider),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCountryField(CountryProvider countryProvider) {
    if (countryProvider.status == CountryListStatus.loading) {
      return const LinearProgressIndicator();
    }
    if (countryProvider.status == CountryListStatus.error) {
      return Text(
        'Could not load countries: ${countryProvider.errorMessage}',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      );
    }
    final names = countryProvider.countries.map((c) => c.name).toSet().toList()..sort();
    if (_selectedCountry != null && !names.contains(_selectedCountry)) {
      names.add(_selectedCountry!);
    }
    return DropdownButtonFormField<String>(
      initialValue: _selectedCountry,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Country',
        prefixIcon: Icon(Icons.public_outlined),
        filled: true,
      ),
      items: names
          .map((name) => DropdownMenuItem(
                value: name,
                child: Text(name, overflow: TextOverflow.ellipsis),
              ))
          .toList(),
      onChanged: (value) => setState(() => _selectedCountry = value),
      validator: (value) => value == null || value.isEmpty ? 'Country is required' : null,
    );
  }
}
