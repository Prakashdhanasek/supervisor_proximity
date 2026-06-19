import 'dart:io';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../controllers/fleet_controller.dart';
import '../models/fleet_models.dart';
import '../models/unassigned_device.dart';
import '../services/vehicle_register_service.dart';
import 'theme/app_theme.dart';

class MasterDriver {
  final String name;
  final String empId;
  final String email;
  final String mobile;
  final String licenseNumber;
  final DateTime licenseExpiry;
  final String projectSite;
  final String? vehicle;
  final String shift;
  final String status;
  final String enrollment;
  final String licenseStatus;
  final DateTime enrolledSince;
  final List<String> faceConditions;
  final Map<String, List<File>> facePhotos;

  MasterDriver({
    required this.name,
    required this.empId,
    required this.email,
    required this.mobile,
    required this.licenseNumber,
    required this.licenseExpiry,
    required this.projectSite,
    this.vehicle,
    required this.shift,
    this.status = 'ACTIVE',
    this.enrollment = 'ENROLLED',
    this.licenseStatus = 'VALID',
    DateTime? enrolledSince,
    this.faceConditions = const ['Normal Face'],
    this.facePhotos = const {},
  }) : enrolledSince = enrolledSince ?? DateTime.now();

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  int get totalPhotos =>
      facePhotos.values.fold(0, (sum, list) => sum + list.length);
}

class MasterView extends StatefulWidget {
  const MasterView({super.key});
  @override
  State<MasterView> createState() => _MasterViewState();
}

