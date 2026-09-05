import 'package:flutter/material.dart' as material;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:optic/app_shell.dart';
import 'package:optic/data/data_provider.dart';
import 'package:optic/data/client_repository.dart';
import 'package:optic/helpers/breakpoint.dart';
import 'package:optic/helpers/empty_state.dart';
import 'package:optic/helpers/nav_items.dart';
import 'package:optic/helpers/client_list_tile.dart';
import 'package:optic/helpers/clients_table.dart';
import 'package:optic/localization/app_strings.dart';
import 'package:optic/models/client.dart';

/// Clients list: search, an "Add client" action, and a tap-through to
/// each client's file (`/clients/:id`). Data comes from your real
/// [DataProvider] via [ProviderClientRepository] — same bridge pattern as
/// [DashboardScreen]/[CalendarScreen], so once `DataProvider` talks to a
/// real backend, nothing here needs to change.
class ClientsScreen extends StatelessWidget {
  const ClientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();
    final repository = ProviderClientRepository(dataProvider);

    return AppShell(
      navItems: (context) => buildAppNavItems(context, NavRoute.clients),
      bodyBuilder: (context, breakpoint) =>
          _ClientsBody(breakpoint: breakpoint, repository: repository),
    );
  }
}

class _ClientsBody extends StatefulWidget {
  final Breakpoint breakpoint;
  final ClientRepository repository;

  const _ClientsBody({required this.breakpoint, required this.repository});

  @override
  State<_ClientsBody> createState() => _ClientsBodyState();
}

class _ClientsBodyState extends State<_ClientsBody> {
  final _searchController = material.TextEditingController();
  List<Client> _clients = const [];
  bool _isLoading = true;

  // View toggle — table view is desktop/tablet only (see build(), which
  // forces card view on mobile regardless of this flag; there's just
  // nowhere sensible for a 5-column table to go on a phone width).
  bool _isTableView = false;

  // null == "All" for both filters.
  String? _genderFilter;
  String? _insuranceFilter; // 'has' | 'none'
  String? _statusFilter; // 'active' | 'inactive'

