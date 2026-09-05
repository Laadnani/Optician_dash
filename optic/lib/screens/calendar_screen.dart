import 'package:flutter/material.dart' as material;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:optic/app_shell.dart';
import 'package:optic/helpers/breakpoint.dart';
import 'package:optic/helpers/nav_items.dart';
import 'package:optic/data/data_provider.dart';
import 'package:optic/data/dashboard_repository.dart';
import 'package:optic/models/dashboard_appointment.dart';
import 'package:optic/helpers/calendar_header_bar.dart';
import 'package:optic/helpers/calendar_day_view.dart';
import 'package:optic/helpers/calendar_week_view.dart';
import 'package:optic/helpers/calendar_month_view.dart';
import 'package:optic/helpers/add_appointment_dialog.dart';
import 'package:optic/localization/app_strings.dart';

/// Full calendar screen — Day/Week/Month views over the same appointment
/// data the dashboard uses (via [DashboardRepository], so there's one data
/// source, not a second copy).
class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();
    final repository = ProviderDashboardRepository(dataProvider);
    final extra = GoRouterState.of(context).extra;
    final openAdd = extra is Map && extra['openAdd'] == true;
    final initialClientId = extra is Map ? extra['clientId'] as String? : null;

    return AppShell(
      navItems: (context) => buildAppNavItems(context, NavRoute.calendar),
      bodyBuilder: (context, breakpoint) => _CalendarBody(
        breakpoint: breakpoint,
        repository: repository,
        openAdd: openAdd,
        initialClientId: initialClientId,
      ),
    );
  }
}

class _CalendarBody extends StatefulWidget {
  final Breakpoint breakpoint;
  final DashboardRepository repository;
  final bool openAdd;
  final String? initialClientId;

  const _CalendarBody({
    required this.breakpoint,
    required this.repository,
    this.openAdd = false,
    this.initialClientId,
  });

  @override
  State<_CalendarBody> createState() => _CalendarBodyState();
}

class _CalendarBodyState extends State<_CalendarBody> {
  DateTime _selectedDate = DateTime.now();
  CalendarViewMode _viewMode = CalendarViewMode.day;
  List<DashboardAppointment> _appointments = const [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    if (widget.openAdd) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showAddAppointmentDialog(
          context,
          initialDate: _selectedDate,
          initialClientId: widget.initialClientId,
        );
      });
    }
  }

  @override
  void didUpdateWidget(covariant _CalendarBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final appointments = await widget.repository.fetchAppointments();
    if (!mounted) return;
    setState(() {
      _appointments = appointments;
      _isLoading = false;
    });
  }

  void _goToday() => setState(() {
    _selectedDate = DateTime.now();
  });

  void _goPrevious() => setState(() {
    switch (_viewMode) {
      case CalendarViewMode.day:
        _selectedDate = _selectedDate.subtract(const Duration(days: 1));
        break;
      case CalendarViewMode.week:
        _selectedDate = _selectedDate.subtract(const Duration(days: 7));
        break;
      case CalendarViewMode.month:
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month - 1,
          1,
        );
        break;
    }
  });

  void _goNext() => setState(() {
    switch (_viewMode) {
      case CalendarViewMode.day:
        _selectedDate = _selectedDate.add(const Duration(days: 1));
        break;
      case CalendarViewMode.week:
        _selectedDate = _selectedDate.add(const Duration(days: 7));
        break;
      case CalendarViewMode.month:
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month + 1,
          1,
        );
        break;
    }
  });

  void _selectDay(DateTime day) => setState(() {
    _selectedDate = day;
    // Tapping a specific day in week/month view is naturally "show me
    // that day" — jump straight to day view, matching Google Calendar's
    // own behavior when you click a date.
    _viewMode = CalendarViewMode.day;
  });

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: material.CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CalendarHeaderBar(
            selectedDate: _selectedDate,
            viewMode: _viewMode,
            onPrevious: _goPrevious,
            onNext: _goNext,
            onToday: _goToday,
            onViewModeChanged: (mode) => setState(() => _viewMode = mode),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Button.outline(
                onPressed: () =>
                    showAddAppointmentDialog(context, initialDate: _selectedDate),
                leading: const Icon(Icons.add, size: 16),
                child: Text(AppStrings.addDialogAppointmentTitle),
              ),
            ],
          ),
          const SizedBox(height: 16),
          switch (_viewMode) {
            CalendarViewMode.day => CalendarDayView(
              selectedDate: _selectedDate,
              appointments: _appointments,
            ),
            CalendarViewMode.week => CalendarWeekView(
              selectedDate: _selectedDate,
              appointments: _appointments,
              onSelectDay: _selectDay,
            ),
            CalendarViewMode.month => CalendarMonthView(
              selectedDate: _selectedDate,
              appointments: _appointments,
              breakpoint: widget.breakpoint,
              onSelectDay: _selectDay,
            ),
          },
        ],
      ),
    );
  }
}
