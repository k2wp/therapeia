import 'package:flutter/material.dart';

import 'package:flutter_frontend/api_service.dart';
import 'package:flutter_frontend/doctor/models/doctor_models.dart';
import 'package:flutter_frontend/models/auth_session.dart';

import 'dispense_medicine_page.dart';

class MedicalExaminationHistoryPage extends StatefulWidget {
  final AuthSession session;
  final String patientId;
  final String patientName;

  static final Color _accentColor = Colors.lightGreen[100]!;

  const MedicalExaminationHistoryPage({
    super.key,
    required this.session,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<MedicalExaminationHistoryPage> createState() =>
      _MedicalExaminationHistoryPageState();
}

class _MedicalExaminationHistoryPageState
    extends State<MedicalExaminationHistoryPage> {
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  String? _errorMessage;
  List<DiagnosisEntry> _entries = <DiagnosisEntry>[];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _apiService.getPatientDiagnoses(
        widget.session,
        widget.patientId,
      );
      setState(() {
        _entries = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'ประวัติการตรวจรักษา',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: MedicalExaminationHistoryPage._accentColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _isLoading ? null : _loadHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildHistoryList()),
          _buildDispenseButton(context),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'เกิดข้อผิดพลาดในการโหลดประวัติ',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadHistory,
                child: const Text('ลองอีกครั้ง'),
              ),
            ],
          ),
        ),
      );
    }

    if (_entries.isEmpty) {
      return const Center(
        child: Text(
          'ไม่พบประวัติการตรวจรักษา',
          style: TextStyle(color: Colors.black54, fontSize: 16),
        ),
      );
    }

    return Container(
      color: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _entries.length,
        itemBuilder: (context, index) {
          final entry = _entries[index];
          return _buildHistoryEntry(entry);
        },
      ),
    );
  }

  Widget _buildHistoryEntry(DiagnosisEntry entry) {
    final date = entry.recordedAt.toLocal();
    final dateLabel =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: MedicalExaminationHistoryPage._accentColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dateLabel,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              entry.symptom,
              style: const TextStyle(color: Colors.black, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDispenseButton(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DispenseMedicinePage(
                  session: widget.session,
                  patientId: widget.patientId,
                  patientName: widget.patientName,
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: MedicalExaminationHistoryPage._accentColor,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            elevation: 0,
          ),
          child: const Text(
            'จ่ายยา',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}
