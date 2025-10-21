import 'package:flutter/material.dart';
import 'package:flutter_frontend/api_service.dart';
import 'package:flutter_frontend/models/auth_session.dart';
import 'widgets/custom_button.dart';
import 'widgets/custom_textfield.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _citizenIdController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _roleSpecificController = TextEditingController();

  UserRole _selectedRole = UserRole.patient;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _citizenIdController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _roleSpecificController.dispose();
    super.dispose();
  }

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
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'ยินดีต้อนรับ',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16.0),
                CustomTextField(
                  controller: _citizenIdController,
                  labelText: 'เลขบัตรประชาชน 13 หลัก (Citizen ID)',
                  hintText: 'Enter your Citizen ID',
                ),
                const SizedBox(height: 16.0),
                CustomTextField(
                  controller: _firstNameController,
                  labelText: 'ชื่อ (First Name)',
                  hintText: 'Enter your First Name',
                ),
                const SizedBox(height: 16.0),
                CustomTextField(
                  controller: _lastNameController,
                  labelText: 'นามสกุล (Last Name)',
                  hintText: 'Enter your Last Name',
                ),
                const SizedBox(height: 16.0),
                CustomTextField(
                  controller: _phoneController,
                  labelText: 'โทรศัพท์ (Phone Number)',
                  hintText: 'Enter your Phone Number',
                ),
                const SizedBox(height: 16.0),
                CustomTextField(
                  controller: _passwordController,
                  labelText: 'รหัสผ่าน (Password)',
                  hintText: 'Enter your Password',
                  obscureText: true,
                ),
                const SizedBox(height: 16.0),
                _RoleSelector(
                  selectedRole: _selectedRole,
                  onRoleChanged: (role) {
                    if (role != null) {
                      setState(() {
                        _selectedRole = role;
                        _roleSpecificController.clear();
                      });
                    }
                  },
                ),
                const SizedBox(height: 16.0),
                if (_selectedRole == UserRole.patient)
                  _PatientSpecificField(controller: _roleSpecificController)
                else
                  CustomTextField(
                    controller: _roleSpecificController,
                    labelText: 'เลขเวชกรรม',
                    hintText: 'Enter your Medical License Number',
                  ),
                const SizedBox(height: 32.0),
                CustomButton(
                  text: _isSubmitting ? 'กำลังสร้างบัญชี...' : 'สร้างบัญชีใหม่',
                  onPressed: _isSubmitting ? null : () => _handleRegister(),
                  color: Colors.lightGreen[100],
                  textColor: Colors.black,
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'มีบัญชีอยู่แล้ว เข้าสู่ระบบที่นี่',
                    style: TextStyle(color: Colors.green),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final citizenId = _citizenIdController.text.trim();
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final identifier = _roleSpecificController.text.trim();

    if (citizenId.isEmpty ||
        firstName.isEmpty ||
        lastName.isEmpty ||
        phone.isEmpty ||
        password.isEmpty ||
        identifier.isEmpty) {
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
      if (_selectedRole == UserRole.patient) {
        await apiService.registerPatient(
          hn: identifier,
          citizenId: citizenId,
          firstName: firstName,
          lastName: lastName,
          phone: phone,
          password: password,
        );
      } else {
        await apiService.registerDoctor(
          mln: identifier,
          citizenId: citizenId,
          firstName: firstName,
          lastName: lastName,
          phone: phone,
          password: password,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('สมัครสมาชิกสำเร็จ')));
      Navigator.pop(context);
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

class _RoleSelector extends StatelessWidget {
  final UserRole selectedRole;
  final ValueChanged<UserRole?> onRoleChanged;

  const _RoleSelector({
    required this.selectedRole,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Radio<UserRole>(
          value: UserRole.patient,
          groupValue: selectedRole,
          onChanged: onRoleChanged,
        ),
        const Text('ผู้ป่วย'),
        Radio<UserRole>(
          value: UserRole.doctor,
          groupValue: selectedRole,
          onChanged: onRoleChanged,
        ),
        const Text('แพทย์'),
      ],
    );
  }
}

class _PatientSpecificField extends StatelessWidget {
  final TextEditingController controller;
  const _PatientSpecificField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
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
        const SizedBox(height: 8.0),
        TextFormField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter your HN',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }
}
