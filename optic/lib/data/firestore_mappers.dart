// firestore_mappers.dart
//
// One `toMap()` extension + one top-level `xFromMap()` function per model
// backing a `DataProvider` list — the reshaping layer between our plain
// Dart model classes and a document-store-shaped `Map<String, dynamic>`
// (Firestore's native shape, and also plain JSON).
//
// Deliberately kept dependency-free (no `cloud_firestore` import): every
// `DateTime` is stored as an ISO-8601 string rather than a Firestore
// `Timestamp`, so this file compiles and is testable before the Firebase
// packages are even added to the project, and isn't tied to one specific
// backend. Once `cloud_firestore` is wired in (see the migration guide's
// Step 5), the one place that needs to know about `Timestamp` is the
// Firestore read/write layer itself — it can convert `Timestamp` <->
// ISO-8601 string in a couple of lines right where it calls these
// functions, without this file changing at all. If that conversion ever
// feels like overhead worth removing, swapping the two helpers below
// (`_enc`/`_dec`) to produce/consume `Timestamp` directly is a small,
// isolated change.
//
// Every model here is immutable with a plain constructor (no existing
// `toJson`/`fromJson`), so nothing is overridden — these are purely
// additive, via Dart extension methods for the `toMap()` direction and
// plain top-level functions for the `fromMap()` direction (Dart extensions
// can't add named constructors from outside a class).

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

// --- DateTime <-> ISO-8601 string helpers ----------------------------------

String _enc(DateTime d) => d.toIso8601String();
String? _encN(DateTime? d) => d?.toIso8601String();
DateTime _dec(dynamic v) => DateTime.parse(v as String);
DateTime? _decN(dynamic v) => v == null ? null : DateTime.parse(v as String);

/// `List<String>` fields (`coatings`, `framesTried`,
/// `recommendedCoatings`) round-trip through a plain `List<dynamic>` once
/// they've been through JSON/Firestore — this normalizes either shape back
/// to `List<String>`.
List<String> _strList(dynamic v) =>
    v == null ? const [] : List<String>.from(v as List);

// --- Clients / foundation ---------------------------------------------------

extension ClientMapper on Client {
  Map<String, dynamic> toMap() => {
    'id': id,
    'fileNumber': fileNumber,
    'nationalId': nationalId,
    'firstName': firstName,
    'lastName': lastName,
    'dob': _enc(dob),
    'gender': gender,
    'bloodGroup': bloodGroup,
    'phone': phone,
    'email': email,
    'insurance': insurance,
    'address': address,
    'profession': profession,
    'emergencyContactName': emergencyContactName,
    'emergencyContactPhone': emergencyContactPhone,
    'preferredContactMethod': preferredContactMethod,
    'status': status,
  };
}

Client clientFromMap(Map<String, dynamic> map) => Client(
  id: map['id'] as String,
  fileNumber: map['fileNumber'] as String,
  nationalId: map['nationalId'] as String,
  firstName: map['firstName'] as String,
  lastName: map['lastName'] as String,
  dob: _dec(map['dob']),
  gender: map['gender'] as String,
  bloodGroup: map['bloodGroup'] as String,
  phone: map['phone'] as String,
  email: map['email'] as String,
  insurance: map['insurance'] as String,
  address: map['address'] as String? ?? '',
  profession: map['profession'] as String? ?? '',
  emergencyContactName: map['emergencyContactName'] as String? ?? '',
  emergencyContactPhone: map['emergencyContactPhone'] as String? ?? '',
  preferredContactMethod: map['preferredContactMethod'] as String? ?? 'phone',
  status: map['status'] as String? ?? 'active',
);

extension AppointmentMapper on Appointment {
  Map<String, dynamic> toMap() => {
    'id': id,
    'clientId': clientId,
    'date': _enc(date),
    'reason': reason,
    'status': status,
    'price': price,
    'paymentStatus': paymentStatus,
    'type': type,
  };
}

Appointment appointmentFromMap(Map<String, dynamic> map) => Appointment(
  id: map['id'] as String,
  clientId: map['clientId'] as String,
  date: _dec(map['date']),
  reason: map['reason'] as String,
  status: map['status'] as String,
  price: (map['price'] as num?)?.toDouble() ?? 0,
  paymentStatus: map['paymentStatus'] as String? ?? 'unpaid',
  type: map['type'] as String? ?? 'appointment',
);

