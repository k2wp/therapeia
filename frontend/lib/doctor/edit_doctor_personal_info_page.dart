import 'package:flutter/material.dart';
import 'models/schedule.dart';

class EditDoctorPersonalInfoPage extends StatefulWidget {
  final String doctorName;
  final String department;
  final String position;
  final String email;
  final String phone;
  final List<ScheduleEntry> scheduleEntries;

  const EditDoctorPersonalInfoPage({
    Key? key,
    required this.doctorName,
    required this.department,
    required this.position,
    required this.email,
    required this.phone,
    required this.scheduleEntries,
  }) : super(key: key);

  @override
  State<EditDoctorPersonalInfoPage> createState() =>
      _EditDoctorPersonalInfoPageState();
}

class _EditDoctorPersonalInfoPageState
    extends State<EditDoctorPersonalInfoPage> {
  static final Color _accentColor = Colors.lightGreen[100]!;
  late TextEditingController _nameController;
  late TextEditingController _departmentController;
  late TextEditingController _positionController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  List<ScheduleEntry> _scheduleEntries = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.doctorName);
    _departmentController = TextEditingController(text: widget.department);
    _positionController = TextEditingController(text: widget.position);
    _emailController = TextEditingController(text: widget.email);
    _phoneController = TextEditingController(text: widget.phone);

    // Deep copy the schedule entries
    _scheduleEntries = widget.scheduleEntries
        .map(
          (entry) => entry.copyWith(
            timeSlots: entry.timeSlots.map((slot) => slot.copyWith()).toList(),
          ),
        )
        .toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _departmentController.dispose();
    _positionController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
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
          'แก้ไขข้อมูลส่วนตัว',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: _accentColor,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.black)),
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
                    _buildPersonalInfoSection(),
                    const SizedBox(height: 24),
                    _buildScheduleSection(),
                  ],
                ),
              ),
            ),
          ),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _accentColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ข้อมูลส่วนตัว',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField('ชื่อ-นามสกุล', _nameController),
            const SizedBox(height: 12),
            _buildTextField('แผนก', _departmentController),
            const SizedBox(height: 12),
            _buildTextField('ตำแหน่ง', _positionController),
            const SizedBox(height: 12),
            _buildTextField('อีเมล', _emailController),
            const SizedBox(height: 12),
            _buildTextField('เบอร์โทรศัพท์', _phoneController),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: _accentColor, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            fillColor: Colors.white,
            filled: true,
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'ตารางงาน',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            TextButton.icon(
              onPressed: _addNewTimeSlot,
              icon: const Icon(Icons.add, color: Colors.black),
              label: const Text(
                'เพิ่มเวลา',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._scheduleEntries.map((entry) => _buildEditableDaySchedule(entry)),
      ],
    );
  }

  Widget _buildEditableDaySchedule(ScheduleEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                entry.day,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...entry.timeSlots.map((slot) => _buildEditableTimeSlot(slot)),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableTimeSlot(TimeSlot slot) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _accentColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.time,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  slot.location,
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.black, size: 20),
            onPressed: () => _editTimeSlot(slot),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
            onPressed: () => _deleteTimeSlot(slot),
          ),
        ],
      ),
    );
  }

  void _addNewTimeSlot() {
    showDialog(
      context: context,
      builder: (context) => _TimeSlotDialog(
        onSave: (day, time, location) {
          setState(() {
            var dayEntry = _scheduleEntries.firstWhere(
              (entry) => entry.day == day,
              orElse: () {
                var newEntry = ScheduleEntry(day: day, timeSlots: []);
                _scheduleEntries.add(newEntry);
                // Sort entries by day of week
                _scheduleEntries.sort((a, b) {
                  final daysOrder = [
                    'วันจันทร์',
                    'วันอังคาร',
                    'วันพุธ',
                    'วันพฤหัสบดี',
                    'วันศุกร์',
                    'วันเสาร์',
                    'วันอาทิตย์',
                  ];
                  return daysOrder
                      .indexOf(a.day)
                      .compareTo(daysOrder.indexOf(b.day));
                });
                return newEntry;
              },
            );
            dayEntry.timeSlots.add(TimeSlot(time: time, location: location));
            // Sort time slots by time
            dayEntry.timeSlots.sort((a, b) => a.time.compareTo(b.time));
          });
        },
      ),
    );
  }

  void _editTimeSlot(TimeSlot slot) {
    showDialog(
      context: context,
      builder: (context) => _TimeSlotDialog(
        initialTime: slot.time,
        initialLocation: slot.location,
        initialDay: _scheduleEntries
            .firstWhere((entry) => entry.timeSlots.contains(slot))
            .day,
        onSave: (day, time, location) {
          setState(() {
            final index = _scheduleEntries
                .expand((e) => e.timeSlots)
                .toList()
                .indexOf(slot);
            if (index != -1) {
              final newSlot = slot.copyWith(time: time, location: location);
              for (var entry in _scheduleEntries) {
                final slotIndex = entry.timeSlots.indexOf(slot);
                if (slotIndex != -1) {
                  entry.timeSlots[slotIndex] = newSlot;
                  break;
                }
              }
            }
          });
        },
      ),
    );
  }

  void _deleteTimeSlot(TimeSlot slot) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบตารางงาน'),
        content: Text('คุณต้องการลบเวลา "${slot.time}" หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                for (var entry in _scheduleEntries) {
                  entry.timeSlots.removeWhere((s) => s.time == slot.time);
                }
                _scheduleEntries.removeWhere(
                  (entry) => entry.timeSlots.isEmpty,
                );
              });
            },
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: _saveChanges,
        style: ElevatedButton.styleFrom(
          backgroundColor: _accentColor,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text(
          'บันทึก',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  void _saveChanges() {
    // Validate inputs
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('กรุณากรอกชื่อ-นามสกุล')));
      return;
    }

    // Return the updated data
    Navigator.pop(context, {
      'doctorName': _nameController.text.trim(),
      'department': _departmentController.text.trim(),
      'position': _positionController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'scheduleEntries': _scheduleEntries,
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('บันทึกข้อมูลเรียบร้อย')));
  }
}

