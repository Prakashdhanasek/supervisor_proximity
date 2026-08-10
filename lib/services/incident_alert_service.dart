import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/incident_alert_setting.dart';
import 'auth_service.dart';

class IncidentAlertService {
  static const _base = 'https://proximity-driver-api.prod-app.in/api';

  Future<List<IncidentAlertSetting>> fetchIncidentAlerts() async {
    final res = await http.get(
      Uri.parse('$_base/settings/incident-alerts'),
      headers: AuthService.instance.authHeaders,
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data is List) {
        return data
            .whereType<Map>()
            .map(
              (e) =>
                  IncidentAlertSetting.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList();
      }
      return <IncidentAlertSetting>[];
    }

    throw Exception(_extractError(res, 'Unable to load incident alerts'));
  }

  Future<void> updateIncidentAlert(IncidentAlertSetting setting) async {
    final res = await http.put(
      Uri.parse('$_base/settings/incident-alerts/${setting.id}'),
      headers: AuthService.instance.authJsonHeaders,
      body: jsonEncode(setting.toJson()),
    );

    if (res.statusCode == 200 ||
        res.statusCode == 201 ||
        res.statusCode == 204) {
      return;
    }

    throw Exception(_extractError(res, 'Unable to update incident alert'));
  }

  String _extractError(http.Response res, String fallback) {
    try {
      final body = jsonDecode(res.body);
      if (body is Map) {
        return (body['message'] ?? body['error'] ?? fallback).toString();
      }
    } catch (_) {}
    return fallback;
  }
}
