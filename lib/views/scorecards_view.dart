import 'dart:math';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../controllers/fleet_controller.dart';
import '../models/fleet_models.dart';
import 'theme/app_theme.dart';

class ScorecardsView extends StatefulWidget {
  const ScorecardsView({super.key});

  @override
  State<ScorecardsView> createState() => _ScorecardsViewState();
}

class _ScorecardsViewState extends State<ScorecardsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fleet = context.watch<FleetController>();
    final allCards = [...fleet.scorecards]
      ..sort((a, b) => b.safetyScore.compareTo(a.safetyScore));

    List<DriverScorecard> filtered;
    switch (_tabController.index) {
      case 1:
        filtered = allCards.where((d) => d.grade == 'A').toList();
        break;
      case 2:
        filtered = allCards.where((d) => d.grade == 'B').toList();
        break;
      case 3:
        filtered = allCards.where((d) => d.grade == 'C').toList();
        break;
      case 4:
        filtered = allCards.where((d) => d.grade == 'D' || d.grade == 'F').toList();
        break;
      default:
        filtered = allCards;
    }

    int countGrade(String g) =>
        allCards.where((d) => d.grade == g).length;

    return Scaffold(
      backgroundColor: AppTheme.of(context).surface,
      body: Column(
        children: [
          // ── Blue header ─────────────────────────────────────────────
          _buildHeader(fleet),

          // ── Tab bar ─────────────────────────────────────────────────
          _buildTabBar(allCards.length, countGrade('A'), countGrade('B'), countGrade('C'),
              allCards.where((d) => d.grade == 'D' || d.grade == 'F').length),

          // ── Cards ───────────────────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? _buildEmpty()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _buildCard(context, filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────
  // Header
  // ────────────────────────────────────────────────────────────────────
  Widget _buildHeader(FleetController fleet) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A4FBA), Color(0xFF3B82F6)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
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
              const SizedBox(width: 12),
              Text(AppLocalizations.of(context).translate('driver_performance'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              _iconBtn(Icons.search_rounded),
              const SizedBox(width: 10),
              _iconBtn(Icons.notifications_none_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon) => Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      );

  // ────────────────────────────────────────────────────────────────────
  // Tab bar
  // ────────────────────────────────────────────────────────────────────
  Widget _buildTabBar(int all, int gradeA, int gradeB, int gradeC, int gradeD) {
    return Container(
      color: AppTheme.of(context).card,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: const Color(0xFF2B72F5),
        indicatorWeight: 2.5,
        labelColor: const Color(0xFF2B72F5),
        unselectedLabelColor: const Color(0xFF94A3B8),
        dividerColor: const Color(0xFFE2E8F0),
        labelStyle:
            GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold),
        unselectedLabelStyle:
            GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500),
        tabs: [
          _tabItem('All', all, 0),
          _tabItem('Grade A', gradeA, 1),
          _tabItem('Grade B', gradeB, 2),
          _tabItem('Grade C', gradeC, 3),
          _tabItem('Grade D', gradeD, 4),
        ],
      ),
    );
  }

  Widget _tabItem(String label, int count, int index) => Tab(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _tabController.index == index
                      ? const Color(0xFF2B72F5)
                      : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _tabController.index == index
                        ? Colors.white
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ],
        ),
      );

  // ────────────────────────────────────────────────────────────────────
  // Empty state
  // ────────────────────────────────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_off_rounded,
              size: 56, color: Colors.grey.withValues(alpha: 0.3)),
          const SizedBox(height: 14),
          Text(AppLocalizations.of(context).translate('no_drivers_grade'),
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.of(context).textPrimary)),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────
  // Driver card (tappable)
  // ────────────────────────────────────────────────────────────────────
  Widget _buildCard(BuildContext context, DriverScorecard d) {
    final scoreCol = _scoreColor(d.safetyScore);
    final gradeCol = _gradeColor(d.grade);
    final up = d.trend >= 0;
    final trendCol = up ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return GestureDetector(
      onTap: () => _showDriverDetailSheet(context, d),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        decoration: BoxDecoration(
          color: AppTheme.of(context).card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Row 1: avatar | name | grade pill | tap hint ──────────
            Row(
              children: [
                // Colored avatar with initial
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: gradeCol,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    d.name.isNotEmpty ? d.name[0].toUpperCase() : '?',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.of(context).textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (d.projectSite.isNotEmpty)
                        Text(
                          d.projectSite,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 10, color: const Color(0xFF94A3B8)),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                // Grade pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: gradeCol.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: gradeCol.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    'Grade ${d.grade}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: gradeCol,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded,
                    color: Color(0xFFCBD5E1), size: 20),
              ],
            ),
            const SizedBox(height: 10),

            // ── Row 2: big score + trend ────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '${d.safetyScore}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: scoreCol,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                  size: 14,
                  color: trendCol,
                ),
                const SizedBox(width: 2),
                Text(
                  '${d.trend.abs()} pts vs previous',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: trendCol,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                // Category badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _categoryColor(d.category).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    d.category,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: _categoryColor(d.category)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Sparkline chart ─────────────────────────────────────────
            SizedBox(
              height: 56,
              child: CustomPaint(
                size: const Size(double.infinity, 56),
                painter: _SparklinePainter(values: d.last7Days, color: scoreCol),
              ),
            ),
            const SizedBox(height: 12),

            const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 12),

            // ── Metrics row ─────────────────────────────────────────────
            Row(
              children: [
                _metricCol(Icons.route_rounded, 'Trips', '${d.tripsThisWeek}'),
                _vDivider(),
                _metricCol(Icons.location_on_outlined, 'Distance',
                    '${d.distanceKm.toInt()} km'),
                _vDivider(),
                _metricCol(Icons.warning_amber_outlined, 'Incidents',
                    '${d.incidents}'),
                _vDivider(),
                _metricCol(Icons.access_time_rounded, 'On-time', '${d.onTimeRate}%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricCol(IconData icon, String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
          const SizedBox(height: 4),
          Text(label,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 10, color: const Color(0xFF94A3B8))),
          const SizedBox(height: 1),
          Text(value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppTheme.of(context).textPrimary,
              )),
        ],
      ),
    );
  }

  Widget _vDivider() => Container(
      width: 1,
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: const Color(0xFFF1F5F9));

  // ────────────────────────────────────────────────────────────────────
  // Driver Detail Bottom Sheet
  // ────────────────────────────────────────────────────────────────────
  void _showDriverDetailSheet(BuildContext context, DriverScorecard d) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.68,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (ctx, scrollController) => Container(
          decoration: BoxDecoration(
            color: AppTheme.of(context).surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Big score circle + name
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildScoreCircle(d),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d.name,
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.of(context).textPrimary)),
                        const SizedBox(height: 2),
                        Text(
                          [
                            if (d.vehicleReg.isNotEmpty && d.vehicleReg != '—') d.vehicleReg,
                            if (d.projectSite.isNotEmpty) d.projectSite,
                          ].join(' · '),
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 11, color: const Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _categoryColor(d.category).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: _categoryColor(d.category).withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            '● ${d.category.toUpperCase()}',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _categoryColor(d.category)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Divider(color: Color(0xFFF1F5F9)),
              const SizedBox(height: 14),

              // Score breakdown
              _sectionLabel('SCORE BREAKDOWN'),
              const SizedBox(height: 10),
              _buildScoreBar('Safe Driving', d.safeDrivingScore),
              _buildScoreBar('Speed Compliance', d.speedComplianceScore),
              _buildScoreBar('Fatigue / Drowsiness', d.fatigueScore),
              _buildScoreBar('Distraction', d.distractionScore),

              const SizedBox(height: 16),
              const Divider(color: Color(0xFFF1F5F9)),
              const SizedBox(height: 14),

              // Incident breakdown
              _sectionLabel('INCIDENT BREAKDOWN (THIS WEEK)'),
              const SizedBox(height: 10),
              Row(
                children: [
                  _incidentPill('${d.criticalIncidents} CRITICAL', const Color(0xFF991B1B), const Color(0xFFFFEDED)),
                  const SizedBox(width: 6),
                  _incidentPill('${d.highIncidents} HIGH', const Color(0xFFB45309), const Color(0xFFFEF3C7)),
                  const SizedBox(width: 6),
                  _incidentPill('${d.mediumIncidents} MEDIUM', const Color(0xFF1E40AF), const Color(0xFFDBEAFE)),
                  const SizedBox(width: 6),
                  _incidentPill('${d.lowIncidents} LOW', const Color(0xFF065F46), const Color(0xFFD1FAE5)),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(color: Color(0xFFF1F5F9)),
              const SizedBox(height: 14),

              // Weekly trend bar chart
              _sectionLabel('WEEKLY SAFETY TREND'),
              const SizedBox(height: 12),
              _buildWeeklyBarChart(d),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(
        label,
        style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF94A3B8),
            letterSpacing: 0.8),
      );

  Widget _buildScoreCircle(DriverScorecard d) {
    final col = _scoreColor(d.safetyScore);
    return SizedBox(
      width: 80,
      height: 80,
      child: CustomPaint(
        painter: _ScoreCirclePainter(score: d.safetyScore, color: col),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${d.safetyScore}',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: col,
                      height: 1)),
              Text('Score',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 9, color: const Color(0xFF94A3B8))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreBar(String label, int score) {
    final col = _scoreColor(score);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(label,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12, color: const Color(0xFF475569))),
          ),
          Expanded(
            flex: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: score / 100,
                backgroundColor: const Color(0xFFF1F5F9),
                valueColor: AlwaysStoppedAnimation<Color>(col),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 30,
            child: Text(
              '$score',
              textAlign: TextAlign.right,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: col),
            ),
          ),
        ],
      ),
    );
  }

  Widget _incidentPill(String label, Color textColor, Color bgColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: textColor),
        ),
      ),
    );
  }

  Widget _buildWeeklyBarChart(DriverScorecard d) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Today'];
    final scores = d.last7Days.length >= 7 ? d.last7Days : List.generate(7, (_) => d.safetyScore);
    final maxScore = scores.reduce(max).toDouble();
    final col = _scoreColor(d.safetyScore);
    const barAreaHeight = 64.0;

    return SizedBox(
      height: 100,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(scores.length > 7 ? 7 : scores.length, (i) {
          final isToday = i == (scores.length > 7 ? 6 : scores.length - 1);
          final ratio = maxScore > 0 ? scores[i] / maxScore : 1.0;
          final barH = (ratio * barAreaHeight).clamp(8.0, barAreaHeight);
          return Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('${scores[i]}',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: isToday ? col : const Color(0xFF94A3B8))),
                const SizedBox(height: 4),
                Container(
                  width: 24,
                  height: barH,
                  decoration: BoxDecoration(
                    color: isToday ? col : col.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Text(days[i % days.length],
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 8.5, color: const Color(0xFF94A3B8))),
              ],
            ),
          );
        }),
      ),
    );
  }

  Color _scoreColor(int score) {
    if (score >= 85) return const Color(0xFF10B981);
    if (score >= 70) return const Color(0xFF2B72F5);
    if (score >= 55) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  Color _gradeColor(String grade) => switch (grade) {
        'A' => const Color(0xFF10B981),
        'B' => const Color(0xFF2B72F5),
        'C' => const Color(0xFFF59E0B),
        _ => const Color(0xFFEF4444),
      };

  Color _categoryColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'excellent': return const Color(0xFF10B981);
      case 'good': return const Color(0xFF2B72F5);
      case 'needs coaching': return const Color(0xFFF59E0B);
      case 'high risk': return const Color(0xFFEF4444);
      default: return const Color(0xFF64748B);
    }
  }
}

