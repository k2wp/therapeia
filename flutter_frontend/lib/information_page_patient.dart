import 'package:flutter/material.dart';
import 'widgets/custom_app_bar.dart';

class InformationPagePatient extends StatelessWidget {
  const InformationPagePatient({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'ข้อมูลส่วนตัว'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: <Widget>[
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.lightGreen[200],
                // Placeholder for patient image
                backgroundImage: NetworkImage(
                  'https://via.placeholder.com/150',
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildInfoTile(title: 'ชื่อ-นามสกุล', value: 'ทักษิณ ชินชา'),
            _buildInfoTile(title: 'น้ำหนัก', value: '70 กก.'),
            _buildInfoTile(title: 'ส่วนสูง', value: '175 ซม.'),
            _buildInfoTile(title: 'อายุ', value: '30 ปี'),
            _buildInfoTile(title: 'โรคประจำตัว', value: 'คันปาก'),
            _buildInfoTile(title: 'ยาที่แพ้', value: 'น้ำเกลือ'),
          ],
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
}
