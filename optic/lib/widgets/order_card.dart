import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../models/order.dart';
import '../localization/app_strings.dart';
import '../helpers/status_chip.dart';

(String, Color) _orderStatusStyle(String status, ColorScheme colorScheme) {
  switch (status) {
    case 'inProduction':
      return (AppStrings.orderStatusInProduction, colorScheme.primary);
    case 'ready':
      return (AppStrings.orderStatusReady, Colors.teal.shade600);
    case 'delivered':
      return (AppStrings.orderStatusDelivered, Colors.green.shade700);
    case 'cancelled':
      return (AppStrings.orderStatusCancelled, colorScheme.destructive);
    case 'pending':
    default:
      return (AppStrings.orderStatusPending, Colors.orange.shade700);
  }
}

class OrderCard extends StatelessWidget {
  final Order order;
  const OrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (label, color) = _orderStatusStyle(order.status, colorScheme);

    return Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${order.totalAmount.toStringAsFixed(0)} MAD',
                ).semiBold(),
              ),
              StatusChip(label: label, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(order.description).small(),
        ],
      ),
    );
  }
}
