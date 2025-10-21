import 'package:flutter/material.dart';
import 'appointments_page_doctor.dart';
import 'consultation_request_page.dart';
import 'doctor_personal_info_page.dart';
import '../login_page.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/landing_page_item.dart';

import 'package:flutter_frontend/models/auth_session.dart';

class LandingPageDoctor extends StatelessWidget {
  final AuthSession session;

  const LandingPageDoctor({super.key, required this.session});

  static const List<Map<String, String>> items = [
    {'text': 'ตารางนัดผู้ป่วย', 'icon': '⭐'},
    {'text': 'คำขอตรวจ', 'icon': '⭐'},
    {'text': 'ข้อมูลส่วนตัว', 'icon': '⭐'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Therapeia (Doctor)',
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
                case 'ตารางนัดผู้ป่วย':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AppointmentsPageDoctor(session: session),
                    ),
                  );
                  break;
                case 'คำขอตรวจ':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ConsultationRequestPage(session: session),
                    ),
                  );
                  break;
                case 'ข้อมูลส่วนตัว':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          DoctorPersonalInfoPage(session: session),
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
