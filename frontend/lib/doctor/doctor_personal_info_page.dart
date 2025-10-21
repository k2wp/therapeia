import 'package:flutter/material.dart';
import 'package:flutter_frontend/api_service.dart';
import 'package:flutter_frontend/models/auth_session.dart';

class DoctorPersonalInfoPage extends StatefulWidget {
  final AuthSession session;

  const DoctorPersonalInfoPage({super.key, required this.session});

  @override
  State<DoctorPersonalInfoPage> createState() => _DoctorPersonalInfoPageState();
}

class _DoctorPersonalInfoPageState extends State<DoctorPersonalInfoPage> {
  final ApiService _apiService = ApiService();
  late Future<DoctorProfile> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _apiService.getDoctorProfile(widget.session);
  }

  Future<void> _reload() async {
    setState(() {
      _profileFuture = _apiService.getDoctorProfile(widget.session);
    });
    await _profileFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ข้อมูลส่วนตัว',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.lightGreen[100],
        foregroundColor: Colors.black,
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<DoctorProfile>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _ErrorCard(
                    message: 'ไม่สามารถโหลดข้อมูลแพทย์ได้',
                    detail: snapshot.error.toString(),
                  ),
                ],
              );
            }

            final profile = snapshot.data;
            if (profile == null) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: const [_ErrorCard(message: 'ไม่พบข้อมูลแพทย์')],
              );
            }

            final infoItems = <_InfoItem>[
              _InfoItem(label: 'ชื่อ-นามสกุล', value: profile.fullName),
              _InfoItem(
                label: 'แผนก',
                value: profile.departments.isEmpty ? '-' : profile.departments,
              ),
              _InfoItem(
                label: 'ตำแหน่ง',
                value: profile.position.isEmpty ? '-' : profile.position,
              ),
              _InfoItem(
                label: 'อีเมล',
                value: profile.email.isEmpty ? '-' : profile.email,
              ),
              _InfoItem(
                label: 'เบอร์โทรศัพท์',
                value: profile.phone.isEmpty ? '-' : profile.phone,
              ),
            ];

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: Colors.lightGreen[50],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: infoItems
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.label,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.value,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'ตารางงาน',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'ฟีเจอร์จัดการตารางงานจะพร้อมใช้งานเร็วๆ นี้',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _InfoItem {
  final String label;
  final String value;

  const _InfoItem({required this.label, required this.value});
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final String? detail;

  const _ErrorCard({required this.message, this.detail});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.redAccent,
              ),
            ),
            if (detail != null) ...[
              const SizedBox(height: 8),
              Text(detail!, style: const TextStyle(color: Colors.redAccent)),
            ],
          ],
        ),
      ),
    );
  }
}
