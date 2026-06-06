import 'dart:ui';

/// ============================================================================
/// Models for the Proximity Guard Drive — Supervisor (Fleet Manager) app.
/// All data is simulated in FleetController; these are plain value types.
/// ============================================================================

enum VehicleStatus { driving, idle, alert, offline }

extension VehicleStatusX on VehicleStatus {
  String get label => switch (this) {
        VehicleStatus.driving => 'Driving',
        VehicleStatus.idle => 'Idle',
        VehicleStatus.alert => 'Alert',
        VehicleStatus.offline => 'Offline',
      };
}

class FleetVehicle {
  final String id;
  final String registration;
  final String driverName;
  final String routeName;
  final VehicleStatus status;
  final double speedKmh;
  final double routeProgress; // 0..1
  final int safetyScore; // 0..100
  final bool inGeofence;
  final Offset position; // normalised 0..1 on the map
  final double heading; // radians, direction of travel
  final DateTime lastUpdate;

  const FleetVehicle({
    required this.id,
    required this.registration,
    required this.driverName,
    required this.routeName,
    required this.status,
    required this.speedKmh,
    required this.routeProgress,
    required this.safetyScore,
    required this.inGeofence,
    required this.position,
    required this.heading,
    required this.lastUpdate,
  });

  FleetVehicle copyWith({
    VehicleStatus? status,
    double? speedKmh,
    double? routeProgress,
    int? safetyScore,
    bool? inGeofence,
    Offset? position,
    double? heading,
    DateTime? lastUpdate,
  }) {
    return FleetVehicle(
      id: id,
      registration: registration,
      driverName: driverName,
      routeName: routeName,
      status: status ?? this.status,
      speedKmh: speedKmh ?? this.speedKmh,
      routeProgress: routeProgress ?? this.routeProgress,
      safetyScore: safetyScore ?? this.safetyScore,
      inGeofence: inGeofence ?? this.inGeofence,
      position: position ?? this.position,
      heading: heading ?? this.heading,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }
}

enum AuthMethod { face, rfid, pin, mobileOverride }

extension AuthMethodX on AuthMethod {
  String get label => switch (this) {
        AuthMethod.face => 'Face + liveness',
        AuthMethod.rfid => 'RFID card',
        AuthMethod.pin => 'PIN',
        AuthMethod.mobileOverride => 'Mobile override',
      };
}

enum ApprovalStatus { pending, approved, denied }

class ApprovalRequest {
  final String id;
  final String driverName;
  final String vehicleReg;
  final AuthMethod method;
  final int faceConfidence; // 0..100, relevant for face
  final bool driverAssigned; // is this driver assigned to this vehicle?
  final DateTime requestedAt;
  final ApprovalStatus status;

  const ApprovalRequest({
    required this.id,
    required this.driverName,
    required this.vehicleReg,
    required this.method,
    required this.faceConfidence,
    required this.driverAssigned,
    required this.requestedAt,
    this.status = ApprovalStatus.pending,
  });

  ApprovalRequest copyWith({ApprovalStatus? status}) => ApprovalRequest(
        id: id,
        driverName: driverName,
        vehicleReg: vehicleReg,
        method: method,
        faceConfidence: faceConfidence,
        driverAssigned: driverAssigned,
        requestedAt: requestedAt,
        status: status ?? this.status,
      );
}

enum IncidentType { drowsiness, distraction, harshBraking, speeding, geofence, tamper, forwardDistance }

extension IncidentTypeX on IncidentType {
  String get label => switch (this) {
        IncidentType.drowsiness => 'Drowsiness',
        IncidentType.distraction => 'Distraction',
        IncidentType.harshBraking => 'Harsh braking',
        IncidentType.speeding => 'Over speed',
        IncidentType.geofence => 'Geofence breach',
        IncidentType.tamper => 'Device tamper',
        IncidentType.forwardDistance => 'Unsafe following',
      };
}

enum IncidentSeverity { low, medium, high, critical }

enum ReviewState { unreviewed, reviewing, resolved }

class FleetIncident {
  final String id;
  final String vehicleReg;
  final String driverName;
  final IncidentType type;
  final IncidentSeverity severity;
  final DateTime timestamp;
  final bool hasVideo;
  final String location;
  final ReviewState reviewState;

  const FleetIncident({
    required this.id,
    required this.vehicleReg,
    required this.driverName,
    required this.type,
    required this.severity,
    required this.timestamp,
    required this.hasVideo,
    required this.location,
    this.reviewState = ReviewState.unreviewed,
  });

  FleetIncident copyWith({ReviewState? reviewState}) => FleetIncident(
        id: id,
        vehicleReg: vehicleReg,
        driverName: driverName,
        type: type,
        severity: severity,
        timestamp: timestamp,
        hasVideo: hasVideo,
        location: location,
        reviewState: reviewState ?? this.reviewState,
      );
}

class DriverScorecard {
  final String id;
  final String name;
  final String vehicleReg;
  final int safetyScore; // 0..100
  final int previousScore; // for trend
  final int tripsThisWeek;
  final double distanceKm;
  final int incidents;
  final int onTimeRate; // %
  final List<int> last7Days; // sparkline scores

  const DriverScorecard({
    required this.id,
    required this.name,
    required this.vehicleReg,
    required this.safetyScore,
    required this.previousScore,
    required this.tripsThisWeek,
    required this.distanceKm,
    required this.incidents,
    required this.onTimeRate,
    required this.last7Days,
  });

  int get trend => safetyScore - previousScore;
  String get grade {
    if (safetyScore >= 90) return 'A';
    if (safetyScore >= 80) return 'B';
    if (safetyScore >= 70) return 'C';
    if (safetyScore >= 60) return 'D';
    return 'F';
  }
}
