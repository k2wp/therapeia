import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';
import '../api_service.dart';
import 'package:flutter_frontend/models/auth_session.dart';

class AppointmentsPagePatient extends StatefulWidget {
  final AuthSession session;

  const AppointmentsPagePatient({super.key, required this.session});

  @override
  State<AppointmentsPagePatient> createState() =>
      _AppointmentsPagePatientState();
}

class _AppointmentsPagePatientState extends State<AppointmentsPagePatient> {
  bool showUpcoming = true;
  final ApiService _apiService = ApiService();
  late Future<PatientAppointments> _appointmentsFuture;

  @override
  void initState() {
    super.initState();
    _appointmentsFuture = _apiService.getPatientAppointments(widget.session);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'รายการนัด'),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SegmentedSwitch(
              leftLabel: 'Upcoming',
              rightLabel: 'Past/Canceled',
              valueLeft: showUpcoming,
              onChanged: (leftSelected) {
                setState(() => showUpcoming = leftSelected);
              },
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<PatientAppointments>(
                future: _appointmentsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final data = snapshot.data;
                  if (data == null) {
                    return const Center(child: Text('ไม่พบข้อมูลการนัดหมาย'));
                  }

                  final items = showUpcoming ? data.upcoming : data.history;
                  if (items.isEmpty) {
                    return const Center(
                      child: Text('ยังไม่มีรายการนัดหมายในช่วงนี้'),
                    );
                  }

                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, index) {
                      final appointment = items[index];
                      return _AppointmentRow(appointment: appointment);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentRow extends StatelessWidget {
  final AppointmentOverview appointment;

  const _AppointmentRow({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final status = _mapStatus(appointment.status);
    final dateLabel =
        '${appointment.date} • ${appointment.startTime} - ${appointment.endTime}';

    return Card(
      elevation: 0,
      color: Colors.lightGreen[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.doctorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        appointment.department ?? '-',
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ],
                  ),
                ),
                _StatusChip(status: status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.calendar_month_outlined, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dateLabel,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.location_on_outlined, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    appointment.placeName.isEmpty ? '-' : appointment.placeName,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  AppointmentStatus _mapStatus(String value) {
    switch (value.toUpperCase()) {
      case 'PENDING':
        return AppointmentStatus.requested;
      case 'ACCEPTED':
        return AppointmentStatus.confirmed;
      default:
        return AppointmentStatus.canceled;
    }
  }
}

enum AppointmentStatus { confirmed, requested, canceled }

class _StatusChip extends StatelessWidget {
  final AppointmentStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color bg;
    late final Color fg;

    switch (status) {
      case AppointmentStatus.confirmed:
        label = 'ยืนยันแล้ว';
        bg = const Color(0xFFB9F6CA);
        fg = const Color(0xFF1B5E20);
        break;
      case AppointmentStatus.requested:
        label = 'รอการยืนยัน';
        bg = const Color(0xFFFFF9C4);
        fg = const Color(0xFF8D6E63);
        break;
      case AppointmentStatus.canceled:
        label = 'ยกเลิก/ไม่สำเร็จ';
        bg = const Color(0xFFFFCDD2);
        fg = const Color(0xFFB71C1C);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

class _SegmentedSwitch extends StatelessWidget {
  final String leftLabel;
  final String rightLabel;
  final bool valueLeft;
  final ValueChanged<bool> onChanged;

  const _SegmentedSwitch({
    required this.leftLabel,
    required this.rightLabel,
    required this.valueLeft,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black26),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => onChanged(true),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: valueLeft
                      ? Colors.greenAccent.shade100
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (valueLeft) ...[
                      const Icon(Icons.check_circle, size: 16),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      ' $leftLabel ',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => onChanged(false),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: valueLeft
                      ? Colors.transparent
                      : Colors.redAccent.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!valueLeft) ...[
                      const Icon(Icons.cancel, size: 16),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      ' $rightLabel ',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
