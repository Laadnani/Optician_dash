/// Module 2 — Optical Prescription Management.
///
/// A versioned entity of its own (not fields bolted onto [Client]), per the
/// architecture spec — a client can have several prescriptions over time
/// and the old ones stay on file. Deliberately named `Prescription` (the
/// clinical medication-prescription model that used to own this name was
/// deleted in the optical-retail pivot, freeing it up for the optical Rx
/// concept the spec actually means by "Prescription").
///
/// Practical core subset of the spec's field list: per-eye SPH/CYL/AXIS/ADD
/// + visual acuity, overall PD, dominant eye, type, expiration. The more
/// exotic fields (prism/prism base, monocular vs. binocular PD split,
/// vertex distance, pantoscopic/face-form angle, segment height, fitting
/// height) live on [Measurement] instead (module 3) rather than duplicated
/// here — this keeps the two modules from overlapping.
class Prescription {
  final String id;
  final String clientId;

  /// References [OpticalConsultation.id], when this prescription follows a
  /// recorded consultation visit.
  final String? consultationId;
  final DateTime date;
  final DateTime? expirationDate;

  /// 'distance' | 'reading' | 'progressive' | 'occupational' | 'contactLens'.
  final String type;

  final double sphOD;
  final double cylOD;
  final int axisOD;
  final double addOD;
  final String visualAcuityOD;

  final double sphOS;
  final double cylOS;
  final int axisOS;
  final double addOS;
  final String visualAcuityOS;

  /// Pupillary distance, in mm.
  final double pd;

  /// 'OD' | 'OS' | 'none'.
  final String dominantEye;

  final String notes;

  Prescription({
    required this.id,
    required this.clientId,
    this.consultationId,
    required this.date,
    this.expirationDate,
    this.type = 'distance',
    this.sphOD = 0,
    this.cylOD = 0,
    this.axisOD = 0,
    this.addOD = 0,
    this.visualAcuityOD = '',
    this.sphOS = 0,
    this.cylOS = 0,
    this.axisOS = 0,
    this.addOS = 0,
    this.visualAcuityOS = '',
    this.pd = 0,
    this.dominantEye = 'none',
    this.notes = '',
  });
}
