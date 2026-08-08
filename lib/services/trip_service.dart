import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart';

class TripService {
  static const _base = 'https://proximity-driver-api.prod-app.in/api';

  Future<List<Map<String, dynamic>>> fetchTrips() async {
    final res = await http.get(
      Uri.parse('$_base/trips'),
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

    throw Exception(_extractError(res, 'Unable to load trips'));
  }

  Future<List<Map<String, dynamic>>> fetchTripPoints(String tripId) async {
    final res = await http.get(
      Uri.parse('$_base/trips/$tripId/points'),
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

    throw Exception(_extractError(res, 'Unable to load trip points'));
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
