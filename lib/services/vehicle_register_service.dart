import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/unassigned_device.dart';
import 'auth_service.dart';

class VehicleRegisterService {
  static const _base = 'https://proximity-driver-api.prod-app.in/api';

  Future<List<UnassignedDevice>> fetchUnassignedDevices() async {
    final res = await http.get(
      Uri.parse('$_base/devices/unassigned'),
      headers: AuthService.instance.authHeaders,
    );
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List)
          .map((e) => UnassignedDevice.fromJson(e))
          .toList();
    }
    throw Exception('Failed to load devices (${res.statusCode})');
  }

  Future<void> registerVehicle(Map<String, dynamic> payload) async {
    final res = await http.post(
      Uri.parse('$_base/vehicle'),
      headers: AuthService.instance.authJsonHeaders,
      body: jsonEncode(payload),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Registration failed (${res.statusCode}): ${res.body}');
    }
  }
}
