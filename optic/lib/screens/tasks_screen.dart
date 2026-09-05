import 'package:flutter/material.dart' as material;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:optic/app_shell.dart';
import 'package:optic/data/data_provider.dart';
import 'package:optic/data/dashboard_repository.dart';
import 'package:optic/helpers/breakpoint.dart';
import 'package:optic/helpers/empty_state.dart';
import 'package:optic/helpers/month_filter_bar.dart';
import 'package:optic/helpers/nav_items.dart';
import 'package:optic/helpers/stat_card.dart';
import 'package:optic/localization/app_strings.dart';
import 'package:optic/models/pending_task.dart';

/// Module: Tasks (Management). Every "needs your attention" item across the
/// whole app in one list — the same [derivePendingTasks] the dashboard's
/// pending-tasks panel and the notification bell already surface, now with
/// somewhere real to land when you tap "See all" from either of those.
class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      navItems: (context) => buildAppNavItems(context, NavRoute.tasks),
      bodyBuilder: (context, breakpoint) => _TasksBody(breakpoint: breakpoint),
    );
  }
}

class _TasksBody extends StatefulWidget {
  final Breakpoint breakpoint;
  const _TasksBody({required this.breakpoint});

  @override
  State<_TasksBody> createState() => _TasksBodyState();
}

class _TasksBodyState extends State<_TasksBody> with MonthFilterState<_TasksBody> {
  (IconData, Color) _styleFor(PendingTaskKind kind, ColorScheme colors) {
    switch (kind) {
      case PendingTaskKind.signature:
        return (Icons.draw_outlined, Colors.orange.shade600);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final allTasks = derivePendingTasks(dataProvider);
    final tasks = allTasks.where((t) => isInSelectedMonth(t.date)).toList();
    final withClient = tasks.where((t) => t.clientId != null).length;
    final int crossAxisCount = widget.breakpoint == Breakpoint.mobile ? 1 : 3;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.navTasks).large().bold(),
          const SizedBox(height: 4),
          Text(AppStrings.tasksScreenSubtitle).muted(),
          const SizedBox(height: 12),
          buildMonthFilterBar(),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 3,
            children: [
              DashboardStatCard(
                label: AppStrings.tasksKpiTotal,
                value: '${tasks.length}',
                icon: Icons.checklist_outlined,
                accent: colorScheme.primary,
              ),
              DashboardStatCard(
                label: AppStrings.tasksKpiLinkedToClient,
                value: '$withClient',
                icon: Icons.person_outline,
                accent: colorScheme.chart2,
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (tasks.isEmpty)
            EmptyState(
              icon: Icons.checklist_outlined,
              title: AppStrings.pendingTasksEmpty,
            )
          else
            Card(
              child: material.ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: tasks.length,
                separatorBuilder: (_, __) => Container(
                  height: 1,
                  color: colorScheme.border,
                ),
                itemBuilder: (context, i) {
                  final task = tasks[i];
                  final (icon, color) = _styleFor(task.kind, colorScheme);
                  return material.InkWell(
                    onTap: task.clientId != null
                        ? () => context.go('/clients/${task.clientId}')
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Icon(icon, size: 16, color: color),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(task.title),
                                Text(task.subtitle).muted().small(),
                              ],
                            ),
                          ),
                          if (task.clientId != null)
                            Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: colorScheme.mutedForeground,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
