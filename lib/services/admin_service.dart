import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart';

class AdminService {
  static const _base = 'https://proximity-driver-api.prod-app.in/api';

  Future<List<Map<String, dynamic>>> fetchAdmins() async {
    final res = await http.get(
      Uri.parse('$_base/auth/admins'),
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

    throw Exception(_extractError(res, 'Unable to load admins'));
  }

  Future<void> createAdmin({
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/auth/admins'),
      headers: AuthService.instance.authJsonHeaders,
      body: jsonEncode({
        'fullName': fullName,
        'email': email,
        'password': password,
        'role': role,
      }),
    );

    if (res.statusCode == 200 ||
        res.statusCode == 201 ||
        res.statusCode == 204) {
      return;
    }

    throw Exception(_extractError(res, 'Unable to create admin'));
  }

  Future<void> updateAdmin({
    required String id,
    required String fullName,
    required String email,
    required String role,
    required bool isActive,
    String? password,
  }) async {
    final payload = <String, dynamic>{
      'fullName': fullName,
      'email': email,
      'role': role,
      'isActive': isActive,
    };

    if (password != null && password.trim().isNotEmpty) {
      payload['password'] = password;
    }

    final res = await http.put(
      Uri.parse('$_base/auth/admins/$id'),
      headers: AuthService.instance.authJsonHeaders,
      body: jsonEncode(payload),
    );

    if (res.statusCode == 200 || res.statusCode == 204) {
      return;
    }

    throw Exception(_extractError(res, 'Unable to update admin'));
  }

  Future<void> deleteAdmin(String id) async {
    final res = await http.delete(
      Uri.parse('$_base/auth/admins/$id'),
      headers: AuthService.instance.authHeaders,
    );

    if (res.statusCode == 200 || res.statusCode == 204) {
      return;
    }

    throw Exception(_extractError(res, 'Unable to delete admin'));
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
