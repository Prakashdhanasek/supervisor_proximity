import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../controllers/fleet_controller.dart';
import 'admin_device_management_view.dart';
import 'notification_settings_view.dart';
import 'dashboard_overview_view.dart';
import 'fleet_map_view.dart';
import 'geofencing_view.dart';
import 'incidents_view.dart';
import 'live_streaming_view.dart';
import 'masterview.dart';
import 'project_sites_view.dart';
import 'scorecards_view.dart';
import 'theme/app_theme.dart';
import 'trip_monitoring_view.dart';
import 'vehicle_types_view.dart';
import 'video_recordings_view.dart';

class SupervisorShell extends StatefulWidget {
  const SupervisorShell({super.key});

  @override
  State<SupervisorShell> createState() => _SupervisorShellState();
}

class _ShellSection {
  final String title;
  final List<_ShellItem> items;

  const _ShellSection({required this.title, required this.items});
}

class _ShellItem {
  final String key;
  final String title;
  final IconData icon;
  final Widget page;

  const _ShellItem({
    required this.key,
    required this.title,
    required this.icon,
    required this.page,
  });
}

class _SupervisorShellState extends State<SupervisorShell> {
  int _index = 0;

  late final List<_ShellSection> _sections = [
    _ShellSection(
      title: 'Dashboard',
      items: [
        _ShellItem(
          key: 'overview',
          title: 'Overview',
          icon: Icons.dashboard_outlined,
          page: const DashboardOverviewView(),
        ),
        _ShellItem(
          key: 'fleet-map',
          title: 'Fleet Live Map',
          icon: Icons.map_outlined,
          page: const FleetMapView(),
        ),
        _ShellItem(
          key: 'incidents',
          title: 'Incidents & Evidence',
          icon: Icons.warning_amber_rounded,
          page: const IncidentsView(),
        ),
        _ShellItem(
          key: 'trips',
          title: 'Trip Monitoring',
          icon: Icons.timeline_rounded,
          page: const TripMonitoringView(),
        ),
        _ShellItem(
          key: 'videos',
          title: 'Video Recordings',
          icon: Icons.videocam_outlined,
          page: const VideoRecordingsView(),
        ),
        _ShellItem(
          key: 'geofence',
          title: 'Geofencing',
          icon: Icons.location_on_outlined,
          page: const GeofencingView(),
        ),
        _ShellItem(
          key: 'streaming',
          title: 'Live Streaming',
          icon: Icons.wifi_tethering_rounded,
          page: const LiveStreamingView(),
        ),
      ],
    ),
    _ShellSection(
      title: 'Master Data',
      items: [
        _ShellItem(
          key: 'driver-master',
          title: 'Driver Master',
          icon: Icons.person_outline_rounded,
          page: const MasterView(initialTab: 0),
        ),
        _ShellItem(
          key: 'vehicle-master',
          title: 'Vehicle Master',
          icon: Icons.local_shipping_outlined,
          page: const MasterView(initialTab: 1),
        ),
      ],
    ),
    _ShellSection(
      title: 'Analytics',
      items: [
        _ShellItem(
          key: 'scorecard',
          title: 'Driver Scorecard',
          icon: Icons.bar_chart_rounded,
          page: const ScorecardsView(),
        ),
      ],
    ),
    _ShellSection(
      title: 'Configuration',
      items: [
        _ShellItem(
          key: 'vehicle-types',
          title: 'Vehicle Types',
          icon: Icons.local_offer_outlined,
          page: const VehicleTypesView(),
        ),
        _ShellItem(
          key: 'sites',
          title: 'Project / Sites',
          icon: Icons.push_pin_outlined,
          page: const ProjectSitesView(),
        ),
        _ShellItem(
          key: 'devices',
          title: 'Hardware Devices',
          icon: Icons.tablet_android_outlined,
          page: const AdminDeviceManagementView(),
        ),
        _ShellItem(
          key: 'settings',
          title: 'Settings',
          icon: Icons.settings_outlined,
          page: const NotificationSettingsView(),
        ),
      ],
    ),
  ];

  late final List<_ShellItem> _items = _sections
      .expand((s) => s.items)
      .toList();

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 980;
    final colors = AppTheme.of(context);

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: isWide
          ? null
          : AppBar(
              elevation: 0,
              backgroundColor: colors.card,
              iconTheme: IconThemeData(color: colors.textPrimary),
              title: Text(
                _items[_index].title,
                style: GoogleFonts.plusJakartaSans(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
      drawer: isWide ? null : Drawer(child: _sideNav()),
      body: isWide
          ? Row(
              children: [
                SizedBox(width: 280, child: _sideNav()),
                Expanded(
                  child: IndexedStack(
                    index: _index,
                    children: _items.map((e) => e.page).toList(),
                  ),
                ),
              ],
            )
          : IndexedStack(
              index: _index,
              children: _items.map((e) => e.page).toList(),
            ),
    );
  }

  Widget _sideNav() {
    final fleet = context.watch<FleetController>();
    final colors = AppTheme.of(context);

    return Container(
      color: colors.card,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: colors.cardBorder)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A4CB1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Proximity Guard',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          'Driver Intelligence',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                children: [
                  for (final section in _sections) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
                      child: Text(
                        section.title.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w700,
                          color: colors.textMuted,
                        ),
                      ),
                    ),
                    for (final item in section.items) _sideNavItem(item),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: colors.cardBorder)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A4CB1).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      fleet.supervisorInitials,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0A4CB1),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fleet.supervisorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          fleet.supervisorEmail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sideNavItem(_ShellItem item) {
    final colors = AppTheme.of(context);
    final itemIndex = _items.indexOf(item);
    final active = _index == itemIndex;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            setState(() => _index = itemIndex);
            if (MediaQuery.of(context).size.width < 980) {
              Navigator.of(context).maybePop();
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: active
                  ? const Color(0xFF0A4CB1).withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: active
                  ? Border.all(
                      color: const Color(0xFF0A4CB1).withValues(alpha: 0.28),
                    )
                  : null,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 18,
                  color: active
                      ? const Color(0xFF0A4CB1)
                      : colors.textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: active
                          ? const Color(0xFF0A4CB1)
                          : colors.textSecondary,
                    ),
                  ),
                ),
                if (item.key == 'incidents')
                  _badge(
                    context.watch<FleetController>().unreviewedIncidents.length,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _badge(int count) {
    if (count <= 0) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.danger,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
