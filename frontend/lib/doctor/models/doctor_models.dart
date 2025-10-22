import 'dart:ffi';

class Doctor {
  final String id;
  final String name;
  final String? department;
  late List<DoctorTimeSlot> timeSlots = [];

  Doctor({required this.id, required this.name, required this.department});

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: (json['doctor_id'] as String?)?.trim() ?? '',
      name: (json['doctor_name'] as String?)?.trim() ?? '-',
      department: (json['department'] as String?)?.trim(),
    );
  }
}

class DoctorTimeSlot {
  final int timeSlotId;
  final int dayOfWeeks;
  final String startTime;
  final String endTime;
  final String placeName;

  DoctorTimeSlot({
    required this.timeSlotId,
    required this.dayOfWeeks,
    required this.startTime,
    required this.endTime,
    required this.placeName,
  });

  factory DoctorTimeSlot.fromJson(Map<String, dynamic> json) {
    return DoctorTimeSlot(
      timeSlotId: json['timeslot_id'] as int,
      dayOfWeeks: json['day_of_weeks'] as int,
      startTime: (json['start_time'] as String?)?.trim() ?? '',
      endTime: (json['end_time'] as String?)?.trim() ?? '',
      placeName: (json['place_name'] as String?)?.trim() ?? '-',
    );
  }
}

class DoctorAppointment {
  final int appointmentId;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String placeName;
  final String patientId;
  final String patientName;
  final String status;
  final int? statusCode;
  final int? patientAge;
  final double? patientHeightCm;
  final double? patientWeightKg;
  final String? medicalConditions;
  final String? drugAllergies;
  final String? latestDiagnosis;

  DoctorAppointment({
    required this.appointmentId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.placeName,
    required this.patientId,
    required this.patientName,
    required this.status,
    required this.statusCode,
    required this.patientAge,
    required this.patientHeightCm,
    required this.patientWeightKg,
    required this.medicalConditions,
    required this.drugAllergies,
    required this.latestDiagnosis,
  });

  factory DoctorAppointment.fromJson(Map<String, dynamic> json) {
    return DoctorAppointment(
      appointmentId: json['appointment_id'] as int,
      date: _parseDate(json['date']),
      startTime: (json['start_time'] as String?)?.trim() ?? '',
      endTime: (json['end_time'] as String?)?.trim() ?? '',
      placeName: (json['place_name'] as String?)?.trim() ?? '-',
      patientId: (json['patient_id'] as String?)?.trim() ?? '',
      patientName: (json['patient_name'] as String?)?.trim() ?? '-',
      status: (json['status'] as String? ?? 'PENDING').toUpperCase(),
      statusCode: json['status_code'] as int?,
      patientAge: json['patient_age'] as int?,
      patientHeightCm: (json['patient_height_cm'] as num?)?.toDouble(),
      patientWeightKg: (json['patient_weight_kg'] as num?)?.toDouble(),
      medicalConditions: (json['medical_conditions'] as String?)?.trim(),
      drugAllergies: (json['drug_allergies'] as String?)?.trim(),
      latestDiagnosis: (json['latest_diagnosis'] as String?)?.trim(),
    );
  }

  String get timeRange => '$startTime - $endTime';

  bool get isPending => status == 'PENDING';

  DateTime get startDateTime {
    final base = DateTime(date.year, date.month, date.day);
    final parts = startTime.split(':');
    if (parts.length >= 2) {
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour != null && minute != null) {
        return DateTime(date.year, date.month, date.day, hour, minute);
      }
    }
    return base;
  }

  String get formattedDate {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  String get locationLabel => placeName.isEmpty ? '-' : placeName;

  String get statusLabel {
    switch (status) {
      case 'PENDING':
        return 'รอการยืนยัน';
      case 'ACCEPTED':
        return 'ยืนยันแล้ว';
      case 'REJECTED':
        return 'ปฏิเสธ';
      case 'CANCELED':
        return 'ยกเลิก';
      default:
        return status;
    }
  }

  String get medicalHistory {
    final parts = <String>[];
    if (medicalConditions != null && medicalConditions!.trim().isNotEmpty) {
      parts.add('โรคประจำตัว: $medicalConditions');
    }
    if (drugAllergies != null && drugAllergies!.trim().isNotEmpty) {
      parts.add('ประวัติการแพ้ยา: $drugAllergies');
    }
    return parts.isEmpty ? '-' : parts.join('\n');
  }

  String get notes {
    final value = latestDiagnosis?.trim();
    if (value == null || value.isEmpty) {
      return 'ไม่มีบันทึกอาการล่าสุด';
    }
    return value;
  }
}

