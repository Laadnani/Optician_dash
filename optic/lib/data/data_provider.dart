import 'dart:async';

// `cloud_firestore` also exports an `Order` symbol (its query-ordering enum),
// which collides with our own `Order` model (lib/models/order.dart) — hiding
// it here is what fixes the "Order is imported from both..." build error.
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/material.dart';

import 'firestore_mappers.dart';
import '../models/client.dart';
import '../models/appointment.dart';
import '../models/eye_exam.dart';
import '../models/billing.dart';
import '../models/payments.dart';
import '../models/insurance.dart';
import '../models/document.dart';
import '../models/digital_signature.dart';
import '../models/optical_consultation.dart';
import '../models/prescription.dart';
import '../models/measurement.dart';
import '../models/frame.dart';
import '../models/lens.dart';
import '../models/contact_lens.dart';
import '../models/communication_log.dart';
import '../models/frame_selection.dart';
import '../models/lens_recommendation.dart';
import '../models/accessory.dart';
import '../models/quote.dart';
import '../models/order.dart';
import '../models/lab_work_order.dart';
import '../models/mounting_job.dart';
import '../models/quality_check.dart';
import '../models/final_fitting.dart';
import '../models/delivery_record.dart';
import '../models/after_sales_ticket.dart';
import '../models/repair_ticket.dart';
import '../models/warranty_claim.dart';
import '../models/supplier.dart';
import '../models/purchase_order.dart';

/// The app's data layer — every record list a screen reads through
/// `ClientRepository`/`DashboardRepository` (or directly via
/// `context.watch<DataProvider>()`) lives here. Each list starts empty and
/// is populated live from Cloud Firestore once [attachTenant] is called —
/// there's no more mock-data seeding; that in-memory-only phase of the
/// project is over.
///
/// **Tenant scoping.** Every collection lives under
/// `tenants/{tenantId}/<collection>` — see the Firebase migration guide's
/// Step 4/5 for why: this is a multi-tenant app (separate optician shops),
/// and the path itself is what keeps one shop's data from ever being
/// fetched alongside another's, backed up by the Firestore security rules
/// in `firestore.rules`. [attachTenant] is called once, right after
/// `TenantSession` resolves which tenant the signed-in user belongs to
/// (wired in `main.dart`) — nothing before that point should call any
/// `addX`/`updateX` method, since there's no tenant path to write to yet.
///
/// **Reads** are live Firestore listeners: the moment a document changes —
/// on this device or any other device signed into the same tenant — the
/// matching list here updates and `notifyListeners()` fires, exactly like
/// the old in-memory version, just backed by something durable and shared
/// now. **Writes** (`addX`/`updateX`) go straight to Firestore; the list
/// itself is never mutated directly by them — the listener is what brings
/// the change back in, which is also what makes multi-device sync work
/// without any extra plumbing.
class DataProvider extends ChangeNotifier {
  String? _tenantId;
  final List<StreamSubscription<QuerySnapshot<Map<String, dynamic>>>> _subs =
      [];

  /// Which tenant's data this instance is currently attached to, or null
  /// before the first [attachTenant] call (or after [detachTenant]). Only
  /// used by `main.dart`'s sync widget to avoid redundantly re-attaching on
  /// every rebuild — screens have no reason to read this.
  String? get attachedTenantId => _tenantId;

  final List<Client> clients = [];
  final List<Appointment> appointments = [];
  final List<EyeExam> eyeExams = [];
  final List<Invoice> invoices = [];
  final List<Payment> payments = [];
  final List<Insurance> insurances = [];
  final List<DocumentRecord> documents = [];
  final List<DigitalSignature> signatures = [];

  // --- Optical Consultation (CRM flow diagram) ------------------------------
  final List<OpticalConsultation> consultations = [];

  // --- Modules 2-6 (optical-retail architecture spec) ---------------------
  final List<Prescription> prescriptions = [];
  final List<Measurement> measurements = [];
  final List<Frame> frames = [];
  final List<Lens> lenses = [];
  final List<ContactLensProduct> contactLensProducts = [];
  final List<ContactLensPrescription> contactLensPrescriptions = [];

  // --- Modules 7-14 (optical-retail architecture spec) ---------------------
  final List<CommunicationLog> communicationLogs = [];
  final List<FrameSelectionSession> frameSelectionSessions = [];
  final List<LensRecommendation> lensRecommendations = [];
  final List<Accessory> accessories = [];
  final List<Quote> quotes = [];
  final List<Order> orders = [];
  final List<LabWorkOrder> labWorkOrders = [];
  final List<MountingJob> mountingJobs = [];

