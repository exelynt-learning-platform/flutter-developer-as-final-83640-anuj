import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/employee_entity.dart';
import '../providers/employee_provider.dart';
import '../widgets/employee_card.dart';
import '../widgets/filter_sheet.dart';
import 'employee_detail_screen.dart';
import 'employee_form_screen.dart';

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    context.read<EmployeeProvider>().fetchEmployees();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _runSearch(EmployeeProvider provider, String id) {
    _searchFocusNode.unfocus();
    provider.searchById(id);
  }

  void _clearSearch(EmployeeProvider provider) {
    _searchController.clear();
    provider.clearSearch();
  }

  Future<void> _confirmLogout(AuthProvider auth) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await auth.logOut();
    }
  }

  Future<void> _confirmDelete(EmployeeProvider provider, EmployeeEntity employee) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete employee'),
        content: Text('Are you sure you want to delete ${employee.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final success = await provider.removeEmployee(employee.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? '${employee.name} deleted' : provider.errorMessage ?? 'Delete failed',
        ),
      ),
    );
  }

  Future<void> _openFilterSheet(EmployeeProvider provider) async {
    final result = await showEmployeeFilterSheet(
      context,
      initialField: provider.filterField,
      initialQuery: provider.filterQuery,
    );
    if (result != null) {
      provider.setFilter(result.field, result.query);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployeeProvider>();
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.themeMode == ThemeMode.dark ||
        (themeProvider.themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employees'),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            tooltip: 'Toggle theme',
            onPressed: themeProvider.toggleTheme,
          ),
          IconButton(
            icon: Badge(
              isLabelVisible: provider.isFilterActive,
              child: const Icon(Icons.filter_list),
            ),
            tooltip: 'Filter',
            onPressed: () => _openFilterSheet(provider),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () => _confirmLogout(auth),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _buildSearchField(provider),
          ),
          Expanded(child: _buildBody(provider)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add employee',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const EmployeeFormScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchField(EmployeeProvider provider) {
    return LayoutBuilder(
      builder: (context, constraints) => RawAutocomplete<EmployeeEntity>(
        textEditingController: _searchController,
        focusNode: _searchFocusNode,
        displayStringForOption: (employee) => employee.id,
        optionsBuilder: (value) => provider.idSuggestions(value.text),
        onSelected: (employee) => _runSearch(provider, employee.id),
        fieldViewBuilder: (context, controller, focusNode, _) => TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search employee by ID',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) => value.text.isNotEmpty || provider.isSearchingById
                  ? IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Clear search',
                      onPressed: () => _clearSearch(provider),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          onChanged: (value) {
            if (value.trim().isEmpty && provider.isSearchingById) provider.clearSearch();
          },
          onSubmitted: (value) => _runSearch(provider, value),
        ),
        optionsViewBuilder: (context, onSelected, options) => _IdSuggestions(
          width: constraints.maxWidth,
          query: _searchController.text.trim(),
          options: options.toList(),
          onSelected: onSelected,
        ),
      ),
    );
  }

  Widget _buildBody(EmployeeProvider provider) {
    if (provider.isSearchingById) {
      if (provider.isSearchInFlight) return const LoadingView();
      if (provider.searchResult != null) {
        final employee = provider.searchResult!;
        return ListView(
          padding: const EdgeInsets.only(top: 8, bottom: 96),
          children: [
            EmployeeCard(
              employee: employee,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => EmployeeDetailScreen(employee: employee)),
              ),
              onEdit: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => EmployeeFormScreen(employee: employee)),
              ),
              onDelete: () => _confirmDelete(provider, employee),
            ),
          ],
        );
      }
      return EmptyView(message: provider.searchError ?? 'No employee found', icon: Icons.search_off);
    }

    switch (provider.status) {
      case EmployeeListStatus.initial:
      case EmployeeListStatus.loading:
        return const LoadingView();
      case EmployeeListStatus.error:
        return ErrorView(
          message: provider.errorMessage ?? 'Something went wrong',
          onRetry: provider.fetchEmployees,
        );
      case EmployeeListStatus.loaded:
        final employees = provider.employees;
        return RefreshIndicator(
          onRefresh: provider.refresh,
          child: Column(
            children: [
              if (provider.isShowingCache && provider.errorMessage != null)
                Container(
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.errorContainer,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    provider.errorMessage!,
                    style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                  ),
                ),
              if (provider.isFilterActive)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      Flexible(
                        child: InputChip(
                          avatar: const Icon(Icons.filter_list, size: 18),
                          label: Text(
                            '${provider.filterField!.label}: "${provider.filterQuery.trim()}"',
                            overflow: TextOverflow.ellipsis,
                          ),
                          onPressed: () => _openFilterSheet(provider),
                          onDeleted: provider.clearFilter,
                          deleteButtonTooltipMessage: 'Clear filter',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${employees.length} ${employees.length == 1 ? 'result' : 'results'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: employees.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 120),
                          EmptyView(
                            message: provider.isFilterActive
                                ? 'No employees match this ${provider.filterField!.label.toLowerCase()} filter'
                                : 'No employees found',
                          ),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(top: 8, bottom: 96),
                        itemCount: employees.length,
                        itemBuilder: (context, index) {
                          final employee = employees[index];
                          return EmployeeCard(
                            employee: employee,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => EmployeeDetailScreen(employee: employee),
                              ),
                            ),
                            onEdit: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => EmployeeFormScreen(employee: employee),
                              ),
                            ),
                            onDelete: () => _confirmDelete(provider, employee),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
    }
  }
}

class _IdSuggestions extends StatelessWidget {
  const _IdSuggestions({
    required this.width,
    required this.query,
    required this.options,
    required this.onSelected,
  });

  final double width;
  final String query;
  final List<EmployeeEntity> options;
  final AutocompleteOnSelected<EmployeeEntity> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Material(
          elevation: 6,
          shadowColor: Colors.black26,
          color: colors.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: width, maxHeight: 300),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 4),
              shrinkWrap: true,
              itemCount: options.length,
              separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
              itemBuilder: (context, index) {
                final employee = options[index];
                final highlighted = AutocompleteHighlightedOption.of(context) == index;
                return ListTile(
                  tileColor: highlighted ? colors.primary.withValues(alpha: 0.08) : null,
                  leading: CircleAvatar(
                    backgroundColor: colors.primaryContainer,
                    foregroundColor: colors.onPrimaryContainer,
                    child: const Icon(Icons.person_outline),
                  ),
                  title: Text.rich(_highlightId(employee.id, theme)),
                  subtitle: Text(
                    '${employee.name} · ${employee.email}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => onSelected(employee),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  TextSpan _highlightId(String id, ThemeData theme) {
    final match = id.indexOf(query);
    final base = theme.textTheme.bodyLarge;
    final bold = base?.copyWith(fontWeight: FontWeight.w800, color: theme.colorScheme.primary);
    if (query.isEmpty || match < 0) return TextSpan(text: 'ID $id', style: base);
    return TextSpan(
      style: base,
      children: [
        TextSpan(text: 'ID ${id.substring(0, match)}'),
        TextSpan(text: query, style: bold),
        TextSpan(text: id.substring(match + query.length)),
      ],
    );
  }
}
