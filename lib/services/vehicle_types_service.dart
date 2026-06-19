import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/vehicle_type.dart';
import 'auth_service.dart';

class VehicleTypesService {
  static const _base = 'https://proximity-driver-api.prod-app.in/api';

  Future<List<VehicleType>> fetchVehicleTypes() async {
    final res = await http.get(
      Uri.parse('$_base/vehicle-types'),
      headers: AuthService.instance.authHeaders,
    );
    print('GET /api/vehicle-types response: ${res.statusCode} ${res.body}');
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List)
          .map((e) => VehicleType.fromJson(e))
          .toList();
    }
    throw Exception('Failed to load vehicle types (${res.statusCode})');
  }

  Future<VehicleType> createVehicleType(String name) async {
    final res = await http.post(
      Uri.parse('$_base/vehicle-types'),
      headers: AuthService.instance.authJsonHeaders,
      body: jsonEncode({'name': name}),
    );
    print('POST /api/vehicle-types payload: {"name": "$name"}');
    print('POST /api/vehicle-types response: ${res.statusCode} ${res.body}');
    
    if (res.statusCode == 200 || res.statusCode == 201) {
      // Sometimes APIs return the created object, sometimes just 200.
      // If it returns JSON, parse it.
      if (res.body.isNotEmpty) {
        try {
          return VehicleType.fromJson(jsonDecode(res.body));
        } catch (_) {
          // If body is not a valid JSON representation of VehicleType,
          // throw or return a dummy.
        }
      }
      
      // Fallback dummy object if API doesn't return the full created object immediately
      return VehicleType(
        id: DateTime.now().toIso8601String(), 
        name: name, 
        isActive: true, 
        createdAt: DateTime.now(), 
        updatedAt: DateTime.now()
      );
    }
    throw Exception('Failed to create vehicle type (${res.statusCode}): ${res.body}');
  }

  Future<VehicleType> updateVehicleType(String id, String name) async {
    final res = await http.put(
      Uri.parse('$_base/vehicle-types/$id'),
      headers: AuthService.instance.authJsonHeaders,
      body: jsonEncode({'id': id, 'name': name}),
    );
    print('PUT /api/vehicle-types/$id payload: {"id": "$id", "name": "$name"}');
    print('PUT /api/vehicle-types/$id response: ${res.statusCode} ${res.body}');
    
    if (res.statusCode == 200 || res.statusCode == 204) {
      if (res.body.isNotEmpty) {
        try {
          return VehicleType.fromJson(jsonDecode(res.body));
        } catch (_) {}
      }
      return VehicleType(
        id: id, 
        name: name, 
        isActive: true, 
        createdAt: DateTime.now(), 
        updatedAt: DateTime.now()
      );
    }
    
    // Fallback if the API doesn't support /{id} but uses /vehicle-types directly
    if (res.statusCode == 404 || res.statusCode == 405) {
      print('PUT to /$id failed, trying base endpoint');
      final fallbackRes = await http.put(
        Uri.parse('$_base/vehicle-types'),
        headers: AuthService.instance.authJsonHeaders,
        body: jsonEncode({'id': id, 'name': name}),
      );
      print('PUT /api/vehicle-types payload: {"id": "$id", "name": "$name"}');
      print('PUT /api/vehicle-types response: ${fallbackRes.statusCode} ${fallbackRes.body}');
      if (fallbackRes.statusCode == 200 || fallbackRes.statusCode == 204) {
        if (fallbackRes.body.isNotEmpty) {
          try {
            return VehicleType.fromJson(jsonDecode(fallbackRes.body));
          } catch (_) {}
        }
        return VehicleType(
          id: id, 
          name: name, 
          isActive: true, 
          createdAt: DateTime.now(), 
          updatedAt: DateTime.now()
        );
      }
      throw Exception('Failed to update vehicle type (${fallbackRes.statusCode}): ${fallbackRes.body}');
    }

    throw Exception('Failed to update vehicle type (${res.statusCode}): ${res.body}');
  }

  Future<void> updateVehicleTypeStatus(String id, bool isActive) async {
    final res = await http.put(
      Uri.parse('$_base/vehicle-types/$id/status'),
      headers: AuthService.instance.authJsonHeaders,
      body: jsonEncode({'isActive': isActive}),
    );
    print('PUT /api/vehicle-types/$id/status payload: {"isActive": $isActive}');
    print('PUT /api/vehicle-types/$id/status response: ${res.statusCode} ${res.body}');
    
    if (res.statusCode == 200 || res.statusCode == 204) {
      return;
    }
    
    // Fallback to PATCH if PUT fails with 405 Method Not Allowed
    if (res.statusCode == 405) {
      final patchRes = await http.patch(
        Uri.parse('$_base/vehicle-types/$id/status'),
        headers: AuthService.instance.authJsonHeaders,
        body: jsonEncode({'isActive': isActive}),
      );
      print('PATCH /api/vehicle-types/$id/status response: ${patchRes.statusCode} ${patchRes.body}');
      if (patchRes.statusCode == 200 || patchRes.statusCode == 204) {
        return;
      }
      throw Exception('Failed to update status (${patchRes.statusCode}): ${patchRes.body}');
    }

    throw Exception('Failed to update status (${res.statusCode}): ${res.body}');
  }
}
