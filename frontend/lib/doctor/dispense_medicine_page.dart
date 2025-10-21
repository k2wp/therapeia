import 'package:flutter/material.dart';

import 'package:flutter_frontend/api_service.dart';
import 'package:flutter_frontend/doctor/models/doctor_models.dart';
import 'package:flutter_frontend/models/auth_session.dart';

import 'add_edit_medicine_page.dart';

class DispenseMedicinePage extends StatefulWidget {
  final AuthSession session;
  final String patientId;
  final String patientName;

  static final Color accentColor = Colors.lightGreen[100]!;

  const DispenseMedicinePage({
    super.key,
    required this.session,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<DispenseMedicinePage> createState() => _DispenseMedicinePageState();
}

class _DispenseMedicinePageState extends State<DispenseMedicinePage> {
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  bool _isProcessing = false;
  String? _errorMessage;

  List<PrescriptionItem> _activePrescriptions = <PrescriptionItem>[];
  List<PrescriptionItem> _inactivePrescriptions = <PrescriptionItem>[];

  @override
  void initState() {
    super.initState();
    _loadPrescriptions();
  }

  Future<void> _loadPrescriptions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _apiService.getPatientPrescriptions(
        widget.session,
        widget.patientId,
      );
      setState(() {
        _splitPrescriptions(items);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _splitPrescriptions(List<PrescriptionItem> items) {
    final active = <PrescriptionItem>[];
    final inactive = <PrescriptionItem>[];
    for (final item in items) {
      if (item.isActive) {
        active.add(item);
      } else {
        inactive.add(item);
      }
    }
    active.sort((a, b) => a.medicineName.compareTo(b.medicineName));
    inactive.sort((a, b) => a.medicineName.compareTo(b.medicineName));
    _activePrescriptions = active;
    _inactivePrescriptions = inactive;
  }

  Future<void> _togglePrescription(PrescriptionItem item) async {
    setState(() {
      _isProcessing = true;
    });

    final medicineId = item.medicineId;
    if (medicineId == null) {
      setState(() {
        _isProcessing = false;
      });
      _showSnackBar('ไม่สามารถอัปเดตรายการนี้ได้ (ไม่ทราบรหัสยา)');
      return;
    }

    try {
      final updated = await _apiService.updatePrescription(
        session: widget.session,
        prescriptionId: item.prescriptionId,
        patientId: item.patientId,
        medicineId: medicineId,
        dosage: item.dosage,
        amount: item.amount,
        onGoing: !item.isActive,
        doctorComment: item.doctorComment,
      );
      setState(() {
        _replacePrescription(updated);
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showSnackBar('ไม่สามารถอัปเดตรายการยาได้: $e');
    }
  }

  Future<void> _deletePrescription(PrescriptionItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบยา'),
        content: Text('คุณต้องการลบยา "${item.medicineName}" หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      await _apiService.deletePrescription(
        session: widget.session,
        prescriptionId: item.prescriptionId,
      );
      setState(() {
        _activePrescriptions.removeWhere(
          (entry) => entry.prescriptionId == item.prescriptionId,
        );
        _inactivePrescriptions.removeWhere(
          (entry) => entry.prescriptionId == item.prescriptionId,
        );
        _isProcessing = false;
      });
      _showSnackBar('ลบรายการยาเรียบร้อย');
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showSnackBar('ไม่สามารถลบรายการยาได้: $e');
    }
  }

  void _replacePrescription(PrescriptionItem updated) {
    _activePrescriptions.removeWhere(
      (entry) => entry.prescriptionId == updated.prescriptionId,
    );
    _inactivePrescriptions.removeWhere(
      (entry) => entry.prescriptionId == updated.prescriptionId,
    );

    if (updated.isActive) {
      _activePrescriptions.add(updated);
      _activePrescriptions.sort(
        (a, b) => a.medicineName.compareTo(b.medicineName),
      );
    } else {
      _inactivePrescriptions.add(updated);
      _inactivePrescriptions.sort(
        (a, b) => a.medicineName.compareTo(b.medicineName),
      );
    }
  }

  Future<void> _openAddOrEdit({PrescriptionItem? item}) async {
    final result = await Navigator.push<PrescriptionItem>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditMedicinePage(
          session: widget.session,
          patientId: widget.patientId,
          patientName: widget.patientName,
          prescription: item,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _replacePrescription(result);
      });
      _showSnackBar(item == null ? 'เพิ่มยาสำเร็จ' : 'แก้ไขยาสำเร็จ');
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
        title: const Text('การจ่ายยา', style: TextStyle(color: Colors.black)),
        backgroundColor: DispenseMedicinePage.accentColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _isLoading ? null : _loadPrescriptions,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildBody()),
          _buildBottomButtons(),
        ],
      ),
    );
  }

  Widget _buildBody() {
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
                'ไม่สามารถโหลดรายการยาได้',
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
                onPressed: _loadPrescriptions,
                child: const Text('ลองอีกครั้ง'),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDrugSection('ยาที่จ่าย', _activePrescriptions, true),
            const SizedBox(height: 24),
            _buildDrugSection('ยาที่หยุดจ่าย', _inactivePrescriptions, false),
          ],
        ),
      ),
    );
  }

  Widget _buildDrugSection(
    String title,
    List<PrescriptionItem> items,
    bool isActiveSection,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'ไม่มีรายการยา',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          )
        else
          ...items.map((item) => _buildDrugCard(item, isActiveSection)),
      ],
    );
  }

  Widget _buildDrugCard(PrescriptionItem item, bool isActiveSection) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: item.imageUrl != null
                    ? Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.medication,
                          color: Colors.grey.shade400,
                          size: 30,
                        ),
                      )
                    : Icon(
                        Icons.medication,
                        color: Colors.grey.shade400,
                        size: 30,
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.medicineName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.dosage,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  if (item.doctorComment != null &&
                      item.doctorComment!.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        item.doctorComment!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.black),
              onPressed: _isProcessing
                  ? null
                  : () => _showDrugOptions(item, isActiveSection),
            ),
          ],
        ),
      ),
    );
  }

  void _showDrugOptions(PrescriptionItem item, bool isActiveSection) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                item.medicineName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildOptionButton(
                isActiveSection ? 'หยุดจ่ายยา' : 'กลับไปจ่ายยาใหม่',
                () {
                  Navigator.pop(context);
                  _togglePrescription(item);
                },
              ),
              const SizedBox(height: 12),
              _buildOptionButton('แก้ไข', () {
                Navigator.pop(context);
                _openAddOrEdit(item: item);
              }),
              const SizedBox(height: 12),
              _buildOptionButton('ลบ', () {
                Navigator.pop(context);
                _deletePrescription(item);
              }),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.shade200,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _isProcessing ? null : () => _openAddOrEdit(),
              style: ElevatedButton.styleFrom(
                backgroundColor: DispenseMedicinePage.accentColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'เพิ่มยา',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isProcessing
                  ? null
                  : () {
                      Navigator.pop(context);
                      _showSnackBar('บันทึกข้อมูลเรียบร้อย');
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: DispenseMedicinePage.accentColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'ตกลง',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