  // --- Modules 15-22 (optical-retail architecture spec) --------------------
  final List<QualityCheck> qualityChecks = [];
  final List<FinalFitting> finalFittings = [];
  final List<DeliveryRecord> deliveryRecords = [];
  final List<AfterSalesTicket> afterSalesTickets = [];
  final List<RepairTicket> repairTickets = [];
  final List<WarrantyClaim> warrantyClaims = [];
  final List<Supplier> suppliers = [];
  final List<PurchaseOrder> purchaseOrders = [];

  // --- Tenant attach/detach lifecycle --------------------------------------

  CollectionReference<Map<String, dynamic>> _tenantCollection(String name) {
    final tenantId = _tenantId;
    if (tenantId == null) {
      throw StateError(
        "DataProvider.$name accessed before attachTenant() — the auth gate "
        "should guarantee a tenant is attached before any screen can read "
        "or write data.",
      );
    }
    return FirebaseFirestore.instance.collection('tenants/$tenantId/$name');
  }

  /// One listener per collection, hydrating [target] from Firestore and
  /// keeping it live from then on. Called once per module inside
  /// [attachTenant].
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>> _watch<T>(
    String collection,
    List<T> target,
    T Function(Map<String, dynamic>) fromMap,
  ) {
    return _tenantCollection(collection).snapshots().listen((snapshot) {
      target
        ..clear()
        ..addAll(snapshot.docs.map((doc) => fromMap(doc.data())));
      notifyListeners();
    });
  }

  /// Call once the signed-in user's tenant is known (see `main.dart`'s
  /// `TenantSession` sync). Safe to call again for a different tenant (e.g.
  /// signing out and a different person signing into a different shop on
  /// the same device) — tears down the previous tenant's listeners/data
  /// first via [detachTenant].
  void attachTenant(String tenantId) {
    if (_tenantId == tenantId) return; // already attached, nothing to do
    detachTenant();
    _tenantId = tenantId;
    _subs.addAll([
      _watch('clients', clients, clientFromMap),
      _watch('appointments', appointments, appointmentFromMap),
      _watch('eyeExams', eyeExams, eyeExamFromMap),
      _watch('invoices', invoices, invoiceFromMap),
      _watch('payments', payments, paymentFromMap),
      _watch('insurances', insurances, insuranceFromMap),
      _watch('documents', documents, documentRecordFromMap),
      _watch('signatures', signatures, digitalSignatureFromMap),
      _watch('consultations', consultations, opticalConsultationFromMap),
      _watch('prescriptions', prescriptions, prescriptionFromMap),
      _watch('measurements', measurements, measurementFromMap),
      _watch('frames', frames, frameFromMap),
      _watch('lenses', lenses, lensFromMap),
      _watch(
        'contactLensProducts',
        contactLensProducts,
        contactLensProductFromMap,
      ),
      _watch(
        'contactLensPrescriptions',
        contactLensPrescriptions,
        contactLensPrescriptionFromMap,
      ),
      _watch('communicationLogs', communicationLogs, communicationLogFromMap),
      _watch(
        'frameSelectionSessions',
        frameSelectionSessions,
        frameSelectionSessionFromMap,
      ),
      _watch(
        'lensRecommendations',
        lensRecommendations,
        lensRecommendationFromMap,
      ),
      _watch('accessories', accessories, accessoryFromMap),
      _watch('quotes', quotes, quoteFromMap),
      _watch('orders', orders, orderFromMap),
      _watch('labWorkOrders', labWorkOrders, labWorkOrderFromMap),
      _watch('mountingJobs', mountingJobs, mountingJobFromMap),
      _watch('qualityChecks', qualityChecks, qualityCheckFromMap),
      _watch('finalFittings', finalFittings, finalFittingFromMap),
      _watch('deliveryRecords', deliveryRecords, deliveryRecordFromMap),
      _watch('afterSalesTickets', afterSalesTickets, afterSalesTicketFromMap),
      _watch('repairTickets', repairTickets, repairTicketFromMap),
      _watch('warrantyClaims', warrantyClaims, warrantyClaimFromMap),
      _watch('suppliers', suppliers, supplierFromMap),
      _watch('purchaseOrders', purchaseOrders, purchaseOrderFromMap),
    ]);
  }

