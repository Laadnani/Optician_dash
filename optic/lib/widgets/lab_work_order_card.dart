import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../models/lab_work_order.dart';
import '../localization/app_strings.dart';
import '../helpers/status_chip.dart';

String _taskTypeLabel(String type) {
  switch (type) {
    case 'edging':
      return AppStrings.labTaskEdging;
    case 'coating':
      return AppStrings.labTaskCoating;
    case 'tinting':
      return AppStrings.labTaskTinting;
    case 'engraving':
      return AppStrings.labTaskEngraving;
    case 'lensCutting':
      return AppStrings.labTaskLensCutting;
    default:
      return AppStrings.labTaskOther;
  }
}

(String, Color) _labStatusStyle(String status, ColorScheme colorScheme) {
  switch (status) {
    case 'inProgress':
      return (AppStrings.labStatusInProgress, colorScheme.primary);
    case 'qualityHold':
      return (AppStrings.labStatusQualityHold, colorScheme.destructive);
    case 'completed':
      return (AppStrings.labStatusCompleted, Colors.green.shade700);
    case 'queued':
    default:
      return (AppStrings.labStatusQueued, colorScheme.mutedForeground);
  }
}

class LabWorkOrderCard extends StatelessWidget {
  final LabWorkOrder workOrder;
  const LabWorkOrderCard({super.key, required this.workOrder});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (label, color) = _labStatusStyle(workOrder.status, colorScheme);
    final now = DateTime.now();
    final isOverdue =
        workOrder.status != 'completed' &&
        workOrder.dueDate != null &&
        workOrder.dueDate!.isBefore(now);

    return Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(_taskTypeLabel(workOrder.taskType)).semiBold(),
              ),
              StatusChip(label: label, color: color),
            ],
          ),
          if (workOrder.dueDate != null) ...[
            const SizedBox(height: 6),
            Text(
              '${AppStrings.cardLabDueDate} ${_formatDate(workOrder.dueDate!)}',
            ).muted().small(),
          ],
          if (isOverdue) ...[
            const SizedBox(height: 6),
            StatusChip(
              label: AppStrings.labOverdue,
              color: colorScheme.destructive,
            ),
          ],
        ],
      ),
    );
  }
}

String _formatDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
