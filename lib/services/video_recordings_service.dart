import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart';

class VideoRecordingsService {
  static const _base = 'https://proximity-driver-api.prod-app.in/api';

  Future<List<Map<String, dynamic>>> fetchRecordings() async {
    final res = await http.get(
      Uri.parse('$_base/video-recordings'),
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
      if (data is Map && data['items'] is List) {
        return (data['items'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      return <Map<String, dynamic>>[];
    }

    throw Exception(_extractError(res, 'Unable to load video recordings'));
  }

  Future<List<Map<String, dynamic>>> fetchByVehicle(String vehicleId) async {
    final res = await http.get(
      Uri.parse('$_base/video-recordings/vehicle/$vehicleId'),
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

    throw Exception(_extractError(res, 'Unable to load vehicle recordings'));
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