  /// Cancels every live listener and empties every list — called at the
  /// start of [attachTenant] (to clean up a previous tenant, if any) and
  /// from `main.dart` the moment `TenantSession` no longer has a ready
  /// tenant (signed out, or still resolving). Safe to call repeatedly.
  void detachTenant() {
    for (final sub in _subs) {
      sub.cancel();
    }
    _subs.clear();
    _tenantId = null;
    clients.clear();
    appointments.clear();
    eyeExams.clear();
    invoices.clear();
    payments.clear();
    insurances.clear();
    documents.clear();
    signatures.clear();
    consultations.clear();
    prescriptions.clear();
    measurements.clear();
    frames.clear();
    lenses.clear();
    contactLensProducts.clear();
    contactLensPrescriptions.clear();
    communicationLogs.clear();
    frameSelectionSessions.clear();
    lensRecommendations.clear();
    accessories.clear();
    quotes.clear();
    orders.clear();
    labWorkOrders.clear();
    mountingJobs.clear();
    qualityChecks.clear();
    finalFittings.clear();
    deliveryRecords.clear();
    afterSalesTickets.clear();
    repairTickets.clear();
    warrantyClaims.clear();
    suppliers.clear();
    purchaseOrders.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    detachTenant();
    super.dispose();
  }

  // --- Shared write helper --------------------------------------------------
  //
  // Every model here is immutable (`final` fields, no `copyWith`), so
  // "updating" a record means building a new instance with the same `id`
  // and handing it to `updateX` — same as before, except now both `addX`
  // and `updateX` do the exact same thing: a full-document `.set()` at
  // `tenants/{tenantId}/<collection>/{id}`. Neither mutates the list
  // directly or calls `notifyListeners()` itself — the [_watch] listener
  // above picks the change back up (from Firestore's local cache
  // instantly, then the server) and that's what drives the rebuild, on
  // this device and every other device signed into the same tenant.

  void _write<T>(
    String collection,
    T item,
    Map<String, dynamic> Function(T) toMap,
    String Function(T) idOf,
  ) {
    _tenantCollection(collection).doc(idOf(item)).set(toMap(item));
  }

  // --- Shared delete helper ---------------------------------------------
  //
  // Same shape as [_write]: fires the Firestore delete and lets the
  // [_watch] listener above bring the removal back into the in-memory list
  // (on this device and every other device signed into the same tenant) —
  // nothing here mutates a list or calls notifyListeners() directly.
  void _delete(String collection, String id) {
    _tenantCollection(collection).doc(id).delete();
  }

  // --- Clients --------------------------------------------------------------
  void addClient(Client client) =>
      _write('clients', client, (c) => c.toMap(), (c) => c.id);
  void updateClient(Client client) => addClient(client);
  void deleteClient(String id) => _delete('clients', id);

