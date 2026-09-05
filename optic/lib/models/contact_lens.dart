/// Module 6 — Contact Lens Management.
///
/// Two entities, mirroring the spec's own split: [ContactLensProduct] is
/// the store's sellable catalog/stock (parallel to [Lens]/[Frame]);
/// [ContactLensPrescription] is a client's actual per-eye contact lens Rx
/// (parallel to [Prescription], but contact lenses need their own fields —
/// base curve/diameter instead of a frame-mounted lens' SPH/CYL/AXIS/ADD
/// alone). Trial-lens tracking (spec: trial result/comfort/wearing
/// time/problems) is deferred — [ContactLensPrescription.notes] covers it
/// informally until that's worth a field of its own.
library;

class ContactLensProduct {
  final String id;
  final String sku;
  final String brand;
  final String model;
  final String material;

  /// 'daily' | 'weekly' | 'biweekly' | 'monthly' | 'quarterly' | 'yearly'.
  final String replacementSchedule;

  final int boxQuantity;
  final String supplier;
  final int stock;
  final double cost;
  final double price;

  ContactLensProduct({
    required this.id,
    required this.sku,
    required this.brand,
    required this.model,
    this.material = '',
    this.replacementSchedule = 'monthly',
    this.boxQuantity = 6,
    this.supplier = '',
    this.stock = 0,
    this.cost = 0,
    this.price = 0,
  });
}

class ContactLensPrescription {
  final String id;
  final String clientId;
  final DateTime date;

  final double powerOD;
  final double baseCurveOD;
  final double diameterOD;
  final double cylOD;
  final int axisOD;
  final double addOD;

  final double powerOS;
  final double baseCurveOS;
  final double diameterOS;
  final double cylOS;
  final int axisOS;
  final double addOS;

  final String brand;
  final String material;

  /// 'daily' | 'weekly' | 'biweekly' | 'monthly' | 'quarterly' | 'yearly'.
  final String replacementFrequency;

  final String notes;

  ContactLensPrescription({
    required this.id,
    required this.clientId,
    required this.date,
    this.powerOD = 0,
    this.baseCurveOD = 0,
    this.diameterOD = 0,
    this.cylOD = 0,
    this.axisOD = 0,
    this.addOD = 0,
    this.powerOS = 0,
    this.baseCurveOS = 0,
    this.diameterOS = 0,
    this.cylOS = 0,
    this.axisOS = 0,
    this.addOS = 0,
    this.brand = '',
    this.material = '',
    this.replacementFrequency = 'monthly',
    this.notes = '',
  });
}