class DiagnosisEntry {
  final int diagnosisId;
  final String symptom;
  final DateTime recordedAt;

  DiagnosisEntry({
    required this.diagnosisId,
    required this.symptom,
    required this.recordedAt,
  });

  factory DiagnosisEntry.fromJson(Map<String, dynamic> json) {
    return DiagnosisEntry(
      diagnosisId: json['diagnosis_id'] as int,
      symptom: (json['symptom'] as String?)?.trim() ?? '-',
      recordedAt: _parseDateTime(json['recorded_at']),
    );
  }
}

class PrescriptionItem {
  final int prescriptionId;
  final String patientId;
  final int? medicineId;
  final String medicineName;
  final String dosage;
  final int amount;
  final bool isActive;
  final String? doctorComment;
  final String? imageUrl;

  const PrescriptionItem({
    required this.prescriptionId,
    required this.patientId,
    required this.medicineId,
    required this.medicineName,
    required this.dosage,
    required this.amount,
    required this.isActive,
    required this.doctorComment,
    required this.imageUrl,
  });

  factory PrescriptionItem.fromJson(Map<String, dynamic> json) {
    return PrescriptionItem(
      prescriptionId: json['prescription_id'] as int,
      patientId: (json['patient_id'] as String?)?.trim() ?? '',
      medicineId: json['medicine_id'] as int?, // May be absent in current API
      medicineName: (json['medicine_name'] as String?)?.trim() ?? '-',
      dosage: (json['dosage'] as String?)?.trim() ?? '-',
      amount: json['amount'] as int? ?? 0,
      isActive: json['on_going'] as bool? ?? false,
      doctorComment: (json['doctor_comment'] as String?)?.trim(),
      imageUrl: (json['image_url'] as String?)?.trim(),
    );
  }

  PrescriptionItem copyWith({
    bool? isActive,
    String? dosage,
    String? doctorComment,
    int? amount,
    int? medicineId,
    String? medicineName,
    String? imageUrl,
  }) {
    return PrescriptionItem(
      prescriptionId: prescriptionId,
      patientId: patientId,
      medicineId: medicineId ?? this.medicineId,
      medicineName: medicineName ?? this.medicineName,
      dosage: dosage ?? this.dosage,
      amount: amount ?? this.amount,
      isActive: isActive ?? this.isActive,
      doctorComment: doctorComment ?? this.doctorComment,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

class MedicineItem {
  final int medicineId;
  final String medicineName;
  final String? details;
  final String? imageUrl;
  final double? unitPrice;

  const MedicineItem({
    required this.medicineId,
    required this.medicineName,
    this.details,
    this.imageUrl,
    this.unitPrice,
  });

  factory MedicineItem.fromSearchJson(Map<String, dynamic> json) {
    return MedicineItem(
      medicineId: json['medicine_id'] as int,
      medicineName: (json['medicine_name'] as String?)?.trim() ?? '-',
    );
  }

  factory MedicineItem.fromInfoJson(Map<String, dynamic> json) {
    return MedicineItem(
      medicineId: json['medicine_id'] as int,
      medicineName: (json['medicine_name'] as String?)?.trim() ?? '-',
      imageUrl: (json['img_link'] as String?)?.trim(),
    );
  }

  MedicineItem copyWith({
    String? details,
    String? imageUrl,
    double? unitPrice,
  }) {
    return MedicineItem(
      medicineId: medicineId,
      medicineName: medicineName,
      details: details ?? this.details,
      imageUrl: imageUrl ?? this.imageUrl,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }

  @override
  String toString() => medicineName;
}

DateTime _parseDate(dynamic value) {
  if (value is String && value.isNotEmpty) {
    try {
      return DateTime.parse(value).toLocal();
    } catch (_) {
      // Fall through to now.
    }
  }
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

DateTime _parseDateTime(dynamic value) {
  if (value is String && value.isNotEmpty) {
    try {
      return DateTime.parse(value).toLocal();
    } catch (_) {
      // ignore
    }
  }
  return DateTime.now();
}
