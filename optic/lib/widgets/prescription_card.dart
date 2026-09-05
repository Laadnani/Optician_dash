import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../models/prescription.dart';
import '../localization/app_strings.dart';
import '../helpers/status_chip.dart';

class PrescriptionCard extends StatelessWidget {
  final Prescription prescription;
  const PrescriptionCard({super.key, required this.prescription});

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _typeLabel(String type) {
    switch (type) {
      case 'reading':
        return AppStrings.prescriptionTypeReading;
      case 'progressive':
        return AppStrings.prescriptionTypeProgressive;
      case 'occupational':
        return AppStrings.prescriptionTypeOccupational;
      case 'contactLens':
        return AppStrings.prescriptionTypeContactLens;
      case 'distance':
      default:
        return AppStrings.prescriptionTypeDistance;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isExpired =
        prescription.expirationDate != null &&
        prescription.expirationDate!.isBefore(DateTime.now());

    return Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${AppStrings.cardPrescriptionTitle} — ${_formatDate(prescription.date)}',
                ).semiBold(),
              ),
              StatusChip(
                label: _typeLabel(prescription.type),
                color: colorScheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (prescription.expirationDate != null)
            Text(
              '${AppStrings.cardPrescriptionExpires} ${_formatDate(prescription.expirationDate!)}'
              '${isExpired ? ' (${AppStrings.cardPrescriptionExpired})' : ''}',
            ).muted().small(),
          const SizedBox(height: 8),
          Text(
            'OD  SPH ${prescription.sphOD}  CYL ${prescription.cylOD}  AXIS ${prescription.axisOD}  ADD ${prescription.addOD}  ${prescription.visualAcuityOD}',
          ).small(),
          Text(
            'OS  SPH ${prescription.sphOS}  CYL ${prescription.cylOS}  AXIS ${prescription.axisOS}  ADD ${prescription.addOS}  ${prescription.visualAcuityOS}',
          ).small(),
          Text('${AppStrings.cardPrescriptionPd} ${prescription.pd} mm').muted().small(),
          if (prescription.notes.isNotEmpty)
            Text(prescription.notes).muted().small(),
        ],
      ),
    );
  }
}
