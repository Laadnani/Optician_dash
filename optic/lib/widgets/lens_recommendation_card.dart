import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../models/lens_recommendation.dart';
import '../localization/app_strings.dart';
import '../helpers/status_chip.dart';

String _lensTypeLabel(String type) {
  switch (type) {
    case 'bifocal':
      return AppStrings.lensTypeBifocal;
    case 'progressive':
      return AppStrings.lensTypeProgressive;
    case 'occupational':
      return AppStrings.lensTypeOccupational;
    case 'computer':
      return AppStrings.lensTypeComputer;
    case 'myopiaControl':
      return AppStrings.lensTypeMyopiaControl;
    case 'plano':
      return AppStrings.lensTypePlano;
    case 'sunglasses':
      return AppStrings.lensTypeSunglasses;
    case 'specialty':
      return AppStrings.lensTypeSpecialty;
    case 'singleVision':
    default:
      return AppStrings.lensTypeSingleVision;
  }
}

class LensRecommendationCard extends StatelessWidget {
  final LensRecommendation recommendation;
  const LensRecommendationCard({super.key, required this.recommendation});

  @override
  Widget build(BuildContext context) {
    return Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _lensTypeLabel(recommendation.recommendedLensType),
                ).semiBold(),
              ),
              StatusChip(
                label: recommendation.accepted
                    ? AppStrings.cardLensRecAccepted
                    : AppStrings.cardLensRecPending,
                color: recommendation.accepted
                    ? Colors.green.shade700
                    : Colors.orange.shade700,
              ),
            ],
          ),
          if (recommendation.recommendedCoatings.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(recommendation.recommendedCoatings.join(', '))
                .muted()
                .small(),
          ],
          if (recommendation.reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(recommendation.reason).small(),
          ],
        ],
      ),
    );
  }
}
