import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class DashboardStats {
  final int totalDrivers;
  final int activeDrivers;
  final int totalVehicles;
  final int activeVehicles;
  final int totalViolations;
  final int violationsToday;
  final int criticalToday;
  final int highToday;
  final int violationsThisWeek;
  final Map<String, int> violationsByType;
  final Map<String, int> violationsByRisk;
  final List<DailyTrend> dailyTrend;
  final List<RecentIncident> recentIncidents;
  final List<FleetMapVehicle> fleetMapVehicles;
  final double activeDriverRate;
  final double fleetActiveRate;
  final double alertResolutionRate;

  const DashboardStats({
    required this.totalDrivers,
    required this.activeDrivers,
    required this.totalVehicles,
    required this.activeVehicles,
    required this.totalViolations,
    required this.violationsToday,
    required this.criticalToday,
    required this.highToday,
    required this.violationsThisWeek,
    required this.violationsByType,
    required this.violationsByRisk,
    required this.dailyTrend,
    required this.recentIncidents,
    required this.fleetMapVehicles,
    required this.activeDriverRate,
    required this.fleetActiveRate,
    required this.alertResolutionRate,
  });
}

class DailyTrend {
  final String day;
  final int count;
  const DailyTrend({required this.day, required this.count});
}

class RecentIncident {
  final String id;
  final String vehicleReg;
  final String driverName;
  final String eventType;
  final String projectSite;
  final DateTime occurredAt;
  final String riskLevel;
  final double aiConfidence;
  final String status;

  const RecentIncident({
    required this.id,
    required this.vehicleReg,
    required this.driverName,
    required this.eventType,
    required this.projectSite,
    required this.occurredAt,
    required this.riskLevel,
    required this.aiConfidence,
    required this.status,
  });
}

class FleetMapVehicle {
  final String id;
  final String vehicleReg;
  final String vehicleType;
  final String assignedProjectSite;
  final double? latitude;
  final double? longitude;
  final double currentSpeed;
  final bool isOnline;
  final DateTime? lastLocationUpdate;

  const FleetMapVehicle({
    required this.id,
    required this.vehicleReg,
    required this.vehicleType,
    required this.assignedProjectSite,
    this.latitude,
    this.longitude,
    required this.currentSpeed,
    required this.isOnline,
    this.lastLocationUpdate,
  });
}

class DashboardService {
  DashboardService._();
  static final DashboardService instance = DashboardService._();

  static const _base = 'https://proximity-driver-api.prod-app.in/api';

