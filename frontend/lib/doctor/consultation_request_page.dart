import 'package:flutter/material.dart';

import 'package:flutter_frontend/api_service.dart';
import 'package:flutter_frontend/doctor/models/doctor_models.dart';
import 'package:flutter_frontend/models/auth_session.dart';

import 'patient_details_page.dart';

class ConsultationRequestPage extends StatefulWidget {
  final AuthSession session;

  const ConsultationRequestPage({super.key, required this.session});

  @override
  State<ConsultationRequestPage> createState() =>
      _ConsultationRequestPageState();
}

class _ConsultationRequestPageState extends State<ConsultationRequestPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  static final Color _accentColor = Colors.lightGreen[100]!;
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  String? _errorMessage;
  List<DoctorAppointment> _pending = <DoctorAppointment>[];
  List<DoctorAppointment> _assessed = <DoctorAppointment>[];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadConsultations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadConsultations({bool showSpinner = true}) async {
    if (showSpinner) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final pending = await _apiService.getDoctorPendingAppointments(
        widget.session,
      );
      final assessed = await _apiService.getDoctorAssessedAppointments(
        widget.session,
      );
      if (!mounted) return;

      pending.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
      assessed.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));

      setState(() {
        _pending = pending;
        _assessed = assessed;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('คำขอตรวจ', style: TextStyle(color: Colors.black)),
        backgroundColor: _accentColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _isLoading ? null : () => _loadConsultations(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTabSwitcher(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildPendingTab(), _buildAssessedTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tabController.index = 0),
              child: _buildTabButton('Request', _tabController.index == 0),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tabController.index = 1),
              child: _buildTabButton('Assessed', _tabController.index == 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? _accentColor : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isSelected)
            const Icon(Icons.check, color: Colors.white, size: 16),
          if (isSelected) const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildErrorContent();
    }

    if (_pending.isEmpty) {
      return _buildEmptyState('ไม่มีคำขอตรวจใหม่');
    }

    return RefreshIndicator(
      onRefresh: () => _loadConsultations(showSpinner: false),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _pending.length,
        itemBuilder: (context, index) => _buildConsultationCard(
          appointment: _pending[index],
          statusAccent: _accentColor,
        ),
      ),
    );
  }

  Widget _buildAssessedTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildErrorContent();
    }

    if (_assessed.isEmpty) {
      return _buildEmptyState('ยังไม่มีรายการที่ประเมินแล้ว');
    }

    return RefreshIndicator(
      onRefresh: () => _loadConsultations(showSpinner: false),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _assessed.length,
        itemBuilder: (context, index) => _buildConsultationCard(
          appointment: _assessed[index],
          statusAccent: Colors.grey.shade200,
        ),
      ),
    );
  }

  Widget _buildConsultationCard({
    required DoctorAppointment appointment,
    required Color statusAccent,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: statusAccent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PatientDetailsPage(
                session: widget.session,
                appointment: appointment,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.patientName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${appointment.formattedDate}  •  ${appointment.timeRange}',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          appointment.locationLabel,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      appointment.statusLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                appointment.notes,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorContent() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'ไม่สามารถโหลดคำขอตรวจได้',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? '-',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadConsultations(),
              child: const Text('ลองอีกครั้ง'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return RefreshIndicator(
      onRefresh: () => _loadConsultations(showSpinner: false),
      child: ListView(
        padding: const EdgeInsets.all(32),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_outlined, color: Colors.grey.shade400, size: 48),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54, fontSize: 15),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
