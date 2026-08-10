import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/dashboard_service.dart';
import '../services/auth_service.dart';
import 'theme/app_theme.dart';

class DashboardOverviewView extends StatefulWidget {
  final VoidCallback? onNavigateToMap;
  const DashboardOverviewView({super.key, this.onNavigateToMap});

  @override
  State<DashboardOverviewView> createState() => _DashboardOverviewViewState();
}

class _DashboardOverviewViewState extends State<DashboardOverviewView> {
  DashboardStats? _stats;
  bool _loading = true;
  String? _error;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _fetchData(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final stats = await DashboardService.instance.fetchDashboard();
      if (mounted) {
        setState(() {
          _stats = stats;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);

    if (_loading && _stats == null) {
      return Scaffold(
        backgroundColor: colors.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null && _stats == null) {
      return Scaffold(
        backgroundColor: colors.surface,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppTheme.danger),
              const SizedBox(height: 12),
              Text(
                'Failed to load dashboard',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(onPressed: _fetchData, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final stats = _stats!;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchData,
          child: CustomScrollView(
            slivers: [
              // Summary Cards
              SliverToBoxAdapter(child: _buildSummaryCards(stats, colors)),
              // Daily Incident Trend
              SliverToBoxAdapter(child: _buildDailyTrend(stats, colors)),
              // Top Violation Types
              SliverToBoxAdapter(child: _buildTopViolationTypes(stats, colors)),
              // Incidents by Risk Level
              SliverToBoxAdapter(child: _buildRiskLevel(stats, colors)),
              // Compliance Summary
              SliverToBoxAdapter(child: _buildComplianceSummary(stats, colors)),
              // Live Fleet Map Summary
              SliverToBoxAdapter(child: _buildFleetMapSummary(stats, colors)),
              // Live Alert Feed
              SliverToBoxAdapter(child: _buildLiveAlertFeed(stats, colors)),
              // Recent Incidents
              SliverToBoxAdapter(child: _buildRecentIncidents(stats, colors)),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(DashboardStats stats, AppColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _summaryCard(
                  icon: Icons.people_rounded,
                  iconColor: AppTheme.primary,
                  title: 'Total Drivers',
                  value: '${stats.totalDrivers}',
                  subtitle:
                      '${stats.activeDrivers} active · ${stats.totalDrivers > 0 ? ((stats.activeDrivers / stats.totalDrivers) * 100).round() : 0}%',
                  colors: colors,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _summaryCard(
                  icon: Icons.local_shipping_rounded,
                  iconColor: AppTheme.success,
                  title: 'Total Vehicles',
                  value: '${stats.totalVehicles}',
                  subtitle: '${stats.activeVehicles} active',
                  colors: colors,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _summaryCard(
                  icon: Icons.warning_amber_rounded,
                  iconColor: AppTheme.warning,
                  title: 'Total Violations',
                  value: '${stats.totalViolations}',
                  subtitle: '${stats.violationsThisWeek} this week',
                  colors: colors,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _summaryCard(
                  icon: Icons.notification_important_rounded,
                  iconColor: AppTheme.danger,
                  title: 'Violations Today',
                  value: '${stats.violationsToday}',
                  subtitle:
                      '${stats.criticalToday} critical · ${stats.highToday} high',
                  colors: colors,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
    required AppColors colors,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: colors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyTrend(DashboardStats stats, AppColors colors) {
    final maxCount = stats.dailyTrend.map((d) => d.count).fold(0, max);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daily Incident Trend',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Last 7 days',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: colors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 160,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: stats.dailyTrend.map((trend) {
                  final isToday = trend == stats.dailyTrend.last;
                  final barHeight = maxCount > 0
                      ? (trend.count / maxCount) * 100
                      : 0.0;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (trend.count > 0)
                            Text(
                              '${trend.count}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: colors.textSecondary,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Container(
                            height: barHeight.clamp(4.0, 100.0),
                            decoration: BoxDecoration(
                              color: isToday
                                  ? AppTheme.warning
                                  : AppTheme.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            trend.day,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              color: colors.textMuted,
                              fontWeight: isToday
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopViolationTypes(DashboardStats stats, AppColors colors) {
    final types = stats.violationsByType.entries.take(6).toList();
    final maxVal = types.isNotEmpty ? types.first.value : 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Top Violation Types',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'All time',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: colors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...types.map((entry) {
              final fraction = entry.value / maxVal;
              final barColor = _violationTypeColor(entry.key);
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text(
                        entry.key,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: fraction,
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: barColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 36,
                      child: Text(
                        '${entry.value}',
                        textAlign: TextAlign.end,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskLevel(DashboardStats stats, AppColors colors) {
    final risk = stats.violationsByRisk;
    final total = stats.totalViolations;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Incidents by Risk Level',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$total',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _riskRow(
              'Critical',
              risk['Critical'] ?? 0,
              const Color(0xFF991B1B),
              colors,
            ),
            _riskRow('High', risk['High'] ?? 0, AppTheme.danger, colors),
            _riskRow('Medium', risk['Medium'] ?? 0, AppTheme.warning, colors),
            _riskRow('Low', risk['Low'] ?? 0, AppTheme.primary, colors),
          ],
        ),
      ),
    );
  }

  Widget _riskRow(String label, int count, Color color, AppColors colors) {
    final total = _stats!.totalViolations;
    final fraction = total > 0 ? count / total : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: fraction,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 36,
            child: Text(
              '$count',
              textAlign: TextAlign.end,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplianceSummary(DashboardStats stats, AppColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Compliance Summary',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _complianceRow(
              'Active Driver Rate',
              stats.activeDriverRate,
              colors,
            ),
            const SizedBox(height: 12),
            _complianceRow('Fleet Active Rate', stats.fleetActiveRate, colors),
            const SizedBox(height: 12),
            _complianceRow(
              'Alert Resolution Rate',
              stats.alertResolutionRate,
              colors,
            ),
          ],
        ),
      ),
    );
  }

  Widget _complianceRow(String label, double percent, AppColors colors) {
    final color = percent >= 80
        ? AppTheme.success
        : percent >= 50
        ? AppTheme.warning
        : AppTheme.danger;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${percent.round()}%',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent / 100,
            minHeight: 6,
            backgroundColor: colors.surface,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildFleetMapSummary(DashboardStats stats, AppColors colors) {
    final online = stats.fleetMapVehicles.where((v) => v.isOnline).length;
    final offline = stats.fleetMapVehicles.where((v) => !v.isOnline).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: GestureDetector(
        onTap: widget.onNavigateToMap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Live Fleet Map',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppTheme.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$online online',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppTheme.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: colors.textMuted,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$offline offline',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: colors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...stats.fleetMapVehicles.map((v) => _vehicleRow(v, colors)),
              if (widget.onNavigateToMap != null) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map_rounded, size: 14, color: AppTheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Tap to view full map',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 10,
                      color: AppTheme.primary,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _vehicleRow(FleetMapVehicle v, AppColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (v.isOnline ? AppTheme.success : colors.textMuted)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.local_shipping_rounded,
              size: 18,
              color: v.isOnline ? AppTheme.success : colors.textMuted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  v.vehicleReg,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  '${v.vehicleType} · ${v.assignedProjectSite}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (v.isOnline ? AppTheme.success : colors.textMuted)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  v.isOnline ? 'Online' : 'Offline',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: v.isOnline ? AppTheme.success : colors.textMuted,
                  ),
                ),
              ),
              if (v.isOnline) ...[
                const SizedBox(height: 2),
                Text(
                  '${v.currentSpeed.round()} km/h',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: colors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiveAlertFeed(DashboardStats stats, AppColors colors) {
    final openIncidents = stats.recentIncidents
        .where((i) => i.status == 'Open')
        .take(8)
        .toList();

    if (openIncidents.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Live Alert Feed',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppTheme.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Auto-updating',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: AppTheme.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...openIncidents.map(
              (incident) => _alertFeedItem(incident, colors),
            ),
          ],
        ),
      ),
    );
  }

  Widget _alertFeedItem(RecentIncident incident, AppColors colors) {
    final riskColor = _riskColor(incident.riskLevel);
    final time =
        '${incident.occurredAt.hour.toString().padLeft(2, '0')}:${incident.occurredAt.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(color: riskColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  incident.eventType,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${incident.vehicleReg} · ${incident.driverName}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: colors.textSecondary,
                  ),
                ),
                Text(
                  '$time · ${incident.status}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: riskColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              incident.riskLevel.toUpperCase(),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: riskColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentIncidents(DashboardStats stats, AppColors colors) {
    final incidents = stats.recentIncidents.take(10).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Incidents',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  '${stats.totalViolations} Total Violations',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Table header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text('Vehicle', style: _tableHeaderStyle(colors)),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text('Driver', style: _tableHeaderStyle(colors)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('Event', style: _tableHeaderStyle(colors)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('Risk', style: _tableHeaderStyle(colors)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            ...incidents.map((incident) => _incidentRow(incident, colors)),
          ],
        ),
      ),
    );
  }

  Widget _incidentRow(RecentIncident incident, AppColors colors) {
    final riskColor = _riskColor(incident.riskLevel);
    final time =
        '${incident.occurredAt.hour.toString().padLeft(2, '0')}:${incident.occurredAt.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colors.cardBorder.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  incident.vehicleReg,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  time,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              incident.driverName,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: colors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              incident.eventType,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: _violationTypeColor(incident.eventType),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  incident.riskLevel.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: riskColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _tableHeaderStyle(AppColors colors) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: colors.textMuted,
      letterSpacing: 0.3,
    );
  }

  Color _riskColor(String risk) {
    switch (risk) {
      case 'Critical':
        return const Color(0xFF991B1B);
      case 'High':
        return AppTheme.danger;
      case 'Medium':
        return AppTheme.warning;
      default:
        return AppTheme.primary;
    }
  }

  Color _violationTypeColor(String type) {
    switch (type) {
      case 'Distraction':
        return AppTheme.warning;
      case 'Drowsiness':
        return const Color(0xFF7C3AED);
      case 'PhoneUsage':
        return AppTheme.danger;
      case 'Seatbelt':
        return const Color(0xFF0891B2);
      case 'UnauthorizedDriver':
        return const Color(0xFF991B1B);
      case 'TripStop':
        return AppTheme.primary;
      case 'TripStart':
        return AppTheme.success;
      case 'Speeding':
        return AppTheme.danger;
      case 'HarshBraking':
        return AppTheme.warning;
      default:
        return AppTheme.primary;
    }
  }
}
