import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../models/optical_consultation.dart';
import '../localization/app_strings.dart';

class OpticalConsultationCard extends StatelessWidget {
  final OpticalConsultation consultation;
  const OpticalConsultationCard({super.key, required this.consultation});

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _screenUsageLabel(String s) {
    switch (s) {
      case 'low':
        return AppStrings.consultationScreenUsageLow;
      case 'high':
        return AppStrings.consultationScreenUsageHigh;
      case 'moderate':
      default:
        return AppStrings.consultationScreenUsageModerate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${AppStrings.cardConsultationTitle} — ${_formatDate(consultation.date)}',
          ).semiBold(),
          const SizedBox(height: 8),
          if (consultation.visualNeeds.isNotEmpty)
            Text(consultation.visualNeeds).small(),
          const SizedBox(height: 4),
          Text(
            '${AppStrings.consultationFieldScreenUsage}: ${_screenUsageLabel(consultation.screenUsage)}',
          ).muted().small(),
          Text(
            '${AppStrings.consultationFieldDriving}: ${consultation.driving ? AppStrings.dialogYes : AppStrings.dialogNo}'
            '  •  ${AppStrings.consultationFieldReading}: ${consultation.reading ? AppStrings.dialogYes : AppStrings.dialogNo}',
          ).muted().small(),
          if (consultation.previousProblems.isNotEmpty)
            Text(consultation.previousProblems).muted().small(),
        ],
      ),
    );
  }
}
