import 'package:flutter/material.dart';
import 'package:flutter_frontend/patient/book_appointments_page.dart';
import 'package:flutter_frontend/patient/medical_rights_page.dart';
import 'package:flutter_frontend/patient/patient_personal_info_page.dart';
import 'package:flutter_frontend/patient/payment_page.dart';
import 'package:flutter_frontend/patient/prescriptions_page.dart';
import 'appointments_page_patient.dart';
import 'order_history_page.dart';
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
    {'text': 'ใบสั่งยา', 'icon': '⭐'},
    {'text': 'ประวัติการสั่งซื้อ', 'icon': '⭐'},
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
                          PatientPersonalInfoPage(session: session),
                    ),
                  );
                  break;
                case 'เช็คสิทธิ์รักษา':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          MedicalRightsPagePatient(session: session),
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
                case 'ใบสั่งยา':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PrescriptionsPage(session: session),
                    ),
                  );
                  break;
                case 'ประวัติการสั่งซื้อ':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          OrderHistoryPage(session: session),
                    ),
                  );
                  break;
                case 'ชำระเงิน':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          PaymentPagePatient(session: session),
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
