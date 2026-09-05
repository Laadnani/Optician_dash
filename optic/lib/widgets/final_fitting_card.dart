import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../models/final_fitting.dart';
import '../localization/app_strings.dart';
import '../helpers/status_chip.dart';

String _adjustmentTypeLabel(String type) {
  switch (type) {
    case 'nosePads':
      return AppStrings.fittingTypeNosePads;
    case 'templeLength':
      return AppStrings.fittingTypeTempleLength;
    case 'lensPosition':
      return AppStrings.fittingTypeLensPosition;
    case 'frameAlignment':
      return AppStrings.fittingTypeFrameAlignment;
    default:
      return AppStrings.fittingTypeOther;
  }
}

class FinalFittingCard extends StatelessWidget {
  final FinalFitting fitting;
  const FinalFittingCard({super.key, required this.fitting});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLowComfort = fitting.comfortRating <= 2;

    return Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _adjustmentTypeLabel(fitting.adjustmentType),
                ).semiBold(),
              ),
              StatusChip(
                label: '${fitting.comfortRating}/5',
                color: isLowComfort
                    ? colorScheme.destructive
                    : Colors.green.shade700,
              ),
            ],
          ),
          if (fitting.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(fitting.notes).small(),
          ],
        ],
      ),
    );
  }
}
