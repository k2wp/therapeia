import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:flutter_frontend/api_service.dart';
import 'package:flutter_frontend/models/auth_session.dart';

import 'models/doctor_models.dart';
import 'patient_details_page.dart';

class AppointmentsPageDoctor extends StatefulWidget {
  final AuthSession session;

  const AppointmentsPageDoctor({super.key, required this.session});

  @override
  State<AppointmentsPageDoctor> createState() => _AppointmentsPageDoctorState();
}

class _AppointmentsPageDoctorState extends State<AppointmentsPageDoctor> {
  static final Color _accentColor = Colors.lightGreen[100]!;
  final ApiService _apiService = ApiService();

  late DateTime _focusedDay;
  DateTime? _selectedDay;

  bool _isLoading = true;
  String? _errorMessage;

  Map<DateTime, List<DoctorAppointment>> _appointmentsByDay =
      <DateTime, List<DoctorAppointment>>{};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedDay = DateTime(now.year, now.month, now.day);
    _selectedDay = _focusedDay;
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await _apiService.getDoctorAppointments(widget.session);

      setState(() {
        _appointmentsByDay = _groupByDay(results);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Map<DateTime, List<DoctorAppointment>> _groupByDay(
    List<DoctorAppointment> items,
  ) {
    final grouped = <DateTime, List<DoctorAppointment>>{};
    for (final appointment in items) {
      final key = DateTime(
        appointment.date.year,
        appointment.date.month,
        appointment.date.day,
      );
      grouped.putIfAbsent(key, () => <DoctorAppointment>[]).add(appointment);
    }
    return grouped;
  }

  List<DoctorAppointment> _appointmentsFor(DateTime? day) {
    if (day == null) {
      return <DoctorAppointment>[];
    }
    final key = DateTime(day.year, day.month, day.day);
    return _appointmentsByDay[key] ?? <DoctorAppointment>[];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar', style: TextStyle(color: Colors.black)),
        backgroundColor: _accentColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _isLoading ? null : _loadAppointments,
          ),
        ],
      ),
      body: _buildBody(),
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
                'ไม่สามารถโหลดข้อมูลนัดหมายได้',
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
                onPressed: _loadAppointments,
                child: const Text('ลองอีกครั้ง'),
              ),
            ],
          ),
        ),
      );
    }

    final appointmentsForSelected = _appointmentsFor(_selectedDay);

    return Column(
      children: [
        TableCalendar<DoctorAppointment>(
          firstDay: DateTime.now().subtract(const Duration(days: 365)),
          lastDay: DateTime.now().add(const Duration(days: 365)),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = DateTime(
                selectedDay.year,
                selectedDay.month,
                selectedDay.day,
              );
              _focusedDay = focusedDay;
            });
          },
          onPageChanged: (focusedDay) {
            setState(() {
              _focusedDay = focusedDay;
            });
          },
          eventLoader: (day) => _appointmentsFor(day),
          calendarStyle: CalendarStyle(
            selectedDecoration: const BoxDecoration(
              color: Color(0xFF81C784),
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: _accentColor,
              shape: BoxShape.circle,
            ),
            markerDecoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            leftChevronIcon: Icon(Icons.chevron_left, color: Colors.black),
            rightChevronIcon: Icon(Icons.chevron_right, color: Colors.black),
            titleTextStyle: TextStyle(
              color: Colors.black,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: _buildAppointmentsList(appointmentsForSelected)),
      ],
    );
  }

  Widget _buildAppointmentsList(List<DoctorAppointment> appointments) {
    if (appointments.isEmpty) {
      return const Center(
        child: Text(
          'ไม่มีการนัดหมายในวันที่เลือก',
          style: TextStyle(color: Colors.black54, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        return Card(
          color: const Color(0xFFE8F5E9),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            title: Text(
              appointment.patientName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${appointment.formattedDate}  •  ${appointment.timeRange}',
                  style: const TextStyle(color: Colors.black87, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  appointment.locationLabel,
                  style: const TextStyle(color: Colors.black87, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  appointment.statusLabel,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.black45),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PatientDetailsPage(
                    session: widget.session,
                    appointment: appointment,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
