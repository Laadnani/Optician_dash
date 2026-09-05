import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../models/measurement.dart';
import '../localization/app_strings.dart';

class MeasurementCard extends StatelessWidget {
  final Measurement measurement;
  const MeasurementCard({super.key, required this.measurement});

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
            '${AppStrings.cardMeasurementTitle} — ${_formatDate(measurement.date)}',
          ).semiBold(),
          const SizedBox(height: 8),
          Text('${AppStrings.cardMeasurementPd} ${measurement.pd} mm (OD ${measurement.monocularPdOD} / OS ${measurement.monocularPdOS})').muted().small(),
          Text('${AppStrings.cardMeasurementFittingHeight} ${measurement.fittingHeight} mm').muted().small(),
          Text('${AppStrings.cardMeasurementFrameGeometry} ${measurement.frameWidth}-${measurement.bridge}-${measurement.templeLength}').muted().small(),
          Text('${AppStrings.cardMeasurementVertexDistance} ${measurement.vertexDistance} mm').muted().small(),
          Text('${AppStrings.cardMeasurementPantoscopicAngle} ${measurement.pantoscopicAngle}°  ${AppStrings.cardMeasurementFaceFormAngle} ${measurement.faceFormAngle}°').muted().small(),
          const SizedBox(height: 4),
          Text(
            '${AppStrings.cardMeasurementMethod} ${measurement.method}${measurement.deviceUsed.isEmpty ? '' : ' (${measurement.deviceUsed})'} · ${AppStrings.cardMeasurementOperator} ${measurement.operator}',
          ).muted().small(),
          if (measurement.notes.isNotEmpty)
            Text(measurement.notes).muted().small(),
        ],
      ),
    );
  }
}
