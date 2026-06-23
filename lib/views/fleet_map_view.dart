import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supervisor_proximity/profile_view.dart';
import 'package:supervisor_proximity/controllers/locale_controller.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/fleet_controller.dart';
import '../controllers/project_sites_controller.dart';
import '../models/fleet_models.dart';
import 'theme/app_theme.dart';
import '../controllers/theme_controller.dart';
import 'package:flutter_map/flutter_map.dart';
import 'widgets/fleet_map.dart';
import 'widgets/common.dart';

class FleetMapView extends StatefulWidget {
  const FleetMapView({super.key});

  @override
  State<FleetMapView> createState() => _FleetMapViewState();
}

class _FleetMapViewState extends State<FleetMapView> {
  String? _selectedId;
  String _activeFilter = 'All';
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sitesController = context.read<ProjectSitesController>();
      if (sitesController.projectSites.isEmpty) {
        sitesController.fetchProjectSites();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final fleet = context.watch<FleetController>();
    final colors = AppTheme.of(context);

    // Apply Filter to list of vehicles
    final filteredVehicles = fleet.vehicles.where((v) {
      if (_activeFilter == 'All') return true;
      if (_activeFilter == 'Driving') return v.status == VehicleStatus.driving;
      if (_activeFilter == 'Idle') return v.status == VehicleStatus.idle;
      if (_activeFilter == 'Alerts') return v.status == VehicleStatus.alert;
      if (_activeFilter == 'Offline') return v.status == VehicleStatus.offline;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: colors.surface,
      body: Column(
        children: [
          _premiumHeader(context, fleet),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                // Live Tracking Map header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context).translate('fleet_map'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: colors.textSecondary,
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Map Section
                Stack(
                  children: [
                    FleetMap(
                      mapController: _mapController,
                      vehicles: fleet.vehicles,
                      selectedId: _selectedId,
                      onSelect: (id) => setState(() => _selectedId = id),
                      height: 320,
                    ),

                    // Floating map overlays (Compass & zoom controls)
                    Positioned(
                      right: 12,
                      bottom: 96,
                      child: _mapFloatingButton(Icons.explore_outlined, () {
                        _mapController.rotate(0);
                      }),
                    ),
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _mapFloatingButton(Icons.add, () {
                            final currentZoom = _mapController.camera.zoom;
                            _mapController.move(
                              _mapController.camera.center,
                              currentZoom + 1,
                            );
                          }),
                          const SizedBox(height: 6),
                          _mapFloatingButton(Icons.remove, () {
                            final currentZoom = _mapController.camera.zoom;
                            _mapController.move(
                              _mapController.camera.center,
                              currentZoom - 1,
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Legend
                _legendRow(context),
                const SizedBox(height: 24),

                // All Fleets Title Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context).translate('all_fleets'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          '${AppLocalizations.of(context).translate('total')}: ${fleet.vehicles.length.toString().padLeft(2, '0')}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: Text(
                        'View all',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2B72F5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Filter Chips Horizontal Scroll
                // SizedBox(
                //   height: 38,
                //   child: ListView(
                //     scrollDirection: Axis.horizontal,
                //     children: [
                //       _filterChip('All', _activeFilter == 'All'),
                //       _filterChip('Driving', _activeFilter == 'Driving'),
                //       _filterChip('Idle', _activeFilter == 'Idle'),
                //       _filterChip('By Zone', _activeFilter == 'By Zone'),
                //     ],
                //   ),
                // ),
                const SizedBox(height: 16),

                // Vehicles list filtered
                ...filteredVehicles.map((v) => _vehicleCard(context, v)),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _premiumHeader(BuildContext context, FleetController fleet) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 54, 16, 20),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/common_background.png'),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SupervisorProfileView(),
                  ),
                ),
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    fleet.supervisorInitials,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hi, ${fleet.supervisorName}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      AppLocalizations.of(context).translate('live_fleet'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                    ),
                  ],
                ),
              ),
              // Live status Pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      AppLocalizations.of(context).translate('live'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // Search & Notification icons
              _headerIconButton(
                Icons.search,
                onTap: () => _showSearchSheet(context),
              ),
              const SizedBox(width: 6),
              _headerIconButton(
                context.watch<ThemeController>().isDarkMode
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
                onTap: () => context.read<ThemeController>().toggleTheme(),
              ),
              const SizedBox(width: 6),
              _headerIconButton(
                Icons.notifications_none,
                onTap: () => _showNotificationsSheet(context),
              ),
              const SizedBox(width: 6),
              PopupMenuButton<String>(
                icon: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.language,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
                onSelected: (String languageCode) {
                  context.read<LocaleController>().setLocale(
                    Locale(languageCode),
                  );
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'en',
                    child: Text('English'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'ar',
                    child: Text('العربية'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'hi',
                    child: Text('हिन्दी'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Project Site Dropdown Container
          _buildProjectSiteDropdown(context),
        ],
      ),
    );
  }

  Widget _buildProjectSiteDropdown(BuildContext context) {
    final sitesController = context.watch<ProjectSitesController>();
    final activeSites = sitesController.projectSites
        .where((s) => s.isActive)
        .toList();
    final selectedSite = sitesController.selectedSite;
    final colors = AppTheme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_on_outlined,
            color: Color(0xFF2B72F5),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: activeSites.isEmpty
                ? Text(
                    sitesController.isLoading
                        ? 'Loading sites...'
                        : 'No active sites',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  )
                : DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      isDense: true,
                      dropdownColor: colors.card,
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.cardBorder),
                        ),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: colors.textMuted,
                        ),
                      ),
                      value: selectedSite?.id,
                      hint: Text(
                        'Select Site',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                      onChanged: (String? newId) {
                        if (newId != null) {
                          final site = activeSites.firstWhere(
                            (s) => s.id == newId,
                          );
                          context
                              .read<ProjectSitesController>()
                              .setSelectedSite(site);
                        }
                      },
                      items: activeSites.map((site) {
                        return DropdownMenuItem<String>(
                          value: site.id,
                          child: Text(site.name),
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _headerIconButton(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF1D4ED8), size: 16),
      ),
    );
  }

  Widget _statusCountCol(
    IconData icon,
    String label,
    String count,
    Color color,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            color: const Color(0xFF64748B),
          ),
        ),
        Text(
          count,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _statusCountDivider() {
    return Container(height: 32, width: 1, color: const Color(0xFFE2E8F0));
  }

  Widget _mapFloatingButton(IconData icon, VoidCallback onTap) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, size: 18, color: const Color(0xFF64748B)),
        onPressed: onTap,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _legendRow(BuildContext context) {
    Widget item(Color c, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
    return Wrap(
      spacing: 16,
      alignment: WrapAlignment.center,
      children: [
        item(
          const Color(0xFF3B82F6),
          AppLocalizations.of(context).translate('active'),
        ),
        item(
          const Color(0xFFF59E0B),
          AppLocalizations.of(context).translate('idle'),
        ),
        item(
          const Color(0xFFEF4444),
          AppLocalizations.of(context).translate('alert'),
        ),
        item(
          const Color(0xFF94A3B8),
          AppLocalizations.of(context).translate('offline'),
        ),
      ],
    );
  }

  Widget _filterChip(String text, bool selected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(text),
        selected: selected,
        onSelected: (val) {
          if (val) {
            setState(() {
              _activeFilter = text;
            });
          }
        },
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          color: selected ? Colors.white : const Color(0xFF64748B),
        ),
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFF2B72F5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: selected ? Colors.transparent : const Color(0xFFE2E8F0),
          ),
        ),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }

  Widget _vehicleCard(BuildContext context, FleetVehicle v) {
    final statusColor = vehicleStatusColor(v.status);
    final isSel = v.id == _selectedId;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedId = v.id);
        _showVehicleBottomSheet(context, v);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.of(context).card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSel
                ? const Color(0xFF2B72F5)
                : AppTheme.of(context).cardBorder,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Row 1: Icon, ID, status pill
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.local_shipping_rounded,
                    size: 16,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  v.registration,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    v.status.label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Row 2: Driver icon/name, speedometer/speed
            Row(
              children: [
                const Icon(
                  Icons.person_outline_rounded,
                  size: 14,
                  color: Color(0xFF94A3B8),
                ),
                const SizedBox(width: 4),
                Text(
                  _resolveDriverName(v, context.read<FleetController>()),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.speed_rounded,
                  size: 14,
                  color: Color(0xFF2B72F5),
                ),
                const SizedBox(width: 4),
                Text(
                  '${v.speedKmh.toInt()} km/h',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2B72F5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Row 3: Route path details
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: Color(0xFF94A3B8),
                ),
                const SizedBox(width: 4),
                Text(
                  'Warehouse',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 12,
                  color: Color(0xFF94A3B8),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: Color(0xFF94A3B8),
                ),
                const SizedBox(width: 4),
                Text(
                  'Delivery Hub',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),

            // Row 4: Red Warning Box (only for Alerts status)
            if (v.status == VehicleStatus.alert) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 14,
                      color: Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Phone Usage Detected',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showVehicleBottomSheet(BuildContext context, FleetVehicle v) {
    final statusColor = vehicleStatusColor(v.status);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.of(context).surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            24,
            12,
            24,
            MediaQuery.of(ctx).viewPadding.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Row 1: Truck icon + Registration + Status pill
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.local_shipping_rounded,
                      size: 22,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      v.registration,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      v.status.label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Row 2: Driver + Speed
              Row(
                children: [
                  Icon(
                    Icons.person_outline_rounded,
                    size: 16,
                    color: const Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    v.driverName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.speed_rounded,
                    size: 16,
                    color: const Color(0xFF2B72F5),
                  ),
                  const SizedBox(width: 6),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${v.speedKmh.toInt()} ',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        TextSpan(
                          text: 'km/h',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Row 3: Route
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: const Color(0xFF2B72F5),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Warehouse',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: const Color(0xFFEF4444),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Delivery Hub',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Divider
              Divider(color: const Color(0xFFE2E8F0), thickness: 1),
              const SizedBox(height: 16),

              // Row 4: Progress | Safety | Zone
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.route_rounded,
                          size: 20,
                          color: const Color(0xFF64748B),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Progress',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                        Text(
                          '${(v.routeProgress * 100).toInt()}%',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 50,
                    width: 1,
                    color: const Color(0xFFE2E8F0),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: 20,
                            color: const Color(0xFF64748B),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Safety',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                          Text(
                            '${v.safetyScore}%',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    height: 50,
                    width: 1,
                    color: const Color(0xFFE2E8F0),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 20,
                            color: const Color(0xFF64748B),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Zone',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                          Text(
                            v.inGeofence ? 'In' : 'Out',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: v.inGeofence
                                  ? const Color(0xFF2B72F5)
                                  : const Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Call & Message buttons
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          final fleet = context.read<FleetController>();
                          final phone = _resolveDriverPhone(v, fleet);
                          final name = _resolveDriverName(v, fleet);
                          if (phone.isNotEmpty) {
                            launchUrl(Uri.parse('tel:$phone'));
                          } else {
                            _snack(
                              context,
                              'No phone number available for $name',
                            );
                          }
                        },
                        icon: const Icon(Icons.phone_outlined, size: 18),
                        label: Text(
                          'Call',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2B72F5),
                          side: const BorderSide(
                            color: Color(0xFFE2E8F0),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          final fleet = context.read<FleetController>();
                          final phone = _resolveDriverPhone(v, fleet);
                          final name = _resolveDriverName(v, fleet);
                          if (phone.isNotEmpty) {
                            launchUrl(Uri.parse('sms:$phone'));
                          } else {
                            _snack(
                              context,
                              'No phone number available for $name',
                            );
                          }
                        },
                        icon: const Icon(Icons.mail_outline_rounded, size: 18),
                        label: Text(
                          'Message',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2B72F5),
                          side: const BorderSide(
                            color: Color(0xFFE2E8F0),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _resolveDriverPhone(FleetVehicle v, FleetController fleet) {
    // Try rawApiData first
    final fromRaw =
        v.rawApiData['driverPhone'] ??
        v.rawApiData['mobileNumber'] ??
        v.rawApiData['assignedDriverPhone'] ??
        '';
    if (fromRaw.toString().isNotEmpty) return fromRaw.toString();

    // Cross-reference with apiDrivers by name
    final driverName = v.driverName.toLowerCase();
    if (driverName.isNotEmpty &&
        driverName != 'unknown' &&
        driverName != 'unassigned') {
      for (final d in fleet.apiDrivers) {
        final name = (d['driverName'] ?? d['name'] ?? '')
            .toString()
            .toLowerCase();
        if (name == driverName) {
          final phone =
              d['mobileNumber'] ?? d['phone'] ?? d['driverPhone'] ?? '';
          if (phone.toString().isNotEmpty) return phone.toString();
        }
      }
    }
    return '';
  }

  String _resolveDriverName(FleetVehicle v, FleetController fleet) {
    if (v.driverName.isNotEmpty &&
        v.driverName != 'Unknown' &&
        v.driverName != 'Unassigned') {
      return v.driverName;
    }
    // Try rawApiData
    final fromRaw =
        v.rawApiData['assignedDriverName'] ?? v.rawApiData['driverName'] ?? '';
    if (fromRaw.toString().isNotEmpty) return fromRaw.toString();
    return v.driverName;
  }

  void _showSearchSheet(BuildContext context) {
    final fleet = context.read<FleetController>();
    final searchController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final query = searchController.text.toLowerCase();
            final results = query.isEmpty
                ? <FleetVehicle>[]
                : fleet.vehicles.where((v) {
                    return v.registration.toLowerCase().contains(query) ||
                        v.driverName.toLowerCase().contains(query) ||
                        v.routeName.toLowerCase().contains(query);
                  }).toList();
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.7,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.of(context).surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  MediaQuery.of(ctx).viewPadding.bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: searchController,
                      autofocus: true,
                      onChanged: (_) => setSheetState(() {}),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: AppTheme.of(context).textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search vehicle, driver...',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: AppTheme.of(context).textMuted,
                        ),
                        prefixIcon: const Icon(Icons.search, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: AppTheme.of(context).cardBorder,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: AppTheme.of(context).cardBorder,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFF2B72F5),
                            width: 1.5,
                          ),
                        ),
                        filled: true,
                        fillColor: AppTheme.of(context).card,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (query.isNotEmpty && results.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'No vehicles found',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: AppTheme.of(context).textMuted,
                          ),
                        ),
                      ),
                    if (results.isNotEmpty)
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: results.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            color: AppTheme.of(context).cardBorder,
                          ),
                          itemBuilder: (_, i) {
                            final v = results[i];
                            final statusColor = vehicleStatusColor(v.status);
                            return Material(
                              color: Colors.transparent,
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.local_shipping_rounded,
                                    size: 18,
                                    color: statusColor,
                                  ),
                                ),
                                title: Text(
                                  v.registration,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.of(context).textPrimary,
                                  ),
                                ),
                                subtitle: Text(
                                  _resolveDriverName(v, fleet),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: AppTheme.of(context).textMuted,
                                  ),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    v.status.label,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  setState(() => _selectedId = v.id);
                                  _showVehicleBottomSheet(context, v);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) => searchController.dispose());
  }

  void _showNotificationsSheet(BuildContext context) {
    final fleet = context.read<FleetController>();
    final recentIncidents = fleet.incidents.take(20).toList();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.7,
          ),
          decoration: BoxDecoration(
            color: AppTheme.of(context).surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(ctx).viewPadding.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(
                    Icons.notifications_active_rounded,
                    size: 20,
                    color: Color(0xFF2B72F5),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Notifications',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.of(context).textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${recentIncidents.length} recent',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppTheme.of(context).textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (recentIncidents.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'No notifications',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppTheme.of(context).textMuted,
                    ),
                  ),
                ),
              if (recentIncidents.isNotEmpty)
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: recentIncidents.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: AppTheme.of(context).cardBorder,
                    ),
                    itemBuilder: (_, i) {
                      final inc = recentIncidents[i];
                      final color = severityColor(inc.severity);
                      final icon = incidentIcon(inc.type);
                      final age = DateTime.now().difference(inc.timestamp);
                      final timeAgo = age.inMinutes < 60
                          ? '${age.inMinutes}m ago'
                          : age.inHours < 24
                          ? '${age.inHours}h ago'
                          : '${age.inDays}d ago';
                      return Material(
                        color: Colors.transparent,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, size: 18, color: color),
                          ),
                          title: Text(
                            '${inc.type.label} · ${inc.vehicleReg}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.of(context).textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            '${inc.driverName} · ${inc.severity.name[0].toUpperCase()}${inc.severity.name.substring(1)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppTheme.of(context).textMuted,
                            ),
                          ),
                          trailing: Text(
                            timeAgo,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppTheme.of(context).textMuted,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }
}
