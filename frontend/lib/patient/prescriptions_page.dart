import 'package:flutter/material.dart';
import '../doctor/models/doctor_models.dart';
import '../widgets/custom_app_bar.dart';
import '../api_service.dart';
import '../models/auth_session.dart';

class PrescriptionsPage extends StatefulWidget {
  final AuthSession session;

  const PrescriptionsPage({
    super.key,
    required this.session,
  });

  @override
  State<PrescriptionsPage> createState() =>
      _PrescriptionsPageState();
}

class _PrescriptionsPageState extends State<PrescriptionsPage> {
  final _api = ApiService();
  late Future<List<PrescriptionItem>> _rxFuture;
  bool _showActive = true;

  @override
  void initState() {
    super.initState();
    _rxFuture = _api.getPrescriptions(widget.session);
  }

  Future<void> _refresh() async {
    setState(() {
      _rxFuture = _api.getPrescriptions(widget.session);
    });
    await _rxFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'ใบสั่งยา'),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Column(
          children: [
            _SegmentedSwitch(
              leftLabel: 'กำลังใช้',
              rightLabel: 'หยุดแล้ว',
              valueLeft: _showActive,
              onChanged: (left) => setState(() => _showActive = left),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: FutureBuilder<List<PrescriptionItem>>(
                future: _rxFuture,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return _ErrorBox(
                      message: 'โหลดรายการยาล้มเหลว',
                      onRetry: _refresh,
                    );
                  }

                  final all = snap.data ?? const <PrescriptionItem>[];
                  final active = all.where((e) => e.isActive).toList();
                  final inactive = all.where((e) => !e.isActive).toList();
                  final showing = _showActive ? active : inactive;

                  if (showing.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 80),
                          Center(
                            child: Text(
                              _showActive
                                  ? 'ยังไม่มีรายการยาที่กำลังใช้'
                                  : 'ยังไม่มีรายการยาที่หยุดแล้ว',
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView.separated(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: showing.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _RxTile(rx: showing[i]),
                    ),
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

class _RxTile extends StatelessWidget {
  final PrescriptionItem rx;
  const _RxTile({required this.rx});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Thumb(url: rx.imageUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rx.medicineName,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  if (rx.dosage.isNotEmpty)
                    Text(rx.dosage,
                        style: const TextStyle(color: Colors.black87, height: 1.2)),
                  if ((rx.doctorComment ?? '').isNotEmpty)
                    Text(rx.doctorComment!,
                        style: const TextStyle(color: Colors.black87, height: 1.2)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text('${rx.amount} ชุด',
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final String? url;
  const _Thumb({this.url});

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: 52,
      height: 52,
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Icon(Icons.medication, size: 26),
    );
    if (url == null || url!.isEmpty) return fallback;

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.network(
        url!,
        width: 52,
        height: 52,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBox({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message, style: const TextStyle(color: Colors.redAccent)),
        const SizedBox(height: 8),
        OutlinedButton(onPressed: onRetry, child: const Text('ลองอีกครั้ง')),
      ],
    ),
  );
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
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => onChanged(true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
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
                    Text(' $leftLabel ',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
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
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
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
                    Text(' $rightLabel ',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
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
