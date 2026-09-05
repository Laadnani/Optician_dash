import 'package:flutter/material.dart' as material;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:optic/app_shell.dart';
import 'package:optic/data/data_provider.dart';
import 'package:optic/data/client_repository.dart';
import 'package:optic/helpers/add_appointment_dialog.dart';
import 'package:optic/helpers/add_record_dialog.dart';
import 'package:optic/helpers/breakpoint.dart';
import 'package:optic/helpers/confirm_dialog.dart';
import 'package:optic/helpers/empty_state.dart';
import 'package:optic/helpers/journey_status_row.dart';
import 'package:optic/helpers/nav_items.dart';
import 'package:optic/helpers/status_chip.dart';
import 'package:optic/localization/app_strings.dart';
import 'package:optic/models/appointment.dart';
import 'package:optic/models/billing.dart';
import 'package:optic/models/digital_signature.dart';
import 'package:optic/models/document.dart';
import 'package:optic/models/eye_exam.dart';
import 'package:optic/models/insurance.dart';
import 'package:optic/models/client.dart';
import 'package:optic/models/payments.dart';
import 'package:optic/models/prescription.dart';
import 'package:optic/models/measurement.dart';
import 'package:optic/models/contact_lens.dart';
import 'package:optic/models/client_timeline_event.dart';
import 'package:optic/widgets/appointment_card.dart';
import 'package:optic/widgets/billing_card.dart';
import 'package:optic/widgets/digital_signature_card.dart';
import 'package:optic/widgets/document_card.dart';
import 'package:optic/widgets/eye_exam_card.dart';
import 'package:optic/widgets/insurance_card.dart';
import 'package:optic/widgets/payments_card.dart';
import 'package:optic/widgets/prescription_card.dart';
import 'package:optic/widgets/measurement_card.dart';
import 'package:optic/widgets/contact_lens_card.dart';

/// A single client's full chart: identity header + tabs over every
/// client-linked record `DataProvider` carries. Every tab reuses the
/// `*_card.dart` widget already built for its model — this screen is what
/// finally wires them up. Data comes through [ClientRepository], same
/// "simple for now, real backend later" bridge as [DashboardRepository].
///
/// Trimmed down as part of the clinical → optical-retail pivot: the Orders
/// tab (clinical lab/imaging/DICOM/referrals) and the old medication-Rx
/// Prescriptions tab are gone; Overview is now Insurance-only and Exams is
/// now EyeExams-only. Nine tabs remain: Overview, Appointments, Exams,
/// Prescriptions (module 2, optical Rx), Measurements (module 3), Contact
/// Lens (module 6), Billing, Documents, and Timeline — the CRM flow
/// diagram's "Client Timeline" node, merging every other retail module
/// (Consultation, Frame Selection, Quotes, Orders, Lab, Mounting, QC,
/// Fitting, Delivery, After-Sales, Repairs, Warranty, Communication) into
/// one chronological feed via `deriveClientTimeline`.
class ClientFileScreen extends StatelessWidget {
  final String clientId;
  const ClientFileScreen({super.key, required this.clientId});

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();
    final repository = ProviderClientRepository(dataProvider);

    return AppShell(
      // Stays on the "Clients" nav entry — this screen is a drill-down
      // from the clients list, not its own top-level destination.
      navItems: (context) => buildAppNavItems(context, NavRoute.clients),
      bodyBuilder: (context, breakpoint) => _ClientFileBody(
        clientId: clientId,
        breakpoint: breakpoint,
        repository: repository,
      ),
    );
  }
}

/// Everything a client's file needs, fetched once per load and handed to
/// every tab. Plain data holder — no behavior.
class _ClientFileData {
  final Client? client;
  final List<Appointment> appointments;
  final List<EyeExam> eyeExams;
  final List<Invoice> invoices;
  final List<Payment> payments;
  final List<Insurance> insurances;
  final List<DocumentRecord> documents;
  final List<DigitalSignature> signatures;
  final ClientMetrics metrics;
  final List<Prescription> prescriptions;
  final List<Measurement> measurements;
  final List<ContactLensPrescription> contactLensPrescriptions;
  final List<ClientTimelineEvent> timeline;

  const _ClientFileData({
    required this.client,
    required this.appointments,
    required this.eyeExams,
    required this.invoices,
    required this.payments,
    required this.insurances,
    required this.documents,
    required this.signatures,
    required this.metrics,
    required this.prescriptions,
    required this.measurements,
    required this.contactLensPrescriptions,
    required this.timeline,
  });
}

class _ClientFileBody extends StatefulWidget {
  final String clientId;
  final Breakpoint breakpoint;
  final ClientRepository repository;

  const _ClientFileBody({
    required this.clientId,
    required this.breakpoint,
    required this.repository,
  });

  @override
  State<_ClientFileBody> createState() => _ClientFileBodyState();
}

class _ClientFileBodyState extends State<_ClientFileBody> {
  _ClientFileData? _data;
  bool _isLoading = true;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant _ClientFileBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Either a different client (navigated file-to-file) or DataProvider
    // notified (e.g. a record was added elsewhere) — either way, re-fetch.
    if (oldWidget.clientId != widget.clientId ||
        oldWidget.repository != widget.repository) {
      setState(() {
        _isLoading = true;
        _tabIndex = 0;
      });
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final id = widget.clientId;
    final repo = widget.repository;

    final client = await repo.fetchClient(id);
    final appointments = await repo.fetchAppointments(id);
    final eyeExams = await repo.fetchEyeExams(id);
    final invoices = await repo.fetchInvoices(id);
    final payments = await repo.fetchPayments(id);
    final insurances = await repo.fetchInsurances(id);
    final documents = await repo.fetchDocuments(id);
    final signatures = await repo.fetchSignatures(id);
    final metrics = await repo.fetchClientMetrics(id);
    final prescriptions = await repo.fetchPrescriptions(id);
    final measurements = await repo.fetchMeasurements(id);
    final contactLensPrescriptions = await repo.fetchContactLensPrescriptions(
      id,
    );
    final timeline = await repo.fetchClientTimeline(id);

    if (!mounted) return;
    setState(() {
      _data = _ClientFileData(
        client: client,
        appointments: appointments,
        eyeExams: eyeExams,
        invoices: invoices,
        payments: payments,
        insurances: insurances,
        documents: documents,
        signatures: signatures,
        metrics: metrics,
        prescriptions: prescriptions,
        measurements: measurements,
        contactLensPrescriptions: contactLensPrescriptions,
        timeline: timeline,
      );
      _isLoading = false;
    });
  }