  Future<DashboardStats> fetchDashboard() async {
    final headers = AuthService.instance.authHeaders;

    final results = await Future.wait([
      http.get(Uri.parse('$_base/drivers'), headers: headers),
      http.get(Uri.parse('$_base/vehicle'), headers: headers),
      http.get(Uri.parse('$_base/incidents'), headers: headers),
      http.get(Uri.parse('$_base/fleet-map/vehicles'), headers: headers),
    ]);

    // Parse drivers
    final driversResp = results[0];
    List<dynamic> drivers = [];
    if (driversResp.statusCode == 200) {
      drivers = jsonDecode(driversResp.body);
    }

    // Parse vehicles
    final vehiclesResp = results[1];
    List<dynamic> vehicles = [];
    if (vehiclesResp.statusCode == 200) {
      vehicles = jsonDecode(vehiclesResp.body);
    }

    // Parse incidents
    final incidentsResp = results[2];
    List<dynamic> incidents = [];
    if (incidentsResp.statusCode == 200) {
      incidents = jsonDecode(incidentsResp.body);
    }

    // Parse fleet map vehicles
    final fleetMapResp = results[3];
    List<dynamic> fleetMapData = [];
    if (fleetMapResp.statusCode == 200) {
      fleetMapData = jsonDecode(fleetMapResp.body);
    }

    // Compute stats
    final totalDrivers = drivers.length;
    final activeDrivers = drivers.where((d) => d['isActive'] == true).length;

    final totalVehicles = fleetMapData.isNotEmpty
        ? fleetMapData.length
        : vehicles.length;
    final activeVehicles = fleetMapData
        .where((v) => v['isOnline'] == true)
        .length;

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));

    final todayIncidents = incidents.where((i) {
      final occurredAt = DateTime.tryParse(i['occurredAt'] ?? '');
      return occurredAt != null && occurredAt.isAfter(todayStart);
    }).toList();

    final weekIncidents = incidents.where((i) {
      final occurredAt = DateTime.tryParse(i['occurredAt'] ?? '');
      return occurredAt != null && occurredAt.isAfter(weekStart);
    }).toList();

    final criticalToday = todayIncidents
        .where((i) => i['riskLevel'] == 'Critical')
        .length;
    final highToday = todayIncidents
        .where((i) => i['riskLevel'] == 'High')
        .length;

    // Violation types
    final Map<String, int> violationsByType = {};
    for (final i in incidents) {
      final type = i['eventType'] as String? ?? 'Unknown';
      violationsByType[type] = (violationsByType[type] ?? 0) + 1;
    }
    // Sort by count descending
    final sortedTypes = Map.fromEntries(
      violationsByType.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)),
    );

    // Violations by risk level
    final Map<String, int> violationsByRisk = {
      'Critical': 0,
      'High': 0,
      'Medium': 0,
      'Low': 0,
    };
    for (final i in incidents) {
      final risk = i['riskLevel'] as String? ?? 'Low';
      violationsByRisk[risk] = (violationsByRisk[risk] ?? 0) + 1;
    }

    // Daily trend (last 7 days)
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final List<DailyTrend> dailyTrend = [];
    for (var d = 6; d >= 0; d--) {
      final day = todayStart.subtract(Duration(days: d));
      final dayEnd = day.add(const Duration(days: 1));
      final count = incidents.where((i) {
        final t = DateTime.tryParse(i['occurredAt'] ?? '');
        return t != null && t.isAfter(day) && t.isBefore(dayEnd);
      }).length;
      dailyTrend.add(DailyTrend(day: dayNames[day.weekday - 1], count: count));
    }

    // Recent incidents (top 30, sorted by time)
    final sortedIncidents = List<dynamic>.from(incidents);
    sortedIncidents.sort((a, b) {
      final aTime = DateTime.tryParse(a['occurredAt'] ?? '') ?? DateTime(2000);
      final bTime = DateTime.tryParse(b['occurredAt'] ?? '') ?? DateTime(2000);
      return bTime.compareTo(aTime);
    });

    final recentIncidents = sortedIncidents
        .take(30)
        .map(
          (i) => RecentIncident(
            id: i['id'] ?? '',
            vehicleReg: i['vehicleRegistrationNumber'] ?? 'Unknown',
            driverName: i['driverName'] ?? 'Unknown',
            eventType: i['eventType'] ?? 'Unknown',
            projectSite: i['assignedProjectSite'] ?? '',
            occurredAt:
                DateTime.tryParse(i['occurredAt'] ?? '') ?? DateTime.now(),
            riskLevel: i['riskLevel'] ?? 'Low',
            aiConfidence: (i['aiConfidence'] as num?)?.toDouble() ?? 0,
            status: i['status'] ?? 'Open',
          ),
        )
        .toList();

    // Fleet map vehicles
    final fleetMapVehicles = fleetMapData
        .map(
          (v) => FleetMapVehicle(
            id: v['id'] ?? '',
            vehicleReg: v['vehicleRegistrationNumber'] ?? 'Unknown',
            vehicleType: v['vehicleType'] ?? '',
            assignedProjectSite: v['assignedProjectSite'] ?? '',
            latitude: (v['latitude'] as num?)?.toDouble(),
            longitude: (v['longitude'] as num?)?.toDouble(),
            currentSpeed: (v['currentSpeed'] as num?)?.toDouble() ?? 0,
            isOnline: v['isOnline'] == true,
            lastLocationUpdate: DateTime.tryParse(
              v['lastLocationUpdate'] ?? '',
            ),
          ),
        )
        .toList();

    // Compliance rates
    final activeDriverRate = totalDrivers > 0
        ? (activeDrivers / totalDrivers) * 100
        : 0.0;
    final fleetActiveRate = totalVehicles > 0
        ? (activeVehicles / totalVehicles) * 100
        : 0.0;
    final resolvedCount = incidents
        .where(
          (i) => i['status'] == 'Acknowledged' || i['status'] == 'Resolved',
        )
        .length;
    final alertResolutionRate = incidents.isNotEmpty
        ? (resolvedCount / incidents.length) * 100
        : 0.0;

    return DashboardStats(
      totalDrivers: totalDrivers,
      activeDrivers: activeDrivers,
      totalVehicles: totalVehicles,
      activeVehicles: activeVehicles,
      totalViolations: incidents.length,
      violationsToday: todayIncidents.length,
      criticalToday: criticalToday,
      highToday: highToday,
      violationsThisWeek: weekIncidents.length,
      violationsByType: sortedTypes,
      violationsByRisk: violationsByRisk,
      dailyTrend: dailyTrend,
      recentIncidents: recentIncidents,
      fleetMapVehicles: fleetMapVehicles,
      activeDriverRate: activeDriverRate,
      fleetActiveRate: fleetActiveRate,
      alertResolutionRate: alertResolutionRate,
    );
  }
}
