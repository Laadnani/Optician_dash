import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../models/contact_lens.dart';
import '../localization/app_strings.dart';
import '../helpers/status_chip.dart';

class ContactLensProductCard extends StatelessWidget {
  final ContactLensProduct product;
  const ContactLensProductCard({super.key, required this.product});

  static const int lowStockThreshold = 5;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLow = product.stock <= lowStockThreshold;

    return Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('${product.brand} ${product.model}').semiBold(),
              ),
              StatusChip(
                label: isLow ? AppStrings.stockLow : AppStrings.stockOk,
                color: isLow ? Colors.orange.shade700 : Colors.green.shade700,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('${product.sku} · ${product.material}').muted().small(),
          const SizedBox(height: 8),
          Text('${AppStrings.cardFrameStock} ${product.stock} × ${product.boxQuantity} (${AppStrings.cardFramePrice} ${product.price.toStringAsFixed(0)} MAD)').muted().small(),
        ],
      ),
    );
  }
}

class ContactLensPrescriptionCard extends StatelessWidget {
  final ContactLensPrescription prescription;
  const ContactLensPrescriptionCard({super.key, required this.prescription});

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${AppStrings.cardContactLensRxTitle} — ${_formatDate(prescription.date)}',
          ).semiBold(),
          const SizedBox(height: 4),
          Text('${prescription.brand} · ${prescription.material}').muted().small(),
          const SizedBox(height: 8),
          Text(
            'OD  ${prescription.powerOD}  BC ${prescription.baseCurveOD}  DIA ${prescription.diameterOD}',
          ).small(),
          Text(
            'OS  ${prescription.powerOS}  BC ${prescription.baseCurveOS}  DIA ${prescription.diameterOS}',
          ).small(),
          if (prescription.notes.isNotEmpty)
            Text(prescription.notes).muted().small(),
        ],
      ),
    );
  }
}