  /// Deletes a client's own profile plus every clinical/service record
  /// elsewhere in the data model that references it via `clientId` —
  /// Appointments, Eye Exams, Documents, Digital Signatures, Optical
  /// Consultations, Prescriptions, Measurements, Contact Lens
  /// Prescriptions, Communication Logs, Frame Selection Sessions, Lens
  /// Recommendations, Insurance, Lab Work Orders, Mounting Jobs, Quality
  /// Checks, Final Fittings, Delivery Records, After-Sales Tickets, Repair
  /// Tickets, and Warranty Claims.
  ///
  /// Deliberately leaves the financial/profit trail on file even after the
  /// client profile is gone: Orders, Quotes, Invoices, Payments, and
  /// Purchase Orders are never touched by this method, no matter whose
  /// `clientId` they carry — call [deleteClient] directly if you ever need
  /// the bare client-only delete instead.
  ///
  /// Runs as a single Firestore batch so it's all-or-nothing rather than a
  /// partial cascade if something fails halfway through.
  Future<void> deleteClientAndRelatedRecords(String clientId) async {
    final batch = FirebaseFirestore.instance.batch();

    void deleteWhere<T>(
      String collection,
      List<T> source,
      bool Function(T) matches,
      String Function(T) idOf,
    ) {
      for (final item in source.where(matches)) {
        batch.delete(_tenantCollection(collection).doc(idOf(item)));
      }
    }

    deleteWhere(
      'appointments',
      appointments,
      (a) => a.clientId == clientId,
      (a) => a.id,
    );
    deleteWhere('eyeExams', eyeExams, (e) => e.clientId == clientId, (e) => e.id);
    deleteWhere(
      'insurances',
      insurances,
      (i) => i.clientId == clientId,
      (i) => i.id,
    );
    deleteWhere(
      'documents',
      documents,
      (d) => d.clientId == clientId,
      (d) => d.id,
    );
    deleteWhere(
      'signatures',
      signatures,
      (s) => s.clientId == clientId,
      (s) => s.id,
    );
    deleteWhere(
      'consultations',
      consultations,
      (c) => c.clientId == clientId,
      (c) => c.id,
    );
    deleteWhere(
      'prescriptions',
      prescriptions,
      (p) => p.clientId == clientId,
      (p) => p.id,
    );
    deleteWhere(
      'measurements',
      measurements,
      (m) => m.clientId == clientId,
      (m) => m.id,
    );
    deleteWhere(
      'contactLensPrescriptions',
      contactLensPrescriptions,
      (c) => c.clientId == clientId,
      (c) => c.id,
    );
    deleteWhere(
      'communicationLogs',
      communicationLogs,
      (l) => l.clientId == clientId,
      (l) => l.id,
    );
    deleteWhere(
      'frameSelectionSessions',
      frameSelectionSessions,
      (s) => s.clientId == clientId,
      (s) => s.id,
    );
    deleteWhere(
      'lensRecommendations',
      lensRecommendations,
      (r) => r.clientId == clientId,
      (r) => r.id,
    );
    deleteWhere(
      'labWorkOrders',
      labWorkOrders,
      (w) => w.clientId == clientId,
      (w) => w.id,
    );
    deleteWhere(
      'mountingJobs',
      mountingJobs,
      (j) => j.clientId == clientId,
      (j) => j.id,
    );
    deleteWhere(
      'qualityChecks',
      qualityChecks,
      (c) => c.clientId == clientId,
      (c) => c.id,
    );
    deleteWhere(
      'finalFittings',
      finalFittings,
      (f) => f.clientId == clientId,
      (f) => f.id,
    );
    deleteWhere(
      'deliveryRecords',
      deliveryRecords,
      (d) => d.clientId == clientId,
      (d) => d.id,
    );
    deleteWhere(
      'afterSalesTickets',
      afterSalesTickets,
      (t) => t.clientId == clientId,
      (t) => t.id,
    );
    deleteWhere(
      'repairTickets',
      repairTickets,
      (t) => t.clientId == clientId,
      (t) => t.id,
    );
    deleteWhere(
      'warrantyClaims',
      warrantyClaims,
      (c) => c.clientId == clientId,
      (c) => c.id,
    );

    batch.delete(_tenantCollection('clients').doc(clientId));

    await batch.commit();
  }

  // --- Appointments ------------------------------------------------------------
  void addAppointment(Appointment appointment) => _write(
    'appointments',
    appointment,
    (a) => a.toMap(),
    (a) => a.id,
  );
  void updateAppointment(Appointment appointment) => addAppointment(appointment);
  void deleteAppointment(String id) => _delete('appointments', id);

  // --- Eye exams -----------------------------------------------------------------
  void addEyeExam(EyeExam exam) =>
      _write('eyeExams', exam, (e) => e.toMap(), (e) => e.id);
  void updateEyeExam(EyeExam exam) => addEyeExam(exam);
  void deleteEyeExam(String id) => _delete('eyeExams', id);

  // --- Billing: invoices & payments ------------------------------------------------
  void addInvoice(Invoice invoice) =>
      _write('invoices', invoice, (i) => i.toMap(), (i) => i.id);
  void updateInvoice(Invoice invoice) => addInvoice(invoice);
  void deleteInvoice(String id) => _delete('invoices', id);

  void addPayment(Payment payment) =>
      _write('payments', payment, (p) => p.toMap(), (p) => p.id);
  void updatePayment(Payment payment) => addPayment(payment);
  void deletePayment(String id) => _delete('payments', id);

  // --- Insurance -------------------------------------------------------------------------------
  void addInsurance(Insurance insurance) =>
      _write('insurances', insurance, (i) => i.toMap(), (i) => i.id);
  void updateInsurance(Insurance insurance) => addInsurance(insurance);
  void deleteInsurance(String id) => _delete('insurances', id);

  // --- Documents -----------------------------------------------------------------------------------
  void addDocument(DocumentRecord document) =>
      _write('documents', document, (d) => d.toMap(), (d) => d.id);
  void updateDocument(DocumentRecord document) => addDocument(document);
  void deleteDocument(String id) => _delete('documents', id);

