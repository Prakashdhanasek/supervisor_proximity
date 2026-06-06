import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/fleet_models.dart';
import '../theme/app_theme.dart';
import 'common.dart';

/// A self-contained live fleet map. No map package, no API key — it renders
/// the operating zone, a depot, and every vehicle as a status-coloured marker
/// that moves with FleetController. Tap a marker to select it.
///
/// Swap to real geography later by feeding LatLng into a flutter_map layer and
/// projecting to the same normalised 0..1 space used here.
class FleetMap extends StatefulWidget {
  final List<FleetVehicle> vehicles;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  final double height;

  const FleetMap({
    super.key,
    required this.vehicles,
    required this.onSelect,
    this.selectedId,
    this.height = 360,
  });

  @override
  State<FleetMap> createState() => _FleetMapState();
}

class _FleetMapState extends State<FleetMap> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  static const double _pad = 16;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Offset _toCanvas(Offset n, Size s) =>
      Offset(_pad + n.dx * (s.width - 2 * _pad), _pad + n.dy * (s.height - 2 * _pad));

  void _handleTap(Offset local, Size size) {
    String? hit;
    double best = 28; // tap radius in px
    for (final v in widget.vehicles) {
      final c = _toCanvas(v.position, size);
      final d = (c - local).distance;
      if (d < best) {
        best = d;
        hit = v.id;
      }
    }
    if (hit != null) widget.onSelect(hit);
  }

  static Color statusColor(VehicleStatus s) => vehicleStatusColor(s);

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: colors.cardBorder),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            return GestureDetector(
              onTapUp: (d) => _handleTap(d.localPosition, size),
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (context, _) => CustomPaint(
                  size: size,
                  painter: _FleetMapPainter(
                    vehicles: widget.vehicles,
                    selectedId: widget.selectedId,
                    pulse: _pulse.value,
                    isDark: colors.isDark,
                    gridColor: colors.cardBorder,
                    labelColor: colors.textSecondary,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FleetMapPainter extends CustomPainter {
  final List<FleetVehicle> vehicles;
  final String? selectedId;
  final double pulse;
  final bool isDark;
  final Color gridColor;
  final Color labelColor;

  _FleetMapPainter({
    required this.vehicles,
    required this.selectedId,
    required this.pulse,
    required this.isDark,
    required this.gridColor,
    required this.labelColor,
  });

  static const double _pad = 16;
  Offset _toCanvas(Offset n, Size s) =>
      Offset(_pad + n.dx * (s.width - 2 * _pad), _pad + n.dy * (s.height - 2 * _pad));

  @override
  void paint(Canvas canvas, Size size) {
    _background(canvas, size);
    _grid(canvas, size);
    _geofence(canvas, size);
    _depot(canvas, size);

    // Non-selected markers first, selected last (on top).
    for (final v in vehicles) {
      if (v.id == selectedId) continue;
      _vehicle(canvas, size, v, selected: false);
    }
    final sel = vehicles.where((v) => v.id == selectedId).toList();
    if (sel.isNotEmpty) _vehicle(canvas, size, sel.first, selected: true);
  }

  void _background(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF111B2E), const Color(0xFF0C1525)]
              : [const Color(0xFFEFF4FB), const Color(0xFFE7EEF7)],
        ).createShader(rect),
    );
    canvas.drawCircle(
      Offset(size.width * 0.75, size.height * 0.7),
      size.height * 0.26,
      Paint()
        ..color = AppTheme.success.withValues(alpha: 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );
  }

  void _grid(Canvas canvas, Size size) {
    final p = Paint()
      ..color = gridColor.withValues(alpha: isDark ? 0.3 : 0.5)
      ..strokeWidth = 1;
    const step = 36.0;
    for (double x = step; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = step; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
    final road = Paint()
      ..color = gridColor.withValues(alpha: isDark ? 0.55 : 0.85)
      ..strokeWidth = 3;
    canvas.drawLine(Offset(0, size.height * 0.4), Offset(size.width, size.height * 0.36), road);
    canvas.drawLine(Offset(size.width * 0.5, 0), Offset(size.width * 0.55, size.height), road);
  }

  void _geofence(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(8, 8, size.width - 16, size.height - 16),
      const Radius.circular(18),
    );
    canvas.drawRRect(rrect, Paint()..color = AppTheme.primary.withValues(alpha: 0.04));
    final dash = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = AppTheme.primary.withValues(alpha: 0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    for (final m in dash.computeMetrics()) {
      double d = 0;
      while (d < m.length) {
        final n = math.min(d + 7, m.length);
        canvas.drawPath(m.extractPath(d, n), paint);
        d = n + 6;
      }
    }
  }

  void _depot(Canvas canvas, Size size) {
    final c = _toCanvas(const Offset(0.5, 0.52), size);
    canvas.drawCircle(c, 7, Paint()..color = AppTheme.primary);
    canvas.drawCircle(c, 7, Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke);
    final tp = TextPainter(
      text: TextSpan(
        text: 'Depot',
        style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w600, color: labelColor),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, c + const Offset(10, -6));
  }

  void _vehicle(Canvas canvas, Size size, FleetVehicle v, {required bool selected}) {
    final c = _toCanvas(v.position, size);
    final color = _FleetMapState.statusColor(v.status);
    final moving = v.status == VehicleStatus.driving || v.status == VehicleStatus.alert;

    // Pulsing halo for alerting vehicles or the selection.
    if (v.status == VehicleStatus.alert || selected) {
      final r = 16 + pulse * 16;
      canvas.drawCircle(c, r, Paint()..color = color.withValues(alpha: (1 - pulse) * 0.35));
    }
    if (selected) {
      canvas.drawCircle(c, 18, Paint()
        ..color = AppTheme.primary
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke);
    }

    canvas.drawCircle(c, 11, Paint()..color = Colors.white);
    canvas.drawCircle(c, 11, Paint()..color = color);

    if (moving) {
      // Heading chevron.
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(v.heading);
      final chevron = Path()
        ..moveTo(6, 0)
        ..lineTo(-3, -4.5)
        ..lineTo(-1, 0)
        ..lineTo(-3, 4.5)
        ..close();
      canvas.drawPath(chevron, Paint()..color = Colors.white);
      canvas.restore();
    } else {
      // Idle/offline dot.
      canvas.drawCircle(c, 3.5, Paint()..color = Colors.white);
    }

    // Registration label under the marker.
    final tp = TextPainter(
      text: TextSpan(
        text: v.registration.split(' ').take(2).join(' '),
        style: GoogleFonts.poppins(
          fontSize: 8,
          fontWeight: FontWeight.w600,
          color: selected ? AppTheme.primary : labelColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(c.dx - tp.width / 2, c.dy + 13));
  }

  @override
  bool shouldRepaint(covariant _FleetMapPainter old) =>
      old.vehicles != vehicles || old.selectedId != selectedId || old.pulse != pulse || old.isDark != isDark;
}
