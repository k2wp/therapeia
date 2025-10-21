import 'package:flutter/material.dart';
import 'doctor/landing_page_doctor.dart';
import 'patient/landing_page_patient.dart';
import 'register_page.dart';
import 'widgets/custom_textfield.dart';
import 'widgets/custom_button.dart';

import 'package:flutter_frontend/api_service.dart';
import 'package:flutter_frontend/models/auth_session.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _citizenIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _identifierController = TextEditingController();
  UserRole _selectedRole = UserRole.patient;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _citizenIdController.dispose();
    _passwordController.dispose();
    _identifierController.dispose();
    super.dispose();
  }

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
              controller: _citizenIdController,
              labelText: 'เลขบัตรประชาชน 13 หลัก (Citizen ID)',
              hintText: 'กรอกเลขบัตรประชาชน',
            ),
            const SizedBox(height: 16.0),
            CustomTextField(
              controller: _identifierController,
              labelText: _selectedRole == UserRole.patient
                  ? 'Hospital Number (HN)'
                  : 'เลขที่ใบประกอบวิชาชีพ (MLN)',
              hintText: _selectedRole == UserRole.patient
                  ? 'กรอก HN ของผู้ป่วย'
                  : 'กรอกเลขเวชกรรมของแพทย์',
            ),
            const SizedBox(height: 16.0),
            CustomTextField(
              controller: _passwordController,
              labelText: 'รหัสผ่าน (Password)',
              hintText: 'Enter your Password',
              obscureText: true,
            ),
            SizedBox(height: 24.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Radio<UserRole>(
                  value: UserRole.patient,
                  groupValue: _selectedRole,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedRole = value;
                      });
                    }
                  },
                ),
                const Text('ผู้ป่วย'),
                const SizedBox(width: 16.0),
                Radio<UserRole>(
                  value: UserRole.doctor,
                  groupValue: _selectedRole,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedRole = value;
                      });
                    }
                  },
                ),
                const Text('แพทย์'),
              ],
            ),
            const SizedBox(height: 24.0),
            CustomButton(
              text: _isSubmitting ? 'กำลังเข้าสู่ระบบ...' : 'เข้าสู่ระบบ',
              onPressed: _isSubmitting ? null : () => _handleLogin(),
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

  Future<void> _handleLogin() async {
    final citizenId = _citizenIdController.text.trim();
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;

    if (citizenId.isEmpty || identifier.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบถ้วน')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final apiService = ApiService();

    try {
      late AuthSession session;
      if (_selectedRole == UserRole.patient) {
        session = await apiService.loginPatient(
          hn: identifier,
          citizenId: citizenId,
          password: password,
        );
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => LandingPagePatient(session: session),
          ),
        );
      } else {
        session = await apiService.loginDoctor(
          mln: identifier,
          citizenId: citizenId,
          password: password,
        );
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => LandingPageDoctor(session: session),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
