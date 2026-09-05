import '../models/payments.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../localization/app_strings.dart';

class PaymentsCard extends StatelessWidget {
  final Payment payment;
  const PaymentsCard({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    return Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.cardPaymentTitle).semiBold(),
          const SizedBox(height: 8),
          Text('${AppStrings.cardFieldAmount} ${payment.amount} MAD').muted(),
          Text('${AppStrings.cardPaymentMethod} ${payment.method}').muted(),
          Text('${AppStrings.cardFieldDate} ${payment.date}').muted(),
        ],
      ),
    );
  }
}
