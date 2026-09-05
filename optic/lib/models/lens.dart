/// Module 5 — Lens Product Management.
///
/// A lens *product* (a catalog entry an optician stocks/orders), not a
/// client's actual glazed lenses (those belong to an Order once module 9
/// exists). Practical core subset of the spec's field list: [coatings] is a
/// free-form list rather than one bool per coating type (anti-reflective,
/// scratch-resistant, hydrophobic, oleophobic, blue filter, UV, mirror,
/// photochromic) — same "list of strings" pattern already used for
/// `MedicalHistory.conditions` before it was deleted, kept here because it
/// scales to new coating types without a model change.
class Lens {
  final String id;
  final String sku;
  final String manufacturer;
  final String brand;
  final String productName;

  /// 'singleVision' | 'bifocal' | 'progressive' | 'occupational' |
  /// 'computer' | 'myopiaControl' | 'plano' | 'sunglasses' | 'specialty'.
  final String lensType;

  final String material;
  final double index;
  final String design;
  final List<String> coatings;
  final double baseCurve;
  final double diameter;
  final double cost;
  final double price;
  final String supplier;
  final int warrantyMonths;

  Lens({
    required this.id,
    required this.sku,
    required this.manufacturer,
    required this.brand,
    required this.productName,
    this.lensType = 'singleVision',
    this.material = '',
    this.index = 1.5,
    this.design = '',
    this.coatings = const [],
    this.baseCurve = 0,
    this.diameter = 0,
    this.cost = 0,
    this.price = 0,
    this.supplier = '',
    this.warrantyMonths = 12,
  });
}
