import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';

class BenefitsPagePatient extends StatelessWidget {
  const BenefitsPagePatient({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <_BenefitItem>[
      _BenefitItem(
        title: 'สำนักงานหลักประกันสุขภาพแห่งชาติ (บัตรทอง)',
        subtitle: 'บัตรทอง 30 บาท การรักษาโรคทั่วไปสำหรับประชาชนทั่วไป',
        asset: 'assets/images/nhso_logo.png',
      ),
      _BenefitItem(
        title: 'ประกันสังคม',
        subtitle: 'สำหรับผู้ลูกจ้างและผู้จ้างตนเองตามระบบประกันสังคม',
        asset: 'assets/images/sss_logo.png',
      ),
      _BenefitItem(
        title: 'กรมบัญชีกลาง',
        subtitle: 'สำหรับข้าราชการ ลูกจ้างประจำ และครอบครัว',
        asset: 'assets/images/cgd_logo.png',
      ),
    ];

    return Scaffold(
      appBar: const CustomAppBar(title: 'เช็คสิทธิ์รักษา'),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          return Card(
            elevation: 0,
            color: Colors.lightGreen[50],
            child: ListTile(
              leading: _Logo(asset: item.asset),
              title: Text(
                item.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(item.subtitle),
            ),
          );
        },
      ),
    );
  }
}

class _BenefitItem {
  final String title;
  final String subtitle;
  final String asset;

  _BenefitItem({
    required this.title,
    required this.subtitle,
    required this.asset,
  });
}

class _Logo extends StatelessWidget {
  final String asset;

  const _Logo({required this.asset});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: Colors.white,
      child: ClipOval(
        child: Image.asset(
          asset,
          width: 36,
          height: 36,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(Icons.local_hospital),
        ),
      ),
    );
  }
}
