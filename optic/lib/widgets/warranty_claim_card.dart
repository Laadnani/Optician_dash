import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../models/warranty_claim.dart';
import '../localization/app_strings.dart';
import '../helpers/status_chip.dart';

String _itemTypeLabel(String type) {
  switch (type) {
    case 'lens':
      return AppStrings.repairItemLens;
    case 'contactLens':
      return AppStrings.repairItemContactLens;
    default:
      return AppStrings.repairItemFrame;
  }
}

(String, Color) _statusStyle(String status, ColorScheme colorScheme) {
  switch (status) {
    case 'approved':
      return (AppStrings.warrantyStatusApproved, colorScheme.primary);
    case 'rejected':
      return (AppStrings.warrantyStatusRejected, colorScheme.destructive);
    case 'replaced':
      return (AppStrings.warrantyStatusReplaced, Colors.green.shade700);
    default:
      return (AppStrings.warrantyStatusSubmitted, Colors.orange.shade700);
  }
}

class WarrantyClaimCard extends StatelessWidget {
  final WarrantyClaim claim;
  const WarrantyClaimCard({super.key, required this.claim});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (label, color) = _statusStyle(claim.status, colorScheme);

    return Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(_itemTypeLabel(claim.itemType)).semiBold()),
              StatusChip(label: label, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(claim.issueDescription).small(),
        ],
      ),
    );
  }
}
