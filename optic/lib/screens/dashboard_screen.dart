import 'package:optic/helpers/add_appointment_dialog.dart';
import 'package:optic/helpers/dashboard_hero.dart';
import 'package:optic/helpers/dashboard_sections.dart';
import 'package:optic/helpers/dashboard_widgets.dart';
import 'package:optic/constants.dart';
import 'package:optic/models/pending_task.dart';
import 'package:optic/models/dashboard_widget_id.dart';
import 'package:optic/models/dashboard_date_range.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:optic/app_shell.dart';
import 'package:optic/helpers/breakpoint.dart';
import 'package:optic/helpers/nav_items.dart';
import 'package:optic/localization/app_strings.dart';
import 'package:optic/data/data_provider.dart';
import 'package:optic/controllers/dashboard_prefs_controller.dart';
import 'package:optic/data/dashboard_repository.dart';
import '../models/dashboard_appointment.dart';

/// The store's "operational center" dashboard (Aug 2026 minimalist redesign):
/// a greeting + global date-range filter header, an always-on 4-tile KPI
/// row, then four toggleable sections in canonical `DashboardWidgetId` order
/// — Attention, Tasks+Appointments, Sales+Activity, Inventory+Quick Actions.
/// Which sections show is controlled from Settings → Dashboard (see
/// [DashboardPrefsController]); this screen just walks
/// [DashboardWidgetId.values] and renders whichever are switched on.
///
/// Stateless on purpose — all the sidebar/drawer/resize behavior lives in
/// [AppShell] (shared by every screen), and this widget just supplies the
/// dashboard's content to it. Data comes from your real [DataProvider] via
/// [ProviderDashboardRepository] — `context.watch<DataProvider>()` means
/// this rebuilds (and re-fetches) whenever `DataProvider.notifyListeners()`
/// fires, e.g. after `addAppointment(...)`.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();
    final repository = ProviderDashboardRepository(dataProvider);

    return AppShell(
      navItems: (context) => buildAppNavItems(context, NavRoute.dashboard),
      bodyBuilder: (context, breakpoint) => _DashboardBody(
        breakpoint: breakpoint,
        repository: repository,
      ),
    );
  }
}

class _DashboardBody extends StatefulWidget {
  final Breakpoint breakpoint;
  final DashboardRepository repository;

  const _DashboardBody({required this.breakpoint, required this.repository});

  @override
  State<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<_DashboardBody> {
  List<DashboardAppointment> _allAppointments = const [];
  List<PendingTask> _pendingTasks = const [];
  bool _isLoading = true;

  // The global date-range filter (brief point 13) — drives the KPI row and
  // Sales Overview panel together instead of each picking its own range.
  DashboardDateRangeKind _rangeKind = DashboardDateRangeKind.today;
  DateTime? _customStart;
  DateTime? _customEnd;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant _DashboardBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new repository instance means DataProvider notified — re-fetch so
    // e.g. DataProvider.addAppointment(...) shows up without navigating
    // away and back.
    if (oldWidget.repository != widget.repository) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final appointments = await widget.repository.fetchAppointments();
    final pendingTasks = await widget.repository.fetchPendingTasks();
    if (!mounted) return;
    setState(() {
      _allAppointments = appointments;
      _pendingTasks = pendingTasks;
      _isLoading = false;
    });
  }

