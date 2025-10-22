import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'doctor/models/doctor_models.dart';
import 'models/auth_session.dart';

class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  static final String _baseUrl = _resolveBaseUrl();
  static const Duration _timeout = Duration(seconds: 20);

  final http.Client _client;

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$_baseUrl$path').replace(queryParameters: query);

  static String _resolveBaseUrl() {
    const fallback = 'http://127.0.0.1:8000/api';
    final bindAddr = dotenv.maybeGet('BIND_ADDR')?.trim();
    if (bindAddr == null || bindAddr.isEmpty) {
      return fallback;
    }
    final hasScheme =
        bindAddr.startsWith('http://') || bindAddr.startsWith('https://');
    final withScheme = hasScheme ? bindAddr : 'http://$bindAddr';
    final sanitized = withScheme.endsWith('/')
        ? withScheme.substring(0, withScheme.length - 1)
        : withScheme;
    if (sanitized.endsWith('/api')) {
      return sanitized;
    }
    return '$sanitized/api';
  }

  Map<String, String> _headers({AuthSession? session}) {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    };
    if (session != null) {
      headers['Authorization'] = 'Bearer ${session.accessToken}';
    }
    return headers;
  }

  Future<Map<String, dynamic>> _getJson(
    String path, {
    AuthSession? session,
    Map<String, String>? query,
  }) async {
    final response = await _client
        .get(_uri(path, query), headers: _headers(session: session))
        .timeout(_timeout);
    return _decodeJsonObject(response);
  }

  Future<Map<String, dynamic>?> _getJsonOptional(
    String path, {
    AuthSession? session,
    Map<String, String>? query,
  }) async {
    final response = await _client
        .get(_uri(path, query), headers: _headers(session: session))
        .timeout(_timeout);
    if (response.statusCode == 404) {
      return null;
    }
    return _decodeJsonObject(response);
  }

  Future<List<dynamic>> _getJsonList(
    String path, {
    AuthSession? session,
    Map<String, String>? query,
  }) async {
    final response = await _client
        .get(_uri(path, query), headers: _headers(session: session))
        .timeout(_timeout);
    return _decodeJsonList(response);
  }

  Future<List<dynamic>> _getJsonListOrEmpty(
    String path, {
    AuthSession? session,
    Map<String, String>? query,
  }) async {
    final response = await _client
        .get(_uri(path, query), headers: _headers(session: session))
        .timeout(_timeout);
    if (response.statusCode == 404) {
      return const <dynamic>[];
    }
    return _decodeJsonList(response);
  }

  Future<Map<String, dynamic>> _postJson(
    String path, {
    Map<String, dynamic>? body,
    AuthSession? session,
  }) async {
    final response = await _client
        .post(
          _uri(path),
          headers: _headers(session: session),
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(_timeout);
    return _decodeJsonObject(response);
  }

  Future<Map<String, dynamic>> _patchJson(
    String path, {
    Map<String, dynamic>? body,
    AuthSession? session,
  }) async {
    final response = await _client
        .patch(
          _uri(path),
          headers: _headers(session: session),
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(_timeout);
    return _decodeJsonObject(response);
  }

  Future<void> _delete(String path, {AuthSession? session}) async {
    final response = await _client
        .delete(_uri(path), headers: _headers(session: session))
        .timeout(_timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwHttpError(response);
    }
  }

  Map<String, dynamic> _decodeJsonObject(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwHttpError(response);
    }
    if (response.statusCode == 204 || response.body.isEmpty) {
      return <String, dynamic>{};
    }
    final dynamic decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw Exception('Unexpected response format (expected object)');
  }

  List<dynamic> _decodeJsonList(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwHttpError(response);
    }
    if (response.statusCode == 204 || response.body.isEmpty) {
      return const <dynamic>[];
    }
    final dynamic decoded = jsonDecode(response.body);
    if (decoded is List<dynamic>) {
      return decoded;
    }
    throw Exception('Unexpected response format (expected array)');
  }

  Never _throwHttpError(http.Response response) {
    try {
      final dynamic decoded = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : null;
      if (decoded is Map<String, dynamic>) {
        final message =
            decoded['message'] ??
            decoded['error'] ??
            decoded['detail'] ??
            decoded['reason'];
        if (message is String && message.isNotEmpty) {
          throw Exception(message);
        }
      }
    } catch (_) {
      // Ignore parse errors and fall back to status text.
    }
    throw Exception('Request failed with status ${response.statusCode}');
  }

  String _requireToken(Map<String, dynamic> payload) {
    final token = payload['access_token'] as String?;
    if (token == null || token.isEmpty) {
      throw Exception('ไม่พบ access token จากเซิร์ฟเวอร์');
    }
    return token;
  }

  /// Authentication & registration ------------------------------------------------

  Future<AuthSession> registerPatient({
    required String hn,
    required String citizenId,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  }) async {
    final hnValue = int.tryParse(hn.trim());
    if (hnValue == null) {
      throw Exception('Hospital Number (HN) ต้องเป็นตัวเลข');
    }
    final payload = <String, dynamic>{
      'hn': hnValue,
      'citizen_id': citizenId.trim(),
      'first_name': firstName.trim(),
      'last_name': lastName.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'password': password,
    };
    final data = await _postJson('/users/patients', body: payload);
    final token = _requireToken(data);
    return AuthSession(accessToken: token, role: UserRole.patient);
  }

  Future<AuthSession> registerDoctor({
    required String mln,
    required String citizenId,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  }) async {
    final payload = <String, dynamic>{
      'mln': mln.trim(),
      'citizen_id': citizenId.trim(),
      'first_name': firstName.trim(),
      'last_name': lastName.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'password': password,
    };
    final data = await _postJson('/users/doctors', body: payload);
    final token = _requireToken(data);
    return AuthSession(accessToken: token, role: UserRole.doctor);
  }

  Future<AuthSession> loginPatient({
    required String hn,
    required String citizenId,
    required String password,
  }) async {
    final hnValue = int.tryParse(hn.trim());
    if (hnValue == null) {
      throw Exception('Hospital Number (HN) ต้องเป็นตัวเลข');
    }
    final payload = <String, dynamic>{
      'hn': hnValue,
      'citizen_id': citizenId.trim(),
      'password': password,
    };
    final data = await _postJson('/users/login/patients', body: payload);
    final token = _requireToken(data);
    return AuthSession(accessToken: token, role: UserRole.patient);
  }

  Future<AuthSession> loginDoctor({
    required String mln,
    required String citizenId,
    required String password,
  }) async {
    final payload = <String, dynamic>{
      'mln': mln.trim(),
      'citizen_id': citizenId.trim(),
      'password': password,
    };
    final data = await _postJson('/users/login/doctors', body: payload);
    final token = _requireToken(data);
    return AuthSession(accessToken: token, role: UserRole.doctor);
  }

  /// Profiles --------------------------------------------------------------------

  Future<PatientProfile> getPatientProfile(AuthSession session) async {
    final data = await _getJson('/users/patient/profiles', session: session);
    return PatientProfile.fromJson(data);
  }

  Future<DoctorProfile> getDoctorProfile(AuthSession session) async {
    final data = await _getJson('/users/doctor/profiles', session: session);
    return DoctorProfile.fromJson(data);
  }

  Future<List<MedicalRight>> getMedicalRights(AuthSession session) async {
    final items = await _getJsonListOrEmpty(
      '/users/me/medical-rights',
      session: session,
    );
    return items
        .whereType<Map<String, dynamic>>()
        .map(MedicalRight.fromJson)
        .toList();
  }

  /// Patient view ----------------------------------------------------------------

  Future<PatientAppointments> getPatientAppointments(
    AuthSession session,
  ) async {
    final upcoming = await _getJsonListOrEmpty(
      '/appointments/status',
      session: session,
    );
    final history = await _getJsonListOrEmpty(
      '/appointments/status/others',
      session: session,
    );

    return PatientAppointments(
      upcoming: upcoming
          .whereType<Map<String, dynamic>>()
          .map(AppointmentOverview.fromJson)
          .toList(),
      history: history
          .whereType<Map<String, dynamic>>()
          .map(AppointmentOverview.fromJson)
          .toList(),
    );
  }

  /// Doctor view -----------------------------------------------------------------

  Future<List<DoctorAppointment>> getDoctorAppointments(
    AuthSession session,
  ) async {
    final pending = await getDoctorPendingAppointments(session);
    final assessed = await getDoctorAssessedAppointments(session);
    final combined = <DoctorAppointment>[...pending, ...assessed];
    combined.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
    return combined;
  }

  Future<List<DoctorAppointment>> getDoctorPendingAppointments(
    AuthSession session,
  ) async {
    final data = await _getJsonListOrEmpty(
      '/appointments/request',
      session: session,
    );
    return data
        .whereType<Map<String, dynamic>>()
        .map(DoctorAppointment.fromJson)
        .toList();
  }

  Future<List<DoctorAppointment>> getDoctorAssessedAppointments(
    AuthSession session,
  ) async {
    final data = await _getJsonListOrEmpty(
      '/appointments/assessed',
      session: session,
    );
    return data
        .whereType<Map<String, dynamic>>()
        .map(DoctorAppointment.fromJson)
        .toList();
  }

  Future<List<DoctorAppointment>> getDoctorScheduleByDate(
    AuthSession session,
    DateTime date,
  ) async {
    final data = await _getJsonListOrEmpty(
      '/appointments/by-doctor/${_formatDate(date)}',
      session: session,
    );
    return data
        .whereType<Map<String, dynamic>>()
        .map(DoctorAppointment.fromJson)
        .toList();
  }

  /// Patient details for doctors -------------------------------------------------

  Future<PatientOverview?> getPatientOverview(
    AuthSession session,
    String patientId,
  ) async {
    final data = await _getJsonOptional(
      '/diagnoses/by-patient/$patientId/info',
      session: session,
    );
    if (data == null) {
      return null;
    }
    return PatientOverview.fromJson(data);
  }

  Future<List<DiagnosisEntry>> getPatientDiagnoses(
    AuthSession session,
    String patientId,
  ) async {
    final data = await _getJsonListOrEmpty(
      '/diagnoses/by-patient/$patientId',
      session: session,
    );
    return data
        .whereType<Map<String, dynamic>>()
        .map(DiagnosisEntry.fromJson)
        .toList();
  }

  /// Prescriptions ---------------------------------------------------------------

  Future<List<PrescriptionItem>> getPatientPrescriptions(
    AuthSession session,
    String patientId,
  ) async {
    final data = await _getJsonListOrEmpty(
      '/prescriptions/patient/$patientId',
      session: session,
    );
    return data
        .whereType<Map<String, dynamic>>()
        .map(PrescriptionItem.fromJson)
        .toList();
  }

  Future<PrescriptionItem> createPrescription({
    required AuthSession session,
    required String patientId,
    required int medicineId,
    required String dosage,
    required int amount,
    required bool onGoing,
    String? doctorComment,
  }) async {
    final payload = <String, dynamic>{
      'patient_id': patientId,
      'medicine_id': medicineId,
      'dosage': dosage,
      'amount': amount,
      'on_going': onGoing,
      'doctor_comment': doctorComment,
    };
    final resp = await _postJson(
      '/prescriptions',
      body: payload,
      session: session,
    );
    final createdId = resp['prescription_id'] as int?;
    if (createdId == null) {
      throw Exception('ไม่สามารถสร้างใบสั่งยาใหม่ได้');
    }
    final items = await getPatientPrescriptions(session, patientId);
    final match = items.firstWhere(
      (item) => item.prescriptionId == createdId,
      orElse: () {
        throw Exception('ไม่พบใบสั่งยาที่สร้างใหม่');
      },
    );
    return match.copyWith(medicineId: medicineId);
  }

  Future<PrescriptionItem> updatePrescription({
    required AuthSession session,
    required int prescriptionId,
    required String patientId,
    required int medicineId,
    required String dosage,
    required int amount,
    required bool onGoing,
    String? doctorComment,
  }) async {
    final payload = <String, dynamic>{
      'patient_id': patientId,
      'medicine_id': medicineId,
      'dosage': dosage,
      'amount': amount,
      'on_going': onGoing,
      'doctor_comment': doctorComment,
    };
    await _patchJson(
      '/prescriptions/$prescriptionId',
      body: payload,
      session: session,
    );
    final items = await getPatientPrescriptions(session, patientId);
    final match = items.firstWhere(
      (item) => item.prescriptionId == prescriptionId,
      orElse: () {
        throw Exception('ไม่พบใบสั่งยาหลังอัปเดต');
      },
    );
    return match.copyWith(medicineId: medicineId);
  }

  Future<void> deletePrescription({
    required AuthSession session,
    required int prescriptionId,
  }) async {
    await _delete('/prescriptions/$prescriptionId', session: session);
  }

  Future<List<MedicineItem>> searchMedicines(
    AuthSession session, {
    String keyword = '',
  }) async {
    final safeKeyword = keyword.trim().isEmpty ? 'a' : keyword.trim();
    final data = await _getJsonListOrEmpty(
      '/prescriptions/search/${Uri.encodeComponent(safeKeyword)}',
      session: session,
    );
    return data
        .whereType<Map<String, dynamic>>()
        .map(MedicineItem.fromSearchJson)
        .toList();
  }

  Future<MedicineItem?> getMedicineInfo(
    AuthSession session,
    int medicineId,
  ) async {
    final data = await _getJsonOptional(
      '/prescriptions/medicines/$medicineId',
      session: session,
    );
    if (data == null) {
      return null;
    }
    return MedicineItem.fromInfoJson(data);
  }

  String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

