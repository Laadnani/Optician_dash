/// Module 3 — Visual / Optical Measurements.
///
/// Split out from [Prescription] per the spec: the fitting-relevant numbers
/// (frame/lens geometry, vertex distance, pantoscopic/face-form angle) that
/// an optician measures once a frame is chosen, as opposed to the pure
/// refraction numbers a prescription carries. Practical core subset of the
/// spec's "General" + "Advanced fitting" + "Measurement method" field
/// groups — segment height and full progressive-fitting parameters are
/// deferred (they only matter once module 12, Mounting/Assembly, exists to
/// consume them).
class Measurement {
  final String id;
  final String clientId;

  /// References [OpticalConsultation.id], when this measurement follows a
  /// recorded consultation visit.
  final String? consultationId;
  final DateTime date;

  /// Binocular pupillary distance, in mm.
  final double pd;
  final double monocularPdOD;
  final double monocularPdOS;

  final double fittingHeight;
  final double bridge;
  final double templeLength;
  final double frameWidth;
  final double lensWidth;

  /// Distance Between Lenses.
  final double dbl;

  final double vertexDistance;
  final double pantoscopicAngle;
  final double faceFormAngle;

  /// 'manual' | 'pupillometer' | 'digitalCentration' | 'opticalScanner' |
  /// 'imported'.
  final String method;

  final String deviceUsed;
  final String operator;
  final String notes;

  Measurement({
    required this.id,
    required this.clientId,
    this.consultationId,
    required this.date,
    this.pd = 0,
    this.monocularPdOD = 0,
    this.monocularPdOS = 0,
    this.fittingHeight = 0,
    this.bridge = 0,
    this.templeLength = 0,
    this.frameWidth = 0,
    this.lensWidth = 0,
    this.dbl = 0,
    this.vertexDistance = 0,
    this.pantoscopicAngle = 0,
    this.faceFormAngle = 0,
    this.method = 'manual',
    this.deviceUsed = '',
    this.operator = '',
    this.notes = '',
  });
}
