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
  final double? latitude;
  final double? longitude;
  final double heading; // radians, direction of travel
  final DateTime lastUpdate;
  final Map<String, dynamic> rawApiData;

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
    this.latitude,
    this.longitude,
    required this.heading,
    required this.lastUpdate,
    this.rawApiData = const {},
  });

  FleetVehicle copyWith({
    VehicleStatus? status,
    double? speedKmh,
    double? routeProgress,
    int? safetyScore,
    bool? inGeofence,
    double? latitude,
    double? longitude,
    bool clearPosition = false,
    double? heading,
    DateTime? lastUpdate,
    Map<String, dynamic>? rawApiData,
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
      latitude: clearPosition ? null : (latitude ?? this.latitude),
      longitude: clearPosition ? null : (longitude ?? this.longitude),
      heading: heading ?? this.heading,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      rawApiData: rawApiData ?? this.rawApiData,
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

enum IncidentType {
  drowsiness,
  distraction,
  harshBraking,
  speeding,
  geofence,
  tamper,
  forwardDistance,
  tripStart,
  tripStop,
  seatbelt,
  phoneUsage,
  unauthorizedDriver,
}

extension IncidentTypeX on IncidentType {
  String get label => switch (this) {
    IncidentType.drowsiness => 'Drowsiness',
    IncidentType.distraction => 'Distraction',
    IncidentType.harshBraking => 'Harsh braking',
    IncidentType.speeding => 'Over speed',
    IncidentType.geofence => 'Geofence breach',
    IncidentType.tamper => 'Device tamper',
    IncidentType.forwardDistance => 'Unsafe following',
    IncidentType.tripStart => 'Trip Start',
    IncidentType.tripStop => 'Trip Stop',
    IncidentType.seatbelt => 'Seatbelt',
    IncidentType.phoneUsage => 'Phone Usage',
    IncidentType.unauthorizedDriver => 'Unauthorized Driver',
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
  final String? videoUrl;
  final String? snapshotUrl;
  final String? deviceImei;
  final double? vehicleSpeed;
  final double? confidence;
  final double? gpsLatitude;
  final double? gpsLongitude;

  const FleetIncident({
    required this.id,
    required this.vehicleReg,
    required this.driverName,
    required this.type,
    required this.severity,
    required this.timestamp,
    required this.hasVideo,
    required this.location,
    this.videoUrl,
    this.snapshotUrl,
    this.reviewState = ReviewState.unreviewed,
    this.deviceImei,
    this.vehicleSpeed,
    this.confidence,
    this.gpsLatitude,
    this.gpsLongitude,
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
    videoUrl: videoUrl,
    snapshotUrl: snapshotUrl,
    reviewState: reviewState ?? this.reviewState,
    deviceImei: deviceImei,
    vehicleSpeed: vehicleSpeed,
    confidence: confidence,
    gpsLatitude: gpsLatitude,
    gpsLongitude: gpsLongitude,
  );

  static FleetIncident? fromJson(Map<String, dynamic> json) {
    final eventTypeStr = json['eventType'] as String?;

    IncidentType type;
    switch (eventTypeStr) {
      case 'Drowsiness':
        type = IncidentType.drowsiness;
        break;
      case 'Distraction':
        type = IncidentType.distraction;
        break;
      case 'Harsh braking':
      case 'HarshBraking':
        type = IncidentType.harshBraking;
        break;
      case 'Speeding':
        type = IncidentType.speeding;
        break;
      case 'Geofence':
        type = IncidentType.geofence;
        break;
      case 'Tamper':
        type = IncidentType.tamper;
        break;
      case 'ForwardDistance':
        type = IncidentType.forwardDistance;
        break;
      case 'TripStart':
        type = IncidentType.tripStart;
        break;
      case 'TripStop':
        type = IncidentType.tripStop;
        break;
      case 'Seatbelt':
        type = IncidentType.seatbelt;
        break;
      case 'PhoneUsage':
        type = IncidentType.phoneUsage;
        break;
      case 'UnauthorizedDriver':
        type = IncidentType.unauthorizedDriver;
        break;
      default:
        return null; // Ignore unknown types
    }

    final riskLevelStr = json['riskLevel'] as String?;
    IncidentSeverity severity;
    switch (riskLevelStr) {
      case 'Low':
        severity = IncidentSeverity.low;
        break;
      case 'Medium':
        severity = IncidentSeverity.medium;
        break;
      case 'High':
        severity = IncidentSeverity.high;
        break;
      case 'Critical':
        severity = IncidentSeverity.critical;
        break;
      default:
        severity = IncidentSeverity.low;
        break;
    }

    final statusStr = json['status'] as String?;
    ReviewState reviewState;
    switch (statusStr) {
      case 'Resolved':
      case 'Acknowledged':
        reviewState = ReviewState.resolved;
        break;
      case 'Reviewing':
        reviewState = ReviewState.reviewing;
        break;
      default:
        reviewState = ReviewState.unreviewed;
        break;
    }

    final occurredAtStr = json['occurredAt'] as String?;
    DateTime timestamp = occurredAtStr != null
        ? DateTime.parse(occurredAtStr)
        : DateTime.now();

    final rawVideoUrl = json['videoClipUrl'] as String?;
    // videoClipUrl is "string" placeholder when no real video exists
    const baseUrl = 'https://proximity-driver-api.prod-app.in';
    final videoUrl =
        (rawVideoUrl != null &&
            rawVideoUrl.isNotEmpty &&
            rawVideoUrl != 'string')
        ? (rawVideoUrl.startsWith('http')
              ? rawVideoUrl
              : '$baseUrl$rawVideoUrl')
        : null;
    final rawSnapshotUrl = json['snapshotUrl'] as String?;
    // snapshotUrl is a relative path — prepend base URL
    final snapshotUrl = (rawSnapshotUrl != null && rawSnapshotUrl.isNotEmpty)
        ? (rawSnapshotUrl.startsWith('http')
              ? rawSnapshotUrl
              : '$baseUrl$rawSnapshotUrl')
        : null;
    final hasVideo = videoUrl != null && videoUrl.isNotEmpty;

    final lat = json['gpsLatitude'];
    final lng = json['gpsLongitude'];
    final latD = lat is num ? lat.toDouble() : null;
    final lngD = lng is num ? lng.toDouble() : null;
    final location = (lat != null && lng != null)
        ? 'Lat: $lat, Lng: $lng'
        : 'Unknown location';

    final speedRaw = json['vehicleSpeed'] ?? json['speed'];
    final speed = speedRaw is num ? speedRaw.toDouble() : null;
    final confRaw = json['aiConfidence'] ?? json['confidence'];
    final conf = confRaw is num ? confRaw.toDouble() : null;

    return FleetIncident(
      id: json['id'] as String? ?? '',
      vehicleReg: json['vehicleRegistrationNumber'] as String? ?? 'Unknown',
      driverName: json['driverName'] as String? ?? 'Unknown',
      type: type,
      severity: severity,
      timestamp: timestamp,
      hasVideo: hasVideo,
      location: location,
      videoUrl: videoUrl,
      snapshotUrl: snapshotUrl,
      reviewState: reviewState,
      deviceImei:
          json['deviceTabletId'] as String? ?? json['deviceImei'] as String?,
      vehicleSpeed: speed,
      confidence: conf,
      gpsLatitude: latD,
      gpsLongitude: lngD,
    );
  }
}

class DriverScorecard {
  final String id;
  final String name;
  final String vehicleReg;
  final String projectSite;
  final int rank;
  final int safetyScore; // 0..100
  final int previousScore; // for trend
  final String category; // Excellent, Good, Needs Coaching, High Risk
  final int tripsThisWeek;
  final double distanceKm;
  final int incidents;
  final int onTimeRate; // %
  final List<int> last7Days; // sparkline scores

  // Score breakdown
  final int safeDrivingScore;
  final int speedComplianceScore;
  final int fatigueScore;
  final int distractionScore;

  // Incident breakdown
  final int criticalIncidents;
  final int highIncidents;
  final int mediumIncidents;
  final int lowIncidents;

  const DriverScorecard({
    required this.id,
    required this.name,
    required this.vehicleReg,
    this.projectSite = '',
    this.rank = 0,
    required this.safetyScore,
    required this.previousScore,
    this.category = 'Unknown',
    required this.tripsThisWeek,
    required this.distanceKm,
    required this.incidents,
    required this.onTimeRate,
    required this.last7Days,
    this.safeDrivingScore = 100,
    this.speedComplianceScore = 100,
    this.fatigueScore = 100,
    this.distractionScore = 100,
    this.criticalIncidents = 0,
    this.highIncidents = 0,
    this.mediumIncidents = 0,
    this.lowIncidents = 0,
  });

  static DriverScorecard fromJson(Map<String, dynamic> json) {
    final score = json['score'] as int? ?? 100;
    final trendDelta = json['trendDelta'] as int? ?? 0;
    return DriverScorecard(
      id: json['driverId'] as String? ?? '',
      name: json['fullName'] as String? ?? 'Unknown',
      vehicleReg: json['vehicleRegistrationNumber'] as String? ?? '—',
      projectSite: json['assignedProjectSite'] as String? ?? '',
      rank: json['rank'] as int? ?? 0,
      safetyScore: score,
      previousScore: score - trendDelta,
      category: json['category'] as String? ?? 'Unknown',
      tripsThisWeek: 0,
      distanceKm: 0.0,
      incidents: json['totalIncidents'] as int? ?? 0,
      onTimeRate: 100,
      last7Days: List.generate(7, (_) => score),
      safeDrivingScore: json['safeDrivingScore'] as int? ?? 100,
      speedComplianceScore: json['speedComplianceScore'] as int? ?? 100,
      fatigueScore: json['fatigueScore'] as int? ?? 100,
      distractionScore: json['distractionScore'] as int? ?? 100,
      criticalIncidents: json['criticalIncidents'] as int? ?? 0,
      highIncidents: json['highIncidents'] as int? ?? 0,
      mediumIncidents: json['mediumIncidents'] as int? ?? 0,
      lowIncidents: json['lowIncidents'] as int? ?? 0,
    );
  }

  int get trend => safetyScore - previousScore;
  String get grade {
    if (safetyScore >= 90) return 'A';
    if (safetyScore >= 80) return 'B';
    if (safetyScore >= 70) return 'C';
    if (safetyScore >= 60) return 'D';
    return 'F';
  }
}
