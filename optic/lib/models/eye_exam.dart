class EyeExam {
  final String id;
  final String clientId;
  final DateTime examDate;

  // Visual acuity — Snellen fraction per eye (e.g. "20/20", "20/40").
  // Kept as a string (how it's actually charted/recorded clinically) rather
  // than a raw number; `VisualAcuityPanel` parses the denominator out of
  // this for its trend line instead of asking for a separate numeric field.
  final String visualAcuityOD;
  final String visualAcuityOS;

  // Intraocular pressure per eye, mmHg. Nullable — not every visit measures
  // IOP (e.g. a quick follow-up), so an exam without a reading shouldn't
  // have to fake a value.
  final double? iopOD;
  final double? iopOS;

  // Refraction — single value today (not yet split OD/OS). Row 2 in the
  // exam-type table ("Refraction") is deferred; this stays as-is until
  // that row gets built out the same way visual acuity/IOP just did.
  final double sph; // spherical
  final double cyl; // cylindrical
  final int axis; // axis in degrees

  final String notes;

  EyeExam({
    required this.id,
    required this.clientId,
    required this.examDate,
    required this.visualAcuityOD,
    required this.visualAcuityOS,
    this.iopOD,
    this.iopOS,
    required this.sph,
    required this.cyl,
    required this.axis,
    required this.notes,
  });
}