/// Patient profile returned from /users/patient/profiles
class PatientProfile {
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final DateTime? updatedAt;

  PatientProfile({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.updatedAt,
  });

  factory PatientProfile.fromJson(Map<String, dynamic> json) {
    return PatientProfile(
      firstName: (json['first_name'] as String?)?.trim() ?? '',
      lastName: (json['last_name'] as String?)?.trim() ?? '',
      email: (json['email'] as String?)?.trim() ?? '',
      phone: (json['phone'] as String?)?.trim() ?? '',
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  String get fullName {
    final parts = <String>[];
    if (firstName.isNotEmpty) {
      parts.add(firstName);
    }
    if (lastName.isNotEmpty) {
      parts.add(lastName);
    }
    return parts.isEmpty ? '-' : parts.join(' ');
  }
}

/// Doctor profile returned from /users/doctor/profiles
class DoctorProfile {
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String departments;
  final String position;

  DoctorProfile({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.departments,
    required this.position,
  });

  factory DoctorProfile.fromJson(Map<String, dynamic> json) {
    return DoctorProfile(
      firstName: (json['first_name'] as String?)?.trim() ?? '',
      lastName: (json['last_name'] as String?)?.trim() ?? '',
      email: (json['email'] as String?)?.trim() ?? '',
      phone: (json['phone'] as String?)?.trim() ?? '',
      departments: (json['departments'] as String?)?.trim() ?? '',
      position: (json['position'] as String?)?.trim() ?? '',
    );
  }

  String get fullName {
    final parts = <String>[];
    if (firstName.isNotEmpty) {
      parts.add(firstName);
    }
    if (lastName.isNotEmpty) {
      parts.add(lastName);
    }
    return parts.isEmpty ? '-' : parts.join(' ');
  }
}

/// Medical rights assigned to a patient.
class MedicalRight {
  final int mrId;
  final String name;
  final String details;
  final String imageUrl;

  MedicalRight({
    required this.mrId,
    required this.name,
    required this.details,
    required this.imageUrl,
  });

  factory MedicalRight.fromJson(Map<String, dynamic> json) {
    return MedicalRight(
      mrId: json['mr_id'] as int,
      name: (json['name'] as String?)?.trim() ?? '-',
      details: (json['details'] as String?)?.trim() ?? '',
      imageUrl: (json['image_url'] as String?)?.trim() ?? '',
    );
  }
}

/// Patient appointment result buckets for the patient dashboard.
class PatientAppointments {
  final List<AppointmentOverview> upcoming;
  final List<AppointmentOverview> history;

  PatientAppointments({required this.upcoming, required this.history});
}

/// Appointment overview for patient views.
class AppointmentOverview {
  final int appointmentId;
  final String doctorName;
  final String? department;
  final String placeName;
  final String date;
  final String startTime;
  final String endTime;
  final String status;

  AppointmentOverview({
    required this.appointmentId,
    required this.doctorName,
    required this.department,
    required this.placeName,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
  });

  factory AppointmentOverview.fromJson(Map<String, dynamic> json) {
    return AppointmentOverview(
      appointmentId: json['appointment_id'] as int,
      doctorName: (json['doctor_name'] as String?)?.trim() ?? '-',
      department: (json['department'] as String?)?.trim(),
      placeName: (json['place_name'] as String?)?.trim() ?? '-',
      date: (json['date'] as String?)?.trim() ?? '',
      startTime: (json['start_time'] as String?)?.trim() ?? '',
      endTime: (json['end_time'] as String?)?.trim() ?? '',
      status: (json['status'] as String?)?.trim() ?? '',
    );
  }
}

/// Additional patient details visible to doctors.
class PatientOverview {
  final int? age;
  final String? gender;
  final double? heightCm;
  final double? weightKg;
  final String? medicalConditions;
  final String? drugAllergies;
  final DateTime? updatedAt;

  PatientOverview({
    required this.age,
    required this.gender,
    required this.heightCm,
    required this.weightKg,
    required this.medicalConditions,
    required this.drugAllergies,
    required this.updatedAt,
  });

  factory PatientOverview.fromJson(Map<String, dynamic> json) {
    return PatientOverview(
      age: json['age'] as int?,
      gender: (json['gender'] as String?)?.trim(),
      heightCm: (json['height_cm'] as num?)?.toDouble(),
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      medicalConditions: (json['medical_conditions'] as String?)?.trim(),
      drugAllergies: (json['drug_allergies'] as String?)?.trim(),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }
}

DateTime? _parseDateTime(dynamic value) {
  if (value is String && value.isNotEmpty) {
    try {
      return DateTime.parse(value).toLocal();
    } catch (_) {
      return null;
    }
  }
  return null;
}
