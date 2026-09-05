import 'package:flutter/material.dart' as material;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:optic/app_shell.dart';
import 'package:optic/data/data_provider.dart';
import 'package:optic/helpers/nav_items.dart';
import 'package:optic/localization/app_strings.dart';
import 'package:optic/models/client.dart';

/// Full-screen client intake/edit form — a dedicated route
/// (`/clients/new` to create, `/clients/:id/edit` to edit) rather than a
/// modal. Creating a client establishes a brand new identity/context in
/// the CRM, unlike every other "+ Add" you'll build on [ClientFileScreen],
/// which adds a record to a client already open.
///
/// Reachable from the Clients list "Add client" button, the dashboard's
/// "New client" quick action, and — in edit mode — the "[Edit]" action on
/// [ClientFileScreen]'s redesigned header.
class AddClientScreen extends StatelessWidget {
  /// Non-null in edit mode — the client being edited, with the form
  /// pre-filled from its current fields and Save calling
  /// `DataProvider.updateClient` instead of `addClient`.
  final Client? editClient;

  const AddClientScreen({super.key, this.editClient});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      // Stays on the "Clients" nav entry — same reasoning as
      // ClientFileScreen: this is a drill-down from the clients list,
      // not its own top-level destination.
      navItems: (context) => buildAppNavItems(context, NavRoute.clients),
      bodyBuilder: (context, breakpoint) =>
          _AddClientBody(editClient: editClient),
    );
  }
}

class _AddClientBody extends StatefulWidget {
  final Client? editClient;

  const _AddClientBody({this.editClient});

  @override
  State<_AddClientBody> createState() => _AddClientBodyState();
}

class _AddClientBodyState extends State<_AddClientBody> {
  late final _firstName = material.TextEditingController(
    text: widget.editClient?.firstName,
  );
  late final _lastName = material.TextEditingController(
    text: widget.editClient?.lastName,
  );
  late final _dob = material.TextEditingController(
    text: widget.editClient == null
        ? null
        : _formatDob(widget.editClient!.dob),
  );
  late final _bloodGroup = material.TextEditingController(
    text: widget.editClient?.bloodGroup,
  );
  late final _phone = material.TextEditingController(
    text: widget.editClient?.phone,
  );
  late final _email = material.TextEditingController(
    text: widget.editClient?.email,
  );
  late final _nationalId = material.TextEditingController(
    text: widget.editClient?.nationalId,
  );
  late final _insurance = material.TextEditingController(
    text: widget.editClient?.insurance,
  );
  late final _address = material.TextEditingController(
    text: widget.editClient?.address,
  );
  late final _profession = material.TextEditingController(
    text: widget.editClient?.profession,
  );
  late final _emergencyContactName = material.TextEditingController(
    text: widget.editClient?.emergencyContactName,
  );
  late final _emergencyContactPhone = material.TextEditingController(
    text: widget.editClient?.emergencyContactPhone,
  );
  late String? _gender = widget.editClient?.gender;
  late String _preferredContactMethod =
      widget.editClient?.preferredContactMethod ?? 'phone';

  bool get _isEditing => widget.editClient != null;

  static String _formatDob(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _dob.dispose();
    _bloodGroup.dispose();
    _phone.dispose();
    _email.dispose();
    _nationalId.dispose();
    _insurance.dispose();
    _address.dispose();
    _profession.dispose();
    _emergencyContactName.dispose();
    _emergencyContactPhone.dispose();
    super.dispose();
  }

  DateTime? get _parsedDob => DateTime.tryParse(_dob.text.trim());

  bool get _canSubmit =>
      _firstName.text.trim().isNotEmpty &&
      _lastName.text.trim().isNotEmpty &&
      _parsedDob != null &&
      _gender != null;

  void _submit() {
    if (!_canSubmit) return;
    final dataProvider = context.read<DataProvider>();
    final existing = widget.editClient;
    final client = Client(
      // Editing keeps the original id/fileNumber (Client is immutable, so
      // "updating" means rebuilding it with the same identity) — only a
      // brand new client gets a freshly generated one.
      id: existing?.id ?? 'P${DateTime.now().millisecondsSinceEpoch}',
      fileNumber: existing?.fileNumber ??
          'F${(dataProvider.clients.length + 1).toString().padLeft(3, '0')}',
      nationalId: _nationalId.text.trim(),
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      dob: _parsedDob!,
      gender: _gender!,
      bloodGroup: _bloodGroup.text.trim(),
      phone: _phone.text.trim(),
      email: _email.text.trim(),
      insurance: _insurance.text.trim(),
      address: _address.text.trim(),
      profession: _profession.text.trim(),
      emergencyContactName: _emergencyContactName.text.trim(),
      emergencyContactPhone: _emergencyContactPhone.text.trim(),
      preferredContactMethod: _preferredContactMethod,
      // Editing doesn't currently expose a status toggle — keep whatever
      // the client already had rather than silently resetting it.
      status: existing?.status ?? 'active',
    );
    if (existing != null) {
      dataProvider.updateClient(client);
    } else {
      dataProvider.addClient(client);
    }
    // Same "add/edit then open" behavior the old dialog had — jump
    // straight into the client's file, confirming the save worked.
    context.go('/clients/${client.id}');
  }