extension EyeExamMapper on EyeExam {
  Map<String, dynamic> toMap() => {
    'id': id,
    'clientId': clientId,
    'examDate': _enc(examDate),
    'visualAcuityOD': visualAcuityOD,
    'visualAcuityOS': visualAcuityOS,
    'iopOD': iopOD,
    'iopOS': iopOS,
    'sph': sph,
    'cyl': cyl,
    'axis': axis,
    'notes': notes,
  };
}

EyeExam eyeExamFromMap(Map<String, dynamic> map) => EyeExam(
  id: map['id'] as String,
  clientId: map['clientId'] as String,
  examDate: _dec(map['examDate']),
  visualAcuityOD: map['visualAcuityOD'] as String,
  visualAcuityOS: map['visualAcuityOS'] as String,
  iopOD: (map['iopOD'] as num?)?.toDouble(),
  iopOS: (map['iopOS'] as num?)?.toDouble(),
  sph: (map['sph'] as num).toDouble(),
  cyl: (map['cyl'] as num).toDouble(),
  axis: map['axis'] as int,
  notes: map['notes'] as String,
);

extension InvoiceMapper on Invoice {
  Map<String, dynamic> toMap() => {
    'id': id,
    'clientId': clientId,
    'date': _enc(date),
    'amount': amount,
    'status': status,
    'orderId': orderId,
  };
}

Invoice invoiceFromMap(Map<String, dynamic> map) => Invoice(
  id: map['id'] as String,
  clientId: map['clientId'] as String,
  date: _dec(map['date']),
  amount: (map['amount'] as num).toDouble(),
  status: map['status'] as String,
  orderId: map['orderId'] as String?,
);

extension PaymentMapper on Payment {
  Map<String, dynamic> toMap() => {
    'id': id,
    'invoiceId': invoiceId,
    'date': _enc(date),
    'amount': amount,
    'method': method,
  };
}

Payment paymentFromMap(Map<String, dynamic> map) => Payment(
  id: map['id'] as String,
  invoiceId: map['invoiceId'] as String,
  date: _dec(map['date']),
  amount: (map['amount'] as num).toDouble(),
  method: map['method'] as String,
);

extension InsuranceMapper on Insurance {
  Map<String, dynamic> toMap() => {
    'id': id,
    'clientId': clientId,
    'provider': provider,
    'policyNumber': policyNumber,
    'validUntil': _enc(validUntil),
  };
}

Insurance insuranceFromMap(Map<String, dynamic> map) => Insurance(
  id: map['id'] as String,
  clientId: map['clientId'] as String,
  provider: map['provider'] as String,
  policyNumber: map['policyNumber'] as String,
  validUntil: _dec(map['validUntil']),
);

extension DocumentRecordMapper on DocumentRecord {
  Map<String, dynamic> toMap() => {
    'id': id,
    'clientId': clientId,
    'type': type,
    'filePath': filePath,
    'uploadedAt': _enc(uploadedAt),
  };
}

DocumentRecord documentRecordFromMap(Map<String, dynamic> map) =>
    DocumentRecord(
      id: map['id'] as String,
      clientId: map['clientId'] as String,
      type: map['type'] as String,
      filePath: map['filePath'] as String,
      uploadedAt: _dec(map['uploadedAt']),
    );

extension DigitalSignatureMapper on DigitalSignature {
  Map<String, dynamic> toMap() => {
    'id': id,
    'clientId': clientId,
    'signedAt': _enc(signedAt),
    'signatureData': signatureData,
  };
}

DigitalSignature digitalSignatureFromMap(Map<String, dynamic> map) =>
    DigitalSignature(
      id: map['id'] as String,
      clientId: map['clientId'] as String,
      signedAt: _dec(map['signedAt']),
      signatureData: map['signatureData'] as String,
    );

// --- Optical Consultation + modules 2-6 -------------------------------------

extension OpticalConsultationMapper on OpticalConsultation {
  Map<String, dynamic> toMap() => {
    'id': id,
    'clientId': clientId,
    'appointmentId': appointmentId,
    'date': _enc(date),
    'visualNeeds': visualNeeds,
    'dailyActivities': dailyActivities,
    'screenUsage': screenUsage,
    'driving': driving,
    'reading': reading,
    'workEnvironment': workEnvironment,
    'previousProblems': previousProblems,
    'notes': notes,
  };
}

