import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../models/mounting_job.dart';
import '../localization/app_strings.dart';
import '../helpers/status_chip.dart';

(String, Color) _mountingStatusStyle(String status, ColorScheme colorScheme) {
  switch (status) {
    case 'inProgress':
      return (AppStrings.mountingStatusInProgress, colorScheme.primary);
    case 'completed':
      return (AppStrings.mountingStatusCompleted, Colors.green.shade700);
    case 'rework':
      return (AppStrings.mountingStatusRework, colorScheme.destructive);
    case 'pending':
    default:
      return (AppStrings.mountingStatusPending, Colors.orange.shade700);
  }
}

class MountingJobCard extends StatelessWidget {
  final MountingJob job;

  /// Display labels for [job.frameId]/[job.lensId], resolved by the caller
  /// from the frame/lens catalogs already loaded on the screen.
  final String frameLabel;
  final String lensLabel;

  const MountingJobCard({
    super.key,
    required this.job,
    required this.frameLabel,
    required this.lensLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (label, color) = _mountingStatusStyle(job.status, colorScheme);

    return Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(frameLabel).semiBold()),
              StatusChip(label: label, color: color),
            ],
          ),
          const SizedBox(height: 4),
          Text('${AppStrings.cardMountingLens} $lensLabel').muted().small(),
          if (job.completedDate != null)
            Text(
              '${AppStrings.cardMountingCompleted} ${_formatDate(job.completedDate!)}',
            ).muted().small(),
        ],
      ),
    );
  }
}

String _formatDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
