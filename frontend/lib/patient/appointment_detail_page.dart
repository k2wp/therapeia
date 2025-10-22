import 'package:flutter/material.dart';
import 'package:flutter_frontend/patient/postpone_appointment_page.dart';
import '../api_service.dart';
import '../widgets/custom_app_bar.dart';
import '../models/auth_session.dart';

class AppointmentDetailPage extends StatefulWidget {
  final AuthSession session;
  final AppointmentOverview overview;

  const AppointmentDetailPage({
    super.key,
    required this.session,
    required this.overview,
  });

  @override
  State<AppointmentDetailPage> createState() => _AppointmentDetailPageState();
}

class _AppointmentDetailPageState extends State<AppointmentDetailPage> {
  final _api = ApiService();
  bool _busy = false;

  AppointmentStatus get _status => _mapStatus(widget.overview.status);

  bool get _isPast => _isAppointmentPast(widget.overview);

  @override
  Widget build(BuildContext context) {
    final a = widget.overview;
    final dateLabel = '${a.date} • ${a.startTime} - ${a.endTime}';

    final actionsDisabled = _status == AppointmentStatus.canceled || _isPast;

    return Scaffold(
      appBar: const CustomAppBar(title: 'รายละเอียดการนัดหมาย'),
      body: AbsorbPointer(
        absorbing: _busy,
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                Card(
                  elevation: 0,
                  color: Colors.lightGreen[50],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                                    a.doctorName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    a.department ?? '-',
                                    style: const TextStyle(
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _StatusChip(status: _status),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.calendar_month_outlined, size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text(dateLabel)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                a.placeName.isEmpty ? '-' : a.placeName,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.tag_outlined, size: 18),
                            const SizedBox(width: 8),
                            Text('หมายเลขนัด: ${a.appointmentId}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                if (actionsDisabled) ...[
                  const SizedBox(height: 12),
                  _InfoBanner(
                    text: _status == AppointmentStatus.canceled
                        ? 'การนัดนี้ถูกยกเลิกแล้ว ไม่สามารถเลื่อน/ยกเลิกได้'
                        : 'การนัดนี้สิ้นสุดไปแล้ว ไม่สามารถเลื่อน/ยกเลิกได้',
                  ),
                ],

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: actionsDisabled ? null : () async {
                          final changed = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              fullscreenDialog: true,
                              builder: (_) => PostponeAppointmentPage(
                                session: widget.session,
                                appointmentId: a.appointmentId,
                                preselectedDoctorName: a.doctorName,
                              ),
                            ),
                          );

                          if (changed == 'updated' && mounted) {
                            Navigator.pop(context, 'updated');
                          }
                        },
                        icon: const Icon(Icons.edit_calendar_outlined),
                        label: const Text('เลื่อนนัด'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                        ),
                        onPressed: actionsDisabled
                            ? null
                            : () => _cancel(context),
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('ยกเลิก'),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            if (_busy)
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0x66FFFFFF),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _cancel(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ยกเลิกการนัด'),
        content: const Text('คุณต้องการยกเลิกการนัดครั้งนี้ใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ไม่ใช่'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _busy = true);

    try {
      final canceled = await _api.cancelAppointment(
        session: widget.session,
        appointmentId: widget.overview.appointmentId,
      );
      if (!mounted) return;
      if (canceled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ยกเลิกการนัดเรียบร้อยแล้ว')),
        );
        Navigator.pop(context, 'updated');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่สามารถยกเลิกการนัดได้')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  AppointmentStatus _mapStatus(String v) {
    switch (v.toUpperCase()) {
      case 'PENDING':
        return AppointmentStatus.requested;
      case 'ACCEPTED':
        return AppointmentStatus.confirmed;
      default:
        return AppointmentStatus.canceled;
    }
  }

  bool _isAppointmentPast(AppointmentOverview a) {
    DateTime? date;
    try {
      date = DateTime.parse(a.date);
    } catch (_) {
      final parts = a.date.split('/');
      if (parts.length == 3) {
        final d = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final y = int.tryParse(parts[2]);
        if (d != null && m != null && y != null) {
          date = DateTime(y, m, d);
        }
      }
    }
    if (date == null) return false;

    final endParts = a.endTime.split(':');
    final hh = int.tryParse(endParts[0]);
    final mm = endParts.length > 1 ? int.tryParse(endParts[1]) : 0;
    final end = DateTime(date.year, date.month, date.day, hh ?? 0, mm ?? 0);

    return DateTime.now().isAfter(end);
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

class _InfoBanner extends StatelessWidget {
  final String text;

  const _InfoBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: Colors.black54),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
