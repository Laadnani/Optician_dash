import '../../models/communication_log.dart';
import '../../models/frame_selection.dart';
import '../../models/lens_recommendation.dart';
import '../../models/accessory.dart';
import '../../models/quote.dart';
import '../../models/order.dart';
import '../../models/lab_work_order.dart';
import '../../models/mounting_job.dart';

/// Mock data for modules 7-14 of the optical-retail architecture spec
/// (Communication, Frame Selection/Virtual Sale, Lens Recommendation,
/// Accessories, Quotes, Orders, Laboratory, Mounting) — kept in its own
/// file, same reasoning as `mock_optical.dart` for modules 2-6. Client IDs
/// referenced below match `mock_clients.dart`; frame/lens IDs match
/// `mock_optical.dart`.
final DateTime _today = DateTime.now();
DateTime _daysAgo(int days) => _today.subtract(Duration(days: days));

/// Communication log — a spread of channels/directions across several
/// clients, with a couple flagged for follow-up so that KPI has something
/// real to count.
final List<CommunicationLog> mockCommunicationLogs = [];

/// Frame selection / virtual sale sessions — a few in-store, a couple
/// virtual, some resulting in a selection (referencing frame IDs from
/// `mock_optical.dart`) and some still undecided.
final List<FrameSelectionSession> mockFrameSelectionSessions = [];

/// Lens recommendations — tied to prescriptions on file where relevant,
/// mixing accepted and not-yet-accepted outcomes.
final List<LensRecommendation> mockLensRecommendations = [];

/// Accessories catalog — cases, cleaning kits, chains, one low-stock item.
final List<Accessory> mockAccessories = [];

/// Quotes — spanning every status so the KPI/pending-value metrics have
/// real variety.
final List<Quote> mockQuotes = [];

/// Orders — some linked back to accepted quotes, spanning the production
/// pipeline statuses that `LabWorkOrder`/`MountingJob` below hang off of.
final List<Order> mockOrders = [];

/// Laboratory work orders — production tasks for the two in-flight orders
/// above, including one overdue job (deliberately, for the KPI).
final List<LabWorkOrder> mockLabWorkOrders = [];

/// Mounting jobs — frame + lens assembly for orders that have (or had)
/// lab work completed, referencing frame/lens IDs from `mock_optical.dart`.
final List<MountingJob> mockMountingJobs = [];
