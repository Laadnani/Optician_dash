/// Module 21 — Suppliers (Procurement). Directory of vendors the store
/// orders from — the `supplier` free-text field already on [Frame]/[Lens]/
/// [ContactLensProduct]/[Accessory] names one of these by name; this is
/// the standalone record with contact/terms detail, and what
/// [PurchaseOrder] (module 22) references by id.
class Supplier {
  final String id;
  final String name;

  /// 'frames' | 'lenses' | 'contactLenses' | 'accessories' | 'general'.
  final String category;

  final String contactPerson;
  final String phone;
  final String email;
  final String paymentTerms;

  /// 1-5.
  final int rating;

  Supplier({
    required this.id,
    required this.name,
    this.category = 'general',
    this.contactPerson = '',
    this.phone = '',
    this.email = '',
    this.paymentTerms = '',
    this.rating = 5,
  });
}