  // --- Digital signatures ---------------------------------------------------------------------------
  void addSignature(DigitalSignature signature) =>
      _write('signatures', signature, (s) => s.toMap(), (s) => s.id);
  void updateSignature(DigitalSignature signature) => addSignature(signature);
  void deleteSignature(String id) => _delete('signatures', id);

  // --- Optical Consultation (CRM flow diagram) ------------------------------
  void addConsultation(OpticalConsultation consultation) => _write(
    'consultations',
    consultation,
    (c) => c.toMap(),
    (c) => c.id,
  );
  void updateConsultation(OpticalConsultation consultation) =>
      addConsultation(consultation);
  void deleteConsultation(String id) => _delete('consultations', id);

  // --- Prescriptions (module 2) -----------------------------------------------------------
  void addPrescription(Prescription prescription) => _write(
    'prescriptions',
    prescription,
    (p) => p.toMap(),
    (p) => p.id,
  );
  void updatePrescription(Prescription prescription) =>
      addPrescription(prescription);
  void deletePrescription(String id) => _delete('prescriptions', id);

  // --- Measurements (module 3) ------------------------------------------------------------
  void addMeasurement(Measurement measurement) => _write(
    'measurements',
    measurement,
    (m) => m.toMap(),
    (m) => m.id,
  );
  void updateMeasurement(Measurement measurement) => addMeasurement(measurement);
  void deleteMeasurement(String id) => _delete('measurements', id);

  // --- Frame inventory (module 4) ---------------------------------------------------------
  void addFrame(Frame frame) =>
      _write('frames', frame, (f) => f.toMap(), (f) => f.id);
  void updateFrame(Frame frame) => addFrame(frame);
  void deleteFrame(String id) => _delete('frames', id);

  // --- Lens catalog (module 5) ------------------------------------------------------------
  void addLens(Lens lens) =>
      _write('lenses', lens, (l) => l.toMap(), (l) => l.id);
  void updateLens(Lens lens) => addLens(lens);
  void deleteLens(String id) => _delete('lenses', id);

  // --- Contact lenses (module 6) ----------------------------------------------------------
  void addContactLensProduct(ContactLensProduct product) => _write(
    'contactLensProducts',
    product,
    (p) => p.toMap(),
    (p) => p.id,
  );
  void updateContactLensProduct(ContactLensProduct product) =>
      addContactLensProduct(product);
  void deleteContactLensProduct(String id) => _delete('contactLensProducts', id);

  void addContactLensPrescription(ContactLensPrescription prescription) =>
      _write(
        'contactLensPrescriptions',
        prescription,
        (p) => p.toMap(),
        (p) => p.id,
      );
  void updateContactLensPrescription(ContactLensPrescription prescription) =>
      addContactLensPrescription(prescription);
  void deleteContactLensPrescription(String id) => _delete('contactLensPrescriptions', id);

  // --- Communication (module 7) -----------------------------------------------------------
  void addCommunicationLog(CommunicationLog log) => _write(
    'communicationLogs',
    log,
    (l) => l.toMap(),
    (l) => l.id,
  );
  void updateCommunicationLog(CommunicationLog log) => addCommunicationLog(log);
  void deleteCommunicationLog(String id) => _delete('communicationLogs', id);

  // --- Frame selection / virtual sale (module 8) -------------------------------------------
  void addFrameSelectionSession(FrameSelectionSession session) => _write(
    'frameSelectionSessions',
    session,
    (s) => s.toMap(),
    (s) => s.id,
  );
  void updateFrameSelectionSession(FrameSelectionSession session) =>
      addFrameSelectionSession(session);
  void deleteFrameSelectionSession(String id) => _delete('frameSelectionSessions', id);

  // --- Lens recommendation (module 9) -------------------------------------------------------
  void addLensRecommendation(LensRecommendation recommendation) => _write(
    'lensRecommendations',
    recommendation,
    (r) => r.toMap(),
    (r) => r.id,
  );
  void updateLensRecommendation(LensRecommendation recommendation) =>
      addLensRecommendation(recommendation);
  void deleteLensRecommendation(String id) => _delete('lensRecommendations', id);

  // --- Accessories (module 10) --------------------------------------------------------------
  void addAccessory(Accessory accessory) =>
      _write('accessories', accessory, (a) => a.toMap(), (a) => a.id);
  void updateAccessory(Accessory accessory) => addAccessory(accessory);
  void deleteAccessory(String id) => _delete('accessories', id);

