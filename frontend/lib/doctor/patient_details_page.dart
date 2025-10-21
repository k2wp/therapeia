import 'package:flutter/material.dart';
import 'package:flutter_frontend/api_service.dart';
import 'package:flutter_frontend/doctor/models/doctor_models.dart';
import 'package:flutter_frontend/models/auth_session.dart';

import 'dispense_medicine_page.dart';
import 'medical_examination_history_page.dart';

class PatientDetailsPage extends StatelessWidget {
  final AuthSession session;
  final DoctorAppointment appointment;

  static final Color _accentColor = Colors.lightGreen[100]!;

  const PatientDetailsPage({
    super.key,
    required this.session,
    required this.appointment,
  });

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('ผู้ป่วย', style: TextStyle(color: Colors.black)),
        backgroundColor: _accentColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () => Navigator.pushReplacement(
              context,
              PageRouteBuilder<void>(
                pageBuilder: (_, __, ___) => PatientDetailsPage(
                  session: session,
                  appointment: appointment,
                ),
                transitionDuration: Duration.zero,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<PatientOverview?>(
              future: apiService.getPatientOverview(
                session,
                appointment.patientId,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final overview = snapshot.data;
                final error = snapshot.error;

                if (error != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'ไม่สามารถโหลดข้อมูลผู้ป่วยได้',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            error.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoCard(overview),
                      const SizedBox(height: 16),
                      _buildNotesCard(overview),
                    ],
                  ),
                );
              },
            ),
          ),
          _buildBottomButtons(context),
        ],
      ),
    );
  }

  Widget _buildInfoCard(PatientOverview? overview) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('ชื่อผู้ป่วย', appointment.patientName),
            _buildInfoRow('อายุ', _formatAge(overview?.age)),
            _buildInfoRow('ส่วนสูง', _formatNumber(overview?.heightCm, 'cm')),
            _buildInfoRow('น้ำหนัก', _formatNumber(overview?.weightKg, 'kg')),
            _buildInfoRow('สถานะ', appointment.statusLabel),
            if (overview?.updatedAt != null) ...[
              const SizedBox(height: 12),
              Text(
                'อัปเดตล่าสุด: ${_formatUpdatedAt(overview!.updatedAt!)}',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard(PatientOverview? overview) {
    return Card(
      elevation: 2,
      color: const Color(0xFFE8F5E9),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ข้อมูลด้านสุขภาพ',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            _buildNotesRow(
              title: 'โรคประจำตัว',
              value: overview?.medicalConditions,
            ),
            const SizedBox(height: 8),
            _buildNotesRow(
              title: 'ประวัติการแพ้ยา',
              value: overview?.drugAllergies,
            ),
            const SizedBox(height: 8),
            _buildNotesRow(
              title: 'หมายเหตุล่าสุด',
              value: appointment.latestDiagnosis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesRow({required String title, String? value}) {
    final text = value?.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(text == null || text.isEmpty ? '-' : text),
      ],
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DispenseMedicinePage(
                      session: session,
                      patientId: appointment.patientId,
                      patientName: appointment.patientName,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('สั่งยา'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MedicalExaminationHistoryPage(
                      session: session,
                      patientId: appointment.patientId,
                      patientName: appointment.patientName,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('ประวัติการตรวจ'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAge(int? age) {
    if (age == null || age <= 0) {
      return '-';
    }
    return '$age ปี';
  }

  String _formatNumber(double? value, String unit) {
    if (value == null || value <= 0) {
      return '-';
    }
    return '${value.toStringAsFixed(1)} $unit';
  }

  String _formatUpdatedAt(DateTime value) {
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year} ${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}
