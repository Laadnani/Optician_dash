import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../models/lens.dart';
import '../localization/app_strings.dart';

class LensCard extends StatelessWidget {
  final Lens lens;
  const LensCard({super.key, required this.lens});

  @override
  Widget build(BuildContext context) {
    return Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(lens.productName).semiBold(),
          const SizedBox(height: 4),
          Text('${lens.brand} · ${lens.manufacturer} · ${lens.sku}').muted().small(),
          const SizedBox(height: 8),
          Text('${AppStrings.cardLensMaterial} ${lens.material}  ·  ${AppStrings.cardLensIndex} ${lens.index}').muted().small(),
          if (lens.coatings.isNotEmpty)
            Text('${AppStrings.cardLensCoatings} ${lens.coatings.join(", ")}').muted().small(),
          const SizedBox(height: 4),
          Text('${AppStrings.cardFramePrice} ${lens.price.toStringAsFixed(0)} MAD').muted().small(),
        ],
      ),
    );
  }
}
