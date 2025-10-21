import 'package:flutter/material.dart';
import 'appointments_page_patient.dart';
import 'benefits_page_patient.dart';
import 'information_page_patient.dart';
import 'payment_page_patient.dart';
import '../login_page.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/landing_page_item.dart';

import 'package:flutter_frontend/models/auth_session.dart';

class LandingPagePatient extends StatelessWidget {
  final AuthSession session;

  const LandingPagePatient({super.key, required this.session});

  static const List<Map<String, String>> items = [
    {'text': 'ข้อมูลส่วนตัว', 'icon': '⭐'},
    {'text': 'เช็คสิทธิ์รักษา', 'icon': '⭐'},
    {'text': 'รายการนัด', 'icon': '⭐'},
    {'text': 'เลื่อนนัด', 'icon': '⭐'},
    {'text': 'รับยา', 'icon': '⭐'},
    {'text': 'ชำระเงิน', 'icon': '⭐'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Therapeia',
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        padding: const EdgeInsets.all(10),
        children: items.map((item) {
          return LandingPageItem(
            text: item['text']!,
            icon: item['icon']!,
            onTap: () {
              switch (item['text']) {
                case 'ข้อมูลส่วนตัว':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          InformationPagePatient(session: session),
                    ),
                  );
                  break;
                case 'เช็คสิทธิ์รักษา':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BenefitsPagePatient(),
                    ),
                  );
                  break;
                case 'รายการนัด':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AppointmentsPagePatient(session: session),
                    ),
                  );
                  break;
                case 'เลื่อนนัด':
                  // Navigate to Reschedule Appointment Page
                  break;
                case 'รับยา':
                  // Navigate to Medication Pickup Page
                  break;
                case 'ชำระเงิน':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PaymentPagePatient(),
                    ),
                  );
                  break;
                default:
                  break;
              }
            },
          );
        }).toList(),
      ),
    );
  }
}
