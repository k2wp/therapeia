import 'package:flutter/material.dart';
import '../api_service.dart';
import '../models/auth_session.dart';
import '../widgets/custom_app_bar.dart';
import 'models/patient_models.dart';
import 'order_detail_page.dart';

class OrderHistoryPage extends StatefulWidget {
  final AuthSession session;

  const OrderHistoryPage({super.key, required this.session});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  final _api = ApiService();
  late Future<List<Order>> _ordersFuture;

  OrderFilter _filter = OrderFilter.all;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _api.getOrderHistory(widget.session);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'ประวัติการสั่งซื้อ'),
      body: Column(
        children: [
          const SizedBox(height: 8),
          _FilterChips(
            value: _filter,
            onChanged: (f) => setState(() => _filter = f),
          ),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<Order>>(
              future: _ordersFuture,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return _ErrorBox(
                    message: 'ไม่สามารถโหลดประวัติการสั่งซื้อ',
                    onRetry: () => setState(() {
                      _ordersFuture = _api.getOrderHistory(widget.session);
                    }),
                  );
                }
                final orders = snap.data ?? const <Order>[];
                final filtered = _applyFilter(orders, _filter);
                if (filtered.isEmpty) {
                  return const _EmptyBox(message: 'ไม่พบคำสั่งซื้อตามตัวกรอง');
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final o = filtered[i];
                    return InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OrderDetailPage(
                              session: widget.session,
                              order: o,
                            ),
                          ),
                        );
                      },
                      child: _OrderSummaryTile(order: o),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Order> _applyFilter(List<Order> orders, OrderFilter f) {
    if (f == OrderFilter.all) return orders;
    final status = _mapFilterToStatus(f);
    return orders.where((o) => _statusOf(o) == status).toList();
  }

  OrderStatus _statusOf(Order o) {
    switch (o.statusCode) {
      case 0:
        return OrderStatus.pendingPayment;
      case 1:
        return OrderStatus.packing;
      case 2:
        return OrderStatus.shipping;
      case 3:
        return OrderStatus.complete;
      case 4:
        return OrderStatus.canceled;
      default:
        final l = o.statusLabel.toLowerCase();
        if (l.contains('pending')) return OrderStatus.pendingPayment;
        if (l.contains('pack')) return OrderStatus.packing;
        if (l.contains('ship')) return OrderStatus.shipping;
        if (l.contains('complete') || l.contains('success'))
          return OrderStatus.complete;
        if (l.contains('cancel')) return OrderStatus.canceled;
        return OrderStatus.unknown;
    }
  }

  OrderStatus _mapFilterToStatus(OrderFilter f) {
    switch (f) {
      case OrderFilter.pendingPayment:
        return OrderStatus.pendingPayment;
      case OrderFilter.packing:
        return OrderStatus.packing;
      case OrderFilter.shipping:
        return OrderStatus.shipping;
      case OrderFilter.complete:
        return OrderStatus.complete;
      case OrderFilter.canceled:
        return OrderStatus.canceled;
      case OrderFilter.all:
        return OrderStatus.unknown;
    }
  }
}

enum OrderFilter { all, pendingPayment, packing, shipping, complete, canceled }

enum OrderStatus {
  pendingPayment,
  packing,
  shipping,
  complete,
  canceled,
  unknown,
}

class _FilterChips extends StatelessWidget {
  final OrderFilter value;
  final ValueChanged<OrderFilter> onChanged;

  const _FilterChips({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final entries = <(OrderFilter, String)>[
      (OrderFilter.all, 'ทั้งหมด'),
      (OrderFilter.pendingPayment, 'รอการชำระ'),
      (OrderFilter.packing, 'กำลังจัดเตรียม'),
      (OrderFilter.shipping, 'กำลังจัดส่ง'),
      (OrderFilter.complete, 'จัดส่งสำเร็จ'),
      (OrderFilter.canceled, 'ยกเลิก'),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (f, label) in entries) ...[
            ChoiceChip(
              label: Text(label),
              selected: value == f,
              onSelected: (_) => onChanged(f),
              selectedColor: Colors.greenAccent.shade100,
              shape: StadiumBorder(
                side: BorderSide(
                  color: value == f
                      ? Colors.green.shade300
                      : Colors.grey.shade300,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _OrderSummaryTile extends StatelessWidget {
  final Order order;

  const _OrderSummaryTile({required this.order});

  @override
  Widget build(BuildContext context) {
    final status = _statusOf(order);
    final (bg, fg, label) = _statusStyle(status, order.statusLabel);

    final totalQty = order.items.fold<int>(0, (sum, it) => sum + it.amount);
    final subtitle = '${order.shippingPlatform} • ${order.paymentPlatform}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _OrderIcon(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(order.id, style: const TextStyle(color: Colors.black87)),
              const SizedBox(height: 2),
              Text(
                'จำนวน $totalQty ชิ้น • รวม ${_thb(order.totPrice)}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: Colors.black87)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            style: TextStyle(color: fg, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  static String _thb(double v) => '฿${v.toStringAsFixed(2)}';

  static OrderStatus _statusOf(Order o) {
    switch (o.statusCode) {
      case 0:
        return OrderStatus.pendingPayment;
      case 1:
        return OrderStatus.packing;
      case 2:
        return OrderStatus.shipping;
      case 3:
        return OrderStatus.complete;
      case 4:
        return OrderStatus.canceled;
      default:
        final l = o.statusLabel.toLowerCase();
        if (l.contains('pending')) return OrderStatus.pendingPayment;
        if (l.contains('pack')) return OrderStatus.packing;
        if (l.contains('ship')) return OrderStatus.shipping;
        if (l.contains('complete') || l.contains('success'))
          return OrderStatus.complete;
        if (l.contains('cancel')) return OrderStatus.canceled;
        return OrderStatus.unknown;
    }
  }

  static (Color, Color, String) _statusStyle(
    OrderStatus s,
    String backendLabel,
  ) {
    switch (s) {
      case OrderStatus.pendingPayment:
        return (const Color(0xFFFFF9C4), const Color(0xFF8D6E63), 'Pending');
      case OrderStatus.packing:
        return (Colors.blue.shade50, Colors.blue.shade700, 'Packing');
      case OrderStatus.shipping:
        return (const Color(0xFFFFF9C4), Colors.brown.shade600, 'Shipping');
      case OrderStatus.complete:
        return (const Color(0xFFB9F6CA), const Color(0xFF1B5E20), 'Complete');
      case OrderStatus.canceled:
        return (const Color(0xFFFFCDD2), const Color(0xFFB71C1C), 'Canceled');
      case OrderStatus.unknown:
        return (Colors.grey.shade200, Colors.grey.shade700, backendLabel);
    }
  }
}

class _OrderIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(Icons.shopping_bag, size: 24),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  final String message;

  const _EmptyBox({required this.message});

  @override
  Widget build(BuildContext context) => Center(
    child: Text(message, style: const TextStyle(color: Colors.black54)),
  );
}

class _ErrorBox extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBox({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
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
}
