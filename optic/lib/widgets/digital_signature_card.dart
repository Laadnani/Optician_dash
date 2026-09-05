import '../models/digital_signature.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../localization/app_strings.dart';

class DigitalSignatureCard extends StatelessWidget {
  final DigitalSignature signature;
  const DigitalSignatureCard({super.key, required this.signature});

  @override
  Widget build(BuildContext context) {
    return Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.cardDigitalSignatureTitle).semiBold(),
          const SizedBox(height: 8),
          Text('${AppStrings.cardDigitalSignatureClientId} ${signature.clientId}').muted(),
          Text('${AppStrings.cardDigitalSignatureSignedAt} ${signature.signedAt}').muted(),
        ],
      ),
    );
  }
}