class _MasterViewState extends State<MasterView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int? _selectedDriverIndex;
  final List<MasterDriver> _drivers = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fleet = context.watch<FleetController>();
    final vehicles = fleet.vehicles;

    final List<MasterDriver> mappedDrivers = fleet.apiDrivers.map((d) {
      return MasterDriver(
        name: d['fullName'] ?? 'Unknown',
        empId: d['id']?.toString().substring(0, 8) ?? 'Unknown',
        email: d['email'] ?? 'No email',
        mobile: d['mobileNumber'] ?? 'No mobile',
        licenseNumber: d['licenseNumber'] ?? 'No license',
        licenseExpiry: d['licenseExpiry'] != null ? DateTime.tryParse(d['licenseExpiry']) ?? DateTime.now() : DateTime.now(),
        projectSite: d['assignedProjectSite'] ?? 'Unassigned',
        vehicle: d['vehicleRegistrationNumber'] ?? 'Unassigned',
        shift: d['shift'] ?? 'Unassigned',
        status: d['isActive'] == true ? 'ACTIVE' : 'INACTIVE',
        enrollment: (d['status'] == null || d['status'] == '') ? 'ENROLLED' : d['status'].toString().toUpperCase(),
        licenseStatus: 'VALID',
        enrolledSince: d['createdAt'] != null ? DateTime.tryParse(d['createdAt']) ?? DateTime.now() : DateTime.now(),
        faceConditions: const [],
        facePhotos: const {},
      );
    }).toList();

    final allDrivers = [...mappedDrivers, ..._drivers];

    return Scaffold(
      backgroundColor: AppTheme.of(context).surface,
      body: Column(children: [
        _buildHeader(fleet, allDrivers),
        _buildTabBar(allDrivers.length, vehicles.length),
        Expanded(
          child: TabBarView(controller: _tabController, children: [
            allDrivers.isEmpty
                ? _buildEmptyState(
              icon: Icons.person_off_rounded,
              title: 'No drivers enrolled',
              subtitle: 'Enroll your first driver to get started',
              ctaText: 'Enroll Driver',
              onAdd: () => _showEnrollDriverSheet(context),
            )
                : _buildDriverTab(allDrivers),
            vehicles.isEmpty
                ? _buildEmptyState(
              icon: Icons.local_shipping_outlined,
              title: 'No vehicles added',
              subtitle: 'Add your first vehicle to get started',
              ctaText: 'Add Vehicle',
              onAdd: () => _showAddVehicleSheet(context),
            )
                : _buildVehicleList(vehicles),
          ]),
        ),
      ]),
    );
  }

  Widget _buildHeader(FleetController fleet, List<MasterDriver> drivers) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A4FBA), Color(0xFF3B82F6)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
          child: Row(children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                shape: BoxShape.circle,
              ),
              child: Text(fleet.supervisorInitials,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Driver Master & Enrollment',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    Text(
                      '${drivers.length} enrolled drivers',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.7)),
                    ),
                  ]),
            ),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle),
              child: const Icon(Icons.search_rounded,
                  color: Colors.white, size: 20),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildTabBar(int driverCount, int vehicleCount) {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFF2B72F5),
        indicatorWeight: 2.5,
        labelColor: const Color(0xFF2B72F5),
        unselectedLabelColor: const Color(0xFF94A3B8),
        dividerColor: const Color(0xFFE2E8F0),
        labelStyle:
        GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold),
        unselectedLabelStyle:
        GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500),
        tabs: [
          _tabItem('Drivers', driverCount, 0),
          _tabItem('Vehicles', vehicleCount, 1),
        ],
      ),
    );
  }

  Widget _tabItem(String label, int count, int index) => Tab(
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(label),
      const SizedBox(width: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: _tabController.index == index
              ? const Color(0xFF2B72F5)
              : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text('$count',
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _tabController.index == index
                    ? Colors.white
                    : const Color(0xFF64748B))),
      ),
    ]),
  );

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String ctaText,
    required VoidCallback onAdd,
  }) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9), shape: BoxShape.circle),
          child: Icon(icon, size: 40, color: const Color(0xFF94A3B8)),
        ),
        const SizedBox(height: 20),
        Text(title,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.of(context).textPrimary)),
        const SizedBox(height: 6),
        Text(subtitle,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 13, color: const Color(0xFF94A3B8))),
        const SizedBox(height: 24),
        SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: Text(ctaText,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 14, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2B72F5),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 28),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Driver Tab ────────────────────────────────────────────────────
  Widget _buildDriverTab(List<MasterDriver> drivers) {
    return Column(children: [
      Container(
        color: AppTheme.of(context).card,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(children: [
          Expanded(
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(children: [
                const Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    style: GoogleFonts.plusJakartaSans(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search driver name, ID...',
                      hintStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 12, color: const Color(0xFF94A3B8)),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 40,
            child: ElevatedButton.icon(
              onPressed: () => _showEnrollDriverSheet(context),
              icon: const Icon(Icons.add, size: 16),
              label: Text(AppLocalizations.of(context).translate('enroll'),
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
            ),
          ),
        ]),
      ),
      const Divider(height: 1, color: Color(0xFFE2E8F0)),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.only(bottom: 100),
          itemCount: drivers.length,
          itemBuilder: (_, i) => _buildDriverRow(drivers[i], i),
        ),
      ),
    ]);
  }

  Widget _buildDriverRow(MasterDriver d, int index) {
    final isSelected = _selectedDriverIndex == index;
    return Column(children: [
      InkWell(
        onTap: () =>
            setState(() => _selectedDriverIndex = isSelected ? null : index),
        child: Container(
          color: isSelected ? const Color(0xFFEFF6FF) : AppTheme.of(context).card,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            Container(
              width: 3,
              height: 48,
              decoration: BoxDecoration(
                color:
                isSelected ? const Color(0xFF10B981) : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                  color: Color(0xFF1E3A8A), shape: BoxShape.circle),
              child: d.facePhotos.isNotEmpty &&
                  d.facePhotos.values.first.isNotEmpty
                  ? ClipOval(
                  child: Image.file(d.facePhotos.values.first.first,
                      width: 40, height: 40, fit: BoxFit.cover))
                  : Center(
                  child: Text(d.initials,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.name,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.of(context).textPrimary)),
                    const SizedBox(height: 2),
                    Text('${d.empId} · ${d.totalPhotos} photos',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 11, color: const Color(0xFF94A3B8))),
                  ]),
            ),
            _chip(d.licenseStatus, _licenseColor(d.licenseStatus)),
            const SizedBox(width: 6),
            _chip(
                d.enrollment,
                d.enrollment == 'ENROLLED'
                    ? const Color(0xFF10B981)
                    : const Color(0xFFF59E0B)),
          ]),
        ),
      ),
      if (isSelected) _buildDriverDetail(d),
      const Divider(height: 1, color: Color(0xFFF1F5F9)),
    ]);
  }

  Widget _chip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(label,
        style: GoogleFonts.plusJakartaSans(
            fontSize: 9, fontWeight: FontWeight.w700, color: color)),
  );

  // ── Driver Detail ─────────────────────────────────────────────────
  Widget _buildDriverDetail(MasterDriver d) {
    final licColor = _licenseColor(d.licenseStatus);
    return Container(
      color: AppTheme.of(context).surface,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(children: [
        // Profile
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.of(context).card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                  color: Color(0xFF1E3A8A), shape: BoxShape.circle),
              child: d.facePhotos.isNotEmpty &&
                  d.facePhotos.values.first.isNotEmpty
                  ? ClipOval(
                  child: Image.file(d.facePhotos.values.first.first,
                      width: 56, height: 56, fit: BoxFit.cover))
                  : Center(
                  child: Text(d.initials,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.name,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.of(context).textPrimary)),
                    Text('${d.projectSite} · ${d.empId}',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 11, color: const Color(0xFF94A3B8))),
                    const SizedBox(height: 6),
                    Row(children: [
                      _chip(
                          d.status,
                          d.status == 'ACTIVE'
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444)),
                      const SizedBox(width: 6),
                      _chip('${d.totalPhotos} PHOTOS',
                          const Color(0xFF2B72F5)),
                    ]),
                  ]),
            ),
          ]),
        ),
        const SizedBox(height: 10),

        // Details
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.of(context).card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('DRIVER DETAILS',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF94A3B8),
                    letterSpacing: 0.8)),
            const SizedBox(height: 12),
            _row('Email', d.email),
            _row('Mobile', d.mobile),
            _row('License', d.licenseNumber),
            _rowW(
                'Expiry',
                Text(
                    '${_monthName(d.licenseExpiry.month)} ${d.licenseExpiry.year}',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: licColor))),
            _row('Shift', d.shift),
            _row('Project', d.projectSite),
            _row('Vehicle', d.vehicle ?? '—'),
          ]),
        ),
        const SizedBox(height: 10),

        // Photos
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.of(context).card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text('FACE ENROLLMENT',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF94A3B8),
                        letterSpacing: 0.8)),
              ),
              Text('${d.totalPhotos} total',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2B72F5))),
            ]),
            const SizedBox(height: 12),
            for (final cond in d.faceConditions) ...[
              _detailPhotoRow(cond, d.facePhotos[cond] ?? []),
              const SizedBox(height: 10),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _detailPhotoRow(String condition, List<File> photos) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(
          photos.isNotEmpty
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked,
          size: 14,
          color: photos.isNotEmpty
              ? const Color(0xFF10B981)
              : const Color(0xFFCBD5E1),
        ),
        const SizedBox(width: 6),
        Text(condition,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF475569))),
        const SizedBox(width: 6),
        Text('(${photos.length})',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 11, color: const Color(0xFF94A3B8))),
      ]),
      if (photos.isNotEmpty) ...[
        const SizedBox(height: 8),
        SizedBox(
          height: 70,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: photos.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(photos[i],
                    width: 70, height: 70, fit: BoxFit.cover),
              ),
            ),
          ),
        ),
      ],
    ]);
  }

  Widget _row(String l, String v) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, color: const Color(0xFF64748B))),
          Text(v,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.of(context).textPrimary)),
        ]),
  );

  Widget _rowW(String l, Widget w) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, color: const Color(0xFF64748B))),
          w,
        ]),
  );

  // ── Vehicle List ──────────────────────────────────────────────────
  // ...existing code...

  // ── Vehicle Tab with search + register button ─────────────────────
  Widget _buildVehicleList(List vehicles) {
    return Column(children: [
      // Search bar + Register button
      Container(
        color: AppTheme.of(context).card,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(children: [
          Expanded(
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(children: [
                const Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    style: GoogleFonts.plusJakartaSans(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search registration, driver...',
                      hintStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 12, color: const Color(0xFF94A3B8)),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 40,
            child: ElevatedButton.icon(
              onPressed: () => _showAddVehicleSheet(context),
              icon: const Icon(Icons.add, size: 16),
              label: Text(AppLocalizations.of(context).translate('register'),
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
            ),
          ),
        ]),
      ),
      const Divider(height: 1, color: Color(0xFFE2E8F0)),

      // Stats row
      Container(
        color: AppTheme.of(context).card,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          _vehicleStat(
              'Total', vehicles.length, const Color(0xFF1E3A8A)),
          const SizedBox(width: 16),
          _vehicleStat(
              'Active',
              vehicles
                  .where((v) =>
              (v as FleetVehicle).status == VehicleStatus.driving)
                  .length,
              const Color(0xFF10B981)),
          const SizedBox(width: 16),
          _vehicleStat(
              'Idle',
              vehicles
                  .where((v) =>
              (v as FleetVehicle).status == VehicleStatus.idle)
                  .length,
              const Color(0xFFF59E0B)),
          const SizedBox(width: 16),
          _vehicleStat(
              'Alert',
              vehicles
                  .where((v) =>
              (v as FleetVehicle).status == VehicleStatus.alert)
                  .length,
              const Color(0xFFEF4444)),
        ]),
      ),
      const Divider(height: 1, color: Color(0xFFE2E8F0)),

      // Vehicle list
      Expanded(
        child: RefreshIndicator(
          onRefresh: () => context.read<FleetController>().fetchVehicles(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: vehicles.length,
            itemBuilder: (_, i) {
              final v = vehicles[i] as FleetVehicle;
              return _buildVehicleCard(v);
            },
          ),
        ),
      ),
    ]);
  }

  Widget _vehicleStat(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(children: [
          Text('$count',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          Text(label,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 10, color: color.withOpacity(0.8))),
        ]),
      ),
    );
  }

  Widget _buildVehicleCard(FleetVehicle v) {
    final statusColor = _vehicleStatusColor(v.status);
    final statusLabel = _vehicleStatusLabel(v.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.of(context).card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showVehicleDetailsSheet(context, v),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
          // Vehicle icon with status indicator
          Stack(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF2B72F5).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.local_shipping_rounded,
                    color: Color(0xFF2B72F5), size: 24),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(v.registration,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.of(context).textPrimary)),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(statusLabel,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: statusColor)),
                ),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.person_outline_rounded,
                    size: 14, color: Color(0xFF94A3B8)),
                const SizedBox(width: 4),
                Text(v.driverName,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, color: const Color(0xFF94A3B8))),
              ]),
              const SizedBox(height: 4),
        // ...existing code...

        const SizedBox(height: 4),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            // Route
            Row(children: [
              const Icon(Icons.route_rounded,
                  size: 13, color: Color(0xFFCBD5E1)),
              const SizedBox(width: 4),
              ConstrainedBox(
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.3),
                child: Text(v.routeName,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 11, color: const Color(0xFFCBD5E1))),
              ),
            ]),
            // Speed
            if (v.status == VehicleStatus.driving ||
                v.status == VehicleStatus.alert) ...[
              const SizedBox(width: 8),
              Row(children: [
                const Icon(Icons.speed_rounded,
                    size: 13, color: Color(0xFF94A3B8)),
                const SizedBox(width: 3),
                Text('${v.speedKmh.toStringAsFixed(0)} km/h',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: v.speedKmh > 60
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF64748B))),
              ]),
            ],
            // Safety score
            const SizedBox(width: 8),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _scoreColor(v.safetyScore).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('${v.safetyScore}',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _scoreColor(v.safetyScore))),
            ),
          ]),
        ),




              ]),
          ),

          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded,
              size: 20, color: Color(0xFFCBD5E1)),
        ]),
      ),
    )));
  }

  Color _vehicleStatusColor(VehicleStatus status) => switch (status) {
    VehicleStatus.driving => const Color(0xFF10B981),
    VehicleStatus.idle => const Color(0xFFF59E0B),
    VehicleStatus.alert => const Color(0xFFEF4444),
    VehicleStatus.offline => const Color(0xFF94A3B8),
  };

  String _vehicleStatusLabel(VehicleStatus status) => switch (status) {
    VehicleStatus.driving => 'DRIVING',
    VehicleStatus.idle => 'IDLE',
    VehicleStatus.alert => 'ALERT',
    VehicleStatus.offline => 'OFFLINE',
  };

  Color _scoreColor(int score) {
    if (score >= 85) return const Color(0xFF10B981);
    if (score >= 70) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }



  // ═══════════════════════════════════════════════════════════════════
  // ENROLL DRIVER SHEET
  // ═══════════════════════════════════════════════════════════════════
  void _showEnrollDriverSheet(BuildContext context) {
    final fleet = context.read<FleetController>();
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    final licenseCtrl = TextEditingController();
    DateTime licenseExpiry = DateTime.now().add(const Duration(days: 365));
    String selectedProject = 'Hyderabad Yard';
    String selectedShift = 'Morning (6AM–2PM)';
    String? selectedVehicle;
    int step = 0;

    final projects = [
      'Hyderabad Yard',
      'Chennai Metro Site',
      'Bangalore Depot',
      'Mumbai Coastal Road',
      'Pune Material Route',
    ];
    final shifts = [
      'Morning (6AM–2PM)',
      'Afternoon (2PM–10PM)',
      'Night (10PM–6AM)',
      'General',
    ];
    final Map<String, bool> faceConditions = {
      'Normal Face': true,
      'With Spectacles': false,
      'Low Light Cabin': false,
      'Cabin Lighting': false,
      'Fixed Tablet Angle': false,
      'Sunglasses (if permitted)': false,
    };
    final Map<String, List<File>> facePhotos = {};
    final vehicleOptions = ['Select Vehicle', ...fleet.vehicles.map((v) => v.registration)];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final totalPhotos =
          facePhotos.values.fold(0, (s, l) => s + l.length);

          return Container(
            height: MediaQuery.of(ctx).size.height * 0.92,
            decoration: BoxDecoration(
              color: AppTheme.of(context).card,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(children: [
              // ── Sheet header ──
              Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
                decoration: const BoxDecoration(
                  border:
                  Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Row(children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.person_add_alt_1_rounded,
                        color: Color(0xFF1E3A8A), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Enroll New Driver',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.of(context).textPrimary)),
                          Text(
                              step == 0
                                  ? 'Step 1 of 2 — Driver profile'
                                  : 'Step 2 of 2 — Face photos ($totalPhotos uploaded)',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: const Color(0xFF94A3B8))),
                        ]),
                  ),
                  _stepIndicator(step),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded,
                        size: 22, color: Color(0xFF64748B)),
                  ),
                ]),
              ),

              // ── Content ──
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
                  child: step == 0
                      ? _buildProfileStep(
                    formKey, nameCtrl, emailCtrl, mobileCtrl,
                    licenseCtrl, licenseExpiry, selectedProject,
                    selectedVehicle, selectedShift, projects, shifts, vehicleOptions,
                    faceConditions,
                        (v) => setSheet(() => licenseExpiry = v),
                        (v) => setSheet(() => selectedProject = v),
                        (v) => setSheet(() => selectedVehicle = v),
                        (v) => setSheet(() => selectedShift = v),
                        (k, v) => setSheet(() => faceConditions[k] = v),
                  )
                      : _buildFacePhotoStep(
                    faceConditions,
                    facePhotos,
                        (c, f) => setSheet(
                            () => facePhotos.putIfAbsent(c, () => []).add(f)),
                        (c, i) => setSheet(() {
                      facePhotos[c]?.removeAt(i);
                      if (facePhotos[c]?.isEmpty ?? true) {
                        facePhotos.remove(c);
                      }
                    }),
                        (c) => setSheet(() => facePhotos.remove(c)),
                  ),
                ),
              ),

              // ── Bottom bar ──
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                decoration: BoxDecoration(
                  color: AppTheme.of(context).card,
                  border:
                  Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: step == 0
                    ? Row(children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            setSheet(() => step = 1);
                          }
                        },
                        icon: const Icon(Icons.arrow_forward_rounded,
                            size: 18),
                        label: Text('Next: Face Photos',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24),
                      ),
                      child: Text('Cancel',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: const Color(0xFF64748B))),
                    ),
                  ),
                ])
                    : Row(children: [
                  SizedBox(
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () => setSheet(() => step = 0),
                      icon: const Icon(Icons.arrow_back_rounded,
                          size: 16),
                      label: Text('Back',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16),
                        foregroundColor: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () => _submitEnrollment(
                          ctx, nameCtrl, emailCtrl, mobileCtrl,
                          licenseCtrl, licenseExpiry, selectedProject,
                          selectedVehicle, selectedShift,
                          faceConditions, facePhotos,
                        ),
                        icon: const Icon(Icons.check_rounded,
                            size: 18),
                        label: Text(
                            'Submit ($totalPhotos photos)',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ]),
          );
        },
      ),
    );
  }

  void _submitEnrollment(
      BuildContext ctx,
      TextEditingController nameCtrl,
      TextEditingController emailCtrl,
      TextEditingController mobileCtrl,
      TextEditingController licenseCtrl,
      DateTime licenseExpiry,
      String selectedProject,
      String? selectedVehicle,
      String selectedShift,
      Map<String, bool> faceConditions,
      Map<String, List<File>> facePhotos,
      ) {
    final conds =
    faceConditions.entries.where((e) => e.value).map((e) => e.key).toList();
    final total = facePhotos.values.fold(0, (s, l) => s + l.length);

    final driver = MasterDriver(
      name: nameCtrl.text.trim(),
      empId: emailCtrl.text.trim().split('@').first,
      email: emailCtrl.text.trim(),
      mobile: mobileCtrl.text.trim(),
      licenseNumber: licenseCtrl.text.trim(),
      licenseExpiry: licenseExpiry,
      projectSite: selectedProject,
      vehicle: selectedVehicle,
      shift: selectedShift,
      enrollment:
      facePhotos.length >= conds.length && conds.isNotEmpty
          ? 'ENROLLED'
          : 'PARTIAL',
      licenseStatus: _calcLicenseStatus(licenseExpiry),
      faceConditions: conds,
      facePhotos: facePhotos.map((k, v) => MapEntry(k, List<File>.from(v))),
    );

    setState(() {
      _drivers.add(driver);
      _selectedDriverIndex = _drivers.length - 1;
    });

    final fleet = context.read<FleetController>();
    String? assignedVehicleId;
    if (selectedVehicle != null && selectedVehicle != 'Unassigned') {
      try {
        final v = fleet.vehicles.firstWhere((v) => v.registration == selectedVehicle);
        assignedVehicleId = v.id;
      } catch (_) {}
    }

    fleet.enrollDriverApi(
      fullName: nameCtrl.text.trim(),
      email: emailCtrl.text.trim(),
      mobileNumber: mobileCtrl.text.trim(),
      licenseNumber: licenseCtrl.text.trim(),
      licenseExpiry: licenseExpiry,
      assignedProjectSite: selectedProject,
      assignedVehicleId: assignedVehicleId,
      shift: selectedShift,
      faceConditions: faceConditions,
      facePhotos: facePhotos,
    );

    Navigator.pop(ctx);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${driver.name} enrolled with $total photos'),
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF10B981),
    ));
  }

  Widget _stepIndicator(int step) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: step >= 0 ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
          shape: BoxShape.circle,
        ),
        child: step > 0
            ? const Icon(Icons.check, size: 14, color: Colors.white)
            : Text('1',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
      ),
      Container(
          width: 20, height: 2, color: step > 0 ? const Color(0xFF10B981) : const Color(0xFFE2E8F0)),
      Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: step == 1 ? const Color(0xFF1E3A8A) : const Color(0xFFE2E8F0),
          shape: BoxShape.circle,
        ),
        child: Text('2',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: step == 1 ? Colors.white : const Color(0xFF94A3B8))),
      ),
    ]);
  }

  // ── Step 1: Profile ───────────────────────────────────────────────
  Widget _buildProfileStep(
      GlobalKey<FormState> formKey,
      TextEditingController nameCtrl,
      TextEditingController emailCtrl,
      TextEditingController mobileCtrl,
      TextEditingController licenseCtrl,
      DateTime licenseExpiry,
      String selectedProject,
      String? selectedVehicle,
      String selectedShift,
      List<String> projects,
      List<String> shifts,
      List<String> vehicleOptions,
      Map<String, bool> faceConditions,
      Function(DateTime) onExpiryChanged,
      Function(String) onProjectChanged,
      Function(String?) onVehicleChanged,
      Function(String) onShiftChanged,
      Function(String, bool) onConditionChanged,
      ) {
    return Form(
      key: formKey,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 16),
          _sectionLabel('PERSONAL INFORMATION'),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _field('Full Name *', nameCtrl, 'Enter full name', Icons.person_outline)),
            const SizedBox(width: 12),
            Expanded(child: _field('Email *', emailCtrl, 'abc@gmail.com', Icons.email_outlined)),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _field('Mobile *', mobileCtrl, '1234567890', Icons.phone_outlined, keyboard: TextInputType.phone)),
            const SizedBox(width: 12),
            Expanded(child: _field('License No. *', licenseCtrl, 'TG-56-2345', Icons.credit_card_outlined)),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _fieldLabel('LICENSE EXPIRY *'),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: licenseExpiry,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) onExpiryChanged(picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.calendar_today, size: 16, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 8),
                      Text(
                        '${licenseExpiry.day.toString().padLeft(2, '0')}-${licenseExpiry.month.toString().padLeft(2, '0')}-${licenseExpiry.year}',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.of(context).textPrimary),
                      ),
                    ]),
                  ),
                ),
              ]),
            ),
            const SizedBox(width: 12),
            Expanded(child: _dropdown('PROJECT / SITE', selectedProject, projects, onProjectChanged)),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
                child: _dropdown(
                    'VEHICLE',
                    selectedVehicle ?? 'Select Vehicle',
                    vehicleOptions,
                        (v) => onVehicleChanged(v == 'Select Vehicle' ? null : v))),
            const SizedBox(width: 12),
            Expanded(child: _dropdown('SHIFT', selectedShift, shifts, onShiftChanged)),
          ]),
          const SizedBox(height: 20),
          _sectionLabel('FACE ENROLLMENT CONDITIONS'),
          const SizedBox(height: 10),
          Wrap(
            children: faceConditions.entries.map((e) {
              return SizedBox(
                width: MediaQuery.of(context).size.width / 2 - 30,
                child: CheckboxListTile(
                  value: e.value,
                  onChanged: (v) => onConditionChanged(e.key, v!),
                  title: Text(e.key, style: GoogleFonts.plusJakartaSans(fontSize: 12)),
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  activeColor: const Color(0xFF2B72F5),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF92400E)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Consent Notice: Driver\'s written consent for biometric data collection is mandatory before face enrollment.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF92400E)),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Step 2: Face Photos — Multi-photo per condition
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildFacePhotoStep(
      Map<String, bool> conditions,
      Map<String, List<File>> photos,
      Function(String, File) onAdded,
      Function(String, int) onRemoved,
      Function(String) onAllRemoved,
      ) {
    final selected = conditions.entries.where((e) => e.value).toList();
    final total = photos.values.fold(0, (s, l) => s + l.length);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: _sectionLabel(
                '${selected.length} CONDITION(S) · UPLOAD OR CAPTURE PER CONDITION'),
          ),
        ]),
        const SizedBox(height: 6),
        if (total > 0)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              const Icon(Icons.check_circle_outline_rounded,
                  size: 16, color: Color(0xFF10B981)),
              const SizedBox(width: 8),
              Text('$total photo(s) uploaded across ${photos.length} condition(s)',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF10B981))),
            ]),
          ),

        // Per-condition cards
        for (final cond in selected)
          _photoCard(
            cond.key,
            photos[cond.key] ?? [],
                (f) => onAdded(cond.key, f),
                (i) => onRemoved(cond.key, i),
                () => onAllRemoved(cond.key),
          ),

        // Tips
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.lightbulb_outline_rounded,
                size: 16, color: Color(0xFF1E40AF)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Upload multiple photos per condition for better recognition. Face must be clearly visible and well-lit.',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 11, color: const Color(0xFF1E40AF)),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 20),
      ]),
    );
  }

  // ── Photo card per condition ──────────────────────────────────────
  Widget _photoCard(
      String condition,
      List<File> photos,
      Function(File) onAdded,
      Function(int) onRemoved,
      VoidCallback onAllRemoved,
      ) {
    final hasPhotos = photos.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.of(context).card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: hasPhotos
                ? const Color(0xFF10B981).withOpacity(0.3)
                : const Color(0xFFE2E8F0)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(children: [
            Icon(
              hasPhotos
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked,
              size: 20,
              color: hasPhotos
                  ? const Color(0xFF10B981)
                  : const Color(0xFFCBD5E1),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(condition,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.of(context).textPrimary)),
            ),
            if (hasPhotos)
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('${photos.length} photo(s)',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF10B981))),
              ),
          ]),
        ),

        // Photo grid + action buttons
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(children: [
            // Uploaded photos grid
            if (hasPhotos) ...[
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: photos.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Stack(children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(photos[i],
                            width: 100, height: 100, fit: BoxFit.cover),
                      ),
                      Positioned(
                        bottom: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('${i + 1}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => onRemoved(i),
                          child: Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white, width: 1.5),
                            ),
                            child: const Icon(Icons.close,
                                size: 13, color: Colors.white),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Action buttons — always visible
            Row(children: [
              Expanded(
                child: _actionBtn(
                  Icons.camera_alt_rounded,
                  hasPhotos ? 'Add via Camera' : 'Capture Photo',
                  const Color(0xFF2B72F5),
                      () => _capturePhoto(condition, onAdded),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _actionBtn(
                  Icons.photo_library_rounded,
                  hasPhotos ? 'Add from Gallery' : 'Upload Photo',
                  const Color(0xFF7C3AED),
                      () => _uploadPhoto(condition, onAdded),
                ),
              ),
              const SizedBox(width: 10),

            ]),

            // Clear all
            if (hasPhotos) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onAllRemoved,
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: 15, color: Color(0xFFEF4444)),
                  label: Text('Clear All',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 11, color: const Color(0xFFEF4444))),
                  style: TextButton.styleFrom(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _actionBtn(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 10, fontWeight: FontWeight.w600, color: color)),
        ]),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Photo picking
  // ═══════════════════════════════════════════════════════════════════
  Future<void> _capturePhoto(String condition, Function(File) onAdded) async {
    try {
      final XFile? img = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.front,
      );
      if (img != null) onAdded(File(img.path));
    } catch (e) {
      _showError('Camera error: $e');
    }
  }

  Future<void> _uploadPhoto(String condition, Function(File) onAdded) async {
    try {
      final XFile? img = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (img != null) onAdded(File(img.path));
    } catch (e) {
      _showError('Upload error: $e');
    }
  }

  Future<void> _pickMultiplePhotos(
      String condition, Function(File) onAdded) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      for (final img in images) {
        onAdded(File(img.path));
      }
      if (images.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${images.length} photos added for "$condition"'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (e) {
      _showError('Multi-pick error: $e');
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFEF4444),
      ));
    }
  }

  // ── Add Vehicle ───────────────────────────────────────────────────
  // ...existing code...

  // ── Register Vehicle — Full form matching reference design ────────
  void _showAddVehicleSheet(BuildContext context) {
    final fleet = context.read<FleetController>();
    final formKey = GlobalKey<FormState>();
    final regCtrl = TextEditingController();
    final overspeedCtrl = TextEditingController(text: '60');

    // Device dropdown state
    final svc = VehicleRegisterService();
    List<UnassignedDevice> unassignedDevices = [];
    UnassignedDevice? selectedDevice;
    bool loadingDevices = true;

    String vehicleType = 'Tipper Truck';
    String selectedProject = 'Chennai Metro Site';
    String selectedDriver = 'Unassigned';
    String reVerification = '2 minutes';

    final vehicleTypes = [
      'Tipper Truck',
      'Transit Mixer',
      'Flatbed Trailer',
      'Dumper',
      'Tanker',
      'Mini Truck',
      'Pickup',
    ];
    final projects = [
      'Chennai Metro Site',
      'Hyderabad Yard',
      'Bangalore Depot',
      'Mumbai Coastal Road',
      'Pune Material Route',
    ];
    final reVerifyOptions = [
      '1 minute',
      '2 minutes',
      '5 minutes',
      '10 minutes',
      '15 minutes',
      '30 minutes',
    ];

    final Map<String, bool> preChecks = {
      'Front camera operational': false,
      'Road-facing camera operational': false,
      'GPS signal confirmed': false,
      'MDM/Kiosk mode active': false,
      'App installed & signed': false,
      'Mount secure, no tamper': false,
    };

    // Build driver list from API drivers
    final driverOptions = [
      'Unassigned',
      ...fleet.apiDrivers.map((d) => (d['fullName'] ?? 'Unknown').toString()),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          // Fetch devices on first build
          if (loadingDevices && unassignedDevices.isEmpty) {
            svc.fetchUnassignedDevices().then((devices) {
              setSheet(() {
                unassignedDevices = devices;
                loadingDevices = false;
              });
            }).catchError((e) {
              setSheet(() => loadingDevices = false);
            });
          }

          final allChecked = preChecks.values.every((v) => v);
          final checkedCount = preChecks.values.where((v) => v).length;

          return Material(
            color: AppTheme.of(context).card,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            child: SizedBox(
              height: MediaQuery.of(ctx).size.height * 0.92,
              child: Column(children: [
              // ── Header ──
              Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
                decoration: const BoxDecoration(
                  border: Border(
                      bottom: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Row(children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.local_shipping_rounded,
                        color: Color(0xFF1E3A8A), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Register New Vehicle',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.of(context).textPrimary)),
                          Text('Fleet & device configuration',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: const Color(0xFF94A3B8))),
                        ]),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded,
                        size: 22, color: Color(0xFF64748B)),
                  ),
                ]),
              ),

              // ── Form content ──
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: 16,
                      bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
                  child: Form(
                    key: formKey,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Row 1: Registration + Type
                          Row(children: [
                            Expanded(
                              child: _formSection(
                                'VEHICLE REGISTRATION NO.',
                                TextFormField(
                                  controller: regCtrl,
                                  style: GoogleFonts.plusJakartaSans(fontSize: 13),
                                  decoration: _inputDec(
                                      'e.g. TN-48-LT-XXXX',
                                      Icons.directions_car_outlined),
                                  validator: (v) =>
                                  (v == null || v.trim().isEmpty)
                                      ? 'Required'
                                      : null,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _formSection(
                                'VEHICLE TYPE',
                                _dropdownWidget(vehicleType, vehicleTypes,
                                        (v) => setSheet(() => vehicleType = v)),
                              ),
                            ),
                          ]),
                          const SizedBox(height: 16),

                          // Row 2: Project + Driver
                          Row(children: [
                            Expanded(
                              child: _formSection(
                                'ASSIGNED PROJECT / SITE',
                                _dropdownWidget(
                                    selectedProject,
                                    projects,
                                        (v) => setSheet(
                                            () => selectedProject = v)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _formSection(
                                'ASSIGNED DRIVER',
                                _dropdownWidget(
                                    selectedDriver,
                                    driverOptions,
                                        (v) => setSheet(
                                            () => selectedDriver = v)),
                              ),
                            ),
                          ]),
                          const SizedBox(height: 16),

                          // ── Device / Tablet ID ── API dropdown ──
                          _formSection(
                            'DEVICE / TABLET ID *',
                            loadingDevices
                                ? Container(
                                    height: 48,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  )
                                : unassignedDevices.isEmpty
                                    ? Container(
                                        height: 48,
                                        alignment: Alignment.centerLeft,
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEF2F2),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: const Color(0xFFFCA5A5)),
                                        ),
                                        child: Row(children: [
                                          const Icon(Icons.warning_amber_rounded,
                                              size: 16, color: Color(0xFFEF4444)),
                                          const SizedBox(width: 8),
                                          Text('No unassigned devices available',
                                              style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 12, color: const Color(0xFFEF4444))),
                                        ]),
                                      )
                                    : Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: selectedDevice == null
                                                ? const Color(0xFFF59E0B)
                                                : const Color(0xFF10B981),
                                            width: selectedDevice == null ? 1.5 : 1,
                                          ),
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<UnassignedDevice>(
                                            value: selectedDevice,
                                            isExpanded: true,
                                            icon: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (selectedDevice != null)
                                                  const Icon(Icons.check_circle,
                                                      size: 16, color: Color(0xFF10B981))
                                                else
                                                  const Icon(Icons.warning_amber_rounded,
                                                      size: 16, color: Color(0xFFF59E0B)),
                                                const SizedBox(width: 4),
                                                const Icon(Icons.unfold_more_rounded,
                                                    color: Color(0xFF94A3B8), size: 18),
                                              ],
                                            ),
                                            hint: Row(children: [
                                              const Icon(Icons.tablet_android_outlined,
                                                  size: 16, color: Color(0xFF94A3B8)),
                                              const SizedBox(width: 8),
                                              Text('Select registered device',
                                                  style: GoogleFonts.plusJakartaSans(
                                                      fontSize: 13,
                                                      color: const Color(0xFF94A3B8))),
                                            ]),
                                            selectedItemBuilder: (context) =>
                                                unassignedDevices.map((d) => Row(
                                                  children: [
                                                    const Icon(Icons.tablet_android_outlined,
                                                        size: 16, color: Color(0xFF1E3A8A)),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        'IMEI: ${d.deviceId}',
                                                        overflow: TextOverflow.ellipsis,
                                                        style: GoogleFonts.plusJakartaSans(
                                                            fontSize: 13,
                                                            fontWeight: FontWeight.w600,
                                                            color: AppTheme.of(context).textPrimary),
                                                      ),
                                                    ),
                                                  ],
                                                )).toList(),
                                            items: unassignedDevices
                                                .map((d) => DropdownMenuItem<UnassignedDevice>(
                                                      value: d,
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Text(
                                                            'IMEI: ${d.deviceId}',
                                                            style: GoogleFonts.plusJakartaSans(
                                                                fontSize: 13,
                                                                fontWeight: FontWeight.w600,
                                                                color: AppTheme.of(context).textPrimary),
                                                          ),
                                                          Text(
                                                            'Model: ${d.deviceModel}  •  ${d.status}',
                                                            style: GoogleFonts.plusJakartaSans(
                                                                fontSize: 11,
                                                                color: const Color(0xFF94A3B8)),
                                                          ),
                                                        ],
                                                      ),
                                                    ))
                                                .toList(),
                                            onChanged: (v) => setSheet(() => selectedDevice = v),
                                            style: GoogleFonts.plusJakartaSans(
                                                fontSize: 13, color: AppTheme.of(context).textPrimary),
                                          ),
                                        ),
                                      ),
                          ),
                          // Show auto-filled tablet model if device selected
                          if (selectedDevice != null) ...[
                            const SizedBox(height: 12),
                            _formSection(
                              'TABLET MODEL (AUTO-FILLED)',
                              Container(
                                height: 48,
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FDF4),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFF86EFAC)),
                                ),
                                child: Row(children: [
                                  const Icon(Icons.phone_android_outlined,
                                      size: 16, color: Color(0xFF10B981)),
                                  const SizedBox(width: 8),
                                  Text(selectedDevice!.deviceModel,
                                      style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.of(context).textPrimary)),
                                ]),
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          // ── Device Pre-Checks ──
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: allChecked
                                      ? const Color(0xFF10B981)
                                      .withOpacity(0.3)
                                      : const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    const Icon(
                                        Icons.checklist_rtl_rounded,
                                        size: 16,
                                        color: Color(0xFF64748B)),
                                    const SizedBox(width: 8),
                                    Text(
                                        'DEVICE PRE-CHECKS (CONFIRM BEFORE SAVING)',
                                        style: GoogleFonts.plusJakartaSans(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color:
                                            const Color(0xFF64748B),
                                            letterSpacing: 0.5)),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: allChecked
                                            ? const Color(0xFF10B981)
                                            .withOpacity(0.1)
                                            : const Color(0xFFF59E0B)
                                            .withOpacity(0.1),
                                        borderRadius:
                                        BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                          '$checkedCount/${preChecks.length}',
                                          style: GoogleFonts.plusJakartaSans(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: allChecked
                                                  ? const Color(
                                                  0xFF10B981)
                                                  : const Color(
                                                  0xFFF59E0B))),
                                    ),
                                  ]),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    children:
                                    preChecks.entries.map((e) {
                                      return SizedBox(
                                        width: (MediaQuery.of(context)
                                            .size
                                            .width -
                                            72) /
                                            2,
                                        child: InkWell(
                                          onTap: () => setSheet(() =>
                                          preChecks[e.key] =
                                          !e.value),
                                          borderRadius:
                                          BorderRadius.circular(8),
                                          child: Padding(
                                            padding:
                                            const EdgeInsets.symmetric(
                                                vertical: 6),
                                            child: Row(children: [
                                              Container(
                                                width: 20,
                                                height: 20,
                                                decoration: BoxDecoration(
                                                  color: e.value
                                                      ? const Color(
                                                      0xFF2B72F5)
                                                      : Colors.white,
                                                  borderRadius:
                                                  BorderRadius
                                                      .circular(4),
                                                  border: Border.all(
                                                      color: e.value
                                                          ? const Color(
                                                          0xFF2B72F5)
                                                          : const Color(
                                                          0xFFCBD5E1),
                                                      width: 1.5),
                                                ),
                                                child: e.value
                                                    ? const Icon(
                                                    Icons.check,
                                                    size: 14,
                                                    color:
                                                    Colors.white)
                                                    : null,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(e.key,
                                                    style:
                                                    GoogleFonts.plusJakartaSans(
                                                        fontSize: 12,
                                                        color: const Color(
                                                            0xFF475569))),
                                              ),
                                            ]),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ]),
                          ),
                          const SizedBox(height: 16),
                        ]),
                  ),
                ),
              ),

              // ── Bottom buttons ──
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                decoration: BoxDecoration(
                  color: AppTheme.of(context).card,
                  border: Border(
                      top: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Row(children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (selectedDevice == null) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Row(children: [
                                const Icon(Icons.warning_amber_rounded,
                                    color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                const Text('Please select a device / tablet'),
                              ]),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: const Color(0xFFF59E0B),
                            ));
                            return;
                          }
                          if (formKey.currentState!.validate()) {
                            Navigator.pop(ctx);

                            // Add to fleet controller
                            final fleet = context.read<FleetController>();
                            
                            String? selectedDriverId;
                            if (selectedDriver != 'Unassigned') {
                              try {
                                final d = fleet.apiDrivers.firstWhere(
                                  (d) => d['fullName'] == selectedDriver,
                                );
                                selectedDriverId = d['id'];
                              } catch (_) {}
                            }

                            fleet.addVehicle(
                              registration: regCtrl.text.trim(),
                              driverName: selectedDriver == 'Unassigned'
                                  ? 'Unassigned'
                                  : selectedDriver,
                              assignedDriverId: selectedDriverId,
                              vehicleType: vehicleType,
                              assignedProjectSite: selectedProject,
                              deviceTabletId: selectedDevice?.deviceId ?? '',
                              tabletModel: selectedDevice?.deviceModel ?? '',
                              overspeedThreshold: int.tryParse(overspeedCtrl.text) ?? 60,
                              reVerificationInterval: int.tryParse(reVerification.split(' ')[0]) ?? 2,
                              frontCameraOperational: preChecks['Front camera operational'] ?? false,
                              roadFacingCameraOperational: preChecks['Road-facing camera operational'] ?? false,
                              gpsSignalConfirmed: preChecks['GPS signal confirmed'] ?? false,
                              mdmKioskModeActive: preChecks['MDM/Kiosk mode active'] ?? false,
                              appInstalledAndSigned: preChecks['App installed & signed'] ?? false,
                              mountSecureNoTamper: preChecks['Mount secure, no tamper'] ?? false,
                            );

                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(
                              content: Row(children: [
                                const Icon(Icons.check_circle_rounded,
                                    color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                    'Vehicle "${regCtrl.text.trim()}" registered'),
                              ]),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: const Color(0xFF10B981),
                            ));
                          }
                        },
                        icon: const Icon(
                            Icons.local_shipping_rounded,
                            size: 18),
                        label: Text('Register Vehicle',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Cancel',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                color: const Color(0xFF64748B))),
                      ),
                    ),
                  ),
                ]),
              ),
            ]),
          ));
        },
      ),
    );
  }

  // ── Reusable form section ─────────────────────────────────────────
  Widget _formSection(String label, Widget child) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _fieldLabel(label),
      const SizedBox(height: 6),
      child,
    ]);
  }

  // ── Styled dropdown widget ────────────────────────────────────────
  Widget _dropdownWidget(
      String value, List<String> items, Function(String) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.unfold_more_rounded,
              color: Color(0xFF94A3B8), size: 18),
          style: GoogleFonts.plusJakartaSans(
              fontSize: 13, color: AppTheme.of(context).textPrimary),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }

  // ...existing code...

  // ═══════════════════════════════════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════════════════════════════════
  Widget _sectionLabel(String text) => Text(text,
      style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF64748B),
          letterSpacing: 0.8));

  Widget _field(String label, TextEditingController ctrl, String hint,
      IconData icon, {TextInputType keyboard = TextInputType.text}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _fieldLabel(label.toUpperCase()),
      const SizedBox(height: 6),
      TextFormField(
        controller: ctrl,
        keyboardType: keyboard,
        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.of(context).textPrimary),
        decoration: _inputDec(hint, icon),
        validator: label.contains('*')
            ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
            : null,
      ),
    ]);
  }

  Widget _dropdown(String label, String value, List<String> items,
      Function(String) onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _fieldLabel(label),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF94A3B8)),
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.of(context).textPrimary),
            items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ),
      ),
    ]);
  }

  Widget _fieldLabel(String text) => Text(text,
      style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF64748B),
          letterSpacing: 0.5));

  InputDecoration _inputDec(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF94A3B8)),
    prefixIcon: Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2B72F5), width: 1.5)),
    errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444))),
    focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5)),
  );

  Color _licenseColor(String s) => switch (s) {
    'VALID' => const Color(0xFF10B981),
    'EXPIRING' => const Color(0xFFF59E0B),
    'EXPIRED' => const Color(0xFFEF4444),
    _ => const Color(0xFF94A3B8),
  };

  String _calcLicenseStatus(DateTime expiry) {
    final days = expiry.difference(DateTime.now()).inDays;
    if (days <= 0) return 'EXPIRED';
    if (days <= 60) return 'EXPIRING';
    return 'VALID';
  }

  void _showVehicleDetailsSheet(BuildContext context, FleetVehicle vehicle) {
    final raw = vehicle.rawApiData;
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Detailed data not available')),
      );
      return;
    }

    final String vType = raw['vehicleType'] ?? 'Unknown Type';
    final String site = raw['assignedProjectSite'] ?? 'No Site';
    final String deviceId = raw['deviceTabletId'] ?? 'None';
    final String tabModel = raw['tabletModel'] ?? 'Unknown';
    final int overspeed = raw['overspeedThreshold'] ?? 60;
    final int reverify = raw['reVerificationInterval'] ?? 2;
    
    final List drivers = raw['assignedDrivers'] is List ? raw['assignedDrivers'] : [];
    final String driverNames = drivers.isEmpty 
        ? 'Unassigned' 
        : drivers.map((d) => d['fullName'] ?? 'Unknown').join(', ');

    final bool isFrontCam = raw['frontCameraOperational'] == true;
    final bool isRoadCam = raw['roadFacingCameraOperational'] == true;
    final bool isGps = raw['gpsSignalConfirmed'] == true;
    final bool isAppInstalled = raw['appInstalledAndSigned'] == true;
    final bool isMdm = raw['mdmKioskModeActive'] == true;
    final bool isSecure = raw['mountSecureNoTamper'] == true;

    Widget buildRow(IconData icon, String label, String value, {Color? color}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: const Color(0xFF64748B)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF94A3B8))),
                  const SizedBox(height: 2),
                  Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: color ?? AppTheme.of(context).textPrimary)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    Widget buildCheck(String label, bool isOk) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(isOk ? Icons.check_circle_rounded : Icons.cancel_rounded, 
                 size: 16, color: isOk ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF334155))),
          ],
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.of(context).card,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Column(
                  children: [
                    Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFF2B72F5).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.local_shipping_rounded, color: Color(0xFF2B72F5), size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(vehicle.registration, style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.of(context).textPrimary)),
                              Text(vType, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF64748B))),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Assignment Details
                      Text('ASSIGNMENT', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                        child: Column(
                          children: [
                            buildRow(Icons.location_on_rounded, 'Project Site', site),
                            buildRow(Icons.group_rounded, 'Assigned Driver(s)', driverNames),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Hardware Details
                      Text('HARDWARE & CONFIG', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                        child: Column(
                          children: [
                            buildRow(Icons.tablet_mac_rounded, 'Tablet Device ID', deviceId),
                            buildRow(Icons.info_outline_rounded, 'Tablet Model', tabModel),
                            buildRow(Icons.speed_rounded, 'Overspeed Threshold', '$overspeed km/h'),
                            buildRow(Icons.timer_rounded, 'Re-verification Interval', '$reverify hours'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                      
                      // Pre-Checks & Compliance
                      Text('PRE-CHECKS & COMPLIANCE', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            buildCheck('Front Camera Operational', isFrontCam),
                            buildCheck('Road-facing Camera Operational', isRoadCam),
                            buildCheck('GPS Signal Confirmed', isGps),
                            buildCheck('App Installed & Signed', isAppInstalled),
                            buildCheck('MDM / Kiosk Mode Active', isMdm),
                            buildCheck('Mount Secure (No Tamper)', isSecure),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _monthName(int m) => const [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ][m];
}