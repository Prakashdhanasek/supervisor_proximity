import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/fleet_models.dart';
import '../theme/app_theme.dart';
import 'common.dart';
import '../../secrets.dart';

/// A live fleet map using Mapbox via flutter_map.
class FleetMap extends StatefulWidget {
  final List<FleetVehicle> vehicles;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  final double height;
  final MapController? mapController;

  const FleetMap({
    super.key,
    required this.vehicles,
    required this.onSelect,
    this.selectedId,
    this.height = 360,
    this.mapController,
  });

  @override
  State<FleetMap> createState() => _FleetMapState();
}

class _FleetMapState extends State<FleetMap> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  static Color statusColor(VehicleStatus s) => vehicleStatusColor(s);

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);

    // Find initial center based on valid vehicle coordinates or use default
    LatLng center = const LatLng(10.0167, 76.3656); // Kerala default
    
    for (var v in widget.vehicles) {
      if (v.latitude != null && v.longitude != null) {
        center = LatLng(v.latitude!, v.longitude!);
        break; // Center on first available
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: colors.cardBorder),
        ),
        child: FlutterMap(
          mapController: widget.mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: 12.0,
          ),
          children: [
            TileLayer(
              urlTemplate: "https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/{z}/{x}/{y}@2x?access_token={accessToken}",
              additionalOptions: {
                'accessToken': Secrets.mapboxAccessToken,
              },
            ),
            MarkerLayer(
              markers: widget.vehicles.where((v) => v.latitude != null && v.longitude != null).map((v) {
                final isSelected = v.id == widget.selectedId;
                return Marker(
                  point: LatLng(v.latitude!, v.longitude!),
                  width: 100,
                  height: 80,
                  alignment: Alignment.topCenter,
                  child: _buildMarker(v, isSelected),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarker(FleetVehicle v, bool isSelected) {
    final color = statusColor(v.status);
    final labelParts = v.registration.split(' ');
    final regCode = labelParts.isNotEmpty ? labelParts.last : v.id;
    final speedText = v.status == VehicleStatus.offline ? 'Offline' : '${v.speedKmh.toInt()} km/h';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => widget.onSelect(v.id),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, child) {
              final r = 36.0 + _pulse.value * 12.0; 
              
              return SizedBox(
                width: 48,
                height: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isSelected || v.status == VehicleStatus.alert)
                      Container(
                        width: r,
                        height: r,
                        decoration: BoxDecoration(
                          color: color.withOpacity((1.0 - _pulse.value) * 0.4),
                          shape: BoxShape.circle,
                        ),
                      ),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 3,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 23,
                          height: 23,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.local_shipping_rounded,
                            size: 13,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  regCode,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                    height: 1.2,
                  ),
                ),
                Text(
                  speedText,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 8,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
