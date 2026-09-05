import '../../models/quality_check.dart';
import '../../models/final_fitting.dart';
import '../../models/delivery_record.dart';
import '../../models/after_sales_ticket.dart';
import '../../models/repair_ticket.dart';
import '../../models/warranty_claim.dart';
import '../../models/supplier.dart';
import '../../models/purchase_order.dart';

/// Mock data for modules 15-22 of the optical-retail architecture spec
/// (Quality Control, Final Fitting, Delivery, After-Sales, Repairs,
/// Warranty, Suppliers, Purchasing) — same reasoning as
/// `mock_operations.dart` for modules 7-14. Order/client IDs referenced
/// below match `mock_operations.dart`/`mock_clients.dart`.
final DateTime _today = DateTime.now();
DateTime _daysAgo(int days) => _today.subtract(Duration(days: days));

/// Quality checks — tied to the same orders `mock_operations.dart` already
/// has lab work for, mostly passing with one conditional pass.
final List<QualityCheck> mockQualityChecks = [];

/// Final fittings — adjustment sessions for delivered/ready orders.
final List<FinalFitting> mockFinalFittings = [];

/// Delivery records — the final handoff for completed orders, plus one
/// still scheduled so the KPI has something in flight.
final List<DeliveryRecord> mockDeliveryRecords = [];

/// After-sales tickets — a couple raised after delivery, one already
/// resolved and one still open.
final List<AfterSalesTicket> mockAfterSalesTickets = [];

/// Repair tickets — spanning statuses, one with cost already recorded.
final List<RepairTicket> mockRepairTickets = [];

/// Warranty claims — mostly against frames still within their
/// `warrantyMonths` window.
final List<WarrantyClaim> mockWarrantyClaims = [];

/// Suppliers — the vendors already named in `mock_optical.dart`'s frame/
/// lens/contact lens `supplier` fields, given full directory entries here.
final List<Supplier> mockSuppliers = [];

/// Purchase orders — spanning the procurement pipeline statuses, mostly
/// restocking the lower-stock items already flagged in `mock_optical.dart`.
final List<PurchaseOrder> mockPurchaseOrders = [];