  // --- Quotes (module 11) ---------------------------------------------------------------------
  void addQuote(Quote quote) =>
      _write('quotes', quote, (q) => q.toMap(), (q) => q.id);
  void updateQuote(Quote quote) => addQuote(quote);
  void deleteQuote(String id) => _delete('quotes', id);

  // --- Orders (module 12) ---------------------------------------------------------------------
  void addOrder(Order order) =>
      _write('orders', order, (o) => o.toMap(), (o) => o.id);
  void updateOrder(Order order) => addOrder(order);
  void deleteOrder(String id) => _delete('orders', id);

  // --- Laboratory (module 13) -------------------------------------------------------------------
  void addLabWorkOrder(LabWorkOrder workOrder) => _write(
    'labWorkOrders',
    workOrder,
    (w) => w.toMap(),
    (w) => w.id,
  );
  void updateLabWorkOrder(LabWorkOrder workOrder) => addLabWorkOrder(workOrder);
  void deleteLabWorkOrder(String id) => _delete('labWorkOrders', id);

  // --- Mounting (module 14) -------------------------------------------------------------------
  void addMountingJob(MountingJob job) =>
      _write('mountingJobs', job, (j) => j.toMap(), (j) => j.id);
  void updateMountingJob(MountingJob job) => addMountingJob(job);
  void deleteMountingJob(String id) => _delete('mountingJobs', id);

  // --- Quality control (module 15) --------------------------------------------------------------
  void addQualityCheck(QualityCheck check) =>
      _write('qualityChecks', check, (c) => c.toMap(), (c) => c.id);
  void updateQualityCheck(QualityCheck check) => addQualityCheck(check);
  void deleteQualityCheck(String id) => _delete('qualityChecks', id);

  // --- Final fitting (module 16) ----------------------------------------------------------------
  void addFinalFitting(FinalFitting fitting) => _write(
    'finalFittings',
    fitting,
    (f) => f.toMap(),
    (f) => f.id,
  );
  void updateFinalFitting(FinalFitting fitting) => addFinalFitting(fitting);
  void deleteFinalFitting(String id) => _delete('finalFittings', id);

  // --- Delivery (module 17) ---------------------------------------------------------------------
  void addDeliveryRecord(DeliveryRecord record) => _write(
    'deliveryRecords',
    record,
    (d) => d.toMap(),
    (d) => d.id,
  );
  void updateDeliveryRecord(DeliveryRecord record) => addDeliveryRecord(record);
  void deleteDeliveryRecord(String id) => _delete('deliveryRecords', id);

  // --- After-sales (module 18) ------------------------------------------------------------------
  void addAfterSalesTicket(AfterSalesTicket ticket) => _write(
    'afterSalesTickets',
    ticket,
    (t) => t.toMap(),
    (t) => t.id,
  );
  void updateAfterSalesTicket(AfterSalesTicket ticket) =>
      addAfterSalesTicket(ticket);
  void deleteAfterSalesTicket(String id) => _delete('afterSalesTickets', id);

  // --- Repairs (module 19) ----------------------------------------------------------------------
  void addRepairTicket(RepairTicket ticket) =>
      _write('repairTickets', ticket, (t) => t.toMap(), (t) => t.id);
  void updateRepairTicket(RepairTicket ticket) => addRepairTicket(ticket);
  void deleteRepairTicket(String id) => _delete('repairTickets', id);

  // --- Warranty (module 20) ---------------------------------------------------------------------
  void addWarrantyClaim(WarrantyClaim claim) =>
      _write('warrantyClaims', claim, (c) => c.toMap(), (c) => c.id);
  void updateWarrantyClaim(WarrantyClaim claim) => addWarrantyClaim(claim);
  void deleteWarrantyClaim(String id) => _delete('warrantyClaims', id);

  // --- Suppliers (module 21) --------------------------------------------------------------------
  void addSupplier(Supplier supplier) =>
      _write('suppliers', supplier, (s) => s.toMap(), (s) => s.id);
  void updateSupplier(Supplier supplier) => addSupplier(supplier);
  void deleteSupplier(String id) => _delete('suppliers', id);

  // --- Purchasing (module 22) -------------------------------------------------------------------
  void addPurchaseOrder(PurchaseOrder order) => _write(
    'purchaseOrders',
    order,
    (o) => o.toMap(),
    (o) => o.id,
  );
  void updatePurchaseOrder(PurchaseOrder order) => addPurchaseOrder(order);
  void deletePurchaseOrder(String id) => _delete('purchaseOrders', id);
}
