import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class AppVersionService {
  static const _endpoint = 'https://proximity-driver-api.prod-app.in/api/app-version';

  Future<List<Map<String, dynamic>>> fetchVersions() async {
    final res = await http.get(
      Uri.parse(_endpoint),
      headers: AuthService.instance.authHeaders,
    );

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      return <Map<String, dynamic>>[];
    }
    throw Exception(_extractError(res, 'Unable to load app versions'));
  }

  Future<void> publishVersion({
    required String versionName,
    required String versionCode,
    required String releaseNotes,
    required String apkFilePath,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse(_endpoint));
    request.headers.addAll(AuthService.instance.authHeaders);
    
    request.fields['versionName'] = versionName;
    request.fields['versionCode'] = versionCode;
    request.fields['releaseNotes'] = releaseNotes;
    
    // Upload file using 'file' as key (and optionally 'apkFile' if backend expects it)
    request.files.add(
      await http.MultipartFile.fromPath('file', apkFilePath),
    );

    final streamedResponse = await request.send();
    final res = await http.Response.fromStream(streamedResponse);

    if (res.statusCode == 200 || res.statusCode == 201 || res.statusCode == 204) {
      return;
    }
    throw Exception(_extractError(res, 'Unable to publish new version'));
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
