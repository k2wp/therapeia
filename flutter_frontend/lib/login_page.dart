import 'package:flutter/material.dart';
import 'landing_page_patient.dart';
import 'register_page.dart';
import 'widgets/custom_textfield.dart';
import 'widgets/custom_button.dart';

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Doctor Appointment'),
        backgroundColor: Colors.lightGreen[100],
      ),
      body: Padding(
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
              labelText: 'รหัสผ่าน (Password)',
              hintText: 'Enter your Password',
              obscureText: true,
            ),
            SizedBox(height: 32.0),
            CustomButton(
              text: 'เข้าสู่ระบบ',
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LandingPagePatient()),
                );
              },
              color: Colors.lightGreen[100],
              textColor: Colors.black,
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegisterPage()),
                );
              },
              child: Text('สมัครสมาชิก', style: TextStyle(color: Colors.green)),
            ),
          ],
        ),
      ),
    );
  }
}
