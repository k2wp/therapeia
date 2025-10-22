import 'package:flutter/material.dart';
import '../api_service.dart';
import '../models/auth_session.dart';
import '../widgets/custom_app_bar.dart';

class MedicalRightsPagePatient extends StatefulWidget {
  final AuthSession session;

  const MedicalRightsPagePatient({super.key, required this.session});

  @override
  State<MedicalRightsPagePatient> createState() =>
      _MedicalRightsPagePatientState();
}

class _MedicalRightsPagePatientState extends State<MedicalRightsPagePatient> {
  late Future<List<MedicalRight>> _mrFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _mrFuture = _apiService.getMedicalRights(widget.session);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'เช็คสิทธิ์รักษา'),
      body: FutureBuilder<List<MedicalRight>>(
        future: _mrFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorView(
              message: 'โหลดข้อมูลสิทธิ์รักษาไม่สำเร็จ',
              onRetry: () {
                setState(() {
                  _mrFuture = _apiService.getMedicalRights(widget.session);
                });
              },
            );
          }

          final data = snapshot.data ?? [];
          if (data.isEmpty) {
            return const _EmptyView(message: 'ไม่พบสิทธิ์การรักษา');
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: data.length,
            separatorBuilder: (_, __) => const SizedBox(height: 0),
            itemBuilder: (context, index) {
              final mr = data[index];
              return Card(
                color: Colors.lightGreen[50],
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  leading: _NetworkLogo(url: mr.imageUrl),
                  title: Text(
                    mr.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    mr.details,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final String message;

  const _EmptyView({required this.message});

  @override
  Widget build(BuildContext context) => Center(
    child: Text(message, style: const TextStyle(color: Colors.black54)),
  );
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: const TextStyle(color: Colors.redAccent)),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: onRetry, child: const Text('ลองอีกครั้ง')),
        ],
      ),
    );
  }
}

class _NetworkLogo extends StatelessWidget {
  final String url;

  const _NetworkLogo({required this.url});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: Colors.white,
      radius: 22,
      child: ClipOval(
        child: Image.network(
          url,
          width: 36,
          height: 36,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(Icons.local_hospital),
        ),
      ),
    );
  }
}
