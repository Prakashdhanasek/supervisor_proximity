import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart';

class GeofenceService {
  static const _base = 'https://proximity-driver-api.prod-app.in/api';

  Future<List<Map<String, dynamic>>> fetchGeofences() async {
    final res = await http.get(
      Uri.parse('$_base/geofences'),
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

    throw Exception(_extractError(res, 'Unable to load geofences'));
  }

  Future<List<Map<String, dynamic>>> fetchViolations() async {
    final res = await http.get(
      Uri.parse('$_base/geofences/violations'),
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

    throw Exception(_extractError(res, 'Unable to load geofence violations'));
  }

  String _extractError(http.Response res, String fallback) {
    try {
      final parsed = jsonDecode(res.body);
      if (parsed is Map && parsed['message'] != null) {
        return parsed['message'].toString();
      }
    } catch (_) {}
    return '$fallback (${res.statusCode})';
  }
}