// ────────────────────────────────────────────────────────────────────
// Score circle ring painter
// ────────────────────────────────────────────────────────────────────
class _ScoreCirclePainter extends CustomPainter {
  final int score;
  final Color color;
  _ScoreCirclePainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    const startAngle = -pi / 2;
    final sweepAngle = 2 * pi * (score / 100);

    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = const Color(0xFFF1F5F9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreCirclePainter old) =>
      old.score != score || old.color != color;
}

// ────────────────────────────────────────────────────────────────────
// Smooth sparkline painter with filled area
// ────────────────────────────────────────────────────────────────────
class _SparklinePainter extends CustomPainter {
  final List<int> values;
  final Color color;
  _SparklinePainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    const minV = 40.0, maxV = 100.0;
    final dx = size.width / (values.length - 1);
    double yFor(int v) =>
        size.height - ((v - minV) / (maxV - minV)).clamp(0.0, 1.0) * size.height;

    final points = <Offset>[
      for (var i = 0; i < values.length; i++) Offset(i * dx, yFor(values[i]))
    ];

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final ctrlX = (p0.dx + p1.dx) / 2;
      path.cubicTo(ctrlX, p0.dy, ctrlX, p1.dy, p1.dx, p1.dy);
    }

    final fill = Path.from(path)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0.02)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(points.last, 4.5, Paint()..color = Colors.white);
    canvas.drawCircle(points.last, 3.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) =>
      old.values != values || old.color != color;
}
