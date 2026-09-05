import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../models/after_sales_ticket.dart';
import '../localization/app_strings.dart';
import '../helpers/status_chip.dart';

String _issueTypeLabel(String type) {
  switch (type) {
    case 'breakage':
      return AppStrings.afterSalesIssueBreakage;
    case 'visionIssue':
      return AppStrings.afterSalesIssueVision;
    case 'comfort':
      return AppStrings.afterSalesIssueComfort;
    default:
      return AppStrings.afterSalesIssueOther;
  }
}

(String, Color) _statusStyle(String status, ColorScheme colorScheme) {
  switch (status) {
    case 'inProgress':
      return (AppStrings.afterSalesStatusInProgress, colorScheme.primary);
    case 'resolved':
      return (AppStrings.afterSalesStatusResolved, Colors.green.shade700);
    case 'closed':
      return (AppStrings.afterSalesStatusClosed, colorScheme.mutedForeground);
    default:
      return (AppStrings.afterSalesStatusOpen, Colors.orange.shade700);
  }
}

class AfterSalesTicketCard extends StatelessWidget {
  final AfterSalesTicket ticket;
  const AfterSalesTicketCard({super.key, required this.ticket});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (label, color) = _statusStyle(ticket.status, colorScheme);

    return Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(_issueTypeLabel(ticket.issueType)).semiBold(),
              ),
              StatusChip(label: label, color: color),
            ],
          ),
          if (ticket.resolution.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(ticket.resolution).small(),
          ],
        ],
      ),
    );
  }
}
