import 'package:flutter/material.dart';
import 'package:flutter_frontend/api_service.dart';
import 'package:flutter_frontend/models/auth_session.dart';
import '../widgets/custom_app_bar.dart';

class PatientPersonalInfoPage extends StatefulWidget {
  final AuthSession session;

  const PatientPersonalInfoPage({super.key, required this.session});

  @override
  State<PatientPersonalInfoPage> createState() => _PatientPersonalInfoPageState();
}

class _PatientPersonalInfoPageState extends State<PatientPersonalInfoPage> {
  late Future<PatientProfile> _profileFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _profileFuture = _apiService.getPatientProfile(widget.session);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'ข้อมูลส่วนตัว'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<PatientProfile>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'ไม่สามารถโหลดข้อมูลผู้ป่วยได้',
                  style: const TextStyle(fontSize: 16, color: Colors.redAccent),
                ),
              );
            }

            final profile = snapshot.data;
            if (profile == null) {
              return const Center(
                child: Text(
                  'ไม่พบข้อมูลผู้ป่วย',
                  style: TextStyle(fontSize: 16),
                ),
              );
            }

            final infoItems = <Map<String, String>>[
              {'title': 'ชื่อ-นามสกุล', 'value': profile.fullName},
              {
                'title': 'อีเมล',
                'value': profile.email.isEmpty ? '-' : profile.email,
              },
              {
                'title': 'เบอร์โทรศัพท์',
                'value': profile.phone.isEmpty ? '-' : profile.phone,
              },
              if (profile.updatedAt != null)
                {
                  'title': 'อัปเดตล่าสุด',
                  'value': _formatUpdatedAt(profile.updatedAt!),
                },
            ];

            return ListView(
              children: <Widget>[
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.lightGreen[200],
                    backgroundImage: const NetworkImage(
                      'https://via.placeholder.com/150',
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ...infoItems.map(
                  (item) => _buildInfoTile(
                    title: item['title']!,
                    value: item['value']!,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoTile({required String title, required String value}) {
    return Card(
      color: Colors.lightGreen[50],
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  String _formatUpdatedAt(DateTime value) {
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}
