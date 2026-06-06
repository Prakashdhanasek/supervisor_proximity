import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import '../models/fleet_models.dart';

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
    final parts = _supervisorName.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
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
    if (email != null && email.trim().isNotEmpty) _supervisorEmail = email.trim();
    notifyListeners();
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
  }

  // ---------------------------------------------------------------------------
  void _seed() {
    final names = ['Arun Kumar', 'Priya Nair', 'Suresh M.', 'Fathima R.', 'Joel Thomas', 'Vishnu P.'];
    final regs = ['KL 07 AB 1234', 'KL 11 CD 5678', 'KL 13 EF 9012', 'KL 05 GH 3456', 'KL 09 IJ 7890', 'KL 21 KL 2345'];
    final routes = ['Warehouse → Hub A', 'Depot → City Center', 'Hub B → Airport', 'Warehouse → Hub C', 'Depot → Industrial Zone', 'Hub A → Port'];
    final statuses = [VehicleStatus.driving, VehicleStatus.driving, VehicleStatus.driving, VehicleStatus.idle, VehicleStatus.alert, VehicleStatus.offline];

    for (var i = 0; i < 6; i++) {
      _vehicles.add(FleetVehicle(
        id: 'v$i',
        registration: regs[i],
        driverName: names[i],
        routeName: routes[i],
        status: statuses[i],
        speedKmh: statuses[i] == VehicleStatus.driving ? 35 + _rng.nextDouble() * 45 : 0,
        routeProgress: _rng.nextDouble(),
        safetyScore: 70 + _rng.nextInt(28),
        inGeofence: i != 4,
        position: Offset(0.15 + _rng.nextDouble() * 0.7, 0.15 + _rng.nextDouble() * 0.7),
        heading: _rng.nextDouble() * 2 * pi,
        lastUpdate: DateTime.now(),
      ));

      _scorecards.add(DriverScorecard(
        id: 'd$i',
        name: names[i],
        vehicleReg: regs[i],
        safetyScore: 70 + _rng.nextInt(28),
        previousScore: 68 + _rng.nextInt(28),
        tripsThisWeek: 8 + _rng.nextInt(20),
        distanceKm: 120 + _rng.nextDouble() * 600,
        incidents: _rng.nextInt(6),
        onTimeRate: 80 + _rng.nextInt(20),
        last7Days: List.generate(7, (_) => 65 + _rng.nextInt(33)),
      ));
    }

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

    // Seed some incidents.
    _incidents.addAll([
      FleetIncident(
        id: 'i0',
        vehicleReg: 'KL 09 IJ 7890',
        driverName: 'Joel Thomas',
        type: IncidentType.drowsiness,
        severity: IncidentSeverity.critical,
        timestamp: DateTime.now().subtract(const Duration(minutes: 6)),
        hasVideo: true,
        location: 'NH-66, near Ramanattukara',
      ),
      FleetIncident(
        id: 'i1',
        vehicleReg: 'KL 11 CD 5678',
        driverName: 'Priya Nair',
        type: IncidentType.harshBraking,
        severity: IncidentSeverity.medium,
        timestamp: DateTime.now().subtract(const Duration(minutes: 22)),
        hasVideo: true,
        location: 'Bypass Road, Calicut',
      ),
      FleetIncident(
        id: 'i2',
        vehicleReg: 'KL 09 IJ 7890',
        driverName: 'Joel Thomas',
        type: IncidentType.geofence,
        severity: IncidentSeverity.high,
        timestamp: DateTime.now().subtract(const Duration(minutes: 35)),
        hasVideo: false,
        location: 'Outside permitted zone',
        reviewState: ReviewState.resolved,
      ),
    ]);
  }

  // ---------------------------------------------------------------------------
  void _simulate() {
    // Move driving vehicles around the map and jitter speed.
    for (var i = 0; i < _vehicles.length; i++) {
      final v = _vehicles[i];
      if (v.status != VehicleStatus.driving && v.status != VehicleStatus.alert) continue;

      var heading = v.heading + (_rng.nextDouble() - 0.5) * 0.6;
      const step = 0.012;
      var nx = v.position.dx + cos(heading) * step;
      var ny = v.position.dy + sin(heading) * step;

      // Bounce off the operating-zone edges.
      if (nx < 0.08 || nx > 0.92) {
        heading = pi - heading;
        nx = v.position.dx;
      }
      if (ny < 0.08 || ny > 0.92) {
        heading = -heading;
        ny = v.position.dy;
      }

      _vehicles[i] = v.copyWith(
        position: Offset(nx.clamp(0.08, 0.92), ny.clamp(0.08, 0.92)),
        heading: heading,
        speedKmh: 30 + _rng.nextDouble() * 50,
        routeProgress: (v.routeProgress + 0.01).clamp(0.0, 1.0),
        lastUpdate: DateTime.now(),
      );
    }

    // Occasionally raise an incident on a moving vehicle.
    if (_rng.nextDouble() < 0.12) _raiseRandomIncident();

    // Occasionally a new start-approval request arrives.
    if (_rng.nextDouble() < 0.08) _addRandomApproval();

    notifyListeners();
  }

  void _raiseRandomIncident() {
    final movers = _vehicles
        .where((v) => v.status == VehicleStatus.driving || v.status == VehicleStatus.alert)
        .toList();
    if (movers.isEmpty) return;
    final v = movers[_rng.nextInt(movers.length)];
    const types = IncidentType.values;
    final type = types[_rng.nextInt(types.length)];
    final severity = IncidentSeverity.values[_rng.nextInt(IncidentSeverity.values.length)];

    _incidents.insert(
      0,
      FleetIncident(
        id: 'i${DateTime.now().millisecondsSinceEpoch}',
        vehicleReg: v.registration,
        driverName: v.driverName,
        type: type,
        severity: severity,
        timestamp: DateTime.now(),
        hasVideo: type == IncidentType.drowsiness || type == IncidentType.distraction,
        location: v.routeName,
      ),
    );

    // Flag the vehicle as alerting for critical/high events.
    if (severity == IncidentSeverity.critical || severity == IncidentSeverity.high) {
      final idx = _vehicles.indexWhere((x) => x.id == v.id);
      if (idx != -1) _vehicles[idx] = _vehicles[idx].copyWith(status: VehicleStatus.alert);
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
        faceConfidence: assigned ? 88 + _rng.nextInt(11) : 30 + _rng.nextInt(25),
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

  void setReviewState(String incidentId, ReviewState state) {
    final idx = _incidents.indexWhere((i) => i.id == incidentId);
    if (idx != -1) {
      _incidents[idx] = _incidents[idx].copyWith(reviewState: state);
      // Clearing an alert resolves the vehicle status back to driving.
      if (state == ReviewState.resolved) {
        final vi = _vehicles.indexWhere((v) => v.registration == _incidents[idx].vehicleReg && v.status == VehicleStatus.alert);
        if (vi != -1) _vehicles[vi] = _vehicles[vi].copyWith(status: VehicleStatus.driving);
      }
      notifyListeners();
    }
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