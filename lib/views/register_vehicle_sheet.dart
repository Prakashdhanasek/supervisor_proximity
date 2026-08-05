import 'package:flutter/material.dart';
import '../models/unassigned_device.dart';
import '../services/vehicle_register_service.dart';

class RegisterVehicleSheet extends StatefulWidget {
  const RegisterVehicleSheet({super.key});

  @override
  State<RegisterVehicleSheet> createState() => _RegisterVehicleSheetState();
}

class _RegisterVehicleSheetState extends State<RegisterVehicleSheet> {
  final _svc = VehicleRegisterService();
  final _formKey = GlobalKey<FormState>();
  final _regNoController = TextEditingController();

  String? _vehicleType;
  String? _assignedSite;
  String? _assignedDriver;

  List<UnassignedDevice> _devices = [];
  UnassignedDevice? _selectedDevice;
  bool _loadingDevices = true;

  // ── Add this controller as a class field ──────────────────────
  final _tabletModelController = TextEditingController();

  // Pre-checks (6 total)
  bool _selectAll = false;
  bool _frontCamera = false;
  bool _roadCamera = false;
  bool _gpsSignal = false;
  bool _mdmKiosk = false;
  bool _appSigned = false;
  bool _mountSecure = false;
  bool _submitting = false;

  int get _checkedCount => [
    _frontCamera,
    _roadCamera,
    _gpsSignal,
    _mdmKiosk,
    _appSigned,
    _mountSecure,
  ].where((b) => b).length;

  @override
  void initState() {
    super.initState();
    _fetchDevices();
  }

