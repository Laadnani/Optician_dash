import '../models/eye_exam.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../localization/app_strings.dart';

/// One visit's raw exam record — refraction + notes. Visual acuity and IOP
/// (also captured per visit on [EyeExam]) get their own summary panels
/// above this list (`VisualAcuityPanel`/`IopPanel` in
/// `client_file_screen.dart`) since those need "current value + trend"
/// treatment, not a flat per-visit card — this card is the detail record
/// underneath that summary.
class EyeExamCard extends StatelessWidget {
  final EyeExam exam;
  const EyeExamCard({super.key, required this.exam});

  @override
  Widget build(BuildContext context) {
    return Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${AppStrings.cardEyeExamTitlePrefix} — ${_formatDate(exam.examDate)}',
          ).semiBold(),
          const SizedBox(height: 8),
          Text(
            '${AppStrings.cardEyeExamRefractionPrefix} SPH ${exam.sph}, CYL ${exam.cyl}, AXIS ${exam.axis}°',
          ).muted(),
          Text(
            '${AppStrings.cardEyeExamVaPrefix} OD ${exam.visualAcuityOD} · OS ${exam.visualAcuityOS}',
          ).muted(),
          if (exam.iopOD != null || exam.iopOS != null)
            Text(
              '${AppStrings.cardEyeExamIopPrefix} OD ${exam.iopOD?.toStringAsFixed(0) ?? '—'} · OS ${exam.iopOS?.toStringAsFixed(0) ?? '—'} mmHg',
            ).muted(),
          if (exam.notes.isNotEmpty)
            Text('${AppStrings.cardFieldNotes} ${exam.notes}').muted(),
        ],
      ),
    );
  }
}

String _formatDate(DateTime d) {
  final mm = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  return '${d.year}-$mm-$dd';
}