class _TimeSlotDialog extends StatefulWidget {
  final String? initialTime;
  final String? initialLocation;
  final String? initialDay;
  final Function(String day, String time, String location) onSave;

  const _TimeSlotDialog({
    Key? key,
    this.initialTime,
    this.initialLocation,
    this.initialDay,
    required this.onSave,
  }) : super(key: key);

  @override
  State<_TimeSlotDialog> createState() => _TimeSlotDialogState();
}

class _TimeSlotDialogState extends State<_TimeSlotDialog> {
  late TextEditingController _locationController;
  late String _selectedDay;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final List<String> _days = [
    'วันจันทร์',
    'วันอังคาร',
    'วันพุธ',
    'วันพฤหัสบดี',
    'วันศุกร์',
    'วันเสาร์',
    'วันอาทิตย์',
  ];

  @override
  void initState() {
    super.initState();
    _locationController = TextEditingController(
      text: widget.initialLocation ?? '',
    );
    _selectedDay = widget.initialDay ?? 'วันจันทร์';

    if (widget.initialTime != null) {
      final parts = widget.initialTime!.split('-');
      if (parts.length == 2) {
        _startTime = _parseTime(parts.first);
        _endTime = _parseTime(parts.last);
      }
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('เพิ่ม/แก้ไขเวลา'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: _selectedDay,
            decoration: const InputDecoration(
              labelText: 'วัน',
              border: OutlineInputBorder(),
            ),
            items: _days.map((String day) {
              return DropdownMenuItem<String>(value: day, child: Text(day));
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedDay = newValue;
                });
              }
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _TimePickerButton(
                  label: 'เวลาเริ่ม',
                  time: _startTime,
                  onPressed: () async {
                    final picked = await _pickTime(initial: _startTime);
                    if (picked != null) {
                      setState(() => _startTime = picked);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TimePickerButton(
                  label: 'เวลาสิ้นสุด',
                  time: _endTime,
                  onPressed: () async {
                    final picked = await _pickTime(initial: _endTime);
                    if (picked != null) {
                      setState(() => _endTime = picked);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _locationController,
            decoration: const InputDecoration(
              labelText: 'สถานที่',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ยกเลิก'),
        ),
        TextButton(
          onPressed: () {
            final location = _locationController.text.trim();
            if (_startTime == null || _endTime == null || location.isEmpty) {
              _showValidationMessage('กรุณาเลือกเวลาและสถานที่');
              return;
            }

            final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
            final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
            if (endMinutes <= startMinutes) {
              _showValidationMessage('เวลาเสร็จต้องมากกว่าเวลาเริ่ม');
              return;
            }

            final timeLabel =
                '${_formatTimeOfDay(_startTime!)} - ${_formatTimeOfDay(_endTime!)}';

            widget.onSave(_selectedDay, timeLabel, location);
            Navigator.pop(context);
          },
          child: const Text('บันทึก'),
        ),
      ],
    );
  }

  Future<TimeOfDay?> _pickTime({TimeOfDay? initial}) {
    final initialTime = initial ?? TimeOfDay.now();
    return showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }

  TimeOfDay? _parseTime(String value) {
    final cleaned = value.trim().replaceAll('.', ':');
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(cleaned);
    if (match == null) {
      return null;
    }
    final hour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2)!);
    if (hour == null || minute == null) {
      return null;
    }
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return null;
    }
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _showValidationMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _TimePickerButton extends StatelessWidget {
  final String label;
  final TimeOfDay? time;
  final VoidCallback onPressed;

  const _TimePickerButton({
    required this.label,
    required this.time,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final display = time != null
        ? '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}'
        : 'เลือก';

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 6),
          Text(
            display,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

// Models moved to models/schedule.dart