OpticalConsultation opticalConsultationFromMap(Map<String, dynamic> map) =>
    OpticalConsultation(
      id: map['id'] as String,
      clientId: map['clientId'] as String,
      appointmentId: map['appointmentId'] as String?,
      date: _dec(map['date']),
      visualNeeds: map['visualNeeds'] as String? ?? '',
      dailyActivities: map['dailyActivities'] as String? ?? '',
      screenUsage: map['screenUsage'] as String? ?? 'moderate',
      driving: map['driving'] as bool? ?? false,
      reading: map['reading'] as bool? ?? false,
      workEnvironment: map['workEnvironment'] as String? ?? '',
      previousProblems: map['previousProblems'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
    );

extension PrescriptionMapper on Prescription {
  Map<String, dynamic> toMap() => {
    'id': id,
    'clientId': clientId,
    'consultationId': consultationId,
    'date': _enc(date),
    'expirationDate': _encN(expirationDate),
    'type': type,
    'sphOD': sphOD,
    'cylOD': cylOD,
    'axisOD': axisOD,
    'addOD': addOD,
    'visualAcuityOD': visualAcuityOD,
    'sphOS': sphOS,
    'cylOS': cylOS,
    'axisOS': axisOS,
    'addOS': addOS,
    'visualAcuityOS': visualAcuityOS,
    'pd': pd,
    'dominantEye': dominantEye,
    'notes': notes,
  };
}

Prescription prescriptionFromMap(Map<String, dynamic> map) => Prescription(
  id: map['id'] as String,
  clientId: map['clientId'] as String,
  consultationId: map['consultationId'] as String?,
  date: _dec(map['date']),
  expirationDate: _decN(map['expirationDate']),
  type: map['type'] as String? ?? 'distance',
  sphOD: (map['sphOD'] as num?)?.toDouble() ?? 0,
  cylOD: (map['cylOD'] as num?)?.toDouble() ?? 0,
  axisOD: map['axisOD'] as int? ?? 0,
  addOD: (map['addOD'] as num?)?.toDouble() ?? 0,
  visualAcuityOD: map['visualAcuityOD'] as String? ?? '',
  sphOS: (map['sphOS'] as num?)?.toDouble() ?? 0,
  cylOS: (map['cylOS'] as num?)?.toDouble() ?? 0,
  axisOS: map['axisOS'] as int? ?? 0,
  addOS: (map['addOS'] as num?)?.toDouble() ?? 0,
  visualAcuityOS: map['visualAcuityOS'] as String? ?? '',
  pd: (map['pd'] as num?)?.toDouble() ?? 0,
  dominantEye: map['dominantEye'] as String? ?? 'none',
  notes: map['notes'] as String? ?? '',
);

extension MeasurementMapper on Measurement {
  Map<String, dynamic> toMap() => {
    'id': id,
    'clientId': clientId,
    'consultationId': consultationId,
    'date': _enc(date),
    'pd': pd,
    'monocularPdOD': monocularPdOD,
    'monocularPdOS': monocularPdOS,
    'fittingHeight': fittingHeight,
    'bridge': bridge,
    'templeLength': templeLength,
    'frameWidth': frameWidth,
    'lensWidth': lensWidth,
    'dbl': dbl,
    'vertexDistance': vertexDistance,
    'pantoscopicAngle': pantoscopicAngle,
    'faceFormAngle': faceFormAngle,
    'method': method,
    'deviceUsed': deviceUsed,
    'operator': operator,
    'notes': notes,
  };
}

Measurement measurementFromMap(Map<String, dynamic> map) => Measurement(
  id: map['id'] as String,
  clientId: map['clientId'] as String,
  consultationId: map['consultationId'] as String?,
  date: _dec(map['date']),
  pd: (map['pd'] as num?)?.toDouble() ?? 0,
  monocularPdOD: (map['monocularPdOD'] as num?)?.toDouble() ?? 0,
  monocularPdOS: (map['monocularPdOS'] as num?)?.toDouble() ?? 0,
  fittingHeight: (map['fittingHeight'] as num?)?.toDouble() ?? 0,
  bridge: (map['bridge'] as num?)?.toDouble() ?? 0,
  templeLength: (map['templeLength'] as num?)?.toDouble() ?? 0,
  frameWidth: (map['frameWidth'] as num?)?.toDouble() ?? 0,
  lensWidth: (map['lensWidth'] as num?)?.toDouble() ?? 0,
  dbl: (map['dbl'] as num?)?.toDouble() ?? 0,
  vertexDistance: (map['vertexDistance'] as num?)?.toDouble() ?? 0,
  pantoscopicAngle: (map['pantoscopicAngle'] as num?)?.toDouble() ?? 0,
  faceFormAngle: (map['faceFormAngle'] as num?)?.toDouble() ?? 0,
  method: map['method'] as String? ?? 'manual',
  deviceUsed: map['deviceUsed'] as String? ?? '',
  operator: map['operator'] as String? ?? '',
  notes: map['notes'] as String? ?? '',
);

extension FrameMapper on Frame {
  Map<String, dynamic> toMap() => {
    'id': id,
    'sku': sku,
    'barcode': barcode,
    'brand': brand,
    'model': model,
    'collection': collection,
    'gender': gender,
    'material': material,
    'frameType': frameType,
    'shape': shape,
    'color': color,
    'size': size,
    'price': price,
    'cost': cost,
    'supplier': supplier,
    'stockAvailable': stockAvailable,
    'stockReserved': stockReserved,
    'warrantyMonths': warrantyMonths,
  };
}

Frame frameFromMap(Map<String, dynamic> map) => Frame(
  id: map['id'] as String,
  sku: map['sku'] as String,
  barcode: map['barcode'] as String? ?? '',
  brand: map['brand'] as String,
  model: map['model'] as String,
  collection: map['collection'] as String? ?? '',
  gender: map['gender'] as String? ?? 'unisex',
  material: map['material'] as String? ?? '',
  frameType: map['frameType'] as String? ?? 'fullRim',
  shape: map['shape'] as String? ?? 'other',
  color: map['color'] as String,
  size: map['size'] as String,
  price: (map['price'] as num?)?.toDouble() ?? 0,
  cost: (map['cost'] as num?)?.toDouble() ?? 0,
  supplier: map['supplier'] as String? ?? '',
  stockAvailable: map['stockAvailable'] as int? ?? 0,
  stockReserved: map['stockReserved'] as int? ?? 0,
  warrantyMonths: map['warrantyMonths'] as int? ?? 12,
);

extension LensMapper on Lens {
  Map<String, dynamic> toMap() => {
    'id': id,
    'sku': sku,
    'manufacturer': manufacturer,
    'brand': brand,
    'productName': productName,
    'lensType': lensType,
    'material': material,
    'index': index,
    'design': design,
    'coatings': coatings,
    'baseCurve': baseCurve,
    'diameter': diameter,
    'cost': cost,
    'price': price,
    'supplier': supplier,
    'warrantyMonths': warrantyMonths,
  };
}

Lens lensFromMap(Map<String, dynamic> map) => Lens(
  id: map['id'] as String,
  sku: map['sku'] as String,
  manufacturer: map['manufacturer'] as String,
  brand: map['brand'] as String,
  productName: map['productName'] as String,
  lensType: map['lensType'] as String? ?? 'singleVision',
  material: map['material'] as String? ?? '',
  index: (map['index'] as num?)?.toDouble() ?? 1.5,
  design: map['design'] as String? ?? '',
  coatings: _strList(map['coatings']),
  baseCurve: (map['baseCurve'] as num?)?.toDouble() ?? 0,
  diameter: (map['diameter'] as num?)?.toDouble() ?? 0,
  cost: (map['cost'] as num?)?.toDouble() ?? 0,
  price: (map['price'] as num?)?.toDouble() ?? 0,
  supplier: map['supplier'] as String? ?? '',
  warrantyMonths: map['warrantyMonths'] as int? ?? 12,
);

extension ContactLensProductMapper on ContactLensProduct {
  Map<String, dynamic> toMap() => {
    'id': id,
    'sku': sku,
    'brand': brand,
    'model': model,
    'material': material,
    'replacementSchedule': replacementSchedule,
    'boxQuantity': boxQuantity,
    'supplier': supplier,
    'stock': stock,
    'cost': cost,
    'price': price,
  };
}

ContactLensProduct contactLensProductFromMap(Map<String, dynamic> map) =>
    ContactLensProduct(
      id: map['id'] as String,
      sku: map['sku'] as String,
      brand: map['brand'] as String,
      model: map['model'] as String,
      material: map['material'] as String? ?? '',
      replacementSchedule: map['replacementSchedule'] as String? ?? 'monthly',
      boxQuantity: map['boxQuantity'] as int? ?? 6,
      supplier: map['supplier'] as String? ?? '',
      stock: map['stock'] as int? ?? 0,
      cost: (map['cost'] as num?)?.toDouble() ?? 0,
      price: (map['price'] as num?)?.toDouble() ?? 0,
    );

extension ContactLensPrescriptionMapper on ContactLensPrescription {
  Map<String, dynamic> toMap() => {
    'id': id,
    'clientId': clientId,
    'date': _enc(date),
    'powerOD': powerOD,
    'baseCurveOD': baseCurveOD,
    'diameterOD': diameterOD,
    'cylOD': cylOD,
    'axisOD': axisOD,
    'addOD': addOD,
    'powerOS': powerOS,
    'baseCurveOS': baseCurveOS,
    'diameterOS': diameterOS,
    'cylOS': cylOS,
    'axisOS': axisOS,
    'addOS': addOS,
    'brand': brand,
    'material': material,
    'replacementFrequency': replacementFrequency,
    'notes': notes,
  };
}

ContactLensPrescription contactLensPrescriptionFromMap(
  Map<String, dynamic> map,
) => ContactLensPrescription(
  id: map['id'] as String,
  clientId: map['clientId'] as String,
  date: _dec(map['date']),
  powerOD: (map['powerOD'] as num?)?.toDouble() ?? 0,
  baseCurveOD: (map['baseCurveOD'] as num?)?.toDouble() ?? 0,
  diameterOD: (map['diameterOD'] as num?)?.toDouble() ?? 0,
  cylOD: (map['cylOD'] as num?)?.toDouble() ?? 0,
  axisOD: map['axisOD'] as int? ?? 0,
  addOD: (map['addOD'] as num?)?.toDouble() ?? 0,
  powerOS: (map['powerOS'] as num?)?.toDouble() ?? 0,
  baseCurveOS: (map['baseCurveOS'] as num?)?.toDouble() ?? 0,
  diameterOS: (map['diameterOS'] as num?)?.toDouble() ?? 0,
  cylOS: (map['cylOS'] as num?)?.toDouble() ?? 0,
  axisOS: map['axisOS'] as int? ?? 0,
  addOS: (map['addOS'] as num?)?.toDouble() ?? 0,
  brand: map['brand'] as String? ?? '',
  material: map['material'] as String? ?? '',
  replacementFrequency: map['replacementFrequency'] as String? ?? 'monthly',
  notes: map['notes'] as String? ?? '',
);

// --- Modules 7-14 ------------------------------------------------------------

extension CommunicationLogMapper on CommunicationLog {
  Map<String, dynamic> toMap() => {
    'id': id,
    'clientId': clientId,
    'date': _enc(date),
    'channel': channel,
    'direction': direction,
    'subject': subject,
    'note': note,
    'followUpRequired': followUpRequired,
  };
}

CommunicationLog communicationLogFromMap(Map<String, dynamic> map) =>
    CommunicationLog(
      id: map['id'] as String,
      clientId: map['clientId'] as String,
      date: _dec(map['date']),
      channel: map['channel'] as String? ?? 'phone',
      direction: map['direction'] as String? ?? 'outbound',
      subject: map['subject'] as String,
      note: map['note'] as String? ?? '',
      followUpRequired: map['followUpRequired'] as bool? ?? false,
    );

extension FrameSelectionSessionMapper on FrameSelectionSession {
  Map<String, dynamic> toMap() => {
    'id': id,
    'clientId': clientId,
    'consultationId': consultationId,
    'date': _enc(date),
    'method': method,
    'framesTried': framesTried,
    'selectedFrameId': selectedFrameId,
    'notes': notes,
  };
}

FrameSelectionSession frameSelectionSessionFromMap(
  Map<String, dynamic> map,
) => FrameSelectionSession(
  id: map['id'] as String,
  clientId: map['clientId'] as String,
  consultationId: map['consultationId'] as String?,
  date: _dec(map['date']),
  method: map['method'] as String? ?? 'inStore',
  framesTried: _strList(map['framesTried']),
  selectedFrameId: map['selectedFrameId'] as String?,
  notes: map['notes'] as String? ?? '',
);

extension LensRecommendationMapper on LensRecommendation {
  Map<String, dynamic> toMap() => {
    'id': id,
    'clientId': clientId,
    'date': _enc(date),
    'prescriptionId': prescriptionId,
    'measurementId': measurementId,
    'frameSelectionId': frameSelectionId,
    'recommendedLensType': recommendedLensType,
    'recommendedCoatings': recommendedCoatings,
    'reason': reason,
    'accepted': accepted,
  };
}

LensRecommendation lensRecommendationFromMap(Map<String, dynamic> map) =>
    LensRecommendation(
      id: map['id'] as String,
      clientId: map['clientId'] as String,
      date: _dec(map['date']),
      prescriptionId: map['prescriptionId'] as String?,
      measurementId: map['measurementId'] as String?,
      frameSelectionId: map['frameSelectionId'] as String?,
      recommendedLensType: map['recommendedLensType'] as String,
      recommendedCoatings: _strList(map['recommendedCoatings']),
      reason: map['reason'] as String? ?? '',
      accepted: map['accepted'] as bool? ?? false,
    );

extension AccessoryMapper on Accessory {
  Map<String, dynamic> toMap() => {
    'id': id,
    'sku': sku,
    'name': name,
    'category': category,
    'brand': brand,
    'price': price,
    'cost': cost,
    'supplier': supplier,
    'stock': stock,
  };
}

Accessory accessoryFromMap(Map<String, dynamic> map) => Accessory(
  id: map['id'] as String,
  sku: map['sku'] as String,
  name: map['name'] as String,
  category: map['category'] as String? ?? 'other',
  brand: map['brand'] as String? ?? '',
  price: (map['price'] as num?)?.toDouble() ?? 0,
  cost: (map['cost'] as num?)?.toDouble() ?? 0,
  supplier: map['supplier'] as String? ?? '',
  stock: map['stock'] as int? ?? 0,
);

extension QuoteMapper on Quote {
  Map<String, dynamic> toMap() => {
    'id': id,
    'clientId': clientId,
    'date': _enc(date),
    'description': description,
    'totalAmount': totalAmount,
    'status': status,
    'validUntil': _encN(validUntil),
    'lensRecommendationId': lensRecommendationId,
    'prescriptionId': prescriptionId,
    'measurementId': measurementId,
    'frameId': frameId,
    'lensId': lensId,
    'accessoryId': accessoryId,
  };
}

Quote quoteFromMap(Map<String, dynamic> map) => Quote(
  id: map['id'] as String,
  clientId: map['clientId'] as String,
  date: _dec(map['date']),
  description: map['description'] as String,
  totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0,
  status: map['status'] as String? ?? 'draft',
  validUntil: _decN(map['validUntil']),
  lensRecommendationId: map['lensRecommendationId'] as String?,
  prescriptionId: map['prescriptionId'] as String?,
  measurementId: map['measurementId'] as String?,
  frameId: map['frameId'] as String?,
  lensId: map['lensId'] as String?,
  accessoryId: map['accessoryId'] as String?,
);

extension OrderMapper on Order {
  Map<String, dynamic> toMap() => {
    'id': id,
    'clientId': clientId,
    'date': _enc(date),
    'quoteId': quoteId,
    'description': description,
    'totalAmount': totalAmount,
    'status': status,
    'prescriptionId': prescriptionId,
    'measurementId': measurementId,
    'frameId': frameId,
    'lensId': lensId,
    'accessoryId': accessoryId,
  };
}

Order orderFromMap(Map<String, dynamic> map) => Order(
  id: map['id'] as String,
  clientId: map['clientId'] as String,
  date: _dec(map['date']),
  quoteId: map['quoteId'] as String?,
  description: map['description'] as String,
  totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0,
  status: map['status'] as String? ?? 'pending',
  prescriptionId: map['prescriptionId'] as String?,
  measurementId: map['measurementId'] as String?,
  frameId: map['frameId'] as String?,
  lensId: map['lensId'] as String?,
  accessoryId: map['accessoryId'] as String?,
);

extension LabWorkOrderMapper on LabWorkOrder {
  Map<String, dynamic> toMap() => {
    'id': id,
    'orderId': orderId,
    'clientId': clientId,
    'date': _enc(date),
    'taskType': taskType,
    'status': status,
    'dueDate': _encN(dueDate),
    'prescriptionId': prescriptionId,
    'measurementId': measurementId,
    'frameId': frameId,
    'lensId': lensId,
  };
}

LabWorkOrder labWorkOrderFromMap(Map<String, dynamic> map) => LabWorkOrder(
  id: map['id'] as String,
  orderId: map['orderId'] as String,
  clientId: map['clientId'] as String,
  date: _dec(map['date']),
  taskType: map['taskType'] as String? ?? 'lensCutting',
  status: map['status'] as String? ?? 'queued',
  dueDate: _decN(map['dueDate']),
  prescriptionId: map['prescriptionId'] as String?,
  measurementId: map['measurementId'] as String?,
  frameId: map['frameId'] as String?,
  lensId: map['lensId'] as String?,
);

extension MountingJobMapper on MountingJob {
  Map<String, dynamic> toMap() => {
    'id': id,
    'orderId': orderId,
    'clientId': clientId,
    'date': _enc(date),
    'frameId': frameId,
    'lensId': lensId,
    'status': status,
    'completedDate': _encN(completedDate),
    'labWorkOrderId': labWorkOrderId,
    'reworkOfQualityCheckId': reworkOfQualityCheckId,
  };
}

MountingJob mountingJobFromMap(Map<String, dynamic> map) => MountingJob(
  id: map['id'] as String,
  orderId: map['orderId'] as String,
  clientId: map['clientId'] as String,
  date: _dec(map['date']),
  frameId: map['frameId'] as String,
  lensId: map['lensId'] as String,
  status: map['status'] as String? ?? 'pending',
  completedDate: _decN(map['completedDate']),
  labWorkOrderId: map['labWorkOrderId'] as String?,
  reworkOfQualityCheckId: map['reworkOfQualityCheckId'] as String?,
);

// --- Modules 15-22 ------------------------------------------------------------

extension QualityCheckMapper on QualityCheck {
  Map<String, dynamic> toMap() => {
    'id': id,
    'orderId': orderId,
    'clientId': clientId,
    'date': _enc(date),
    'checkType': checkType,
    'result': result,
    'notes': notes,
    'mountingJobId': mountingJobId,
  };
}

QualityCheck qualityCheckFromMap(Map<String, dynamic> map) => QualityCheck(
  id: map['id'] as String,
  orderId: map['orderId'] as String,
  clientId: map['clientId'] as String,
  date: _dec(map['date']),
  checkType: map['checkType'] as String? ?? 'frameFit',
  result: map['result'] as String? ?? 'pass',
  notes: map['notes'] as String? ?? '',
  mountingJobId: map['mountingJobId'] as String?,
);

extension FinalFittingMapper on FinalFitting {
  Map<String, dynamic> toMap() => {
    'id': id,
    'orderId': orderId,
    'clientId': clientId,
    'date': _enc(date),
    'adjustmentType': adjustmentType,
    'comfortRating': comfortRating,
    'notes': notes,
    'qualityCheckId': qualityCheckId,
  };
}

FinalFitting finalFittingFromMap(Map<String, dynamic> map) => FinalFitting(
  id: map['id'] as String,
  orderId: map['orderId'] as String,
  clientId: map['clientId'] as String,
  date: _dec(map['date']),
  adjustmentType: map['adjustmentType'] as String? ?? 'frameAlignment',
  comfortRating: map['comfortRating'] as int? ?? 5,
  notes: map['notes'] as String? ?? '',
  qualityCheckId: map['qualityCheckId'] as String?,
);

extension DeliveryRecordMapper on DeliveryRecord {
  Map<String, dynamic> toMap() => {
    'id': id,
    'orderId': orderId,
    'clientId': clientId,
    'date': _enc(date),
    'method': method,
    'status': status,
    'recipientSignature': recipientSignature,
    'invoiceId': invoiceId,
  };
}

DeliveryRecord deliveryRecordFromMap(Map<String, dynamic> map) =>
    DeliveryRecord(
      id: map['id'] as String,
      orderId: map['orderId'] as String,
      clientId: map['clientId'] as String,
      date: _dec(map['date']),
      method: map['method'] as String? ?? 'inStore',
      status: map['status'] as String? ?? 'scheduled',
      recipientSignature: map['recipientSignature'] as bool? ?? false,
      invoiceId: map['invoiceId'] as String?,
    );

extension AfterSalesTicketMapper on AfterSalesTicket {
  Map<String, dynamic> toMap() => {
    'id': id,
    'orderId': orderId,
    'clientId': clientId,
    'date': _enc(date),
    'issueType': issueType,
    'status': status,
    'resolution': resolution,
    'deliveryRecordId': deliveryRecordId,
    'outcome': outcome,
  };
}

AfterSalesTicket afterSalesTicketFromMap(Map<String, dynamic> map) =>
    AfterSalesTicket(
      id: map['id'] as String,
      orderId: map['orderId'] as String,
      clientId: map['clientId'] as String,
      date: _dec(map['date']),
      issueType: map['issueType'] as String? ?? 'comfort',
      status: map['status'] as String? ?? 'open',
      resolution: map['resolution'] as String? ?? '',
      deliveryRecordId: map['deliveryRecordId'] as String?,
      outcome: map['outcome'] as String? ?? 'pending',
    );

extension RepairTicketMapper on RepairTicket {
  Map<String, dynamic> toMap() => {
    'id': id,
    'clientId': clientId,
    'orderId': orderId,
    'date': _enc(date),
    'itemType': itemType,
    'issueDescription': issueDescription,
    'status': status,
    'cost': cost,
    'afterSalesTicketId': afterSalesTicketId,
  };
}

RepairTicket repairTicketFromMap(Map<String, dynamic> map) => RepairTicket(
  id: map['id'] as String,
  clientId: map['clientId'] as String,
  orderId: map['orderId'] as String?,
  date: _dec(map['date']),
  itemType: map['itemType'] as String? ?? 'frame',
  issueDescription: map['issueDescription'] as String,
  status: map['status'] as String? ?? 'received',
  cost: (map['cost'] as num?)?.toDouble() ?? 0,
  afterSalesTicketId: map['afterSalesTicketId'] as String?,
);

extension WarrantyClaimMapper on WarrantyClaim {
  Map<String, dynamic> toMap() => {
    'id': id,
    'clientId': clientId,
    'orderId': orderId,
    'date': _enc(date),
    'itemType': itemType,
    'issueDescription': issueDescription,
    'status': status,
    'afterSalesTicketId': afterSalesTicketId,
  };
}

WarrantyClaim warrantyClaimFromMap(Map<String, dynamic> map) =>
    WarrantyClaim(
      id: map['id'] as String,
      clientId: map['clientId'] as String,
      orderId: map['orderId'] as String?,
      date: _dec(map['date']),
      itemType: map['itemType'] as String? ?? 'frame',
      issueDescription: map['issueDescription'] as String,
      status: map['status'] as String? ?? 'submitted',
      afterSalesTicketId: map['afterSalesTicketId'] as String?,
    );

extension SupplierMapper on Supplier {
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'category': category,
    'contactPerson': contactPerson,
    'phone': phone,
    'email': email,
    'paymentTerms': paymentTerms,
    'rating': rating,
  };
}

