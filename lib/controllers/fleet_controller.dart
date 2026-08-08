import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../models/fleet_models.dart';
import '../models/driver.dart';
import '../services/auth_service.dart';
import '../main.dart';
import '../login_screen.dart';

/// Central state for the supervisor app. Simulates a live fleet:
/// vehicles move on the map, new start-approval requests arrive, and
/// incidents are raised periodically. Mirrors the driver app's approach
/// (in-memory, no backend) so both run as a self-contained pilot demo.
class FleetController extends ChangeNotifier {
  final _rng = Random();
  Timer? _tick;

  final List<FleetVehicle> _vehicles = [];
  final List<ApprovalRequest> _approvals = [];
  final List<FleetIncident> _incidents = [];
  final List<DriverScorecard> _scorecards = [];

  List<FleetVehicle> get vehicles => List.unmodifiable(_vehicles);
  List<ApprovalRequest> get approvals => List.unmodifiable(_approvals);
  List<ApprovalRequest> get pendingApprovals =>
      _approvals.where((a) => a.status == ApprovalStatus.pending).toList();
  List<FleetIncident> get incidents => List.unmodifiable(_incidents);
  List<FleetIncident> get unreviewedIncidents =>
      _incidents.where((i) => i.reviewState == ReviewState.unreviewed).toList();
  List<DriverScorecard> get scorecards => List.unmodifiable(_scorecards);

  // ---- Dashboard summary ----
  int get activeVehicles =>
      _vehicles.where((v) => v.status == VehicleStatus.driving).length;
  int get alertVehicles =>
      _vehicles.where((v) => v.status == VehicleStatus.alert).length;
  int get idleVehicles =>
      _vehicles.where((v) => v.status == VehicleStatus.idle).length;
  int get fleetAvgScore => _scorecards.isEmpty
      ? 0
      : (_scorecards.map((s) => s.safetyScore).reduce((a, b) => a + b) /
                _scorecards.length)
            .round();

  // ---- Signed-in supervisor (profile) ----
  String _supervisorName = 'Rahul Menon';
  String _supervisorEmail = 'rahul.menon@fleet.com';

  // Static profile fields (would come from the backend User record in production).
  final String supervisorRole = 'Fleet Manager';
  final String companyName = 'Calicut Logistics Pvt Ltd';
  final String branch = 'Kozhikode Hub';
  final String userId = 'FM-2041';
  final String phone = '+91 98470 11234';
  final String accessLevel = 'Operational access';
  final List<String> permissions = const [
    'Live fleet tracking',
    'Approve driver starts',
    'Review incidents & evidence',
    'Driver scorecards & reports',
    'Call / message drivers',
  ];

  bool mfaEnabled = true;
  bool biometricEnabled = true;
  final DateTime memberSince = DateTime(2025, 8, 12);
  DateTime lastActive = DateTime.now();

  String get supervisorName => _supervisorName;
  String get supervisorEmail => _supervisorEmail;
  String get supervisorFirstName => _supervisorName.split(' ').first;

  String get supervisorInitials {
    final parts = _supervisorName
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'S';
    if (parts.length == 1) {
      final p = parts.first;
      return (p.length >= 2 ? p.substring(0, 2) : p).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  // Oversight stats a Fleet Manager monitors (blueprint §4).
  int get vehiclesOverseen => _vehicles.length;
  int get driversOverseen => _scorecards.length;
  int get approvalsHandled =>
      _approvals.where((a) => a.status != ApprovalStatus.pending).length;
  int get incidentsResolved =>
      _incidents.where((i) => i.reviewState == ReviewState.resolved).length;

  void setSupervisorIdentity({String? name, String? email}) {
    if (name != null && name.trim().isNotEmpty) _supervisorName = name.trim();
    if (email != null && email.trim().isNotEmpty)
      _supervisorEmail = email.trim();
    notifyListeners();
    // Re-fetch all data now that auth token is available
    fetchVehicles();
    fetchApiDrivers();
    fetchIncidents();
    fetchScorecards();
  }

  void setSupervisorName(String name) => setSupervisorIdentity(name: name);
  void toggleMfa(bool v) {
    mfaEnabled = v;
    notifyListeners();
  }

  void toggleBiometric(bool v) {
    biometricEnabled = v;
    notifyListeners();
  }

  FleetController() {
    _seed();
    _tick = Timer.periodic(const Duration(seconds: 2), (_) => _simulate());
    // Defer API calls so notifyListeners() doesn't fire during construction
    Future.microtask(() {
      fetchVehicles();
      fetchApiDrivers();
      fetchIncidents();
      fetchScorecards();
    });
  }

  List<Driver> apiDrivers = [];
  bool isLoadingDrivers = false;

  void _checkUnauthorized(int statusCode) {
    if (statusCode == 401) {
      AuthService.instance.logout().then((_) {
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginView()),
          (route) => false,
        );
      });
    }
  }

