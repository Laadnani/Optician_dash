import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../models/delivery_record.dart';
import '../localization/app_strings.dart';
import '../helpers/status_chip.dart';

String _methodLabel(String method) {
  switch (method) {
    case 'homeDelivery':
      return AppStrings.deliveryMethodHome;
    case 'courier':
      return AppStrings.deliveryMethodCourier;
    default:
      return AppStrings.deliveryMethodInStore;
  }
}

(String, Color) _statusStyle(String status, ColorScheme colorScheme) {
  switch (status) {
    case 'delivered':
      return (AppStrings.deliveryStatusDelivered, Colors.green.shade700);
    case 'failed':
      return (AppStrings.deliveryStatusFailed, colorScheme.destructive);
    default:
      return (AppStrings.deliveryStatusScheduled, Colors.orange.shade700);
  }
}

class DeliveryRecordCard extends StatelessWidget {
  final DeliveryRecord record;
  const DeliveryRecordCard({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (label, color) = _statusStyle(record.status, colorScheme);

    return Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(_methodLabel(record.method)).semiBold()),
              StatusChip(label: label, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            record.recipientSignature
                ? AppStrings.deliverySigned
                : AppStrings.deliveryNotSigned,
          ).muted().small(),
        ],
      ),
    );
  }
}
