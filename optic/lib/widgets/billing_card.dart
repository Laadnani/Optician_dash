import '../models/billing.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../helpers/status_chip.dart';
import '../localization/app_strings.dart';

class BillingCard extends StatelessWidget {
  final Invoice invoice;
  const BillingCard({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    final (label, color) = statusChipStyle(
      invoice.status,
      Theme.of(context).colorScheme,
    );
    return Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${AppStrings.cardBillingInvoicePrefix}${invoice.id}'),
              StatusChip(label: label, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text('${AppStrings.cardFieldAmount} ${invoice.amount} MAD'),
          Text('${AppStrings.cardFieldDate} ${invoice.date}'),
        ],
      ),
    );
  }
}
