import 'package:flutter/material.dart';
import 'widgets/custom_app_bar.dart';
import 'widgets/custom_button.dart';

class PaymentPagePatient extends StatefulWidget {
  const PaymentPagePatient({super.key});

  @override
  State<PaymentPagePatient> createState() => _PaymentPagePatientState();
}

class _PaymentPagePatientState extends State<PaymentPagePatient> {

  final String receiverName = 'นาย ทักษิน ชินวุฒิ';
  final String addressLine1 = '354/89 ถนน แก้วพระกต ตำบล มะขาวเปี้ยว อำเภอ มะม่วงหวาน';
  final String addressLine2 = 'จังหวัด กรุงเทพมหานคร 10900';
  final String coords = '(10.454545,45.9439434)';

  final String productName = 'Metronidazole (ยาฆ่าเชื้อ)';
  final String packInfo = 'จำนวน 3 (ชิ้น)\nราคา 593 บาท';
  final String totalText = 'รวม 593 บาท';

  final List<String> shippingOptions = ['Thailand Post', 'Flash express', 'Kerry'];
  final List<String> paymentOptions = ['QR code', 'COD'];

  String selectedShipping = 'Thailand Post';
  String selectedPayment = 'QR code';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'ชำระเงิน'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AddressBlock(
              name: receiverName,
              line1: addressLine1,
              line2: addressLine2,
              coords: coords,
            ),
            const SizedBox(height: 16),
            const Text('ยาที่จะสั่ง', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _OrderRow(
              imageAsset: 'assets/images/metronidazole.png',
              title: productName,
              subtitle: packInfo,
              trailing: totalText,
            ),
            const SizedBox(height: 24),
            _LabeledDropdown<String>(
              label: 'ขนส่งโดย',
              value: selectedShipping,
              items: shippingOptions,
              onChanged: (v) => setState(() => selectedShipping = v!),
            ),
            const SizedBox(height: 16),
            _LabeledDropdown<String>(
              label: 'ชำระเงินโดย',
              value: selectedPayment,
              items: paymentOptions,
              onChanged: (v) => setState(() => selectedPayment = v!),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'ยืนยัน',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('ชำระเงินด้วย: $selectedPayment • จัดส่ง: $selectedShipping'),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _AddressBlock extends StatelessWidget {
  final String name;
  final String line1;
  final String line2;
  final String coords;

  const _AddressBlock({
    required this.name,
    required this.line1,
    required this.line2,
    required this.coords,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(line1),
        Text(line2),
        Text(coords, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}

class _OrderRow extends StatelessWidget {
  final String imageAsset;
  final String title;
  final String subtitle;
  final String trailing;

  const _OrderRow({
    required this.imageAsset,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.asset(
            imageAsset,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 56,
              height: 56,
              color: Colors.grey.shade300,
              alignment: Alignment.center,
              child: const Icon(Icons.medication, size: 28),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(subtitle),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          trailing,
          textAlign: TextAlign.right,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade700)),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          items: items
              .map((e) => DropdownMenuItem<T>(value: e, child: Text(e.toString())))
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          icon: const Icon(Icons.keyboard_arrow_down),
        ),
      ],
    );
  }
}
