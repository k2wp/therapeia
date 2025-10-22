import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_button.dart';
import '../api_service.dart';
import '../models/auth_session.dart';
import 'models/patient_models.dart';

class PaymentPagePatient extends StatefulWidget {
  final AuthSession session;

  const PaymentPagePatient({super.key, required this.session});

  @override
  State<PaymentPagePatient> createState() => _PaymentPagePatientState();
}

class _PaymentPagePatientState extends State<PaymentPagePatient> {
  final _api = ApiService();

  late Future<List<Order>> _pendingFuture;
  Order? _order;
  bool _boundOrderToControls = false;

  late Future<ShippingAddress?> _addrFuture;
  ShippingAddress? _address;
  bool _editing = false;

  final _shippingOptions = const ['Flash express', 'Thailand Post', 'Kerry', 'DHL'];
  final _paymentOptions = const ['QR Code', 'Credit Card'];
  String? _shipping;
  String? _payment;

  final _formKey = GlobalKey<FormState>();
  final _firstCtl = TextEditingController();
  final _lastCtl = TextEditingController();
  final _addrCtl = TextEditingController();
  final _phoneCtl = TextEditingController();
  final _postalCtl = TextEditingController();
  final _latCtl = TextEditingController();
  final _lonCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pendingFuture = _api.getPendingOrders(widget.session);
    _addrFuture = _api.getShippingAddress(widget.session);
    _shipping = _shippingOptions.first;
    _payment = _paymentOptions.first;
  }

  @override
  void dispose() {
    _firstCtl.dispose();
    _lastCtl.dispose();
    _addrCtl.dispose();
    _phoneCtl.dispose();
    _postalCtl.dispose();
    _latCtl.dispose();
    _lonCtl.dispose();
    super.dispose();
  }

  void _beginEdit([ShippingAddress? a]) {
    setState(() {
      _editing = true;
      _firstCtl.text = a?.firstName ?? '';
      _lastCtl.text = a?.lastName ?? '';
      _addrCtl.text = a?.address ?? '';
      _phoneCtl.text = a?.phone ?? '';
      _postalCtl.text = a?.postalCode ?? '';
      _latCtl.text = a?.lat?.toString() ?? '';
      _lonCtl.text = a?.lon?.toString() ?? '';
    });
  }

  Future<void> _saveAddress() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final lat = _latCtl.text.trim().isEmpty
        ? null
        : double.tryParse(_latCtl.text.trim());
    final lon = _lonCtl.text.trim().isEmpty
        ? null
        : double.tryParse(_lonCtl.text.trim());

    final ok = await _api.updateShippingAddress(
      widget.session,
      _addrCtl.text,
      _firstCtl.text,
      _lastCtl.text,
      lat,
      lon,
      _phoneCtl.text,
      _postalCtl.text,
    );

    if (!ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('บันทึกที่อยู่ไม่สำเร็จ')));
      return;
    }

    if (!mounted) return;
    setState(() {
      _addrFuture = _api.getShippingAddress(widget.session);
      _editing = false;
    });
    _address = await _addrFuture;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('บันทึกที่อยู่เรียบร้อย')));
  }

  void _submit() {
    if (_order == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ไม่มีรายการค้างชำระ')));
      return;
    }
    if (_editing) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาบันทึกที่อยู่ก่อนดำเนินการต่อ')),
      );
      return;
    }
    if (_address == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเพิ่มที่อยู่สำหรับจัดส่ง')),
      );
      return;
    }

    // TODO: call confirm endpoint
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('ชำระเงินด้วย: $_payment • จัดส่ง: $_shipping')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'ชำระเงิน'),
      body: FutureBuilder<List<Order>>(
        future: _pendingFuture,
        builder: (context, pendingSnap) {
          if (pendingSnap.connectionState == ConnectionState.waiting &&
              _order == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (pendingSnap.hasError) {
            return Center(
              child: Text(
                'เกิดข้อผิดพลาดในการโหลดคำสั่งซื้อ: ${pendingSnap.error}',
              ),
            );
          }

          final pending = pendingSnap.data ?? const <Order>[];
          if (pending.isEmpty) {
            return const Center(
              child: Text(
                'ไม่มีรายการค้างชำระ',
                style: TextStyle(color: Colors.black54),
              ),
            );
          }

          _order ??= pending.first;

          if (!_boundOrderToControls && _order != null) {
            _boundOrderToControls = true;
            final o = _order!;
            final ship = o.shippingPlatform;
            final pay = o.paymentPlatform;
            if (_shippingOptions.contains(ship)) _shipping = ship;
            if (_paymentOptions.contains(pay)) _payment = pay;
          }

          return FutureBuilder<ShippingAddress?>(
            future: _addrFuture,
            builder: (context, addrSnap) {
              if (addrSnap.connectionState == ConnectionState.waiting &&
                  _address == null) {
                return const Center(child: CircularProgressIndicator());
              }
              if (_address == null &&
                  addrSnap.connectionState == ConnectionState.done) {
                _address = addrSnap.data;
                if (_address == null) _beginEdit();
              }

              final o = _order!;
              final firstItem = o.items.isNotEmpty ? o.items.first : null;
              final productTitle = firstItem?.medicineName ?? 'Order #${o.id}';
              final productSubtitle = firstItem == null
                  ? 'รวม ${o.items.length} รายการ'
                  : 'จำนวน ${firstItem.amount} ชุด\nราคา ${firstItem.price.toStringAsFixed(2)} บาท';
              final totalLabel = 'รวม ${o.totPrice.toStringAsFixed(2)} บาท';
              final productImg = firstItem?.imgLink;

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_editing)
                      _AddressForm(
                        formKey: _formKey,
                        firstCtl: _firstCtl,
                        lastCtl: _lastCtl,
                        addrCtl: _addrCtl,
                        phoneCtl: _phoneCtl,
                        postalCtl: _postalCtl,
                        latCtl: _latCtl,
                        lonCtl: _lonCtl,
                        onSave: _saveAddress,
                        onCancel: () {
                          setState(() => _editing = false);
                          if (_address == null) _beginEdit();
                        },
                      )
                    else
                      _AddressSummary(
                        address: _address!,
                        onEdit: () => _beginEdit(_address),
                      ),

                    const SizedBox(height: 16),

                    const Text(
                      'ยาที่จะสั่ง',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _OrderRow(
                      imageUrl: productImg,
                      title: productTitle,
                      subtitle: productSubtitle,
                      trailing: totalLabel,
                    ),

                    const SizedBox(height: 24),

                    _LabeledDropdown<String>(
                      label: 'shipping platform',
                      value: _shipping!,
                      items: _shippingOptions,
                      onChanged: (v) => setState(() => _shipping = v),
                    ),
                    const SizedBox(height: 16),
                    _LabeledDropdown<String>(
                      label: 'Payment platform',
                      value: _payment!,
                      items: _paymentOptions,
                      onChanged: (v) => setState(() => _payment = v),
                    ),

                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(text: 'ยืนยัน', onPressed: _submit),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _AddressSummary extends StatelessWidget {
  final ShippingAddress address;
  final VoidCallback onEdit;

  const _AddressSummary({required this.address, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final gray = Colors.black.withOpacity(0.75);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'ที่อยู่สำหรับจัดส่ง',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            TextButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('แก้ไขที่อยู่'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '${address.firstName} ${address.lastName}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(address.address, style: TextStyle(color: gray)),
        Text(
          'รหัสไปรษณีย์ ${address.postalCode}',
          style: TextStyle(color: gray),
        ),
        if (address.phone.isNotEmpty)
          Text(
            'โทร: ${address.phone}',
            style: const TextStyle(color: Colors.black54),
          ),
        if (address.lat != null && address.lon != null)
          Text(
            '(${address.lat}, ${address.lon})',
            style: const TextStyle(color: Colors.black54),
          ),
      ],
    );
  }
}

class _AddressForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController firstCtl;
  final TextEditingController lastCtl;
  final TextEditingController addrCtl;
  final TextEditingController phoneCtl;
  final TextEditingController postalCtl;
  final TextEditingController latCtl;
  final TextEditingController lonCtl;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _AddressForm({
    required this.formKey,
    required this.firstCtl,
    required this.lastCtl,
    required this.addrCtl,
    required this.phoneCtl,
    required this.postalCtl,
    required this.latCtl,
    required this.lonCtl,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    InputDecoration deco(String label) => InputDecoration(
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      hintText: label,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ที่อยู่สำหรับจัดส่ง',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: firstCtl,
                  decoration: deco('ชื่อ'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'กรอกชื่อ' : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: lastCtl,
                  decoration: deco('นามสกุล'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'กรอกนามสกุล' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          TextFormField(
            controller: phoneCtl,
            keyboardType: TextInputType.phone,
            decoration: deco('หมายเลขโทรศัพท์'),
          ),
          const SizedBox(height: 10),

          TextFormField(
            controller: addrCtl,
            decoration: deco('ที่อยู่'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'กรอกที่อยู่' : null,
          ),
          const SizedBox(height: 10),

          TextFormField(
            controller: postalCtl,
            keyboardType: TextInputType.number,
            decoration: deco('รหัสไปรษณีย์'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'กรอกรหัสไปรษณีย์' : null,
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: latCtl,
                  decoration: deco('ละติจูด (ไม่บังคับ)'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: lonCtl,
                  decoration: deco('ลองจิจูด (ไม่บังคับ)'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  child: const Text('ยกเลิก'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: onSave,
                  child: const Text('บันทึกที่อยู่'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  final String? imageUrl;
  final String title, subtitle, trailing;

  const _OrderRow({
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: 56,
      height: 56,
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Icon(Icons.medication, size: 28),
    );
    final thumb = (imageUrl == null || imageUrl!.isEmpty)
        ? placeholder
        : ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.network(
              imageUrl!,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => placeholder,
            ),
          );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        thumb,
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(subtitle),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(trailing, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _LabeledDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final ValueChanged<T?> onChanged;

  const _LabeledDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final gray = Colors.grey.shade700;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: gray)),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          items: items
              .map(
                (e) => DropdownMenuItem<T>(value: e, child: Text(e.toString())),
              )
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          icon: const Icon(Icons.keyboard_arrow_down),
        ),
      ],
    );
  }
}
