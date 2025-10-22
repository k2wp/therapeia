import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../api_service.dart';
import '../models/auth_session.dart';
import '../widgets/custom_app_bar.dart';
import 'models/patient_models.dart';

class OrderDetailPage extends StatefulWidget {
  final AuthSession session;
  final Order order;

  const OrderDetailPage({
    super.key,
    required this.session,
    required this.order,
  });

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  final _api = ApiService();

  late Future<ShippingStatus> _statusFuture;
  late Future<Uint8List> _mapFuture;

  @override
  void initState() {
    super.initState();
    _statusFuture = _api.getShippingStatus(widget.session, widget.order.id);
    _mapFuture = _api.getShippingMapImage(widget.session, widget.order.id);
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final totalQty = o.items.fold<int>(0, (s, it) => s + it.amount);

    return Scaffold(
      appBar: const CustomAppBar(title: 'รายละเอียดคำสั่งซื้อ'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _SummaryCard(
            orderId: o.id,
            shippingPlatform: o.shippingPlatform,
            paymentPlatform: o.paymentPlatform,
            totalPriceTHB: _thb(o.totPrice),
            totalQty: totalQty,
          ),
          const SizedBox(height: 16),

          const Text('สินค้าในคำสั่งซื้อ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...o.items.map((it) => _ItemTile(item: it)),
          const Divider(height: 32),

          const Text('แผนที่การจัดส่ง',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          FutureBuilder<Uint8List>(
            future: _mapFuture,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return _MapSkeleton();
              }
              if (snap.hasError) {
                return FutureBuilder<ShippingStatus>(
                  future: _statusFuture,
                  builder: (context, s2) {
                    final fallbackUrl = s2.data?.imageUrl;
                    if (fallbackUrl != null && fallbackUrl.isNotEmpty) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          fallbackUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _ErrorInline(text: 'โหลดแผนที่ไม่สำเร็จ'),
                        ),
                      );
                    }
                    return _ErrorInline(
                      text: 'โหลดแผนที่ไม่สำเร็จ',
                      onRetry: () => setState(() {
                        _mapFuture =
                            _api.getShippingMapImage(widget.session, widget.order.id);
                      }),
                    );
                  },
                );
              }
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(snap.data!, fit: BoxFit.cover),
              );
            },
          ),
          const SizedBox(height: 24),

          const Text('สถานะการจัดส่ง',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          FutureBuilder<ShippingStatus>(
            future: _statusFuture,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return _TimelineSkeleton();
              }
              if (snap.hasError) {
                return _ErrorInline(
                  text: 'โหลดสถานะการจัดส่งไม่สำเร็จ',
                  onRetry: () => setState(() {
                    _statusFuture =
                        _api.getShippingStatus(widget.session, widget.order.id);
                  }),
                );
              }
              final status = snap.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((status.shippingPlatform ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        status.shippingPlatform!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  _TimelineCard(entries: status.status),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  static String _thb(double v) => '฿${v.toStringAsFixed(2)}';
}

class _SummaryCard extends StatelessWidget {
  final String orderId;
  final String shippingPlatform;
  final String paymentPlatform;
  final String totalPriceTHB;
  final int totalQty;

  const _SummaryCard({
    required this.orderId,
    required this.shippingPlatform,
    required this.paymentPlatform,
    required this.totalPriceTHB,
    required this.totalQty,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _KV('หมายเลขคำสั่งซื้อ', orderId),
          _KV('ขนส่ง', shippingPlatform),
          _KV('การชำระเงิน', paymentPlatform),
          _KV('จำนวนสินค้า', '$totalQty ชิ้น'),
          _KV('รวมทั้งหมด', totalPriceTHB),
        ],
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final OrderItem item;
  const _ItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Thumb(url: item.imgLink),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.medicineName,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('จำนวน ${item.amount} ชิ้น • ฿${item.price.toStringAsFixed(2)}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final String? url;
  const _Thumb({this.url});
  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) return _fallback();
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.network(
        url!,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
      ),
    );
  }

  Widget _fallback() => Container(
    width: 48,
    height: 48,
    color: Colors.grey.shade200,
    alignment: Alignment.center,
    child: const Icon(Icons.medication, size: 22),
  );
}

class _TimelineCard extends StatelessWidget {
  final List<ShippingStatusEntry> entries;
  const _TimelineCard({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.black12),
        ),
        child: const Text('ยังไม่มีข้อมูลการติดตามพัสดุ'),
      );
    }

    final list = [...entries]..sort((a, b) => b.at.compareTo(a.at));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < list.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    _fmtDT(list[i].at),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Expanded(child: Text(list[i].details ?? '-')),
              ],
            ),
            if (i != list.length - 1) const Divider(height: 16),
          ],
        ],
      ),
    );
  }

  static String _fmtDT(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/$y  $hh:$mm';
  }
}

class _KV extends StatelessWidget {
  final String k, v;
  const _KV(this.k, this.v);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        SizedBox(
            width: 110,
            child:
            Text(k, style: const TextStyle(color: Colors.black54))),
        const Text(':  '),
        Expanded(child: Text(v)),
      ],
    ),
  );
}

class _MapSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(strokeWidth: 2),
    );
  }
}

class _TimelineSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          const SizedBox(
              width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 12),
          Expanded(child: Text('กำลังโหลดสถานะ...')),
        ],
      ),
    );
  }
}

class _ErrorInline extends StatelessWidget {
  final String text;
  final VoidCallback? onRetry;
  const _ErrorInline({required this.text, this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(text, style: const TextStyle(color: Colors.redAccent)),
        if (onRetry != null) ...[
          const SizedBox(width: 8),
          TextButton(onPressed: onRetry, child: const Text('ลองอีกครั้ง')),
        ]
      ],
    );
  }
}