  Widget _backButton() {
    return Button.outline(
      onPressed: () => context.go(NavRoute.clients.path),
      leading: const Icon(Icons.arrow_back, size: 16),
      child: Text(AppStrings.clientFileBackToClients),
    );
  }

  Widget _notFound(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_off,
              size: 40,
              color: colorScheme.mutedForeground,
            ),
            const SizedBox(height: 12),
            Text(AppStrings.clientFileNotFoundTitle).semiBold(),
            const SizedBox(height: 4),
            Text(AppStrings.clientFileNotFoundSubtitle).muted(),
            const SizedBox(height: 16),
            _backButton(),
          ],
        ),
      ),
    );
  }

  Widget _infoItem(IconData icon, String text) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 14, color: colorScheme.mutedForeground),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ).muted().small(),
        ),
      ],
    );
  }

  // Small caps label above each group of related fields — same visual
  // language `EmptyState`/section titles already use for "muted caption",
  // just smaller and letter-spaced to read as a group heading rather than
  // a value.
  Widget _groupLabel(String text, ColorScheme colorScheme) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: colorScheme.mutedForeground,
      ),
    );
  }

  // Same hairline-divider pattern already used in `appdrawer.dart` and
  // `sidebar.dart` — a themed 1px `Container` rather than a shadcn_flutter
  // `Divider` API this codebase hasn't otherwise verified.
  Widget _divider(ColorScheme colorScheme) =>
      Container(height: 1, color: colorScheme.border);

  Widget _infoGroup(
    String label,
    ColorScheme colorScheme,
    List<Widget> rows,
  ) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 150, maxWidth: 240),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _groupLabel(label, colorScheme),
          const SizedBox(height: 8),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            rows[i],
          ],
        ],
      ),
    );
  }

  String _contactMethodLabel(String method) {
    switch (method) {
      case 'sms':
        return AppStrings.contactMethodSms;
      case 'whatsapp':
        return AppStrings.contactMethodWhatsapp;
      case 'email':
        return AppStrings.contactMethodEmail;
      case 'phone':
      default:
        return AppStrings.contactMethodPhone;
    }
  }

  // Small stat strip for the module 1 derived metrics (first/last visit,
  // total purchases, lifetime value) — deliberately not full
  // `DashboardStatCard` tiles (those assume a grid cell of their own); this
  // is a compact inline row that fits under the header's info groups
  // without pushing the card's height around on every screen size.
  Widget _metricItem(String label, String value, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value).semiBold(),
        Text(label).muted().small(),
      ],
    );
  }

  // Earliest still-scheduled appointment strictly after now — the header
  // summary card's "Next appointment" field from the redesign brief.
  // `null` means nothing upcoming (already-past/completed/cancelled
  // appointments don't count), shown as "No upcoming appointment" instead.
  DateTime? _nextAppointment(_ClientFileData data) {
    final now = DateTime.now();
    final upcoming =
        data.appointments
            .where((a) => a.status == 'scheduled' && a.date.isAfter(now))
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    return upcoming.isEmpty ? null : upcoming.first.date;
  }

  // Confirms, then deletes the client and returns to the clients list —
  // this only removes the client's own profile document; any of their
  // linked records (appointments, orders, invoices, etc.) elsewhere in the
  // data model are left in place, per [AppStrings.clientFileDeleteConfirmMessage].
  Future<void> _deleteClient(Client client) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: AppStrings.clientFileDeleteConfirmTitle,
      message: AppStrings.clientFileDeleteConfirmMessage,
      confirmLabel: AppStrings.clientFileDeleteButton,
    );
    if (confirmed != true || !mounted) return;
    await context.read<DataProvider>().deleteClientAndRelatedRecords(
      client.id,
    );
    if (mounted) context.go('/clients');
  }

  Widget _headerCard(
    Client client,
    ClientMetrics metrics,
    ColorScheme colorScheme,
    DateTime? nextAppointment,
  ) {
    final fullName = '${client.firstName} ${client.lastName}';
    final initial = fullName.trim().isNotEmpty
        ? fullName.trim().substring(0, 1).toUpperCase()
        : '?';
    final isActive = client.status == 'active';

    return Card(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Avatar(initials: initial),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ).large().bold(),
                    const SizedBox(height: 4),
                    Text(
                      client.fileNumber,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ).muted(),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusChip(
                label: isActive
                    ? AppStrings.clientStatusActive
                    : AppStrings.clientStatusInactive,
                color: isActive ? Colors.green.shade600 : colorScheme.mutedForeground,
                icon: isActive ? Icons.check_circle_outline : Icons.pause_circle_outline,
              ),
              if (client.insurance.isNotEmpty) ...[
                const SizedBox(width: 8),
                StatusChip(
                  label: client.insurance,
                  color: colorScheme.primary,
                  icon: Icons.shield_outlined,
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          // Redesign: client name + primary actions, per the designer
          // brief's client-file mockup ("[New Order]" / "[Edit]" next to
          // the name). Wrapped so it never fights the header row above on
          // narrow widths.
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              PrimaryButton(
                onPressed: () =>
                    context.go('/orders', extra: {'clientId': client.id}),
                leading: const Icon(Icons.add_shopping_cart_outlined, size: 14),
                child: Text(AppStrings.clientFileNewOrder),
              ),
              Button.outline(
                onPressed: () => context.go('/clients/${client.id}/edit'),
                leading: const Icon(Icons.edit_outlined, size: 14),
                child: Text(AppStrings.clientFileEdit),
              ),
              Button(
                style: const ButtonStyle.destructive(),
                onPressed: () => _deleteClient(client),
                leading: const Icon(Icons.delete_outline, size: 14),
                child: Text(AppStrings.clientFileDeleteButton),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _divider(colorScheme),
          const SizedBox(height: 16),
          Wrap(
            spacing: 32,
            runSpacing: 16,
            children: [
              _infoGroup(
                AppStrings.clientHeaderGroupIdentity,
                colorScheme,
                [
                  _infoItem(Icons.badge_outlined, client.fileNumber),
                  _infoItem(
                    Icons.credit_card_outlined,
                    client.nationalId.isEmpty ? '—' : client.nationalId,
                  ),
                ],
              ),
              _infoGroup(
                AppStrings.clientHeaderGroupPersonal,
                colorScheme,
                [
                  _infoItem(
                    Icons.cake_outlined,
                    '${_formatDate(client.dob)} (${_ageFromDob(client.dob)} yrs)',
                  ),
                  _infoItem(Icons.wc_outlined, client.gender),
                  _infoItem(
                    Icons.bloodtype_outlined,
                    client.bloodGroup.isEmpty ? '—' : client.bloodGroup,
                  ),
                  _infoItem(
                    Icons.work_outline,
                    client.profession.isEmpty ? '—' : client.profession,
                  ),
                ],
              ),
              _infoGroup(
                AppStrings.clientHeaderGroupContact,
                colorScheme,
                [
                  _infoItem(
                    Icons.phone_outlined,
                    client.phone.isEmpty ? '—' : client.phone,
                  ),
                  _infoItem(
                    Icons.email_outlined,
                    client.email.isEmpty ? '—' : client.email,
                  ),
                  _infoItem(
                    Icons.location_on_outlined,
                    client.address.isEmpty ? '—' : client.address,
                  ),
                  _infoItem(
                    Icons.chat_bubble_outline,
                    _contactMethodLabel(client.preferredContactMethod),
                  ),
                ],
              ),
              _infoGroup(
                AppStrings.clientHeaderGroupEmergencyContact,
                colorScheme,
                [
                  _infoItem(
                    Icons.person_outline,
                    client.emergencyContactName.isEmpty
                        ? '—'
                        : client.emergencyContactName,
                  ),
                  _infoItem(
                    Icons.phone_in_talk_outlined,
                    client.emergencyContactPhone.isEmpty
                        ? '—'
                        : client.emergencyContactPhone,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _divider(colorScheme),
          const SizedBox(height: 16),
          Wrap(
            spacing: 32,
            runSpacing: 12,
            children: [
              _metricItem(
                AppStrings.clientMetricFirstVisit,
                metrics.firstVisit == null
                    ? '—'
                    : _formatDate(metrics.firstVisit!),
                colorScheme,
              ),
              _metricItem(
                AppStrings.clientMetricLastVisit,
                metrics.lastVisit == null
                    ? '—'
                    : _formatDate(metrics.lastVisit!),
                colorScheme,
              ),
              _metricItem(
                AppStrings.clientFileNextAppointment,
                nextAppointment == null
                    ? AppStrings.clientFileNoUpcomingAppointment
                    : _formatDate(nextAppointment),
                colorScheme,
              ),
              _metricItem(
                AppStrings.clientMetricTotalPurchases,
                '${metrics.totalPurchases}',
                colorScheme,
              ),
              _metricItem(
                AppStrings.clientMetricLifetimeValue,
                '${metrics.lifetimeValue.toStringAsFixed(0)} MAD',
                colorScheme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Tabs ------------------------------------------------------------

  // Every "Add X" button below builds its model with a fresh id from this
  // (timestamp collisions are a non-issue — two buttons can't be pressed
  // in the same millisecond) and hands it to the matching `DataProvider`
  // method. `DataProvider.notifyListeners()` inside that call is what
  // makes `_loadData()` re-run via `context.watch<DataProvider>()` up in
  // `ClientFileScreen`, so the new record shows up immediately — nothing
  // here needs to manually refresh anything.
  String _newId(String prefix) =>
      '$prefix${DateTime.now().millisecondsSinceEpoch}';

  // One button style for every "Add X" trigger, gathered per tab into the
  // floating cluster `_floatingActions` renders bottom-right. Plain circle
  // when a tab only has one addable record type (nothing to disambiguate);
  // a labeled pill otherwise, so several buttons sitting next to each other
  // are still distinguishable at a glance.
  //
  // Keyed by `label` (unique across every tab) so switching tabs swaps in
  // genuinely different `Element`s instead of reusing the one at the same
  // `Wrap` position. Without a key, a circle button (single-section tab)
  // landing where a rectangle button (multi-section tab) used to be reads
  // to Flutter as "update this widget in place", and shadcn_flutter's
  // `Clickable` tries to *animate* its BoxDecoration from rectangle
  // (borderRadius set) to circle (shape: circle) — which throws, since a
  // decoration can't have both at once mid-animation.
  Widget _addButton({
    required String label,
    required VoidCallback onPressed,
    bool iconOnly = false,
  }) {
    if (iconOnly) {
      return PrimaryButton(
        key: ValueKey(label),
        onPressed: onPressed,
        shape: ButtonShape.circle,
        child: const Icon(Icons.add),
      );
    }
    return PrimaryButton(
      key: ValueKey(label),
      onPressed: onPressed,
      shape: ButtonShape.rectangle,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.add, size: 14),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }

  // Which "Add X" buttons show for the currently selected tab — always
  // present (even when every section on that tab is empty) so there's
  // always a way to add the first record, not just later ones.
  List<Widget> _floatingActions(_ClientFileData data) {
    switch (_tabIndex) {
      case 0:
        return _overviewActions(data);
      case 1:
        return _appointmentsActions(data);
      case 2:
        return _examsActions(data);
      case 3:
        return _prescriptionsActions(data);
      case 4:
        return _measurementsActions(data);
      case 5:
        return _contactLensActions(data);
      case 6:
        return _billingActions(data);
      case 7:
        return _documentsActions(data);
      default:
        return const [];
    }
  }

  Widget _overviewTab(_ClientFileData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _latestPrescriptionCard(data),
        const SizedBox(height: 20),
        _Section(
          breakpoint: widget.breakpoint,
          title: AppStrings.sectionInsurance,
          cards: data.insurances.map((i) => InsuranceCard(insurance: i)).toList(),
        ),
      ],
    );
  }

  // Prescription tab index in the strip below — kept as one named constant
  // so "View full prescription" can't silently drift out of sync with the
  // tab order if it's ever reshuffled.
  static const int _prescriptionsTabIndex = 3;

  // The Overview tab's "Latest Prescription" table (Right/Left eye ×
  // Sphere/Cylinder/Axis/Add), per the redesign brief's client-file
  // mockup — a compact read-only summary of `data.prescriptions.first`
  // (already sorted newest-first by the repository), with a link that
  // jumps to the full Prescriptions tab instead of duplicating it here.
  Widget _latestPrescriptionCard(_ClientFileData data) {
    final colorScheme = Theme.of(context).colorScheme;
    final rx = data.prescriptions.isEmpty ? null : data.prescriptions.first;

    return Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(AppStrings.clientFileLatestPrescription).semiBold(),
              ),
              if (rx != null)
                material.InkWell(
                  onTap: () => setState(() => _tabIndex = _prescriptionsTabIndex),
                  child: Text(
                    AppStrings.clientFileViewFullPrescription,
                    style: TextStyle(color: colorScheme.primary),
                  ).small(),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (rx == null)
            Text(AppStrings.clientFileNoPrescriptionYet).muted()
          else
            material.Table(
              // Plain flutter/material `Table` (prefixed, per this file's
              // established convention for stock Flutter widgets) rather
              // than a guessed shadcn_flutter table API — this codebase
              // only reaches for a verified widget, and this one's simple
              // enough that plain Table needs no styling shadcn would add.
              columnWidths: const {
                0: material.FlexColumnWidth(1.4),
                1: material.FlexColumnWidth(1),
                2: material.FlexColumnWidth(1),
              },
              children: [
                material.TableRow(
                  children: [
                    const SizedBox(),
                    Text(AppStrings.prescriptionColRightEye).muted().small(),
                    Text(AppStrings.prescriptionColLeftEye).muted().small(),
                  ],
                ),
                _prescriptionRow(
                  AppStrings.prescriptionColSphere,
                  rx.sphOD,
                  rx.sphOS,
                ),
                _prescriptionRow(
                  AppStrings.prescriptionColCylinder,
                  rx.cylOD,
                  rx.cylOS,
                ),
                _prescriptionRow(
                  AppStrings.prescriptionColAxis,
                  rx.axisOD.toDouble(),
                  rx.axisOS.toDouble(),
                  decimals: 0,
                ),
                _prescriptionRow(
                  AppStrings.prescriptionColAdd,
                  rx.addOD,
                  rx.addOS,
                ),
              ],
            ),
        ],
      ),
    );
  }

  material.TableRow _prescriptionRow(
    String label,
    double od,
    double os, {
    int decimals = 2,
  }) {
    return material.TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(label).small(),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(od.toStringAsFixed(decimals)).small(),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(os.toStringAsFixed(decimals)).small(),
        ),
      ],
    );
  }

  // Every button below opens the same dialogs the sections used to trigger
  // inline — now gathered into one floating cluster per tab (see
  // `_floatingActions`) instead of one small button per section header.
  List<Widget> _overviewActions(_ClientFileData data) {
    final client = data.client!;
    final dataProvider = context.read<DataProvider>();

    return [
      // Funnel entry points: these hand off to Quotes/Orders with this
      // client pre-selected (via GoRouter's `extra`) instead of making
      // staff navigate away and re-pick the client from scratch — see
      // `quotes_screen.dart`/`orders_screen.dart`'s `initialClientId`.
      _addButton(
        label: AppStrings.clientFileNewQuote,
        onPressed: () =>
            context.go('/quotes', extra: {'clientId': client.id}),
      ),
      _addButton(
        label: AppStrings.clientFileNewOrder,
        onPressed: () =>
            context.go('/orders', extra: {'clientId': client.id}),
      ),
      _addButton(
        label: 'Insurance',
        iconOnly: true,
        onPressed: () => showAddRecordDialog(
          context: context,
          title: AppStrings.addDialogInsuranceTitle,
          fields: [
            RecordField(key: 'provider', label: AppStrings.recordFieldProvider),
            RecordField(key: 'policyNumber', label: AppStrings.recordFieldPolicyNumber),
            RecordField(
              key: 'validUntil',
              label: AppStrings.recordFieldValidUntil,
              hint: 'YYYY-MM-DD',
              initialValue: _formatDate(
                DateTime.now().add(const Duration(days: 365)),
              ),
            ),
          ],
          onSubmit: (v) => dataProvider.addInsurance(
            Insurance(
              id: _newId('INS'),
              clientId: client.id,
              provider: v['provider']!,
              policyNumber: v['policyNumber']!,
              validUntil:
                  DateTime.tryParse(v['validUntil']!) ??
                  DateTime.now().add(const Duration(days: 365)),
            ),
          ),
        ),
      ),
    ];
  }

  Widget _appointmentsTab(_ClientFileData data) {
    return _Section(
      breakpoint: widget.breakpoint,
      title: AppStrings.sectionAppointments,
      cards: data.appointments
          .map((a) => AppointmentCard(appointment: a))
          .toList(),
    );
  }

  List<Widget> _appointmentsActions(_ClientFileData data) {
    final client = data.client!;
    return [
      _addButton(
        label: 'Appointment',
        iconOnly: true,
        onPressed: () =>
            showAddAppointmentDialog(context, initialClientId: client.id),
      ),
    ];
  }

  Widget _examsTab(_ClientFileData data) {
    return _Section(
      breakpoint: widget.breakpoint,
      title: AppStrings.sectionEyeExams,
      cards: data.eyeExams.map((e) => EyeExamCard(exam: e)).toList(),
    );
  }

  List<Widget> _examsActions(_ClientFileData data) {
    final client = data.client!;
    final dataProvider = context.read<DataProvider>();

    return [
      _addButton(
        label: 'Eye exam',
        iconOnly: true,
        onPressed: () => showAddRecordDialog(
          context: context,
          title: AppStrings.addDialogEyeExamTitle,
          fields: [
            RecordField(
              key: 'examDate',
              label: AppStrings.recordFieldExamDate,
              hint: 'YYYY-MM-DD',
              initialValue: _formatDate(DateTime.now()),
            ),
            RecordField(
              key: 'visualAcuityOD',
              label: AppStrings.recordFieldVisualAcuityOD,
              hint: AppStrings.hintVisualAcuity,
            ),
            RecordField(
              key: 'visualAcuityOS',
              label: AppStrings.recordFieldVisualAcuityOS,
              hint: AppStrings.hintVisualAcuity,
            ),
            RecordField(
              key: 'iopOD',
              label: AppStrings.recordFieldIopOD,
              required: false,
              keyboardType: material.TextInputType.number,
            ),
            RecordField(
              key: 'iopOS',
              label: AppStrings.recordFieldIopOS,
              required: false,
              keyboardType: material.TextInputType.number,
            ),
            RecordField(
              key: 'sph',
              label: AppStrings.recordFieldSph,
              initialValue: '0',
              keyboardType: material.TextInputType.number,
            ),
            RecordField(
              key: 'cyl',
              label: AppStrings.recordFieldCyl,
              initialValue: '0',
              keyboardType: material.TextInputType.number,
            ),
            RecordField(
              key: 'axis',
              label: AppStrings.recordFieldAxis,
              initialValue: '0',
              keyboardType: material.TextInputType.number,
            ),
            RecordField(
              key: 'notes',
              label: AppStrings.recordFieldNotes,
              maxLines: 3,
              required: false,
            ),
          ],
          onSubmit: (v) => dataProvider.addEyeExam(
            EyeExam(
              id: _newId('EX'),
              clientId: client.id,
              examDate: DateTime.tryParse(v['examDate']!) ?? DateTime.now(),
              visualAcuityOD: v['visualAcuityOD']!,
              visualAcuityOS: v['visualAcuityOS']!,
              iopOD: v['iopOD']!.isEmpty ? null : double.tryParse(v['iopOD']!),
              iopOS: v['iopOS']!.isEmpty ? null : double.tryParse(v['iopOS']!),
              sph: double.tryParse(v['sph']!) ?? 0,
              cyl: double.tryParse(v['cyl']!) ?? 0,
              axis: int.tryParse(v['axis']!) ?? 0,
              notes: v['notes']!,
            ),
          ),
        ),
      ),
    ];
  }

  Widget _prescriptionsTab(_ClientFileData data) {
    return _Section(
      breakpoint: widget.breakpoint,
      title: AppStrings.sectionPrescriptions,
      cards: data.prescriptions
          .map((p) => PrescriptionCard(prescription: p))
          .toList(),
    );
  }

  List<Widget> _prescriptionsActions(_ClientFileData data) {
    final client = data.client!;
    final dataProvider = context.read<DataProvider>();

    return [
      _addButton(
        label: 'Prescription',
        iconOnly: true,
        onPressed: () => showAddRecordDialog(
          context: context,
          title: AppStrings.addDialogPrescriptionTitle,
          fields: [
            RecordField(
              key: 'date',
              label: AppStrings.cardFieldDate,
              hint: 'YYYY-MM-DD',
              initialValue: _formatDate(DateTime.now()),
            ),
            RecordField(
              key: 'expirationDate',
              label: AppStrings.cardPrescriptionExpires,
              hint: 'YYYY-MM-DD',
              required: false,
              initialValue: _formatDate(
                DateTime.now().add(const Duration(days: 365)),
              ),
            ),
            RecordField(
              key: 'type',
              label: AppStrings.prescriptionFieldType,
              options:  [
                MapEntry('distance', AppStrings.prescriptionTypeDistance),
                MapEntry('reading', AppStrings.prescriptionTypeReading),
                MapEntry(
                  'progressive',
                  AppStrings.prescriptionTypeProgressive,
                ),
                MapEntry(
                  'occupational',
                  AppStrings.prescriptionTypeOccupational,
                ),
                MapEntry(
                  'contactLens',
                  AppStrings.prescriptionTypeContactLens,
                ),
              ],
            ),
            RecordField(
              key: 'sphOD',
              label: AppStrings.recordFieldSphOD,
              initialValue: '0',
              keyboardType: material.TextInputType.number,
            ),
            RecordField(
              key: 'sphOS',
              label: AppStrings.recordFieldSphOS,
              initialValue: '0',
              keyboardType: material.TextInputType.number,
            ),
            RecordField(
              key: 'pd',
              label: AppStrings.recordFieldPdMm,
              initialValue: '63',
              keyboardType: material.TextInputType.number,
            ),
          ],
          onSubmit: (v) => dataProvider.addPrescription(
            Prescription(
              id: _newId('RX'),
              clientId: client.id,
              date: DateTime.tryParse(v['date']!) ?? DateTime.now(),
              expirationDate: v['expirationDate']!.isEmpty
                  ? null
                  : DateTime.tryParse(v['expirationDate']!),
              type: v['type']!,
              sphOD: double.tryParse(v['sphOD']!) ?? 0,
              sphOS: double.tryParse(v['sphOS']!) ?? 0,
              pd: double.tryParse(v['pd']!) ?? 0,
            ),
          ),
        ),
      ),
    ];
  }

  Widget _measurementsTab(_ClientFileData data) {
    return _Section(
      breakpoint: widget.breakpoint,
      title: AppStrings.sectionMeasurements,
      cards: data.measurements
          .map((m) => MeasurementCard(measurement: m))
          .toList(),
    );
  }

  List<Widget> _measurementsActions(_ClientFileData data) {
    final client = data.client!;
    final dataProvider = context.read<DataProvider>();

    return [
      _addButton(
        label: 'Measurement',
        iconOnly: true,
        onPressed: () => showAddRecordDialog(
          context: context,
          title: AppStrings.addDialogMeasurementTitle,
          fields: [
            RecordField(
              key: 'date',
              label: AppStrings.cardFieldDate,
              hint: 'YYYY-MM-DD',
              initialValue: _formatDate(DateTime.now()),
            ),
            RecordField(
              key: 'pd',
              label: AppStrings.recordFieldPdMm,
              initialValue: '63',
              keyboardType: material.TextInputType.number,
            ),
            RecordField(
              key: 'fittingHeight',
              label: AppStrings.cardMeasurementFittingHeight,
              initialValue: '20',
              required: false,
              keyboardType: material.TextInputType.number,
            ),
            RecordField(
              key: 'operator',
              label: AppStrings.cardMeasurementOperator,
            ),
          ],
          onSubmit: (v) => dataProvider.addMeasurement(
            Measurement(
              id: _newId('MS'),
              clientId: client.id,
              date: DateTime.tryParse(v['date']!) ?? DateTime.now(),
              pd: double.tryParse(v['pd']!) ?? 0,
              fittingHeight: double.tryParse(v['fittingHeight']!) ?? 0,
              operator: v['operator']!,
            ),
          ),
        ),
      ),
    ];
  }

  Widget _contactLensTab(_ClientFileData data) {
    return _Section(
      breakpoint: widget.breakpoint,
      title: AppStrings.sectionContactLensRx,
      cards: data.contactLensPrescriptions
          .map((c) => ContactLensPrescriptionCard(prescription: c))
          .toList(),
    );
  }

  List<Widget> _contactLensActions(_ClientFileData data) {
    final client = data.client!;
    final dataProvider = context.read<DataProvider>();

    return [
      _addButton(
        label: 'Contact lens Rx',
        iconOnly: true,
        onPressed: () => showAddRecordDialog(
          context: context,
          title: AppStrings.addDialogContactLensRxTitle,
          fields: [
            RecordField(
              key: 'date',
              label: AppStrings.cardFieldDate,
              hint: 'YYYY-MM-DD',
              initialValue: _formatDate(DateTime.now()),
            ),
            RecordField(key: 'brand', label: AppStrings.recordFieldBrand),
            RecordField(
              key: 'powerOD',
              label: AppStrings.recordFieldPowerOD,
              initialValue: '0',
              keyboardType: material.TextInputType.number,
            ),
            RecordField(
              key: 'powerOS',
              label: AppStrings.recordFieldPowerOS,
              initialValue: '0',
              keyboardType: material.TextInputType.number,
            ),
          ],
          onSubmit: (v) => dataProvider.addContactLensPrescription(
            ContactLensPrescription(
              id: _newId('CLRX'),
              clientId: client.id,
              date: DateTime.tryParse(v['date']!) ?? DateTime.now(),
              brand: v['brand']!,
              powerOD: double.tryParse(v['powerOD']!) ?? 0,
              powerOS: double.tryParse(v['powerOS']!) ?? 0,
            ),
          ),
        ),
      ),
    ];
  }

  Widget _billingTab(_ClientFileData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Section(
          breakpoint: widget.breakpoint,
          title: AppStrings.sectionInvoices,
          cards: data.invoices.map((i) => BillingCard(invoice: i)).toList(),
        ),
        const SizedBox(height: 20),
        _Section(
          breakpoint: widget.breakpoint,
          title: AppStrings.sectionPayments,
          cards: data.payments.map((p) => PaymentsCard(payment: p)).toList(),
        ),
      ],
    );
  }

  List<Widget> _billingActions(_ClientFileData data) {
    final client = data.client!;
    final dataProvider = context.read<DataProvider>();

    return [
      _addButton(
        label: AppStrings.clientFileAddInvoice,
        onPressed: () => showAddRecordDialog(
          context: context,
          title: AppStrings.addDialogInvoiceTitle,
          fields: [
            RecordField(
              key: 'date',
              label: AppStrings.cardFieldDate,
              hint: 'YYYY-MM-DD',
              initialValue: _formatDate(DateTime.now()),
            ),
            RecordField(
              key: 'amount',
              label: AppStrings.recordFieldAmount,
              keyboardType: material.TextInputType.number,
            ),
            RecordField(
              key: 'orderId',
              label: AppStrings.recordFieldLinkedOrder,
              required: false,
              options: [
                MapEntry('', AppStrings.recordFieldNoneOption),
                for (final o in dataProvider.orders.where(
                  (o) => o.clientId == client.id,
                ))
                  MapEntry(o.id, '${o.id} — ${o.description}'),
              ],
            ),
          ],
          // New invoices always start pending — no payment recorded yet.
          onSubmit: (v) => dataProvider.addInvoice(
            Invoice(
              id: _newId('INV'),
              clientId: client.id,
              date: DateTime.tryParse(v['date']!) ?? DateTime.now(),
              amount: double.tryParse(v['amount']!) ?? 0,
              status: 'pending',
              orderId: v['orderId']!.isEmpty ? null : v['orderId'],
            ),
          ),
        ),
      ),
      // No invoices yet means there's nothing a payment could attach to —
      // omit the button entirely rather than show a dialog with an
      // empty/invalid invoice picker.
      if (data.invoices.isNotEmpty)
        _addButton(
          label: AppStrings.clientFileAddPayment,
          onPressed: () => showAddRecordDialog(
            context: context,
            title: AppStrings.addDialogPaymentTitle,
            fields: [
              RecordField(
                key: 'invoiceId',
                label: AppStrings.recordFieldInvoice,
                options: [
                  for (final invoice in data.invoices)
                    MapEntry(
                      invoice.id,
                      '${invoice.id} — ${invoice.amount} (${invoice.status})',
                    ),
                ],
              ),
              RecordField(
                key: 'date',
                label: AppStrings.cardFieldDate,
                hint: 'YYYY-MM-DD',
                initialValue: _formatDate(DateTime.now()),
              ),
              RecordField(
                key: 'amount',
                label: AppStrings.recordFieldAmount,
                keyboardType: material.TextInputType.number,
              ),
              RecordField(
                key: 'method',
                label: AppStrings.recordFieldMethod,
                hint: AppStrings.hintPaymentMethod,
                initialValue: 'card',
              ),
            ],
            onSubmit: (v) => dataProvider.addPayment(
              Payment(
                id: _newId('PAY'),
                invoiceId: v['invoiceId']!,
                date: DateTime.tryParse(v['date']!) ?? DateTime.now(),
                amount: double.tryParse(v['amount']!) ?? 0,
                method: v['method']!.isEmpty ? 'card' : v['method']!,
              ),
            ),
          ),
        ),
    ];
  }

  Widget _documentsTab(_ClientFileData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Section(
          breakpoint: widget.breakpoint,
          title: AppStrings.sectionDocuments,
          cards: data.documents
              .map((d) => DocumentCard(document: d))
              .toList(),
        ),
        const SizedBox(height: 20),
        _Section(
          breakpoint: widget.breakpoint,
          title: AppStrings.sectionSignatures,
          cards: data.signatures
              .map((s) => DigitalSignatureCard(signature: s))
              .toList(),
        ),
      ],
    );
  }

  List<Widget> _documentsActions(_ClientFileData data) {
    final client = data.client!;
    final dataProvider = context.read<DataProvider>();

    return [
      _addButton(
        label: AppStrings.clientFileAddDocument,
        onPressed: () => showAddRecordDialog(
          context: context,
          title: AppStrings.addDialogDocumentTitle,
          fields: [
            RecordField(
              key: 'type',
              label: AppStrings.recordFieldType,
              hint: AppStrings.hintDocumentType,
              initialValue: 'Consent Form',
            ),
            RecordField(
              key: 'filePath',
              label: AppStrings.recordFieldFilePath,
              hint: '/docs/example.pdf',
            ),
          ],
          onSubmit: (v) => dataProvider.addDocument(
            DocumentRecord(
              id: _newId('DOC'),
              clientId: client.id,
              type: v['type']!,
              filePath: v['filePath']!,
              uploadedAt: DateTime.now(),
            ),
          ),
        ),
      ),
      _addButton(
        label: AppStrings.clientFileAddSignature,
        onPressed: () => showAddRecordDialog(
          context: context,
          title: AppStrings.addDialogSignatureTitle,
          fields: [
            RecordField(
              key: 'signatureData',
              label: AppStrings.recordFieldSignatureData,
              hint: AppStrings.hintSignatureData,
            ),
          ],
          onSubmit: (v) => dataProvider.addSignature(
            DigitalSignature(
              id: _newId('SIG'),
              clientId: client.id,
              signedAt: DateTime.now(),
              signatureData: v['signatureData']!,
            ),
          ),
        ),
      ),
    ];
  }

  // Icon for a timeline entry's kind, in one place (same reasoning as
  // `PendingTasksPanel._styleFor`) so the compiler forces every new
  // `ClientTimelineEventKind` case to be handled here too.
  IconData _timelineIcon(ClientTimelineEventKind kind) {
    switch (kind) {
      case ClientTimelineEventKind.appointment:
        return Icons.event_outlined;
      case ClientTimelineEventKind.consultation:
        return Icons.psychology_outlined;
      case ClientTimelineEventKind.eyeExam:
        return Icons.visibility_outlined;
      case ClientTimelineEventKind.prescription:
        return Icons.description_outlined;
      case ClientTimelineEventKind.measurement:
        return Icons.straighten_outlined;
      case ClientTimelineEventKind.frameSelection:
        return Icons.style_outlined;
      case ClientTimelineEventKind.lensRecommendation:
        return Icons.lightbulb_outline;
      case ClientTimelineEventKind.communication:
        return Icons.chat_outlined;
      case ClientTimelineEventKind.quote:
        return Icons.request_quote_outlined;
      case ClientTimelineEventKind.order:
        return Icons.shopping_bag_outlined;
      case ClientTimelineEventKind.payment:
        return Icons.payments_outlined;
      case ClientTimelineEventKind.labWorkOrder:
        return Icons.science_outlined;
      case ClientTimelineEventKind.mountingJob:
        return Icons.build_outlined;
      case ClientTimelineEventKind.qualityCheck:
        return Icons.verified_outlined;
      case ClientTimelineEventKind.finalFitting:
        return Icons.face_retouching_natural_outlined;
      case ClientTimelineEventKind.invoice:
        return Icons.receipt_long_outlined;
      case ClientTimelineEventKind.delivery:
        return Icons.local_shipping_outlined;
      case ClientTimelineEventKind.afterSales:
        return Icons.support_agent_outlined;
      case ClientTimelineEventKind.repair:
        return Icons.build_circle_outlined;
      case ClientTimelineEventKind.warranty:
        return Icons.verified_user_outlined;
    }
  }

  Widget _timelineRow(ClientTimelineEvent event, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _timelineIcon(event.kind),
              size: 16,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(event.title).semiBold().small()),
                    Text(_formatDate(event.date)).muted().small(),
                  ],
                ),
                const SizedBox(height: 2),
                Text(event.subtitle).muted().small(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Module 23 (CRM flow diagram) — every client-linked record across
  // every module, merged into one chronological feed by
  // `deriveClientTimeline`. Read-only: no floating "add" actions (see
  // `_floatingActions`'s `default` case), since every entry here is
  // created from its own module's screen, not duplicated here.
  Widget _timelineTab(_ClientFileData data) {
    final colorScheme = Theme.of(context).colorScheme;

    if (data.timeline.isEmpty) {
      return EmptyState(
        icon: Icons.timeline_outlined,
        title: AppStrings.emptyRecordsGeneric,
      );
    }

    return Card(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < data.timeline.length; i++) ...[
            if (i > 0) _divider(colorScheme),
            _timelineRow(data.timeline[i], colorScheme),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _data == null) {
      return const Center(child: material.CircularProgressIndicator());
    }

    final data = _data!;
    final colorScheme = Theme.of(context).colorScheme;
    final client = data.client;

    if (client == null) {
      return _notFound(colorScheme);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _backButton(),
                  const SizedBox(height: 16),
                  _headerCard(
                    client,
                    data.metrics,
                    colorScheme,
                    _nextAppointment(data),
                  ),
                  const SizedBox(height: 12),
                  Text(AppStrings.clientJourneyStatusLabel).muted().small(),
                  const SizedBox(height: 6),
                  ClientJourneyStatusRow(clientId: client.id),
                  const SizedBox(height: 20),
                  // Horizontally scrollable so the tab labels never
                  // overflow — French/Arabic translations run noticeably
                  // longer than English and won't all fit on a phone width.
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Tabs(
                      index: _tabIndex,
                      onChanged: (value) => setState(() => _tabIndex = value),
                      children: [
                        TabItem(child: Text(AppStrings.clientFileTabOverview)),
                        TabItem(
                          child: Text(AppStrings.clientFileTabAppointments),
                        ),
                        TabItem(child: Text(AppStrings.clientFileTabExams)),
                        TabItem(
                          child: Text(AppStrings.clientFileTabPrescriptions),
                        ),
                        TabItem(
                          child: Text(AppStrings.clientFileTabMeasurements),
                        ),
                        TabItem(
                          child: Text(AppStrings.clientFileTabContactLens),
                        ),
                        TabItem(child: Text(AppStrings.clientFileTabBilling)),
                        TabItem(
                          child: Text(AppStrings.clientFileTabDocuments),
                        ),
                        TabItem(
                          child: Text(AppStrings.clientFileTabTimeline),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Bottom padding so the last section's cards don't sit right
                  // behind the floating buttons below.
                  Padding(
                    padding: const EdgeInsets.only(bottom: 72),
                    child: IndexedStack(
                      index: _tabIndex,
                      children: [
                        _overviewTab(data),
                        _appointmentsTab(data),
                        _examsTab(data),
                        _prescriptionsTab(data),
                        _measurementsTab(data),
                        _contactLensTab(data),
                        _billingTab(data),
                        _documentsTab(data),
                        _timelineTab(data),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Fixed to the content area's bottom-right corner — the side
            // opposite the sidebar — regardless of scroll position, and
            // always present even when the current tab's sections are all
            // empty, so there's always a way to add the first record.
            // Width-capped and horizontally scrollable (reverse: true keeps
            // it hugging the right edge, matching what a Wrap would've
            // shown, and only reveals earlier buttons via scroll once there
            // are too many to fit) instead of wrapping to a second line,
            // which used to be able to push past the bottom edge.
            Positioned(
              right: 16,
              bottom: 16,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: (constraints.maxWidth - 32).clamp(0, double.infinity),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final action in _floatingActions(data))
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: action,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// One labeled group of record cards, shared by every tab above — a title,
/// then either the cards or a shared [EmptyState] when there aren't any.
class _Section extends StatelessWidget {
  final String title;
  final List<Widget> cards;
  // Nullable rather than defaulted to AppStrings.emptyRecordsGeneric —
  // default parameter values must be compile-time constants, and that
  // string is now a runtime lookup (it varies by the active language).
  final String? emptyTitle;
  // Drives the card layout below — mobile keeps the original one-per-line
  // Column (a fixed-width row wouldn't fit on a phone), desktop/tablet lay
  // cards out inline instead.
  final Breakpoint breakpoint;

  const _Section({
    required this.title,
    required this.cards,
    required this.breakpoint,
    this.emptyTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title).semiBold(),
        const SizedBox(height: 10),
        if (cards.isEmpty)
          EmptyState(title: emptyTitle ?? AppStrings.emptyRecordsGeneric)
        else if (breakpoint == Breakpoint.mobile)
          Column(
            children: [
              for (final card in cards)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: card,
                ),
            ],
          )
        else
          // Desktop/tablet: cards flow left-to-right and wrap onto a new
          // line once they run out of width, instead of always stacking
          // one per line — a section with several short records (e.g.
          // allergies) no longer eats more vertical space than it needs.
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final card in cards) SizedBox(width: 340, child: card),
            ],
          ),
      ],
    );
  }
}

int _ageFromDob(DateTime dob) {
  final now = DateTime.now();
  var age = now.year - dob.year;
  final birthdayPassedThisYear =
      now.month > dob.month || (now.month == dob.month && now.day >= dob.day);
  if (!birthdayPassedThisYear) age--;
  return age;
}

String _formatDate(DateTime d) {
  final mm = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  return '${d.year}-$mm-$dd';
}
