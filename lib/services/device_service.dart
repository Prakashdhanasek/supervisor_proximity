import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart';

class DeviceService {
  static const _base = 'https://proximity-driver-api.prod-app.in/api';

  Future<List<Map<String, dynamic>>> fetchDevices() async {
    final res = await http.get(
      Uri.parse('$_base/devices'),
      headers: AuthService.instance.authHeaders,
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data is List) {
        return data
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      return <Map<String, dynamic>>[];
    }

    throw Exception(_extractError(res, 'Unable to load devices'));
  }

  Future<List<Map<String, dynamic>>> fetchUnassignedDevices() async {
    final res = await http.get(
      Uri.parse('$_base/devices/unassigned'),
      headers: AuthService.instance.authHeaders,
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data is List) {
        return data
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      return <Map<String, dynamic>>[];
    }

    throw Exception(_extractError(res, 'Unable to load unassigned devices'));
  }

  Future<void> createDevice({
    required String deviceId,
    required String deviceModel,
    required String osVersion,
    required String deviceType,
    required String manufacturer,
    required String notes,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/devices'),
      headers: AuthService.instance.authJsonHeaders,
      body: jsonEncode({
        'deviceId': deviceId,
        'deviceModel': deviceModel,
        'osVersion': osVersion,
        'deviceType': deviceType,
        'manufacturer': manufacturer,
        'notes': notes,
      }),
    );

    if (res.statusCode == 200 ||
        res.statusCode == 201 ||
        res.statusCode == 204) {
      return;
    }

    throw Exception(_extractError(res, 'Unable to create device'));
  }

  Future<void> updateDevice({
    required String id,
    required String deviceModel,
    required String osVersion,
    required String deviceType,
    required String manufacturer,
    required String notes,
  }) async {
    final res = await http.put(
      Uri.parse('$_base/devices/$id'),
      headers: AuthService.instance.authJsonHeaders,
      body: jsonEncode({
        'deviceModel': deviceModel,
        'osVersion': osVersion,
        'deviceType': deviceType,
        'manufacturer': manufacturer,
        'notes': notes,
      }),
    );

    if (res.statusCode == 200 || res.statusCode == 204) {
      return;
    }

    throw Exception(_extractError(res, 'Unable to update device'));
  }

  Future<void> deleteDevice(String id) async {
    final res = await http.delete(
      Uri.parse('$_base/devices/$id'),
      headers: AuthService.instance.authHeaders,
    );

    if (res.statusCode == 200 || res.statusCode == 204) {
      return;
    }

    throw Exception(_extractError(res, 'Unable to delete device'));
  }

  Future<void> assignDevice({
    required String id,
    required String vehicleId,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/devices/$id/assign/$vehicleId'),
      headers: AuthService.instance.authHeaders,
    );

    if (res.statusCode == 200 || res.statusCode == 204) {
      return;
    }

    throw Exception(_extractError(res, 'Unable to assign device'));
  }

  Future<void> unassignDevice({required String id}) async {
    final res = await http.post(
      Uri.parse('$_base/devices/$id/unassign'),
      headers: AuthService.instance.authHeaders,
    );

    if (res.statusCode == 200 || res.statusCode == 204) {
      return;
    }

    throw Exception(_extractError(res, 'Unable to unassign device'));
  }

  String _extractError(http.Response res, String fallback) {
    try {
      final parsed = jsonDecode(res.body);
      if (parsed is Map && parsed['message'] != null) {
        return parsed['message'].toString();
      }
    } catch (_) {
      // Ignore JSON parse errors and use fallback.
    }
    return '$fallback (${res.statusCode})';
  }
}
