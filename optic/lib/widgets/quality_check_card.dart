import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../models/quality_check.dart';
import '../localization/app_strings.dart';
import '../helpers/status_chip.dart';

String _checkTypeLabel(String type) {
  switch (type) {
    case 'lensQuality':
      return AppStrings.qcTypeLensQuality;
    case 'prescriptionAccuracy':
      return AppStrings.qcTypePrescriptionAccuracy;
    case 'cosmetic':
      return AppStrings.qcTypeCosmetic;
    case 'frameFit':
      return AppStrings.qcTypeFrameFit;
    default:
      return AppStrings.qcTypeOther;
  }
}

(String, Color) _resultStyle(String result, ColorScheme colorScheme) {
  switch (result) {
    case 'fail':
      return (AppStrings.qcResultFail, colorScheme.destructive);
    case 'conditionalPass':
      return (AppStrings.qcResultConditionalPass, Colors.orange.shade700);
    case 'pass':
    default:
      return (AppStrings.qcResultPass, Colors.green.shade700);
  }
}

class QualityCheckCard extends StatelessWidget {
  final QualityCheck check;
  const QualityCheckCard({super.key, required this.check});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (label, color) = _resultStyle(check.result, colorScheme);

    return Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(_checkTypeLabel(check.checkType)).semiBold(),
              ),
              StatusChip(label: label, color: color),
            ],
          ),
          if (check.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(check.notes).small(),
          ],
        ],
      ),
    );
  }
}
