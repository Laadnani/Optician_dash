import '../models/insurance.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../localization/app_strings.dart';

class InsuranceCard extends StatelessWidget {
  final Insurance insurance;
  const InsuranceCard({super.key, required this.insurance});

  @override
  Widget build(BuildContext context) {
    return Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.cardInsuranceTitle).semiBold(),
          const SizedBox(height: 8),
          Text('${AppStrings.cardInsuranceProvider} ${insurance.provider}').muted(),
          Text('${AppStrings.cardInsurancePolicyNumber} ${insurance.policyNumber}').muted(),
          Text('${AppStrings.cardInsuranceValidUntil} ${insurance.validUntil}').muted(),
        ],
      ),
    );
  }
}
