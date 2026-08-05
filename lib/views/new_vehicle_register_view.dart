import 'package:flutter/material.dart';
import '../models/unassigned_device.dart';
import '../services/vehicle_register_service.dart';

class NewVehicleRegisterView extends StatefulWidget {
  const NewVehicleRegisterView({super.key});

  @override
  State<NewVehicleRegisterView> createState() => _NewVehicleRegisterViewState();
}

class _NewVehicleRegisterViewState extends State<NewVehicleRegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _svc = VehicleRegisterService();

  final _regController = TextEditingController();
  final _typeController = TextEditingController();

  List<UnassignedDevice> _devices = [];
  UnassignedDevice? _selectedDevice;

  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    try {
      final devices = await _svc.fetchUnassignedDevices();
      if (!mounted) return;
      setState(() {
        _devices = devices;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showSnack('Failed to load devices: $e', isError: true);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await _svc.registerVehicle({
        'vehicleRegistrationNumber': _regController.text.trim(),
        'vehicleType': _typeController.text.trim(),
        'deviceTabletId': _selectedDevice!.deviceId,
        'tabletModel': _selectedDevice!.deviceModel,
      });
      if (!mounted) return;
      _showSnack('Vehicle registered successfully');
      Navigator.pop(context, true);
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    _regController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register New Vehicle')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Registration number
                  TextFormField(
                    controller: _regController,
                    decoration: const InputDecoration(
                      labelText: 'Registration Number',
                      hintText: 'e.g. KL-55-L4626',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  // Vehicle type
                  TextFormField(
                    controller: _typeController,
                    decoration: const InputDecoration(
                      labelText: 'Vehicle Type',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  // ── Tablet Device ID — DROPDOWN (was text field) ──
                  DropdownButtonFormField<UnassignedDevice>(
                    value: _selectedDevice,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Tablet Device ID',
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text('Select unassigned device'),
                    items: _devices
                        .map(
                          (d) => DropdownMenuItem(
                            value: d,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  d.deviceId,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${d.deviceModel}  •  ${d.osVersion}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedDevice = v),
                    validator: (v) =>
                        v == null ? 'Please select a device' : null,
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Register Vehicle'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
