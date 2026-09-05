import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../models/repair_ticket.dart';
import '../localization/app_strings.dart';
import '../helpers/status_chip.dart';

String _itemTypeLabel(String type) {
  switch (type) {
    case 'lens':
      return AppStrings.repairItemLens;
    case 'contactLens':
      return AppStrings.repairItemContactLens;
    case 'frame':
      return AppStrings.repairItemFrame;
    default:
      return AppStrings.repairItemOther;
  }
}

(String, Color) _statusStyle(String status, ColorScheme colorScheme) {
  switch (status) {
    case 'inProgress':
      return (AppStrings.repairStatusInProgress, colorScheme.primary);
    case 'completed':
      return (AppStrings.repairStatusCompleted, Colors.green.shade700);
    case 'cannotRepair':
      return (AppStrings.repairStatusCannotRepair, colorScheme.destructive);
    default:
      return (AppStrings.repairStatusReceived, colorScheme.mutedForeground);
  }
}

class RepairTicketCard extends StatelessWidget {
  final RepairTicket ticket;
  const RepairTicketCard({super.key, required this.ticket});

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
                child: Text(_itemTypeLabel(ticket.itemType)).semiBold(),
              ),
              StatusChip(label: label, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(ticket.issueDescription).small(),
          if (ticket.cost > 0) ...[
            const SizedBox(height: 8),
            Text(
              '${AppStrings.cardFramePrice} ${ticket.cost.toStringAsFixed(0)} MAD',
            ).muted().small(),
          ],
        ],
      ),
    );
  }
}
