/// Module 4 — Frame Management / Frame Inventory.
///
/// Practical simplification of the spec's "Frame Model → Variants →
/// Inventory" tree: rather than three separate entities (frame model, a
/// variant per color/size, and a transaction ledger), each [Frame] record
/// already represents one purchasable variant (a specific brand/model in one
/// color and size), carrying its own stock counts directly — the same
/// simplification `Appointment` made for billing (fields on the record
/// itself, not a separate ledger) before a real Order/transaction system
/// exists to justify one.
class Frame {
  final String id;
  final String sku;
  final String barcode;
  final String brand;
  final String model;
  final String collection;

  /// 'men' | 'women' | 'unisex' | 'kids'.
  final String gender;

  final String material;

  /// 'fullRim' | 'semiRimless' | 'rimless'.
  final String frameType;

  /// 'rectangle' | 'round' | 'cat_eye' | 'aviator' | 'square' | 'oval' |
  /// 'other'.
  final String shape;

  final String color;

  /// "52-18-140" style (lens width - bridge - temple length), matching how
  /// the spec itself writes frame sizes.
  final String size;

  final double price;
  final double cost;
  final String supplier;
  final int stockAvailable;
  final int stockReserved;
  final int warrantyMonths;

  Frame({
    required this.id,
    required this.sku,
    this.barcode = '',
    required this.brand,
    required this.model,
    this.collection = '',
    this.gender = 'unisex',
    this.material = '',
    this.frameType = 'fullRim',
    this.shape = 'other',
    required this.color,
    required this.size,
    this.price = 0,
    this.cost = 0,
    this.supplier = '',
    this.stockAvailable = 0,
    this.stockReserved = 0,
    this.warrantyMonths = 12,
  });

  Frame copyWith({
    int? stockAvailable,
    int? stockReserved,
    double? price,
    double? cost,
  }) {
    return Frame(
      id: id,
      sku: sku,
      barcode: barcode,
      brand: brand,
      model: model,
      collection: collection,
      gender: gender,
      material: material,
      frameType: frameType,
      shape: shape,
      color: color,
      size: size,
      price: price ?? this.price,
      cost: cost ?? this.cost,
      supplier: supplier,
      stockAvailable: stockAvailable ?? this.stockAvailable,
      stockReserved: stockReserved ?? this.stockReserved,
      warrantyMonths: warrantyMonths,
    );
  }
}
