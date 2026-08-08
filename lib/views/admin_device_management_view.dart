import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../controllers/fleet_controller.dart';
import '../services/admin_service.dart';
import '../services/device_service.dart';
import 'theme/app_theme.dart';

class AdminDeviceManagementView extends StatefulWidget {
  const AdminDeviceManagementView({super.key});

  @override
  State<AdminDeviceManagementView> createState() =>
      _AdminDeviceManagementViewState();
}

class _AdminDeviceManagementViewState extends State<AdminDeviceManagementView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _adminService = AdminService();
  final _deviceService = DeviceService();

  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _admins = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _devices = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _adminService.fetchAdmins(),
        _deviceService.fetchDevices(),
      ]);

      if (!mounted) return;
      setState(() {
        _admins = results[0];
        _devices = results[1];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);

    return Scaffold(
      backgroundColor: colors.surface,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            _showAdminDialog();
          } else {
            _showDeviceDialog();
          }
        },
        icon: const Icon(Icons.add),
        label: Text(
          _tabController.index == 0 ? 'Add Admin' : 'Add Device',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelStyle: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
            ),
            tabs: const [
              Tab(text: 'Admins'),
              Tab(text: 'Devices'),
            ],
          ),
          Expanded(
            child: Stack(
              children: [
                if (_error != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _error!,
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.danger,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  TabBarView(
                    controller: _tabController,
                    children: [_buildAdminsTab(), _buildDevicesTab()],
                  ),
                if (_loading)
                  Positioned.fill(
                    child: Container(
                      color: colors.surface.withValues(alpha: 0.5),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminsTab() {
    final colors = AppTheme.of(context);

    if (_admins.isEmpty) {
      return _emptyState('No admins found', 'Create your first admin user.');
    }

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: _admins.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final admin = _admins[index];
          final name = (admin['fullName'] ?? 'Unknown').toString();
          final email = (admin['email'] ?? '-').toString();
          final role = (admin['role'] ?? '-').toString();
          final id = (admin['id'] ?? '').toString();
          final isActive = admin['isActive'] == true;

          return Container(
            decoration: AppTheme.cardDecoration(
              context,
              borderColor: colors.cardBorder,
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: GoogleFonts.plusJakartaSans(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    _statusChip(isActive ? 'ACTIVE' : 'INACTIVE', isActive),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  email,
                  style: GoogleFonts.plusJakartaSans(
                    color: colors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Role: $role',
                  style: GoogleFonts.plusJakartaSans(
                    color: colors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showAdminDialog(existing: admin),
                        child: const Text('Edit'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: id.isEmpty ? null : () => _deleteAdmin(id),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.danger,
                        ),
                        child: const Text('Delete'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDevicesTab() {
    final colors = AppTheme.of(context);

    if (_devices.isEmpty) {
      return _emptyState(
        'No devices found',
        'Register hardware devices from here.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: _devices.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final device = _devices[index];
          final id = (device['id'] ?? '').toString();
          final deviceId = (device['deviceId'] ?? '-').toString();
          final model = (device['deviceModel'] ?? '-').toString();
          final type = (device['deviceType'] ?? '-').toString();
          final os = (device['osVersion'] ?? '-').toString();
          final manufacturer = (device['manufacturer'] ?? '-').toString();
          final assignedVehicleId = device['assignedVehicleId']?.toString();

          return Container(
            decoration: AppTheme.cardDecoration(
              context,
              borderColor: colors.cardBorder,
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        deviceId,
                        style: GoogleFonts.plusJakartaSans(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    _statusChip(
                      assignedVehicleId == null || assignedVehicleId.isEmpty
                          ? 'UNASSIGNED'
                          : 'ASSIGNED',
                      assignedVehicleId != null && assignedVehicleId.isNotEmpty,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Model: $model',
                  style: GoogleFonts.plusJakartaSans(
                    color: colors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Type: $type',
                  style: GoogleFonts.plusJakartaSans(
                    color: colors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                Text(
                  'OS: $os',
                  style: GoogleFonts.plusJakartaSans(
                    color: colors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Manufacturer: $manufacturer',
                  style: GoogleFonts.plusJakartaSans(
                    color: colors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                if (assignedVehicleId != null && assignedVehicleId.isNotEmpty)
                  Text(
                    'Vehicle: $assignedVehicleId',
                    style: GoogleFonts.plusJakartaSans(
                      color: colors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: () => _showDeviceDialog(existing: device),
                      child: const Text('Edit'),
                    ),
                    OutlinedButton(
                      onPressed: () => _showAssignDialog(deviceId: id),
                      child: const Text('Assign'),
                    ),
                    OutlinedButton(
                      onPressed: () => _unassignDevice(id),
                      child: const Text('Unassign'),
                    ),
                    OutlinedButton(
                      onPressed: () => _deleteDevice(id),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.danger,
                      ),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statusChip(String text, bool positive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: positive
            ? AppTheme.success.withValues(alpha: 0.1)
            : AppTheme.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: positive ? AppTheme.success : AppTheme.warning,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _emptyState(String title, String subtitle) {
    final colors = AppTheme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_rounded, size: 38, color: colors.textMuted),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(color: colors.textMuted),
          ),
        ],
      ),
    );
  }

  Future<void> _showAdminDialog({Map<String, dynamic>? existing}) async {
    final fullNameController = TextEditingController(
      text: (existing?['fullName'] ?? '').toString(),
    );
    final emailController = TextEditingController(
      text: (existing?['email'] ?? '').toString(),
    );
    final passwordController = TextEditingController();
    final roleController = TextEditingController(
      text: (existing?['role'] ?? 'Supervisor').toString(),
    );
    bool isActive = existing?['isActive'] == true;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setInner) => AlertDialog(
          title: Text(existing == null ? 'Add Admin' : 'Edit Admin'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _textField(controller: fullNameController, label: 'Full Name'),
                const SizedBox(height: 8),
                _textField(controller: emailController, label: 'Email'),
                const SizedBox(height: 8),
                _textField(controller: roleController, label: 'Role'),
                const SizedBox(height: 8),
                _textField(
                  controller: passwordController,
                  label: existing == null
                      ? 'Password'
                      : 'New Password (optional)',
                  obscure: true,
                ),
                if (existing != null)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: isActive,
                    onChanged: (v) => setInner(() => isActive = v),
                    title: const Text('Active'),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final name = fullNameController.text.trim();
                final email = emailController.text.trim();
                final role = roleController.text.trim();
                final password = passwordController.text;

                if (name.isEmpty ||
                    email.isEmpty ||
                    role.isEmpty ||
                    (existing == null && password.isEmpty)) {
                  _snack('Please fill all required fields', danger: true);
                  return;
                }

                Navigator.pop(context);
                try {
                  setState(() => _loading = true);
                  if (existing == null) {
                    await _adminService.createAdmin(
                      fullName: name,
                      email: email,
                      password: password,
                      role: role,
                    );
                  } else {
                    await _adminService.updateAdmin(
                      id: existing['id'].toString(),
                      fullName: name,
                      email: email,
                      role: role,
                      isActive: isActive,
                      password: password.isEmpty ? null : password,
                    );
                  }
                  await _loadAll();
                  _snack(existing == null ? 'Admin created' : 'Admin updated');
                } catch (e) {
                  _snack(
                    e.toString().replaceFirst('Exception: ', ''),
                    danger: true,
                  );
                } finally {
                  if (mounted) {
                    setState(() => _loading = false);
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeviceDialog({Map<String, dynamic>? existing}) async {
    final deviceIdController = TextEditingController(
      text: (existing?['deviceId'] ?? '').toString(),
    );
    final modelController = TextEditingController(
      text: (existing?['deviceModel'] ?? '').toString(),
    );
    final osController = TextEditingController(
      text: (existing?['osVersion'] ?? '').toString(),
    );
    final typeController = TextEditingController(
      text: (existing?['deviceType'] ?? 'Tablet').toString(),
    );
    final manufacturerController = TextEditingController(
      text: (existing?['manufacturer'] ?? '').toString(),
    );
    final notesController = TextEditingController(
      text: (existing?['notes'] ?? '').toString(),
    );

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'Add Device' : 'Edit Device'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (existing == null) ...[
                _textField(controller: deviceIdController, label: 'Device ID'),
                const SizedBox(height: 8),
              ],
              _textField(controller: modelController, label: 'Device Model'),
              const SizedBox(height: 8),
              _textField(controller: osController, label: 'OS Version'),
              const SizedBox(height: 8),
              _textField(controller: typeController, label: 'Device Type'),
              const SizedBox(height: 8),
              _textField(
                controller: manufacturerController,
                label: 'Manufacturer',
              ),
              const SizedBox(height: 8),
              _textField(controller: notesController, label: 'Notes'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final model = modelController.text.trim();
              final os = osController.text.trim();
              final type = typeController.text.trim();
              final manufacturer = manufacturerController.text.trim();
              final notes = notesController.text.trim();

              if (model.isEmpty ||
                  os.isEmpty ||
                  type.isEmpty ||
                  manufacturer.isEmpty) {
                _snack('Please fill all required fields', danger: true);
                return;
              }

              if (existing == null && deviceIdController.text.trim().isEmpty) {
                _snack('Device ID is required', danger: true);
                return;
              }

              Navigator.pop(context);
              try {
                setState(() => _loading = true);
                if (existing == null) {
                  await _deviceService.createDevice(
                    deviceId: deviceIdController.text.trim(),
                    deviceModel: model,
                    osVersion: os,
                    deviceType: type,
                    manufacturer: manufacturer,
                    notes: notes,
                  );
                } else {
                  await _deviceService.updateDevice(
                    id: existing['id'].toString(),
                    deviceModel: model,
                    osVersion: os,
                    deviceType: type,
                    manufacturer: manufacturer,
                    notes: notes,
                  );
                }
                await _loadAll();
                _snack(existing == null ? 'Device created' : 'Device updated');
              } catch (e) {
                _snack(
                  e.toString().replaceFirst('Exception: ', ''),
                  danger: true,
                );
              } finally {
                if (mounted) {
                  setState(() => _loading = false);
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAssignDialog({required String deviceId}) async {
    final vehicles = context.read<FleetController>().vehicles;
    if (vehicles.isEmpty) {
      _snack('No vehicles available to assign', danger: true);
      return;
    }

    String selectedVehicleId = vehicles.first.id;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setInner) => AlertDialog(
          title: const Text('Assign Device'),
          content: DropdownButtonFormField<String>(
            initialValue: selectedVehicleId,
            items: vehicles
                .map(
                  (v) => DropdownMenuItem<String>(
                    value: v.id,
                    child: Text('${v.registration} (${v.id})'),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setInner(() => selectedVehicleId = value);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  setState(() => _loading = true);
                  await _deviceService.assignDevice(
                    id: deviceId,
                    vehicleId: selectedVehicleId,
                  );
                  await _loadAll();
                  _snack('Device assigned');
                } catch (e) {
                  _snack(
                    e.toString().replaceFirst('Exception: ', ''),
                    danger: true,
                  );
                } finally {
                  if (mounted) {
                    setState(() => _loading = false);
                  }
                }
              },
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteAdmin(String id) async {
    final confirmed = await _confirm('Delete this admin?');
    if (!confirmed) return;

    try {
      setState(() => _loading = true);
      await _adminService.deleteAdmin(id);
      await _loadAll();
      _snack('Admin deleted');
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''), danger: true);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _deleteDevice(String id) async {
    final confirmed = await _confirm('Delete this device?');
    if (!confirmed) return;

    try {
      setState(() => _loading = true);
      await _deviceService.deleteDevice(id);
      await _loadAll();
      _snack('Device deleted');
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''), danger: true);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _unassignDevice(String id) async {
    try {
      setState(() => _loading = true);
      await _deviceService.unassignDevice(id: id);
      await _loadAll();
      _snack('Device unassigned');
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''), danger: true);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<bool> _confirm(String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  void _snack(String message, {bool danger = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: danger ? AppTheme.danger : null,
      ),
    );
  }
}
