import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';

class ConsultationRequestPage extends StatefulWidget {
  const ConsultationRequestPage({super.key});

  @override
  State<ConsultationRequestPage> createState() =>
      _ConsultationRequestPageState();
}

class _ConsultationRequestPageState extends State<ConsultationRequestPage> {
  final List<_Appointment> all = [
    _Appointment(
      department: 'Department_1',
      patient: 'Patient Name 1',
      dateTime: DateTime(2024, 9, 15, 9, 0),
      status: AppointmentStatus.confirmed,
    ),
    _Appointment(
      department: 'Department_2',
      patient: 'Patient Name 2',
      dateTime: DateTime(2024, 10, 20, 14, 30),
      status: AppointmentStatus.requested,
    ),
    _Appointment(
      department: 'Department_3',
      patient: 'Patient Name 3',
      dateTime: DateTime(2024, 7, 10, 10, 0),
      status: AppointmentStatus.canceled,
    ),
    _Appointment(
      department: 'Department_4',
      patient: 'Patient Name 4',
      dateTime: DateTime(2024, 8, 5, 11, 15),
      status: AppointmentStatus.requested,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final items = all
        .where((e) => e.status == AppointmentStatus.requested)
        .toList();

    return Scaffold(
      appBar: const CustomAppBar(title: 'คำขอตรวจ'),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, index) {
                  final a = items[index];
                  return _AppointmentRow(appointment: a);
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
  final _Appointment appointment;

  const _AppointmentRow({required this.appointment});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(
                    context,
                  ).style.copyWith(fontSize: 16),
                  children: [
                    const TextSpan(
                      text: 'แผนก: ',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    TextSpan(
                      text: appointment.department,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            _StatusChip(status: appointment.status),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          appointment.patient,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.calendar_month_outlined, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                appointment.dateTime.toLocal().toString().substring(0, 16),
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ),
          ],
        ),
      ],
    );
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
        label = 'Confirmed';
        bg = const Color(0xFFB9F6CA);
        fg = const Color(0xFF1B5E20);
        break;
      case AppointmentStatus.requested:
        label = 'Requested';
        bg = const Color(0xFFFFF9C4);
        fg = const Color(0xFF8D6E63);
        break;
      case AppointmentStatus.canceled:
        label = 'Canceled';
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

class _Appointment {
  final String department;
  final String patient;
  final DateTime dateTime;
  final AppointmentStatus status;

  const _Appointment({
    required this.department,
    required this.patient,
    required this.dateTime,
    required this.status,
  });
}
