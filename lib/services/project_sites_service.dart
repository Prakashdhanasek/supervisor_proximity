import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/project_site.dart';
import 'auth_service.dart';

class ProjectSitesService {
  static const _base = 'https://proximity-driver-api.prod-app.in/api';

  Future<List<ProjectSite>> fetchProjectSites() async {
    final res = await http.get(
      Uri.parse('$_base/project-sites'),
      headers: AuthService.instance.authHeaders,
    );
    print('GET /api/project-sites response: ${res.statusCode} ${res.body}');
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List)
          .map((e) => ProjectSite.fromJson(e))
          .toList();
    }
    throw Exception('Failed to load project sites (${res.statusCode})');
  }

  Future<ProjectSite> createProjectSite(String name) async {
    final res = await http.post(
      Uri.parse('$_base/project-sites'),
      headers: AuthService.instance.authJsonHeaders,
      body: jsonEncode({'name': name}),
    );
    print('POST /api/project-sites payload: {"name": "$name"}');
    print('POST /api/project-sites response: ${res.statusCode} ${res.body}');

    if (res.statusCode == 200 || res.statusCode == 201) {
      if (res.body.isNotEmpty) {
        try {
          return ProjectSite.fromJson(jsonDecode(res.body));
        } catch (_) {}
      }
      return ProjectSite(
        id: DateTime.now().toIso8601String(),
        name: name,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
    // Try to extract a user-friendly message from the response body
    String errorMsg = 'Failed to create project site';
    try {
      final body = jsonDecode(res.body);
      if (body is Map && body['message'] != null) {
        errorMsg = body['message'];
      }
    } catch (_) {}
    throw Exception(errorMsg);
  }

  Future<ProjectSite> updateProjectSite(String id, String name) async {
    final res = await http.put(
      Uri.parse('$_base/project-sites/$id'),
      headers: AuthService.instance.authJsonHeaders,
      body: jsonEncode({'id': id, 'name': name}),
    );
    print('PUT /api/project-sites/$id payload: {"id": "$id", "name": "$name"}');
    print('PUT /api/project-sites/$id response: ${res.statusCode} ${res.body}');

    if (res.statusCode == 200 || res.statusCode == 204) {
      if (res.body.isNotEmpty) {
        try {
          return ProjectSite.fromJson(jsonDecode(res.body));
        } catch (_) {}
      }
      return ProjectSite(
        id: id,
        name: name,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    if (res.statusCode == 404 || res.statusCode == 405) {
      print('PUT to /$id failed, trying base endpoint');
      final fallbackRes = await http.put(
        Uri.parse('$_base/project-sites'),
        headers: AuthService.instance.authJsonHeaders,
        body: jsonEncode({'id': id, 'name': name}),
      );
      print('PUT /api/project-sites payload: {"id": "$id", "name": "$name"}');
      print(
        'PUT /api/project-sites response: ${fallbackRes.statusCode} ${fallbackRes.body}',
      );
      if (fallbackRes.statusCode == 200 || fallbackRes.statusCode == 204) {
        if (fallbackRes.body.isNotEmpty) {
          try {
            return ProjectSite.fromJson(jsonDecode(fallbackRes.body));
          } catch (_) {}
        }
        return ProjectSite(
          id: id,
          name: name,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
      String fallbackMsg = 'Failed to update project site';
      try {
        final body = jsonDecode(fallbackRes.body);
        if (body is Map && body['message'] != null)
          fallbackMsg = body['message'];
      } catch (_) {}
      throw Exception(fallbackMsg);
    }

    String errorMsg = 'Failed to update project site';
    try {
      final body = jsonDecode(res.body);
      if (body is Map && body['message'] != null) errorMsg = body['message'];
    } catch (_) {}
    throw Exception(errorMsg);
  }

  Future<void> updateProjectSiteStatus(String id, bool isActive) async {
    final res = await http.put(
      Uri.parse('$_base/project-sites/$id/status'),
      headers: AuthService.instance.authJsonHeaders,
      body: jsonEncode({'isActive': isActive}),
    );
    print('PUT /api/project-sites/$id/status payload: {"isActive": $isActive}');
    print(
      'PUT /api/project-sites/$id/status response: ${res.statusCode} ${res.body}',
    );

    if (res.statusCode == 200 || res.statusCode == 204) {
      return;
    }

    if (res.statusCode == 405) {
      final patchRes = await http.patch(
        Uri.parse('$_base/project-sites/$id/status'),
        headers: AuthService.instance.authJsonHeaders,
        body: jsonEncode({'isActive': isActive}),
      );
      print(
        'PATCH /api/project-sites/$id/status response: ${patchRes.statusCode} ${patchRes.body}',
      );
      if (patchRes.statusCode == 200 || patchRes.statusCode == 204) {
        return;
      }
      throw Exception(
        'Failed to update status (${patchRes.statusCode}): ${patchRes.body}',
      );
    }

    throw Exception('Failed to update status (${res.statusCode}): ${res.body}');
  }
}
