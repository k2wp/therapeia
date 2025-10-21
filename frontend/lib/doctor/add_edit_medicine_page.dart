import 'package:flutter/material.dart';

import 'package:flutter_frontend/api_service.dart';
import 'package:flutter_frontend/doctor/models/doctor_models.dart';
import 'package:flutter_frontend/models/auth_session.dart';

class AddEditMedicinePage extends StatefulWidget {
  final AuthSession session;
  final String patientId;
  final String patientName;
  final PrescriptionItem? prescription;

  static final Color accentColor = Colors.lightGreen[100]!;

  const AddEditMedicinePage({
    super.key,
    required this.session,
    required this.patientId,
    required this.patientName,
    this.prescription,
  });

  @override
  State<AddEditMedicinePage> createState() => _AddEditMedicinePageState();
}

class _AddEditMedicinePageState extends State<AddEditMedicinePage> {
  final ApiService _apiService = ApiService();

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();

  bool _isDispensing = true;
  bool _isSaving = false;
  bool _isLoadingMedicines = true;
  String? _medicinesError;

  List<MedicineItem> _medicines = <MedicineItem>[];
  List<MedicineItem> _filteredMedicines = <MedicineItem>[];
  MedicineItem? _selectedMedicine;

  @override
  void initState() {
    super.initState();
    if (widget.prescription != null) {
      final prescription = widget.prescription!;
      _dosageController.text = prescription.dosage;
      _amountController.text = prescription.amount.toString();
      _commentController.text = prescription.doctorComment ?? '';
      _isDispensing = prescription.isActive;
    }
    _loadMedicines();
  }

  Future<void> _loadMedicines([String keyword = '']) async {
    setState(() {
      _isLoadingMedicines = true;
      _medicinesError = null;
    });

    try {
      final medicines = await _apiService.searchMedicines(
        widget.session,
        keyword: keyword,
      );

      MedicineItem? selected = _selectedMedicine;
      final prescription = widget.prescription;

      if (prescription != null && prescription.medicineId != null) {
        selected = _findMedicineById(medicines, prescription.medicineId!);
        if (selected == null) {
          final info = await _apiService.getMedicineInfo(
            widget.session,
            prescription.medicineId!,
          );
          if (info != null) {
            medicines.insert(0, info);
            selected = info;
          }
        }
      }

      selected ??= medicines.isNotEmpty ? medicines.first : null;

      setState(() {
        _medicines = medicines;
        _filteredMedicines = medicines;
        _selectedMedicine = selected;
        _isLoadingMedicines = false;
      });
    } catch (e) {
      setState(() {
        _medicinesError = e.toString();
        _isLoadingMedicines = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _dosageController.dispose();
    _amountController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  MedicineItem? _findMedicineById(List<MedicineItem> items, int id) {
    for (final item in items) {
      if (item.medicineId == id) {
        return item;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditMode = widget.prescription != null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('การจ่ายยา', style: TextStyle(color: Colors.black)),
        backgroundColor: AddEditMedicinePage.accentColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _isLoadingMedicines ? null : _loadMedicines,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.white,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMedicineSelector(),
                    const SizedBox(height: 20),
                    _buildMedicineInfo(),
                    const SizedBox(height: 20),
                    _buildDosageSection(),
                    const SizedBox(height: 20),
                    _buildStatusCheckbox(),
                  ],
                ),
              ),
            ),
          ),
          _buildBottomButton(isEditMode),
        ],
      ),
    );
  }

  Widget _buildMedicineSelector() {
    if (_isLoadingMedicines) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_medicinesError != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ไม่สามารถโหลดรายการยาได้',
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _medicinesError!,
              style: TextStyle(color: Colors.red.shade700),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadMedicines,
              child: const Text('ลองอีกครั้ง'),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'ค้นหายา',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              suffixIcon: Icon(Icons.search, color: Colors.grey),
            ),
            onChanged: (value) => _loadMedicines(value),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: DropdownMenu<MedicineItem>(
              initialSelection: _selectedMedicine,
              dropdownMenuEntries: _filteredMedicines
                  .map(
                    (medicine) => DropdownMenuEntry<MedicineItem>(
                      value: medicine,
                      label: medicine.medicineName,
                    ),
                  )
                  .toList(),
              hintText: 'เลือกยา',
              onSelected: (value) {
                setState(() {
                  _selectedMedicine = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineInfo() {
    final selected = _selectedMedicine;
    final imageUrl = selected?.imageUrl;

    return Container(
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                    child: imageUrl != null
                        ? Image.network(
                            imageUrl,
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
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    selected?.medicineName ?? '- เลือกยา -',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            if (selected?.details != null && selected!.details!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  selected.details!,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDosageSection() {
    return Container(
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'รายละเอียดการใช้ยา',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _dosageController,
              decoration: const InputDecoration(
                labelText: 'วิธีการทานยา',
                hintText: 'เช่น ทานครั้งละ 1 เม็ด วันละ 3 ครั้ง หลังอาหาร',
                border: OutlineInputBorder(),
              ),
              maxLines: null,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'จำนวนที่จ่าย (ชุดหรือเม็ด)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'หมายเหตุสำหรับคนไข้',
                border: OutlineInputBorder(),
              ),
              maxLines: null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCheckbox() {
    return Container(
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
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Checkbox(
              value: _isDispensing,
              onChanged: (value) {
                setState(() {
                  _isDispensing = value ?? true;
                });
              },
              activeColor: AddEditMedicinePage.accentColor,
            ),
            const SizedBox(width: 8),
            const Text(
              'ยังจ่ายยาอยู่',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton(bool isEditMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: ElevatedButton(
        onPressed: _isSaving ? null : () => _handleSave(isEditMode),
        style: ElevatedButton.styleFrom(
          backgroundColor: AddEditMedicinePage.accentColor,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                isEditMode ? 'แก้ไข' : 'เพิ่มยา',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
      ),
    );
  }

  Future<void> _handleSave(bool isEditMode) async {
    final selectedMedicine = _selectedMedicine;

    if (selectedMedicine == null) {
      _showSnackBar('กรุณาเลือกยา');
      return;
    }

    if (_dosageController.text.trim().isEmpty) {
      _showSnackBar('กรุณากรอกรายละเอียดการทานยา');
      return;
    }

    final amount = int.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      _showSnackBar('กรุณากรอกจำนวนที่จ่ายให้ถูกต้อง');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final prescription = isEditMode
          ? await _apiService.updatePrescription(
              session: widget.session,
              prescriptionId: widget.prescription!.prescriptionId,
              patientId: widget.prescription!.patientId,
              medicineId: selectedMedicine.medicineId,
              dosage: _dosageController.text.trim(),
              amount: amount,
              onGoing: _isDispensing,
              doctorComment: _commentController.text.trim().isEmpty
                  ? null
                  : _commentController.text.trim(),
            )
          : await _apiService.createPrescription(
              session: widget.session,
              patientId: widget.patientId,
              medicineId: selectedMedicine.medicineId,
              dosage: _dosageController.text.trim(),
              amount: amount,
              onGoing: _isDispensing,
              doctorComment: _commentController.text.trim().isEmpty
                  ? null
                  : _commentController.text.trim(),
            );

      if (!mounted) {
        return;
      }

      Navigator.pop(context, prescription);
    } catch (e) {
      _showSnackBar('ไม่สามารถบันทึกข้อมูลได้: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
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