  Future<void> fetchApiDrivers() async {
    isLoadingDrivers = true;
    notifyListeners();
    try {
      final url = Uri.parse(
        'https://proximity-driver-api.prod-app.in/api/drivers',
      );
      final headers = AuthService.instance.authHeaders;
      debugPrint('==== API REQUEST: GET $url ====');
      debugPrint('Auth token present: ${AuthService.instance.isLoggedIn}');
      debugPrint('Headers: $headers');
      final response = await http.get(url, headers: headers);
      debugPrint('==== API RESPONSE: GET $url ====');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        apiDrivers = data
            .map((d) => Driver.fromJson(d as Map<String, dynamic>))
            .toList();
      } else {
        _checkUnauthorized(response.statusCode);
      }
    } catch (e) {
      debugPrint('Error fetching drivers: $e');
    } finally {
      isLoadingDrivers = false;
      notifyListeners();
    }
  }

  Future<void> fetchIncidents() async {
    try {
      final url = Uri.parse(
        'https://proximity-driver-api.prod-app.in/api/incidents',
      );
      debugPrint('==== API REQUEST: GET $url ====');
      final response = await http.get(
        url,
        headers: AuthService.instance.authHeaders,
      );
      debugPrint('==== API RESPONSE: GET $url ====');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        _incidents.clear();
        for (var item in data) {
          final incident = FleetIncident.fromJson(item);
          if (incident != null) {
            _incidents.add(incident);
          }
        }

        // Sort by timestamp descending
        _incidents.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        notifyListeners();
      } else {
        _checkUnauthorized(response.statusCode);
      }
    } catch (e) {
      debugPrint('Error fetching incidents: $e');
    }
  }

  Future<void> fetchVehicles() async {
    try {
      final url = Uri.parse(
        'https://proximity-driver-api.prod-app.in/api/vehicle',
      );
      debugPrint('==== API REQUEST: GET $url ====');
      final response = await http.get(
        url,
        headers: AuthService.instance.authHeaders,
      );
      debugPrint('==== API RESPONSE: GET $url ====');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        // Remove simulated vehicles that were seeded
        _vehicles.clear();

        for (var item in data) {
          _vehicles.add(
            FleetVehicle(
              id: item['id'] ?? 'v_${DateTime.now().millisecondsSinceEpoch}',
              registration: item['vehicleRegistrationNumber'] ?? 'Unknown',
              driverName: item['assignedDriverName'] ?? 'Unassigned',
              routeName: item['assignedProjectSite'] ?? 'Unassigned Route',
              status: item['isActive'] == true
                  ? VehicleStatus.idle
                  : VehicleStatus.offline,
              speedKmh: 0,
              routeProgress: 0,
              safetyScore: 100,
              inGeofence: true,
              latitude: null,
              longitude: null,
              heading: _rng.nextDouble() * 2 * pi,
              lastUpdate: item['updatedAt'] != null
                  ? DateTime.tryParse(item['updatedAt']) ?? DateTime.now()
                  : DateTime.now(),
              rawApiData: item,
            ),
          );
        }
        notifyListeners();
      } else {
        _checkUnauthorized(response.statusCode);
      }
    } catch (e) {
      debugPrint('Error fetching vehicles: $e');
    }
  }

  Future<void> fetchScorecards() async {
    try {
      final url = Uri.parse(
        'https://proximity-driver-api.prod-app.in/api/scorecard',
      );
      debugPrint('==== API REQUEST: GET $url ====');
      final response = await http.get(
        url,
        headers: AuthService.instance.authHeaders,
      );
      debugPrint('==== API RESPONSE: GET $url ====');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final leaderboard = data['leaderboard'] as List<dynamic>?;

        if (leaderboard != null) {
          _scorecards.clear();
          for (var item in leaderboard) {
            _scorecards.add(DriverScorecard.fromJson(item));
          }
          notifyListeners();
        }
      } else {
        _checkUnauthorized(response.statusCode);
      }
    } catch (e) {
      debugPrint('Error fetching scorecards: $e');
    }
  }

  // ---------------------------------------------------------------------------
  void _seed() {
    // Seed a couple of pending approvals.
    _approvals.addAll([
      ApprovalRequest(
        id: 'a0',
        driverName: 'Arun Kumar',
        vehicleReg: 'KL 07 AB 1234',
        method: AuthMethod.face,
        faceConfidence: 96,
        driverAssigned: true,
        requestedAt: DateTime.now().subtract(const Duration(minutes: 1)),
      ),
      ApprovalRequest(
        id: 'a1',
        driverName: 'Unknown driver',
        vehicleReg: 'KL 13 EF 9012',
        method: AuthMethod.face,
        faceConfidence: 41,
        driverAssigned: false,
        requestedAt: DateTime.now().subtract(const Duration(minutes: 3)),
      ),
    ]);
  }

  // ---------------------------------------------------------------------------
  Future<void> fetchFleetMapVehicles() async {
    try {
      final url = Uri.parse(
        'https://proximity-driver-api.prod-app.in/api/fleet-map/vehicles',
      );
      final response = await http.get(
        url,
        headers: AuthService.instance.authHeaders,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        for (var item in data) {
          final id = item['id'];
          final reg = item['vehicleRegistrationNumber'];
          final lat = (item['latitude'] as num?)?.toDouble();
          final lng = (item['longitude'] as num?)?.toDouble();
          final speed = (item['currentSpeed'] as num?)?.toDouble() ?? 0.0;
          final isOnline = item['isOnline'] == true;

          final idx = _vehicles.indexWhere(
            (v) => v.id == id || v.registration == reg,
          );
          if (idx != -1) {
            final v = _vehicles[idx];
            bool clearPos = false;
            if (lat == null || lng == null) {
              clearPos = true;
            }
            _vehicles[idx] = v.copyWith(
              speedKmh: speed,
              status: isOnline
                  ? (speed > 0 ? VehicleStatus.driving : VehicleStatus.idle)
                  : VehicleStatus.offline,
              latitude: lat,
              longitude: lng,
              clearPosition: clearPos,
              lastUpdate: DateTime.now(),
              rawApiData: {...v.rawApiData, ...item},
            );
          } else {
            _vehicles.add(
              FleetVehicle(
                id: id ?? 'v_${DateTime.now().millisecondsSinceEpoch}',
                registration: reg ?? 'Unknown',
                driverName: 'Unknown',
                routeName: 'Unknown',
                status: isOnline
                    ? (speed > 0 ? VehicleStatus.driving : VehicleStatus.idle)
                    : VehicleStatus.offline,
                speedKmh: speed,
                routeProgress: 0.0,
                safetyScore: 100,
                inGeofence: true,
                latitude: lat,
                longitude: lng,
                heading: 0.0,
                lastUpdate: DateTime.now(),
                rawApiData: item,
              ),
            );
          }
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching map vehicles: $e');
    }
  }

  void _simulate() {
    // Fetch live hardware data instead of moving vehicles manually
    fetchFleetMapVehicles();

    // Occasionally a new start-approval request arrives.
    if (_rng.nextDouble() < 0.08) _addRandomApproval();

    notifyListeners();
  }

  void _raiseRandomIncident() {
    final movers = _vehicles
        .where(
          (v) =>
              v.status == VehicleStatus.driving ||
              v.status == VehicleStatus.alert,
        )
        .toList();
    if (movers.isEmpty) return;
    final v = movers[_rng.nextInt(movers.length)];
    const types = IncidentType.values;
    final type = types[_rng.nextInt(types.length)];
    final severity =
        IncidentSeverity.values[_rng.nextInt(IncidentSeverity.values.length)];

    _incidents.insert(
      0,
      FleetIncident(
        id: 'i${DateTime.now().millisecondsSinceEpoch}',
        vehicleReg: v.registration,
        driverName: v.driverName,
        type: type,
        severity: severity,
        timestamp: DateTime.now(),
        hasVideo:
            type == IncidentType.drowsiness || type == IncidentType.distraction,
        location: v.routeName,
      ),
    );

    // Flag the vehicle as alerting for critical/high events.
    if (severity == IncidentSeverity.critical ||
        severity == IncidentSeverity.high) {
      final idx = _vehicles.indexWhere((x) => x.id == v.id);
      if (idx != -1)
        _vehicles[idx] = _vehicles[idx].copyWith(status: VehicleStatus.alert);
    }
  }

  void _addRandomApproval() {
    if (pendingApprovals.length >= 4) return;
    final assigned = _rng.nextBool();
    _approvals.insert(
      0,
      ApprovalRequest(
        id: 'a${DateTime.now().millisecondsSinceEpoch}',
        driverName: assigned ? 'Vishnu P.' : 'Unknown driver',
        vehicleReg: 'KL 21 KL 2345',
        method: AuthMethod.values[_rng.nextInt(AuthMethod.values.length)],
        faceConfidence: assigned
            ? 88 + _rng.nextInt(11)
            : 30 + _rng.nextInt(25),
        driverAssigned: assigned,
        requestedAt: DateTime.now(),
      ),
    );
  }

  // ---- Actions ----
  void approve(String id) => _setApproval(id, ApprovalStatus.approved);
  void deny(String id) => _setApproval(id, ApprovalStatus.denied);

  void _setApproval(String id, ApprovalStatus status) {
    final idx = _approvals.indexWhere((a) => a.id == id);
    if (idx != -1) {
      _approvals[idx] = _approvals[idx].copyWith(status: status);
      notifyListeners();
    }
  }

  Future<void> setReviewState(String incidentId, ReviewState state) async {
    if (state == ReviewState.resolved) {
      try {
        final url = Uri.parse(
          'https://proximity-driver-api.prod-app.in/api/incidents/$incidentId/acknowledge',
        );
        debugPrint('==== API REQUEST: PATCH $url ====');
        final response = await http.patch(
          url,
          headers: AuthService.instance.authHeaders,
        );
        debugPrint('==== API RESPONSE: PATCH $url ====');
        debugPrint('Status Code: ${response.statusCode}');
        debugPrint('Response Body: ${response.body}');

        if (response.statusCode != 200) {
          return;
        }
      } catch (e) {
        debugPrint('Error acknowledging incident: $e');
        return;
      }
    }

    final idx = _incidents.indexWhere((i) => i.id == incidentId);
    if (idx != -1) {
      _incidents[idx] = _incidents[idx].copyWith(reviewState: state);
      // Clearing an alert resolves the vehicle status back to driving.
      if (state == ReviewState.resolved) {
        final vi = _vehicles.indexWhere(
          (v) =>
              v.registration == _incidents[idx].vehicleReg &&
              v.status == VehicleStatus.alert,
        );
        if (vi != -1)
          _vehicles[vi] = _vehicles[vi].copyWith(status: VehicleStatus.driving);
      }
      notifyListeners();
    }
  }

  // ...existing code...

  Future<void> enrollDriverApi({
    required String fullName,
    required String email,
    required String mobileNumber,
    required String licenseNumber,
    required DateTime licenseExpiry,
    required String assignedProjectSite,
    required List<String> assignedVehicleIds,
    required String shift,
    required Map<String, bool> faceConditions,
    required Map<String, List<File>> facePhotos,
    String preferredLanguage = 'en',
  }) async {
    try {
      final url = Uri.parse(
        'https://proximity-driver-api.prod-app.in/api/drivers',
      );
      final payload = {
        "fullName": fullName,
        "email": email,
        "mobileNumber": mobileNumber,
        "licenseNumber": licenseNumber,
        "licenseExpiry": licenseExpiry.toIso8601String(),
        "assignedProjectSite": assignedProjectSite,
        "assignedVehicleIds": assignedVehicleIds,
        "shift": shift,
        "faceEnrollNormalFace": faceConditions['Normal Face'] ?? false,
        "faceEnrollWithSpectacles": faceConditions['With Spectacles'] ?? false,
        "faceEnrollLowLightCabin": faceConditions['Low Light Cabin'] ?? false,
        "faceEnrollCabinLighting": faceConditions['Cabin Lighting'] ?? false,
        "faceEnrollFixedTabletAngle":
            faceConditions['Fixed Tablet Angle'] ?? false,
        "faceEnrollSunglasses":
            faceConditions['Sunglasses (if permitted)'] ?? false,
        "preferredLanguage": preferredLanguage,
      };

      debugPrint('==== API REQUEST: POST $url ====');
      debugPrint('Payload: ${jsonEncode(payload)}');

      final response = await http.post(
        url,
        headers: AuthService.instance.authJsonHeaders,
        body: jsonEncode(payload),
      );

      debugPrint('==== API RESPONSE: POST $url ====');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final driverId = data['id'];

        if (driverId != null) {
          for (final entry in facePhotos.entries) {
            final condition = _mapConditionToApi(entry.key);
            for (final file in entry.value) {
              final photoUrl = Uri.parse(
                'https://proximity-driver-api.prod-app.in/api/drivers/$driverId/face-photos',
              );
              debugPrint('==== API REQUEST: MULTIPART POST $photoUrl ====');
              debugPrint('Condition: $condition, File: ${file.path}');
              var request = http.MultipartRequest('POST', photoUrl);
              request.headers.addAll(AuthService.instance.authHeaders);
              request.fields['faceCondition'] = condition;
              request.files.add(
                await http.MultipartFile.fromPath('file', file.path),
              );
              final streamedResponse = await request.send();
              final photoResponse = await http.Response.fromStream(
                streamedResponse,
              );
              debugPrint('==== API RESPONSE: MULTIPART POST $photoUrl ====');
              debugPrint('Status Code: ${photoResponse.statusCode}');
              debugPrint('Response Body: ${photoResponse.body}');
              if (photoResponse.statusCode != 200 &&
                  photoResponse.statusCode != 201) {
                _checkUnauthorized(photoResponse.statusCode);
              }
            }
          }
        }
        await fetchApiDrivers();
      } else {
        _checkUnauthorized(response.statusCode);
      }
    } catch (e) {
      debugPrint('Error enrolling driver: $e');
    }
  }

  String _mapConditionToApi(String uiCondition) {
    switch (uiCondition) {
      case 'Normal Face':
        return 'normalFace';
      case 'With Spectacles':
        return 'withSpectacles';
      case 'Low Light Cabin':
        return 'lowLightCabin';
      case 'Cabin Lighting':
        return 'cabinLighting';
      case 'Fixed Tablet Angle':
        return 'fixedTabletAngle';
      case 'Sunglasses (if permitted)':
        return 'sunglasses';
      default:
        return 'normalFace';
    }
  }

  Future<void> updateDriverApi({
    required String id,
    required String fullName,
    required String email,
    required String mobileNumber,
    required String licenseNumber,
    required DateTime licenseExpiry,
    required String assignedProjectSite,
    required String? assignedVehicleId,
    required String shift,
    required String preferredLanguage,
    required Map<String, bool> faceConditions,
    required Map<String, List<File>> facePhotos,
    required bool isActive,
    required String status,
  }) async {
    try {
      final url = Uri.parse(
        'https://proximity-driver-api.prod-app.in/api/drivers/$id',
      );
      final payload = {
        'fullName': fullName,
        'email': email,
        'mobileNumber': mobileNumber,
        'licenseNumber': licenseNumber,
        'licenseExpiry': licenseExpiry.toIso8601String(),
        'assignedProjectSite': assignedProjectSite,
        'assignedVehicleIds': assignedVehicleId == null
            ? <String>[]
            : <String>[assignedVehicleId],
        'shift': shift,
        'faceEnrollNormalFace': faceConditions['Normal Face'] ?? false,
        'faceEnrollWithSpectacles': faceConditions['With Spectacles'] ?? false,
        'faceEnrollLowLightCabin': faceConditions['Low Light Cabin'] ?? false,
        'faceEnrollCabinLighting': faceConditions['Cabin Lighting'] ?? false,
        'faceEnrollFixedTabletAngle':
            faceConditions['Fixed Tablet Angle'] ?? false,
        'faceEnrollSunglasses':
            faceConditions['Sunglasses (if permitted)'] ?? false,
        'isActive': isActive,
        'status': status,
        'preferredLanguage': preferredLanguage,
      };

      final response = await http.put(
        url,
        headers: AuthService.instance.authJsonHeaders,
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        for (final entry in facePhotos.entries) {
          final condition = _mapConditionToApi(entry.key);
          for (final file in entry.value) {
            final photoUrl = Uri.parse(
              'https://proximity-driver-api.prod-app.in/api/drivers/$id/face-photos',
            );
            final request = http.MultipartRequest('POST', photoUrl)
              ..headers.addAll(AuthService.instance.authHeaders)
              ..fields['faceCondition'] = condition
              ..files.add(await http.MultipartFile.fromPath('file', file.path));

            final streamedResponse = await request.send();
            final photoResponse = await http.Response.fromStream(
              streamedResponse,
            );

            if (photoResponse.statusCode != 200 &&
                photoResponse.statusCode != 201 &&
                photoResponse.statusCode != 409) {
              _checkUnauthorized(photoResponse.statusCode);
            }
          }
        }
        await fetchApiDrivers();
        return;
      }

      _checkUnauthorized(response.statusCode);
      throw Exception('Unable to update driver (${response.statusCode})');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteDriverApi(String id) async {
    final url = Uri.parse(
      'https://proximity-driver-api.prod-app.in/api/drivers/$id',
    );
    final response = await http.delete(
      url,
      headers: AuthService.instance.authHeaders,
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      await fetchApiDrivers();
      return;
    }

    _checkUnauthorized(response.statusCode);
    throw Exception('Unable to delete driver (${response.statusCode})');
  }

  void addDriver({
    required String name,
    required String vehicleReg,
    required int safetyScore,
  }) {
    final id = 'd${_scorecards.length}';
    _scorecards.add(
      DriverScorecard(
        id: id,
        name: name,
        vehicleReg: vehicleReg,
        safetyScore: safetyScore,
        previousScore: safetyScore,
        tripsThisWeek: 0,
        distanceKm: 0.0,
        incidents: 0,
        onTimeRate: 100,
        last7Days: List.generate(7, (_) => safetyScore),
      ),
    );
    notifyListeners();
  }

  Future<void> addVehicle({
    required String registration,
    required String driverName,
    required String? assignedDriverId,
    required String vehicleType,
    required String assignedProjectSite,
    required String deviceTabletId,
    required String tabletModel,
    required int overspeedThreshold,
    required int reVerificationInterval,
    required bool frontCameraOperational,
    required bool gpsSignalConfirmed,
    required bool appInstalledAndSigned,
    required bool roadFacingCameraOperational,
    required bool mdmKioskModeActive,
    required bool mountSecureNoTamper,
    String routeName = 'Unassigned Route',
  }) async {
    // API Integration for Add Vehicle
    try {
      final url = Uri.parse(
        'https://proximity-driver-api.prod-app.in/api/vehicle',
      );
      final payload = {
        "vehicleRegistrationNumber": registration,
        "vehicleType": vehicleType,
        "assignedProjectSite": assignedProjectSite,
        "deviceTabletId": deviceTabletId,
        "tabletModel": tabletModel,
        "overspeedThreshold": overspeedThreshold,
        "reVerificationInterval": reVerificationInterval,
        "assignedDriverId": assignedDriverId,
        "frontCameraOperational": frontCameraOperational,
        "gpsSignalConfirmed": gpsSignalConfirmed,
        "appInstalledAndSigned": appInstalledAndSigned,
        "roadFacingCameraOperational": roadFacingCameraOperational,
        "mdmKioskModeActive": mdmKioskModeActive,
        "mountSecureNoTamper": mountSecureNoTamper,
      };

      debugPrint('==== API REQUEST: POST $url ====');
      debugPrint('Payload: ${jsonEncode(payload)}');

      final response = await http.post(
        url,
        headers: AuthService.instance.authJsonHeaders,
        body: jsonEncode(payload),
      );

      debugPrint('==== API RESPONSE: POST $url ====');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        _checkUnauthorized(response.statusCode);
      }
    } catch (e) {
      debugPrint('Error calling Add Vehicle API: $e');
    }

    final id = 'v${_vehicles.length}_${DateTime.now().millisecondsSinceEpoch}';
    _vehicles.add(
      FleetVehicle(
        id: id,
        registration: registration,
        driverName: driverName,
        routeName: routeName,
        status: VehicleStatus.idle,
        speedKmh: 0,
        routeProgress: 0,
        safetyScore: 100,
        inGeofence: true,
        latitude: 10.01 + _rng.nextDouble() * 0.1,
        longitude: 76.3 + _rng.nextDouble() * 0.1,
        heading: _rng.nextDouble() * 2 * pi,
        lastUpdate: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void removeVehicle(String id) {
    _vehicles.removeWhere((v) => v.id == id);
    notifyListeners();
  }

  FleetVehicle? vehicleByReg(String reg) {
    for (final v in _vehicles) {
      if (v.registration == reg) return v;
    }
    return null;
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }
}
