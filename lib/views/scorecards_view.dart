import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../controllers/fleet_controller.dart';
import '../models/fleet_models.dart';
import 'theme/app_theme.dart';
import 'widgets/common.dart';

class ScorecardsView extends StatelessWidget {
  const ScorecardsView({super.key});

  @override
  Widget build(BuildContext context) {
    final fleet = context.watch<FleetController>();
    final colors = AppTheme.of(context);
    final cards = [...fleet.scorecards]..sort((a, b) => b.safetyScore.compareTo(a.safetyScore));

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Driver Scorecards',
                      style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                  Text('Fleet average ${fleet.fleetAvgScore} · ranked by safety',
                      style: GoogleFonts.poppins(fontSize: 12, color: colors.textMuted)),
                ]),
                const Spacer(),
                _avgBadge(context, fleet.fleetAvgScore),
              ]),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: cards.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _card(context, cards[i], i + 1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avgBadge(BuildContext context, int avg) {
    final c = scoreColor(avg);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.shield_rounded, size: 15, color: c),
        const SizedBox(width: 5),
        Text('$avg', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: c)),
      ]),
    );
  }

  Widget _card(BuildContext context, DriverScorecard d, int rank) {
    final c = scoreColor(d.safetyScore);
    final up = d.trend >= 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            // Rank + grade circle
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [c, c.withValues(alpha: 0.7)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(d.grade,
                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text('#$rank  ',
                      style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.of(context).textMuted)),
                  Flexible(
                    child: Text(d.name,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.of(context).textPrimary)),
                  ),
                ]),
                Text(d.vehicleReg, style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.of(context).textMuted)),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${d.safetyScore}',
                  style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: c, height: 1)),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(up ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                    size: 13, color: up ? AppTheme.success : AppTheme.danger),
                const SizedBox(width: 2),
                Text('${d.trend.abs()}',
                    style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: up ? AppTheme.success : AppTheme.danger)),
              ]),
            ]),
          ]),
          const SizedBox(height: 12),
          // 7-day sparkline
          SizedBox(
            height: 38,
            child: CustomPaint(
              size: const Size(double.infinity, 38),
              painter: _SparklinePainter(values: d.last7Days, color: c),
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            _stat(context, Icons.route_rounded, '${d.tripsThisWeek}', 'trips'),
            _stat(context, Icons.straighten_rounded, '${d.distanceKm.toInt()} km', 'distance'),
            _stat(context, Icons.warning_amber_rounded, '${d.incidents}', 'incidents'),
            _stat(context, Icons.schedule_rounded, '${d.onTimeRate}%', 'on-time'),
          ]),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, IconData icon, String value, String label) {
    return Expanded(
      child: Column(children: [
        Icon(icon, size: 15, color: AppTheme.of(context).textMuted),
        const SizedBox(height: 3),
        Text(value, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.of(context).textPrimary)),
        Text(label, style: GoogleFonts.poppins(fontSize: 9, color: AppTheme.of(context).textMuted)),
      ]),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<int> values;
  final Color color;
  _SparklinePainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    const minV = 50.0, maxV = 100.0;
    final dx = size.width / (values.length - 1);
    double yFor(int v) => size.height - ((v - minV) / (maxV - minV)).clamp(0.0, 1.0) * size.height;

    final path = Path();
    final fill = Path();
    for (var i = 0; i < values.length; i++) {
      final p = Offset(i * dx, yFor(values[i]));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
        fill.moveTo(p.dx, size.height);
        fill.lineTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
        fill.lineTo(p.dx, p.dy);
      }
    }
    fill.lineTo(size.width, size.height);
    fill.close();

    canvas.drawPath(fill, Paint()..color = color.withValues(alpha: 0.1));
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round,
    );
    // Last point dot.
    final last = Offset((values.length - 1) * dx, yFor(values.last));
    canvas.drawCircle(last, 3, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) => old.values != values || old.color != color;
}