  Future<void> _pickCustomRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await material.showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
      initialDateRange: (_customStart != null && _customEnd != null)
          ? material.DateTimeRange(start: _customStart!, end: _customEnd!)
          : material.DateTimeRange(
              start: now.subtract(const Duration(days: 7)),
              end: now,
            ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _rangeKind = DashboardDateRangeKind.custom;
      _customStart = picked.start;
      _customEnd = picked.end;
    });
  }

  void _onRangeChanged(DashboardDateRangeKind kind) {
    if (kind == DashboardDateRangeKind.custom) {
      _pickCustomRange(context);
    } else {
      setState(() => _rangeKind = kind);
    }
  }

  List<DashboardAppointment> _upcomingAppointments(DashboardDateRange range) {
    final list =
        _allAppointments
            .where(
              (a) =>
                  a.status == AppointmentStatus.scheduled &&
                  range.contains(a.start),
            )
            .toList()
          ..sort((a, b) => a.start.compareTo(b.start));
    return list.take(6).toList();
  }

  @override
  Widget build(BuildContext context) {
    final dashboardPrefs = context.watch<DashboardPrefsController>();
    if (_isLoading || !dashboardPrefs.isLoaded) {
      return const Center(child: material.CircularProgressIndicator());
    }

    final dataProvider = context.watch<DataProvider>();
    final range = DashboardDateRange.resolve(
      _rangeKind,
      customStart: _customStart,
      customEnd: _customEnd,
    );

    // Walked in `DashboardWidgetId`'s own declaration order — every entry
    // below is skipped outright unless `dashboardPrefs.isEnabled(...)`, so a
    // section's absence here costs nothing (no reserved space, no fetch).
    final sections = <Widget>[];
    void addSection(Widget child) {
      if (sections.isNotEmpty) {
        sections.add(const SizedBox(height: DashboardTokens.sectionGap));
      }
      sections.add(child);
    }

    if (dashboardPrefs.isEnabled(DashboardWidgetId.attention)) {
      addSection(
        AttentionSection(
          dataProvider: dataProvider,
          onOrdersTap: () => context.go(NavRoute.orders.path),
          onLowStockTap: () => context.go(NavRoute.frameInventory.path),
          onOverdueTap: () => context.go(NavRoute.billing.path),
          onUnconfirmedTap: () => context.go(NavRoute.calendar.path),
        ),
      );
    }

    if (dashboardPrefs.isEnabled(DashboardWidgetId.tasksAndAppointments)) {
      addSection(
        DashboardPanelPair(
          breakpoint: widget.breakpoint,
          left: DashboardTasksPanel(
            items: _pendingTasks,
            onSeeAll: () => context.go(NavRoute.tasks.path),
            onTapItem: (item) {
              if (item.clientId != null) {
                context.go('/clients/${item.clientId}');
              } else {
                context.go(NavRoute.tasks.path);
              }
            },
          ),
          right: DashboardAppointmentsPanel(
            appointments: _upcomingAppointments(range),
            onSeeAll: () => context.go(NavRoute.calendar.path),
            onTapItem: (appt) => context.go('/clients/${appt.clientId}'),
          ),
        ),
      );
    }

    if (dashboardPrefs.isEnabled(DashboardWidgetId.salesAndActivity)) {
      addSection(
        DashboardPanelPair(
          breakpoint: widget.breakpoint,
          left: DashboardSalesOverviewPanel(
            dataProvider: dataProvider,
            range: range,
            onSeeAll: () => context.go(NavRoute.billing.path),
          ),
          right: DashboardRecentActivityPanel(
            dataProvider: dataProvider,
            onSeeAll: () => context.go(NavRoute.orders.path),
          ),
        ),
      );
    }

    if (dashboardPrefs.isEnabled(DashboardWidgetId.inventoryAndActions)) {
      addSection(
        DashboardPanelPair(
          breakpoint: widget.breakpoint,
          left: DashboardInventoryAttentionPanel(
            dataProvider: dataProvider,
            onSeeAll: () => context.go(NavRoute.frameInventory.path),
          ),
          right: DashboardQuickActionsPanel(
            onNewClient: () => context.go('/clients/new'),
            onNewSale: () => context.go(NavRoute.orders.path),
            onNewExam: () => showAddAppointmentDialog(context),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DashboardTokens.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: DashboardTokens.sectionGap),
          DashboardKpiSummaryRow(
            breakpoint: widget.breakpoint,
            dataProvider: dataProvider,
            range: range,
            onClientsTap: () => context.go(NavRoute.clients.path),
            onAppointmentsTap: () => context.go(NavRoute.calendar.path),
            onSalesTap: () => context.go(NavRoute.billing.path),
            onOrdersTap: () => context.go(NavRoute.orders.path),
          ),
          const SizedBox(height: DashboardTokens.sectionGap),
          ...sections,
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final rangeControl = DashboardDateRangeControl(
      selected: _rangeKind,
      onChanged: _onRangeChanged,
    );
    final quickAdd = _quickAddButton(context);

    if (widget.breakpoint == Breakpoint.mobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DashboardGreeting(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: rangeControl),
              const SizedBox(width: 8),
              quickAdd,
            ],
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(child: DashboardGreeting()),
        rangeControl,
        const SizedBox(width: 12),
        quickAdd,
      ],
    );
  }

  Widget _quickAddButton(BuildContext context) {
    return Button(
      style: const ButtonStyle.primary(),
      onPressed: () => context.go('/clients/new'),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_add_alt_outlined, size: 16),
          const SizedBox(width: 6),
          Text(AppStrings.quickActionNewClient),
        ],
      ),
    );
  }
}