  Future<void> _fetchDevices() async {
    try {
      final devices = await _svc.fetchUnassignedDevices();
      if (!mounted) return;
      setState(() {
        _devices = devices;
        _loadingDevices = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingDevices = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load devices: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onSelectAll(bool? v) {
    setState(() {
      _selectAll = v ?? false;
      _frontCamera = _roadCamera = _gpsSignal = _mdmKiosk = _appSigned =
          _mountSecure = _selectAll;
    });
  }

  void _syncSelectAll() {
    _selectAll =
        _frontCamera &&
        _roadCamera &&
        _gpsSignal &&
        _mdmKiosk &&
        _appSigned &&
        _mountSecure;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    // Guard: device must be selected
    if (_selectedDevice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a device / tablet'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await _svc.registerVehicle({
        'vehicleRegistrationNumber': _regNoController.text.trim(),
        'vehicleType': _vehicleType,
        'assignedProjectSite': _assignedSite,
        'assignedDriverId': _assignedDriver,
        'deviceTabletId': _selectedDevice!.deviceId, // ← IMEI, never empty
        'tabletModel': _selectedDevice!.deviceModel,
        'frontCameraOperational': _frontCamera,
        'roadFacingCameraOperational': _roadCamera,
        'gpsSignalConfirmed': _gpsSignal,
        'mdmKioskModeActive': _mdmKiosk,
        'appInstalledAndSigned': _appSigned,
        'mountSecureNoTamper': _mountSecure,
      });
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _regNoController.dispose();
    _tabletModelController.dispose(); // dispose it here
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ──────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.local_shipping,
                      color: Color(0xFF1A237E),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Register New Vehicle',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Fleet & device configuration',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
              const Divider(height: 28),

              // ── Row 1: Reg No + Vehicle Type ────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _field(
                      label: 'VEHICLE REGISTRATION NO.',
                      child: TextFormField(
                        controller: _regNoController,
                        decoration: _dec(
                          hint: 'e.g. TN-48-LT-XXXX',
                          prefixIcon: Icons.directions_car_outlined,
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      label: 'VEHICLE TYPE',
                      child: DropdownButtonFormField<String>(
                        value: _vehicleType,
                        isExpanded: true,
                        decoration: _dec(),
                        hint: const Text(
                          'Select type',
                          style: TextStyle(fontSize: 13),
                        ),
                        items: ['Dumper', 'Truck', 'Bus', 'Van', 'Tipper']
                            .map(
                              (t) => DropdownMenuItem(value: t, child: Text(t)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _vehicleType = v),
                        validator: (v) => v == null ? 'Required' : null,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Row 2: Project/Site + Driver ────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _field(
                      label: 'ASSIGNED PROJECT / SITE',
                      child: DropdownButtonFormField<String>(
                        value: _assignedSite,
                        isExpanded: true,
                        decoration: _dec(),
                        hint: const Text(
                          'Select site',
                          style: TextStyle(fontSize: 13),
                        ),
                        items:
                            [
                                  'Chennai Metro Site',
                                  'Bangalore Depot',
                                  'Delhi Hub',
                                ]
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) => setState(() => _assignedSite = v),
                        validator: (v) => v == null ? 'Required' : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      label: 'ASSIGNED DRIVER',
                      child: DropdownButtonFormField<String>(
                        value: _assignedDriver,
                        isExpanded: true,
                        decoration: _dec(),
                        hint: const Text(
                          'Unassigned',
                          style: TextStyle(fontSize: 13),
                        ),
                        items: ['Unassigned', 'sureshm', 'Maneesha manu']
                            .map(
                              (d) => DropdownMenuItem(value: d, child: Text(d)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _assignedDriver = v),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Device / Tablet ID — full width dropdown ────────
              _field(
                label: 'DEVICE / TABLET ID *',
                child: _loadingDevices
                    ? const SizedBox(
                        height: 48,
                        child: Center(child: LinearProgressIndicator()),
                      )
                    : _devices.isEmpty
                    ? Container(
                        height: 48,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.red.shade300),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.red.shade50,
                        ),
                        child: const Text(
                          'No unassigned devices available',
                          style: TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      )
                    : DropdownButtonFormField<UnassignedDevice>(
                        value: _selectedDevice,
                        isExpanded: true,
                        decoration: InputDecoration(
                          hintText: 'Select registered device',
                          hintStyle: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                          prefixIcon: const Icon(
                            Icons.tablet_android_outlined,
                            size: 18,
                          ),
                          // highlight red border when nothing selected
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: _selectedDevice == null
                                  ? Colors.orange.shade400
                                  : const Color(0xFFD1D5DB),
                              width: _selectedDevice == null ? 1.5 : 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF1A237E),
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          suffixIcon: _selectedDevice == null
                              ? const Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.orange,
                                  size: 18,
                                )
                              : const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 18,
                                ),
                        ),
                        hint: const Text(
                          '— Select registered device —',
                          style: TextStyle(fontSize: 13),
                        ),
                        selectedItemBuilder: (context) => _devices
                            .map(
                              (d) => Text(
                                'IMEI: ${d.deviceId}',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                            .toList(),
                        items: _devices
                            .map(
                              (d) => DropdownMenuItem<UnassignedDevice>(
                                value: d,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'IMEI: ${d.deviceId}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'Model: ${d.deviceModel}  •  ${d.status}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() {
                          _selectedDevice = v;
                          _tabletModelController.text = v?.deviceModel ?? '';
                        }),
                        validator: (v) =>
                            v == null ? 'Please select a device' : null,
                      ),
              ),
              const SizedBox(height: 14),

              // ── Tablet Model — full width, auto-filled ──────────
              _field(
                label: 'TABLET MODEL',
                child: TextFormField(
                  readOnly: true,
                  controller: _tabletModelController,
                  style: const TextStyle(fontSize: 13),
                  decoration: _dec(
                    hint: 'Auto-filled after device selection',
                    prefixIcon: Icons.phone_android_outlined,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // ── Device Pre-Checks Card ──────────────────────────
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row(
                    //   children: [
                    //     const Icon(
                    //       Icons.checklist,
                    //       size: 16,
                    //       color: Colors.grey,
                    //     ),
                    //     const SizedBox(width: 6),
                    //     Expanded(
                    //       child: Text(
                    //         'DEVICE PRE-CHECKS (CONFIRM BEFORE SAVING)',
                    //         style: TextStyle(
                    //           fontSize: 11,
                    //           fontWeight: FontWeight.w700,
                    //           color: Colors.grey[500],
                    //           letterSpacing: 0.4,
                    //         ),
                    //       ),
                    //     ),
                    //     // X/6 badge
                    //     Container(
                    //       padding: const EdgeInsets.symmetric(
                    //         horizontal: 8,
                    //         vertical: 2,
                    //       ),
                    //       decoration: BoxDecoration(
                    //         color: _checkedCount == 6
                    //             ? Colors.green[100]
                    //             : Colors.orange[100],
                    //         borderRadius: BorderRadius.circular(12),
                    //       ),
                    //       child: Text(
                    //         '$_checkedCount/6',
                    //         style: TextStyle(
                    //           fontSize: 12,
                    //           fontWeight: FontWeight.bold,
                    //           color: _checkedCount == 6
                    //               ? Colors.green[800]
                    //               : Colors.orange[800],
                    //         ),
                    //       ),
                    // //     ),
                    // //   ],
                    // // ),
                    // // Select All
                    // Row(
                    //   children: [
                    //     Checkbox(value: _selectAll, onChanged: _onSelectAll),
                    //     const Text(
                    //       'Select All',
                    //       style: TextStyle(
                    //         fontWeight: FontWeight.bold,
                    //         fontSize: 14,
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    // const Divider(height: 8),
                    // _checkTile(
                    //   'Front camera operational',
                    //   _frontCamera,
                    //   (v) => setState(() {
                    //     _frontCamera = v ?? false;
                    //     _syncSelectAll();
                    //   }),
                    // ),
                    // _checkTile(
                    //   'Road-facing camera operational',
                    //   _roadCamera,
                    //   (v) => setState(() {
                    //     _roadCamera = v ?? false;
                    //     _syncSelectAll();
                    //   }),
                    // ),
                    // _checkTile(
                    //   'GPS signal confirmed',
                    //   _gpsSignal,
                    //   (v) => setState(() {
                    //     _gpsSignal = v ?? false;
                    //     _syncSelectAll();
                    //   }),
                    // ),
                    // _checkTile(
                    //   'MDM/Kiosk mode active',
                    //   _mdmKiosk,
                    //   (v) => setState(() {
                    //     _mdmKiosk = v ?? false;
                    //     _syncSelectAll();
                    //   }),
                    // ),
                    // _checkTile(
                    //   'App installed & signed',
                    //   _appSigned,
                    //   (v) => setState(() {
                    //     _appSigned = v ?? false;
                    //     _syncSelectAll();
                    //   }),
                    // ),
                    // _checkTile(
                    //   'Mount secure / no tamper',
                    //   _mountSecure,
                    //   (v) => setState(() {
                    //     _mountSecure = v ?? false;
                    //     _syncSelectAll();
                    //   }),
                    // ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Buttons ─────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A237E),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _submitting ? null : _submit,
                      icon: _submitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.local_shipping,
                              color: Colors.white,
                              size: 18,
                            ),
                      label: const Text(
                        'Register Vehicle',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────

  Widget _field({required String label, required Widget child}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.grey[600],
          letterSpacing: 0.4,
        ),
      ),
      const SizedBox(height: 6),
      child,
    ],
  );

  Widget _checkTile(String label, bool value, ValueChanged<bool?> onChange) =>
      CheckboxListTile(
        value: value,
        onChanged: onChange,
        title: Text(label, style: const TextStyle(fontSize: 13)),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
        dense: true,
      );

  InputDecoration _dec({String? hint, IconData? prefixIcon}) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
    prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18) : null,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF1A237E)),
    ),
  );
}
