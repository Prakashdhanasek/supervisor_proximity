import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supervisor_proximity/profile_view.dart';
import '../controllers/fleet_controller.dart';
import '../models/fleet_models.dart';
import 'theme/app_theme.dart';
import 'widgets/fleet_map.dart';
import 'widgets/common.dart';

class FleetMapView extends StatefulWidget {
  const FleetMapView({super.key});

  @override
  State<FleetMapView> createState() => _FleetMapViewState();
}

class _FleetMapViewState extends State<FleetMapView> {
  String? _selectedId;


  

  @override
  Widget build(BuildContext context) {
    final fleet = context.watch<FleetController>();
    final colors = AppTheme.of(context);
    FleetVehicle? selected;
    if (_selectedId != null) {
      for (final v in fleet.vehicles) {
        if (v.id == _selectedId) {
          selected = v;
          break;
        }
      }
    }

    

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _header(context, fleet),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  FleetMap(
                    vehicles: fleet.vehicles,
                    selectedId: _selectedId,
                    onSelect: (id) => setState(() => _selectedId = id),
                  ),
                  const SizedBox(height: 12),
                  _legend(context),
                  const SizedBox(height: 16),
                  if (selected != null) ...[
                    _selectedCard(context, selected),
                    const SizedBox(height: 16),
                  ],
                  Text('All vehicles',
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                  const SizedBox(height: 8),
                  ...fleet.vehicles.map((v) => _vehicleRow(context, v)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, FleetController fleet) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
             GestureDetector(
  onTap: () => Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const SupervisorProfileView()),
  ),
  child: Container(
    width: 44,
    height: 44,
    alignment: Alignment.center,
    decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(14)),
    child: Text(fleet.supervisorInitials,
        style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
  ),
),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hi, ${fleet.supervisorFirstName} 👋',
                        style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.of(context).textSecondary)),
                    Text('Live Fleet',
                        style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.of(context).textPrimary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppTheme.success, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text('LIVE', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.success, letterSpacing: 0.5)),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('${fleet.activeVehicles} driving · ${fleet.alertVehicles} alerts · ${fleet.vehicles.length} total',
              style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.of(context).textMuted)),
        ],
      ),
    );
  }

  Widget _legend(BuildContext context) {
    Widget item(Color c, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 9, height: 9, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(label, style: GoogleFonts.poppins(fontSize: 10, color: AppTheme.of(context).textSecondary)),
        ]);
    return Wrap(spacing: 16, runSpacing: 8, children: [
      item(AppTheme.success, 'Driving'),
      item(AppTheme.warning, 'Idle'),
      item(AppTheme.danger, 'Alert'),
      item(const Color(0xFF94A3B8), 'Offline'),
    ]);
  }

  Widget _selectedCard(BuildContext context, FleetVehicle v) {
    final color = vehicleStatusColor(v.status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(context, borderColor: color.withValues(alpha: 0.3)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(13)),
              child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(v.registration, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.of(context).textPrimary)),
                Text(v.driverName, style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.of(context).textSecondary)),
              ]),
            ),
            StatusChip(label: v.status.label, color: color),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            _metric(context, Icons.speed_rounded, '${v.speedKmh.toInt()}', 'km/h'),
            _metric(context, Icons.route_rounded, '${(v.routeProgress * 100).toInt()}%', 'route'),
            _metric(context, Icons.shield_rounded, '${v.safetyScore}', 'score'),
            _metric(context, v.inGeofence ? Icons.check_circle_rounded : Icons.location_off_rounded,
                v.inGeofence ? 'In' : 'Out', 'zone'),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _snack(context, 'Calling ${v.driverName}…'),
                icon: const Icon(Icons.call_rounded, size: 16),
                label: const Text('Call'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.primary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _snack(context, 'Message sent to ${v.driverName}'),
                icon: const Icon(Icons.message_rounded, size: 16),
                label: const Text('Message'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary, foregroundColor: Colors.white, elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _metric(BuildContext context, IconData icon, String value, String label) {
    return Expanded(
      child: Column(children: [
        Icon(icon, size: 16, color: AppTheme.of(context).textSecondary),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.of(context).textPrimary)),
        Text(label, style: GoogleFonts.poppins(fontSize: 9, color: AppTheme.of(context).textMuted)),
      ]),
    );
  }

  Widget _vehicleRow(BuildContext context, FleetVehicle v) {
    final color = vehicleStatusColor(v.status);
    final isSel = v.id == _selectedId;
    return GestureDetector(
      onTap: () => setState(() => _selectedId = v.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: AppTheme.cardDecoration(context, borderColor: isSel ? AppTheme.primary : null),
        child: Row(children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(v.registration, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.of(context).textPrimary)),
              Text('${v.driverName} · ${v.routeName}',
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.of(context).textMuted)),
            ]),
          ),
          if (v.status == VehicleStatus.driving || v.status == VehicleStatus.alert)
            Text('${v.speedKmh.toInt()} km/h',
                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.of(context).textSecondary))
          else
            StatusChip(label: v.status.label, color: color),
        ]),
      ),
    );
  }

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }
}