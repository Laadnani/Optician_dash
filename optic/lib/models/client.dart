class Client {
  final String id;
  final String fileNumber;
  final String nationalId;
  final String firstName;
  final String lastName;
  final DateTime dob;
  final String gender;
  final String bloodGroup;
  final String phone;
  final String email;
  final String insurance;

  /// Module 1 (Client/Customer Management) additions — the retail-CRM
  /// fields the clinical version never needed. `firstVisit`/`lastVisit`/
  /// `totalPurchases`/`lifetimeValue` from the spec are deliberately NOT
  /// stored fields here: they're derived from Appointments/Invoices (see
  /// `deriveClientMetrics` in `client_repository.dart`) rather than kept
  /// in sync by hand.
  final String address;
  final String profession;
  final String emergencyContactName;
  final String emergencyContactPhone;

  /// 'phone' | 'sms' | 'whatsapp' | 'email' — how this client prefers to
  /// be reached (module 25, Communication, reads this).
  final String preferredContactMethod;

  /// 'active' | 'inactive'.
  final String status;

  Client({
    required this.id,
    required this.fileNumber,
    required this.nationalId,
    required this.firstName,
    required this.lastName,
    required this.dob,
    required this.gender,
    required this.bloodGroup,
    required this.phone,
    required this.email,
    required this.insurance,
    this.address = '',
    this.profession = '',
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
    this.preferredContactMethod = 'phone',
    this.status = 'active',
  });

  Client copyWith({
    String? id,
    String? fileNumber,
    String? nationalId,
    String? firstName,
    String? lastName,
    DateTime? dob,
    String? gender,
    String? bloodGroup,
    String? phone,
    String? email,
    String? insurance,
    String? address,
    String? profession,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? preferredContactMethod,
    String? status,
  }) {
    return Client(
      id: id ?? this.id,
      fileNumber: fileNumber ?? this.fileNumber,
      nationalId: nationalId ?? this.nationalId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      insurance: insurance ?? this.insurance,
      address: address ?? this.address,
      profession: profession ?? this.profession,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      preferredContactMethod:
          preferredContactMethod ?? this.preferredContactMethod,
      status: status ?? this.status,
    );
  }
}
