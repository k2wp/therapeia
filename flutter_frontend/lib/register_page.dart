import 'package:flutter/material.dart';
import 'widgets/custom_textfield.dart';
import 'widgets/custom_button.dart';

class RegisterPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Therapeia (Register_page)'),
        backgroundColor: Colors.lightGreen[100],
        actions: [IconButton(icon: Icon(Icons.more_vert), onPressed: () {})],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'ยินดีต้อนรับ',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 32.0),
              CustomTextField(
                labelText: 'เลขบัตรประชาชน 13 หลัก (Citizen ID)',
                hintText: 'Enter your Citizen ID',
              ),
              SizedBox(height: 16.0),
              CustomTextField(
                labelText: 'ชื่อ (First Name)',
                hintText: 'Enter your First Name',
              ),
              SizedBox(height: 16.0),
              CustomTextField(
                labelText: 'นามสกุล (Last Name)',
                hintText: 'Enter your Last Name',
              ),
              SizedBox(height: 16.0),
              CustomTextField(
                labelText: 'โทรศัพท์ (Phone Number)',
                hintText: 'Enter your Phone Number',
              ),
              SizedBox(height: 16.0),
              CustomTextField(
                labelText: 'รหัสผ่าน (Password)',
                hintText: 'Enter your Password',
                obscureText: true,
              ),
              SizedBox(height: 16.0),
              Row(
                children: [
                  Text(
                    'Hospital Number (HN)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 8.0),
                  Tooltip(
                    message:
                        'Hospital Number (HN) คือ เลขประจำตัวผู้ป่วยที่โรงพยาบาลออกให้เพื่อใช้ระบุตัวตนผู้ป่วย \nสำหรับผู้ป่วยนอก เพื่อในการค้นหาประวัติการรักษาและข้อมูลสุขภาพอื่นๆ \nทำให้บุคลากรทางการแพทย์เข้าถึงข้อมูลได้อย่างถูกต้องและรวดเร็วเมื่อผู้ป่วยมารับบริการเป็นครั้งแรก',
                    child: Icon(Icons.info_outline, size: 16.0),
                  ),
                ],
              ),
              SizedBox(height: 8.0),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Enter your HN',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 32.0),
              CustomButton(
                text: 'สร้างบัญชีใหม่',
                onPressed: () {
                  // TODO: Add registration logic
                  Navigator.pop(context);
                },
                color: Colors.lightGreen[100],
                textColor: Colors.black,
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  'มีบัญชีอยู่แล้ว เข้าสู่ระบบที่นี่',
                  style: TextStyle(color: Colors.green),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