  void _cancel() => _isEditing
      ? context.go('/clients/${widget.editClient!.id}')
      : context.go(NavRoute.clients.path);

  Widget _field({
    required String label,
    required material.TextEditingController controller,
    String? hint,
    material.TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: material.TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: material.InputDecoration(
          labelText: label,
          hintText: hint,
          border: const material.OutlineInputBorder(),
          isDense: true,
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _genderToggle() {
    final options = {
      AppStrings.addClientGenderMale: 'Male',
      AppStrings.addClientGenderFemale: 'Female',
      AppStrings.addClientGenderOther: 'Other',
    };
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.entries.map((entry) {
        final selected = _gender == entry.value;
        return Button(
          style: selected
              ? const ButtonStyle.primary()
              : const ButtonStyle.ghost(),
          onPressed: () => setState(() => _gender = entry.value),
          child: Text(entry.key),
        );
      }).toList(),
    );
  }

  Widget _preferredContactToggle() {
    final options = {
      AppStrings.contactMethodPhone: 'phone',
      AppStrings.contactMethodSms: 'sms',
      AppStrings.contactMethodWhatsapp: 'whatsapp',
      AppStrings.contactMethodEmail: 'email',
    };
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.entries.map((entry) {
        final selected = _preferredContactMethod == entry.value;
        return Button(
          style: selected
              ? const ButtonStyle.primary()
              : const ButtonStyle.ghost(),
          onPressed: () =>
              setState(() => _preferredContactMethod = entry.value),
          child: Text(entry.key),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dobText = _dob.text.trim();
    final dobValid = dobText.isEmpty || _parsedDob != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Button.outline(
            onPressed: _cancel,
            leading: const Icon(Icons.arrow_back, size: 16),
            child: Text(AppStrings.clientFileBackToClients),
          ),
          const SizedBox(height: 16),
          Text(
            _isEditing ? AppStrings.editClientTitle : AppStrings.addClientTitle,
          ).large().bold(),
          const SizedBox(height: 4),
          Text(
            _isEditing
                ? AppStrings.editClientPageSubtitle
                : AppStrings.addClientPageSubtitle,
          ).muted(),
          const SizedBox(height: 20),
          Card(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          label: AppStrings.addClientFirstName,
                          controller: _firstName,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _field(
                          label: AppStrings.addClientLastName,
                          controller: _lastName,
                        ),
                      ),
                    ],
                  ),
                  _field(
                    label: AppStrings.addClientDob,
                    controller: _dob,
                    hint: AppStrings.addClientDobHint,
                    keyboardType: material.TextInputType.datetime,
                  ),
                  if (!dobValid)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        AppStrings.addClientDobError,
                      ).muted().small(),
                    ),
                  Text(AppStrings.addClientGender).semiBold(),
                  const SizedBox(height: 8),
                  _genderToggle(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          label: AppStrings.addClientBloodGroup,
                          controller: _bloodGroup,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _field(
                          label: AppStrings.addClientPhone,
                          controller: _phone,
                          keyboardType: material.TextInputType.phone,
                        ),
                      ),
                    ],
                  ),
                  _field(
                    label: AppStrings.addClientEmail,
                    controller: _email,
                    keyboardType: material.TextInputType.emailAddress,
                  ),
                  _field(
                    label: AppStrings.addClientNationalId,
                    controller: _nationalId,
                  ),
                  _field(
                    label: AppStrings.addClientInsurance,
                    controller: _insurance,
                  ),
                  _field(
                    label: AppStrings.addClientAddress,
                    controller: _address,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          label: AppStrings.addClientProfession,
                          controller: _profession,
                        ),
                      ),
                    ],
                  ),
                  Text(AppStrings.addClientEmergencyContact).semiBold(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          label: AppStrings.addClientEmergencyContactName,
                          controller: _emergencyContactName,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _field(
                          label: AppStrings.addClientEmergencyContactPhone,
                          controller: _emergencyContactPhone,
                          keyboardType: material.TextInputType.phone,
                        ),
                      ),
                    ],
                  ),
                  Text(AppStrings.addClientPreferredContact).semiBold(),
                  const SizedBox(height: 8),
                  _preferredContactToggle(),
                  const SizedBox(height: 12),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Button(
                          style: const ButtonStyle.ghost(),
                          onPressed: _cancel,
                          child: Text(AppStrings.addClientCancel),
                        ),
                        const SizedBox(width: 8),
                        Button(
                          style: const ButtonStyle.primary(),
                          onPressed: _canSubmit ? _submit : null,
                          child: Text(
                            _isEditing
                                ? AppStrings.editClientSubmit
                                : AppStrings.addClientSubmit,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
          ),
        ),
      ),
    );
  }
}