  static const int _pageSize = 8;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    // Any search edit invalidates the current page (e.g. page 3 of an
    // unfiltered list may not exist once a search narrows the results),
    // so it resets alongside the existing "just rebuild" listener.
    _searchController.addListener(() => setState(() => _currentPage = 0));
    _loadData();
  }

  @override
  void didUpdateWidget(covariant _ClientsBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new repository instance means DataProvider notified (e.g. a client
    // was added) — re-fetch so the list stays current.
    if (oldWidget.repository != widget.repository) {
      _loadData();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final clients = await widget.repository.fetchClients();
    if (!mounted) return;
    setState(() {
      _clients = clients;
      _isLoading = false;
    });
  }

  void _addClient() => context.go('/clients/new');

  List<Client> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    return _clients.where((p) {
      if (query.isNotEmpty) {
        final haystack = [
          p.firstName,
          p.lastName,
          p.fileNumber,
          p.nationalId,
          p.phone,
          p.email,
        ].join(' ').toLowerCase();
        if (!haystack.contains(query)) return false;
      }
      if (_genderFilter != null && p.gender != _genderFilter) return false;
      if (_insuranceFilter == 'has' && p.insurance.isEmpty) return false;
      if (_insuranceFilter == 'none' && p.insurance.isNotEmpty) return false;
      if (_statusFilter != null && p.status != _statusFilter) return false;
      return true;
    }).toList();
  }

  bool get _hasActiveFilters =>
      _genderFilter != null || _insuranceFilter != null || _statusFilter != null;

  void _resetFilters() {
    setState(() {
      _genderFilter = null;
      _insuranceFilter = null;
      _statusFilter = null;
      _currentPage = 0;
    });
  }

  List<Client> _paged(List<Client> filtered) {
    final maxPage = (filtered.length / _pageSize).ceil() - 1;
    if (_currentPage > maxPage) {
      // Filters/search just shrank the result set out from under the
      // current page — clamp rather than show an empty page with working
      // "previous" controls that look broken.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _currentPage = maxPage.clamp(0, 1 << 30));
      });
    }
    final start = _currentPage * _pageSize;
    if (start >= filtered.length) return const [];
    return filtered.skip(start).take(_pageSize).toList();
  }

  Widget _viewToggle() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        material.Tooltip(
          message: AppStrings.clientsViewCards,
          child: Button(
            style: _isTableView
                ? const ButtonStyle.ghost()
                : const ButtonStyle.primary(),
            onPressed: () => setState(() => _isTableView = false),
            child: const Icon(Icons.view_agenda_outlined, size: 16),
          ),
        ),
        const SizedBox(width: 4),
        material.Tooltip(
          message: AppStrings.clientsViewTable,
          child: Button(
            style: _isTableView
                ? const ButtonStyle.primary()
                : const ButtonStyle.ghost(),
            onPressed: () => setState(() => _isTableView = true),
            child: const Icon(Icons.table_rows_outlined, size: 16),
          ),
        ),
      ],
    );
  }

  Widget _filterBar() {
    final genderOptions = <String?, String>{
      null: AppStrings.clientsFilterAllGenders,
      'Male': AppStrings.addClientGenderMale,
      'Female': AppStrings.addClientGenderFemale,
      'Other': AppStrings.addClientGenderOther,
    };
    final insuranceOptions = <String?, String>{
      null: AppStrings.clientsFilterAllInsurance,
      'has': AppStrings.clientsFilterHasInsurance,
      'none': AppStrings.clientsFilterNoInsurance,
    };
    final statusOptions = <String?, String>{
      null: AppStrings.clientsFilterAllStatuses,
      'active': AppStrings.clientStatusActive,
      'inactive': AppStrings.clientStatusInactive,
    };

    Widget dropdown<T>({
      required T? value,
      required Map<T?, String> options,
      required void Function(T?) onChanged,
    }) {
      return SizedBox(
        width: 190,
        child: material.DropdownButtonFormField<T>(
          value: value,
          isDense: true,
          // Same fix as add_record_dialog.dart — lets the ellipsis on
          // long option labels actually take effect instead of
          // overflowing the fixed-width field on narrow screens.
          isExpanded: true,
          items: [
            for (final entry in options.entries)
              material.DropdownMenuItem<T>(
                value: entry.key,
                child: Text(
                  entry.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (v) => setState(() {
            onChanged(v);
            _currentPage = 0;
          }),
          decoration: const material.InputDecoration(
            border: material.OutlineInputBorder(),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Icon(Icons.filter_list, size: 18, color: Theme.of(context).colorScheme.mutedForeground),
        dropdown<String>(
          value: _genderFilter,
          options: genderOptions,
          onChanged: (v) => _genderFilter = v,
        ),
        dropdown<String>(
          value: _insuranceFilter,
          options: insuranceOptions,
          onChanged: (v) => _insuranceFilter = v,
        ),
        dropdown<String>(
          value: _statusFilter,
          options: statusOptions,
          onChanged: (v) => _statusFilter = v,
        ),
        if (_hasActiveFilters)
          Button.link(
            onPressed: _resetFilters,
            child: Text(AppStrings.clientsResetFilter),
          ),
      ],
    );
  }

  Widget _pagination(int totalCount) {
    if (totalCount <= _pageSize) return const SizedBox.shrink();
    final maxPage = (totalCount / _pageSize).ceil() - 1;
    final start = _currentPage * _pageSize + 1;
    final end = ((_currentPage + 1) * _pageSize).clamp(0, totalCount);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            AppStrings.clientsShowingRange(start, end, totalCount),
          ).muted().small(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Button(
                style: const ButtonStyle.ghost(),
                onPressed: _currentPage > 0
                    ? () => setState(() => _currentPage -= 1)
                    : null,
                child: const Icon(Icons.chevron_left, size: 18),
              ),
              Button(
                style: const ButtonStyle.ghost(),
                onPressed: _currentPage < maxPage
                    ? () => setState(() => _currentPage += 1)
                    : null,
                child: const Icon(Icons.chevron_right, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _searchField() {
    return TextField(
      controller: _searchController,
      placeholder: Text(AppStrings.clientsSearchPlaceholder),
      features: [
        InputFeature.leading(
          StatedWidget.builder(
            builder: (context, states) {
              if (states.hovered) {
                return const Icon(Icons.search);
              }
              return const Icon(Icons.search).iconMutedForeground();
            },
          ),
          visibility: InputFeatureVisibility.textEmpty,
        ),
        InputFeature.clear(
          visibility:
              (InputFeatureVisibility.textNotEmpty &
                  InputFeatureVisibility.focused) |
              InputFeatureVisibility.hovered,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: material.CircularProgressIndicator());
    }

    final filtered = _filtered;
    // Table view (and its filter bar/pagination) is desktop/tablet only —
    // forced off on mobile regardless of the toggle state, since a phone
    // has nowhere sensible to put a 5-column table.
    final showTable = _isTableView && widget.breakpoint != Breakpoint.mobile;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(AppStrings.navClients).large().bold()),
              const SizedBox(width: 12),
              if (widget.breakpoint != Breakpoint.mobile) ...[
                _viewToggle(),
                const SizedBox(width: 8),
              ],
              Button.outline(
                onPressed: _addClient,
                leading: const Icon(Icons.person_add_alt_outlined, size: 16),
                child: Text(AppStrings.clientsAddButton),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(AppStrings.clientsCount(_clients.length)).muted(),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: _searchField()),
          if (showTable) ...[
            const SizedBox(height: 16),
            _filterBar(),
          ],
          const SizedBox(height: 16),
          if (_clients.isEmpty)
            EmptyState(
              icon: Icons.people_outline,
              title: AppStrings.clientsEmptyTitle,
              subtitle: AppStrings.clientsEmptySubtitle,
            )
          else if (filtered.isEmpty)
            EmptyState(
              icon: Icons.search_off,
              title: AppStrings.clientsNoResultsTitle,
              subtitle: AppStrings.clientsNoResultsSubtitle,
            )
          else if (showTable) ...[
            ClientsTable(
              clients: _paged(filtered),
              onTap: (p) => context.go('/clients/${p.id}'),
            ),
            _pagination(filtered.length),
          ] else
            Column(
              children: filtered
                  .map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ClientListTile(
                        client: p,
                        onTap: () => context.go('/clients/${p.id}'),
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}
