import 'package:flutter/material.dart';
import '../api_service.dart';
import '../doctor/models/doctor_models.dart';
import '../models/auth_session.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_button.dart';

class PostponeAppointmentPage extends StatefulWidget {
  final AuthSession session;
  final int appointmentId;
  final String preselectedDoctorName;

  const PostponeAppointmentPage({
    super.key,
    required this.session,
    required this.appointmentId,
    required this.preselectedDoctorName,
  });

  @override
  State<PostponeAppointmentPage> createState() =>
      _PostponeAppointmentPageState();
}

class _PostponeAppointmentPageState extends State<PostponeAppointmentPage> {
  final ApiService _api = ApiService();

  late Future<List<Doctor>> _doctorsFuture;

  Doctor? _selectedDoctor;
  DateTime? _selectedDate;
  DoctorTimeSlot? _selectedSlot;

  @override
  void initState() {
    super.initState();
    _doctorsFuture = _api.getAvailableDoctors().then((list) {
      Doctor? chosen;
      if (list.isNotEmpty) {
        chosen = list.firstWhere(
              (d) => d.name.trim() == widget.preselectedDoctorName.trim(),
          orElse: () => list.first,
        );
      }
      if (mounted) setState(() => _selectedDoctor = chosen);
      return list;
    });
  }


  int _dartDowToApi(int dartWeekday) => dartWeekday;

  List<DateTime> get _availableDates {
    if (_selectedDoctor == null) return [];
    final now = DateTime.now();
    final end = now.add(const Duration(days: 30));
    final days = _selectedDoctor!.timeSlots.map((s) => s.dayOfWeeks).toSet();
    final out = <DateTime>[];
    for (
      var d = DateTime(now.year, now.month, now.day);
      !d.isAfter(end);
      d = d.add(const Duration(days: 1))
    ) {
      if (days.contains(_dartDowToApi(d.weekday))) {
        out.add(DateTime(d.year, d.month, d.day));
      }
    }
    return out;
  }

  List<DoctorTimeSlot> get _availableSlots {
    if (_selectedDoctor == null || _selectedDate == null) return [];
    final dow = _dartDowToApi(_selectedDate!.weekday);
    return _selectedDoctor!.timeSlots
        .where((s) => s.dayOfWeeks == dow)
        .toList();
  }

  Future<void> _submit() async {
    if (_selectedDoctor == null ||
        _selectedDate == null ||
        _selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกวันที่และช่วงเวลาใหม่')),
      );
      return;
    }

    await _api.cancelAppointment(
      session: widget.session,
      appointmentId: widget.appointmentId,
    );

    final ok = await _api.createAppointment(
      session: widget.session,
      date: _selectedDate!,
      doctorId: _selectedDoctor!.id,
      startTime: _selectedSlot!.startTime,
      endTime: _selectedSlot!.endTime,
    );

    if (!ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เลื่อนนัดไม่สำเร็จ กรุณาลองใหม่')),
      );
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'เลื่อนไปเป็น ${_fmtDate(_selectedDate!)} '
          '${_selectedSlot!.startTime}-${_selectedSlot!.endTime}'
          ' (${_selectedSlot!.placeName})',
        ),
      ),
    );
    Navigator.pop(context, 'updated');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'เลื่อนนัดพบแพทย์'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'แพทย์เจ้าของเคส',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),

            FutureBuilder<List<Doctor>>(
              future: _doctorsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Text(
                    'โหลดรายชื่อแพทย์ไม่สำเร็จ',
                    style: TextStyle(color: Colors.red.shade400),
                  );
                }
                final doctors = snapshot.data ?? [];

                return _Dropdown<Doctor>(
                  enabled: false,
                  value: _selectedDoctor,
                  items: doctors,
                  itemLabel: (d) =>
                      '${d.name}${d.department != null ? " (${d.department})" : ""}',
                  onChanged: (_) {},
                  hint: 'เลือกแพทย์',
                );
              },
            ),

            const SizedBox(height: 16),

            Text(
              'เลือกวันที่ต้องการเลื่อน',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            _Dropdown<DateTime>(
              enabled: _selectedDoctor != null,
              value: _selectedDate,
              items: _availableDates,
              itemLabel: _fmtDate,
              onChanged: (d) => setState(() {
                _selectedDate = d;
                _selectedSlot = null;
              }),
              hint: _selectedDoctor == null
                  ? 'กำลังโหลดแพทย์...'
                  : 'เลือกวันที่',
            ),

            const SizedBox(height: 16),

            Text(
              'เลือกเวลาที่ต้องการเลื่อน',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            _Dropdown<DoctorTimeSlot>(
              enabled: _selectedDate != null,
              value: _selectedSlot,
              items: _availableSlots,
              itemLabel: (s) =>
                  '${s.startTime} - ${s.endTime} (${s.placeName})',
              onChanged: (s) => setState(() => _selectedSlot = s),
              hint: _selectedDate == null
                  ? 'กรุณาเลือกวันก่อน'
                  : 'เลือกช่วงเวลา',
            ),

            const SizedBox(height: 20),
            CustomButton(text: 'ยืนยันการเลื่อนนัด', onPressed: _submit),
          ],
        ),
      ),
    );
  }

  static String _fmtDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return 'วันที่ $dd/$mm/$yyyy';
  }
}

class _Dropdown<T> extends StatelessWidget {
  final bool enabled;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;
  final String hint;

  const _Dropdown({
    required this.enabled,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items
          .map((e) => DropdownMenuItem<T>(value: e, child: Text(itemLabel(e))))
          .toList(),
      onChanged: enabled ? onChanged : null,
      decoration: InputDecoration(
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        hintText: hint,
      ),
      icon: const Icon(Icons.keyboard_arrow_down),
    );
  }
}
