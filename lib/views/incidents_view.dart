import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../controllers/fleet_controller.dart';
import '../models/fleet_models.dart';
import 'theme/app_theme.dart';
import 'widgets/common.dart';
import 'incident_detail_view.dart';

class IncidentsView extends StatefulWidget {
  const IncidentsView({super.key});

  @override
  State<IncidentsView> createState() => _IncidentsViewState();
}

enum _Filter { all, unreviewed, resolved }

class _IncidentsViewState extends State<IncidentsView> {
  _Filter _filter = _Filter.all;
  DateTime? _selectedDate;
  String? _selectedDriver;
  String? _selectedVehicle;

  @override
  Widget build(BuildContext context) {
    final fleet = context.watch<FleetController>();
    final colors = AppTheme.of(context);

    // Get unique drivers from API (full list) and vehicles from fleet list
    final allDrivers = fleet.apiDrivers.map((d) => d.fullName).toSet().toList()
      ..sort();
    final allVehicles =
        fleet.vehicles.map((v) => v.registration).toSet().toList()..sort();

    // Apply all filters
    final incidents = fleet.incidents.where((i) {
      // Status filter
      final passStatus = switch (_filter) {
        _Filter.all => true,
        _Filter.unreviewed => i.reviewState == ReviewState.unreviewed,
        _Filter.resolved => i.reviewState == ReviewState.resolved,
      };
      if (!passStatus) return false;

      // Date filter
      if (_selectedDate != null) {
        final incDate = DateTime(
          i.timestamp.year,
          i.timestamp.month,
          i.timestamp.day,
        );
        final selDate = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
        );
        if (incDate != selDate) return false;
      }

      // Driver filter
      if (_selectedDriver != null && i.driverName != _selectedDriver)
        return false;

      // Vehicle filter
      if (_selectedVehicle != null && i.vehicleReg != _selectedVehicle)
        return false;

      return true;
    }).toList();

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Incidents & Evidence',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          '${incidents.length} / ${fleet.incidents.length}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_hasActiveFilters)
                    IconButton(
                      onPressed: _clearFilters,
                      icon: Icon(
                        Icons.filter_alt_off_rounded,
                        color: colors.textMuted,
                        size: 22,
                      ),
                      tooltip: 'Clear filters',
                    ),
                ],
              ),
            ),

            // Filter bar: Date, Driver, Vehicle
            _buildFilterBar(context, allDrivers, allVehicles),
            const SizedBox(height: 8),

            // Status chips
            _statusChips(context),
            const SizedBox(height: 8),

            // Incident list
            Expanded(
              child: incidents.isEmpty
                  ? _empty(context)
                  : RefreshIndicator(
                      onRefresh: () => fleet.fetchIncidents(),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: incidents.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) =>
                            _incidentCard(context, fleet, incidents[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _hasActiveFilters =>
      _selectedDate != null ||
      _selectedDriver != null ||
      _selectedVehicle != null;

  void _clearFilters() {
    setState(() {
      _selectedDate = null;
      _selectedDriver = null;
      _selectedVehicle = null;
    });
  }

  Widget _buildFilterBar(
    BuildContext context,
    List<String> drivers,
    List<String> vehicles,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Date filter
          _filterChip(
            context,
            icon: Icons.calendar_today_rounded,
            label: _selectedDate != null
                ? DateFormat('dd MMM yyyy').format(_selectedDate!)
                : 'Date',
            active: _selectedDate != null,
            onTap: () => _pickDate(context),
          ),
          const SizedBox(width: 8),
          // Driver filter
          _filterChip(
            context,
            icon: Icons.person_rounded,
            label: _selectedDriver ?? 'All Drivers',
            active: _selectedDriver != null,
            onTap: () => _showDriverPicker(context, drivers),
          ),
          const SizedBox(width: 8),
          // Vehicle filter
          _filterChip(
            context,
            icon: Icons.directions_car_rounded,
            label: _selectedVehicle ?? 'All Vehicles',
            active: _selectedVehicle != null,
            onTap: () => _showVehiclePicker(context, vehicles),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    final colors = AppTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: active ? AppTheme.primary.withValues(alpha: 0.1) : colors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? AppTheme.primary : colors.cardBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: active ? AppTheme.primary : colors.textMuted,
            ),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: active ? AppTheme.primary : colors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: active ? AppTheme.primary : colors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final colors = AppTheme.of(context);
    final isDark = colors.surface != Colors.white;
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? ColorScheme.dark(
                    primary: AppTheme.primary,
                    onPrimary: Colors.white,
                    surface: colors.card,
                    onSurface: colors.textPrimary,
                  )
                : ColorScheme.light(
                    primary: AppTheme.primary,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Colors.black87,
                  ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _showDriverPicker(BuildContext context, List<String> drivers) {
    _showFilterBottomSheet(
      context,
      title: 'Select Driver',
      items: drivers,
      selected: _selectedDriver,
      onSelected: (v) => setState(() => _selectedDriver = v),
    );
  }

  void _showVehiclePicker(BuildContext context, List<String> vehicles) {
    _showFilterBottomSheet(
      context,
      title: 'Select Vehicle',
      items: vehicles,
      selected: _selectedVehicle,
      onSelected: (v) => setState(() => _selectedVehicle = v),
    );
  }

  void _showFilterBottomSheet(
    BuildContext context, {
    required String title,
    required List<String> items,
    required String? selected,
    required void Function(String?) onSelected,
  }) {
    final colors = AppTheme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.cardBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
          ),
          // "All" option
          ListTile(
            leading: Icon(
              selected == null
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: selected == null ? AppTheme.primary : colors.textMuted,
              size: 20,
            ),
            title: Text(
              'All',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: selected == null
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: colors.textPrimary,
              ),
            ),
            onTap: () {
              onSelected(null);
              Navigator.pop(context);
            },
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: items.length,
              itemBuilder: (_, i) {
                final isSelected = items[i] == selected;
                return ListTile(
                  leading: Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: isSelected ? AppTheme.primary : colors.textMuted,
                    size: 20,
                  ),
                  title: Text(
                    items[i],
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: colors.textPrimary,
                    ),
                  ),
                  onTap: () {
                    onSelected(items[i]);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _statusChips(BuildContext context) {
    Widget chip(_Filter f, String label) {
      final active = _filter == f;
      return GestureDetector(
        onTap: () => setState(() => _filter = f),
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppTheme.primary : AppTheme.of(context).card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active
                  ? AppTheme.primary
                  : AppTheme.of(context).cardBorder,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : AppTheme.of(context).textSecondary,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          chip(_Filter.all, 'All'),
          chip(_Filter.unreviewed, 'Unreviewed'),
          chip(_Filter.resolved, 'Resolved'),
        ],
      ),
    );
  }

  Widget _empty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inbox_rounded,
            size: 46,
            color: AppTheme.of(context).textMuted.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            'No incidents found',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppTheme.of(context).textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _incidentCard(
    BuildContext context,
    FleetController fleet,
    FleetIncident inc,
  ) {
    final color = severityColor(inc.severity);
    final resolved = inc.reviewState == ReviewState.resolved;
    final colors = AppTheme.of(context);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => IncidentDetailView(incident: inc)),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: AppTheme.cardDecoration(
          context,
          borderColor: resolved ? null : color.withValues(alpha: 0.3),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(incidentIcon(inc.type), color: color, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            inc.type.label,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusChip(label: inc.severity.name, color: color),
                        ],
                      ),
                      Text(
                        '${inc.vehicleReg} · ${inc.driverName}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  timeAgo(inc.timestamp),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.place_rounded, size: 13, color: colors.textMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    inc.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                if (inc.confidence != null) ...[
                  Text(
                    'Conf: ${inc.confidence!.toStringAsFixed(0)}%',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: colors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (inc.vehicleSpeed != null)
                  Text(
                    '${inc.vehicleSpeed!.toStringAsFixed(0)} km/h',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: colors.textMuted,
                    ),
                  ),
                if (inc.hasVideo) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.videocam_rounded,
                    size: 14,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    'Clip',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            if (resolved)
              Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: AppTheme.success,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    AppLocalizations.of(context).translate('resolved'),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.success,
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => IncidentDetailView(incident: inc),
                        ),
                      ),
                      icon: const Icon(Icons.visibility_rounded, size: 16),
                      label: const Text('View Details'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        side: const BorderSide(color: AppTheme.primary),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Expanded(
                  //   flex: 2,
                  //   child: ElevatedButton.icon(
                  //     onPressed: () =>
                  //         fleet.setReviewState(inc.id, ReviewState.resolved),
                  //     icon: const Icon(Icons.done_all_rounded, size: 16),
                  //     label: const Text('Mark resolved'),
                  //     style: ElevatedButton.styleFrom(
                  //       backgroundColor: AppTheme.primary,
                  //       foregroundColor: Colors.white,
                  //       elevation: 0,
                  //       padding: const EdgeInsets.symmetric(vertical: 11),
                  //       shape: RoundedRectangleBorder(
                  //         borderRadius: BorderRadius.circular(12),
                  //       ),
                  //     ),
                  //   ),
                  // ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
