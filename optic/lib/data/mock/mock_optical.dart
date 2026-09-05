import '../../models/optical_consultation.dart';
import '../../models/prescription.dart';
import '../../models/measurement.dart';
import '../../models/frame.dart';
import '../../models/lens.dart';
import '../../models/contact_lens.dart';

/// Mock data for modules 2-6 of the optical-retail architecture spec
/// (Prescriptions, Measurements, Frame Inventory, Lens Catalog, Contact
/// Lenses) — kept in its own file rather than folded into
/// `mock_clients.dart`, which was already large before the pivot. Client
/// IDs referenced below (P001, P003-P010, P011-P013) match the ones seeded
/// in `mock_clients.dart`.
final DateTime _today = DateTime.now();
DateTime _daysAgo(int days) => _today.subtract(Duration(days: days));

/// Optical consultations — the lifestyle/visual-needs intake that precedes
/// the prescription/measurement pair below for the same visit, for the
/// handful of clients with a full funnel on file.
final List<OpticalConsultation> mockConsultations = [];

/// Prescriptions — one or two per "established" client (the ones who
/// already have prior EyeExams), reusing the same SPH/CYL/AXIS numbers
/// those exams recorded so a client's file reads consistently across
/// modules instead of contradicting itself.
final List<Prescription> mockPrescriptions = [];

/// Measurements — one per client who also has a prescription above, so a
/// frame/lens order (once module 9 exists) would have everything it needs
/// on file already.
final List<Measurement> mockMeasurements = [];

/// Frame inventory — a handful of brands/models across colors and sizes,
/// with a couple deliberately low on stock so `FrameInventoryScreen`'s
/// "low stock" KPI has something real to count.
final List<Frame> mockFrames = [];

/// Lens catalog — a spread of types and coating packages so the catalog
/// screen's filters have real variety to show.
final List<Lens> mockLenses = [];

/// Contact lens products — box goods the store stocks and sells directly,
/// separate from any client's actual fitted prescription below.
final List<ContactLensProduct> mockContactLensProducts = [];

/// A few clients with an active contact lens prescription on file.
final List<ContactLensPrescription> mockContactLensPrescriptions = [];
