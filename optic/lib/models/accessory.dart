/// Module 10 — Accessories. Store-wide catalog for everything sold
/// alongside frames/lenses/contact lenses — cases, cleaning kits, chains,
/// repair kits. Same shape as [Frame]/[Lens]: one record per sellable
/// variant, carrying its own stock count directly.
class Accessory {
  final String id;
  final String sku;
  final String name;

  /// 'case' | 'cleaningSolution' | 'cloth' | 'chain' | 'repairKit' | 'other'.
  final String category;

  final String brand;
  final double price;
  final double cost;
  final String supplier;
  final int stock;

  Accessory({
    required this.id,
    required this.sku,
    required this.name,
    this.category = 'other',
    this.brand = '',
    this.price = 0,
    this.cost = 0,
    this.supplier = '',
    this.stock = 0,
  });

  Accessory copyWith({int? stock, double? price, double? cost}) {
    return Accessory(
      id: id,
      sku: sku,
      name: name,
      category: category,
      brand: brand,
      price: price ?? this.price,
      cost: cost ?? this.cost,
      supplier: supplier,
      stock: stock ?? this.stock,
    );
  }
}