Supplier supplierFromMap(Map<String, dynamic> map) => Supplier(
  id: map['id'] as String,
  name: map['name'] as String,
  category: map['category'] as String? ?? 'general',
  contactPerson: map['contactPerson'] as String? ?? '',
  phone: map['phone'] as String? ?? '',
  email: map['email'] as String? ?? '',
  paymentTerms: map['paymentTerms'] as String? ?? '',
  rating: map['rating'] as int? ?? 5,
);

extension PurchaseOrderMapper on PurchaseOrder {
  Map<String, dynamic> toMap() => {
    'id': id,
    'supplierId': supplierId,
    'date': _enc(date),
    'description': description,
    'totalAmount': totalAmount,
    'status': status,
    'expectedDate': _encN(expectedDate),
    'orderId': orderId,
    'frameId': frameId,
    'lensId': lensId,
  };
}

PurchaseOrder purchaseOrderFromMap(Map<String, dynamic> map) =>
    PurchaseOrder(
      id: map['id'] as String,
      supplierId: map['supplierId'] as String,
      date: _dec(map['date']),
      description: map['description'] as String,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0,
      status: map['status'] as String? ?? 'draft',
      expectedDate: _decN(map['expectedDate']),
      orderId: map['orderId'] as String?,
      frameId: map['frameId'] as String?,
      lensId: map['lensId'] as String?,
    );
