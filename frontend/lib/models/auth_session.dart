enum UserRole { patient, doctor }

extension UserRoleName on UserRole {
  String get apiValue => this == UserRole.patient ? 'PATIENT' : 'DOCTOR';

  String get displayName => this == UserRole.patient ? 'ผู้ป่วย' : 'แพทย์';
}

class AuthSession {
  final String accessToken;
  final UserRole role;

  const AuthSession({required this.accessToken, required this.role});

  bool get isPatient => role == UserRole.patient;

  bool get isDoctor => role == UserRole.doctor;
}
