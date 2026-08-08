import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../services/trip_service.dart';
import 'theme/app_theme.dart';

class _DriverGroup {
  final String driverName;
  final List<Map<String, dynamic>> trips;

  _DriverGroup(this.driverName, this.trips);

  int get tripCount => trips.length;

  DateTime? get earliestStart {
    DateTime? earliest;
    for (final t in trips) {
      final s = t['startedAt'] ?? t['startTime'];
      if (s == null) continue;
      final dt = DateTime.tryParse(s.toString());
      if (dt != null && (earliest == null || dt.isBefore(earliest))) {
        earliest = dt;
      }
    }
    return earliest;
  }

  DateTime? get latestEnd {
    DateTime? latest;
    for (final t in trips) {
      final e = t['endedAt'] ?? t['endTime'];
      if (e == null) continue;
      final dt = DateTime.tryParse(e.toString());
      if (dt != null && (latest == null || dt.isAfter(latest))) {
        latest = dt;
      }
    }
    return latest;
  }

  Duration get totalDuration {
    final s = earliestStart;
    final e = latestEnd;
    if (s != null && e != null) return e.difference(s);
    return Duration.zero;
  }

  double get totalDistanceKm {
    double total = 0;
    for (final t in trips) {
      final d = t['distanceKm'] ?? t['distance'];
      if (d != null)
        total += (d is num ? d.toDouble() : double.tryParse(d.toString()) ?? 0);
    }
    return total;
  }

  double get avgSpeedKmh {
    double totalSpeed = 0;
    int count = 0;
    for (final t in trips) {
      final s = t['averageSpeedKmh'] ?? t['avgSpeed'];
      if (s != null) {
        final v = s is num ? s.toDouble() : double.tryParse(s.toString()) ?? 0;
        if (v > 0) {
          totalSpeed += v;
          count++;
        }
      }
    }
    return count > 0 ? totalSpeed / count : 0;
  }

  Set<String> get vehicles {
    return trips
        .map(
          (t) => (t['vehicleRegistrationNumber'] ?? t['vehicleId'] ?? '')
              .toString(),
        )
        .where((v) => v.isNotEmpty && v != '-')
        .toSet();
  }
}

class TripMonitoringView extends StatefulWidget {
  const TripMonitoringView({super.key});

  @override
  State<TripMonitoringView> createState() => _TripMonitoringViewState();
}

class _TripMonitoringViewState extends State<TripMonitoringView> {
  final _service = TripService();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _allTrips = [];
  String? _expandedDriver;
  final _timeFmt = DateFormat('hh:mm a');
  final _dateFmt = DateFormat('dd MMM yyyy');
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final trips = await _service.fetchTrips();
      if (!mounted) return;
      setState(() => _allTrips = trips);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _trips {
    return _allTrips.where((t) {
      final s = t['startedAt'] ?? t['startTime'];
      if (s == null) return false;
      final dt = DateTime.tryParse(s.toString());
      if (dt == null) return false;
      return dt.year == _selectedDate.year &&
          dt.month == _selectedDate.month &&
          dt.day == _selectedDate.day;
    }).toList();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _expandedDriver = null;
      });
    }
  }

  List<_DriverGroup> _groupByDriver() {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final t in _trips) {
      final name = (t['driverName'] ?? t['driverId'] ?? 'Unknown Driver')
          .toString();
      map.putIfAbsent(name, () => []).add(t);
    }
    return map.entries.map((e) => _DriverGroup(e.key, e.value)).toList()
      ..sort((a, b) => a.driverName.compareTo(b.driverName));
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final groups = _groupByDriver();
    final totalVehicles = _trips
        .map((t) => (t['vehicleRegistrationNumber'] ?? '').toString())
        .where((v) => v.isNotEmpty)
        .toSet()
        .length;

    return Scaffold(
      backgroundColor: colors.surface,
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            Text(
              'Trip Monitoring',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),

            // Date filter
            Row(
              children: [
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colors.cardBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isToday(_selectedDate)
                              ? 'Today'
                              : _dateFmt.format(_selectedDate),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_drop_down_rounded,
                          size: 20,
                          color: Color(0xFF64748B),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (!_isToday(_selectedDate))
                  TextButton.icon(
                    onPressed: () => setState(() {
                      _selectedDate = DateTime.now();
                      _expandedDriver = null;
                    }),
                    icon: const Icon(Icons.today_rounded, size: 14),
                    label: const Text('Today'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      textStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const Spacer(),
                Text(
                  '${_trips.length} trips',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              _errorCard(_error!)
            else ...[
              // Summary cards
              Row(
                children: [
                  _summaryCard(
                    '${groups.length}',
                    'DRIVERS',
                    Icons.people_outline_rounded,
                    const Color(0xFF1E3A8A),
                  ),
                  const SizedBox(width: 10),
                  _summaryCard(
                    '${_trips.length}',
                    'TRIPS',
                    Icons.route_rounded,
                    const Color(0xFF10B981),
                  ),
                  const SizedBox(width: 10),
                  _summaryCard(
                    '$totalVehicles',
                    'VEHICLES',
                    Icons.local_shipping_outlined,
                    const Color(0xFFF59E0B),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_trips.isEmpty)
                _emptyCard('No trip data found')
              else
                ...groups.map(_driverGroupCard),

              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(String value, String label, IconData icon, Color color) {
    final colors = AppTheme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.cardBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(icon, size: 22, color: color.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }

  Widget _driverGroupCard(_DriverGroup group) {
    final colors = AppTheme.of(context);
    final isExpanded = _expandedDriver == group.driverName;
    final start = group.earliestStart;
    final end = group.latestEnd;
    final dur = group.totalDuration;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isExpanded ? const Color(0xFF93C5FD) : colors.cardBorder,
        ),
      ),
      child: Column(
        children: [
          // Driver header
          InkWell(
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(14),
              bottom: Radius.circular(isExpanded ? 0 : 14),
            ),
            onTap: () => setState(
              () => _expandedDriver = isExpanded ? null : group.driverName,
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1E3A8A),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            group.driverName.isNotEmpty
                                ? group.driverName[0].toUpperCase()
                                : '?',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group.driverName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              start != null && end != null
                                  ? '${_timeFmt.format(start)} → ${_timeFmt.format(end)}'
                                  : '-',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: colors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: colors.textMuted,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Stats row
                  Row(
                    children: [
                      _statChip(
                        '${group.tripCount} trips',
                        const Color(0xFF10B981),
                      ),
                      const SizedBox(width: 8),
                      _statChip(_formatDuration(dur), const Color(0xFF2563EB)),
                      const SizedBox(width: 8),
                      _statChip(
                        '${group.totalDistanceKm.toStringAsFixed(1)} km',
                        const Color(0xFFF59E0B),
                      ),
                      if (group.avgSpeedKmh > 0) ...[
                        const SizedBox(width: 8),
                        _statChip(
                          'Avg ${group.avgSpeedKmh.toStringAsFixed(0)} km/h',
                          const Color(0xFF8B5CF6),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Trip list
          if (isExpanded)
            ...group.trips.asMap().entries.map((e) => _tripRow(e.key, e.value)),
        ],
      ),
    );
  }

  Widget _statChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _tripRow(int index, Map<String, dynamic> trip) {
    final colors = AppTheme.of(context);
    final vehicle =
        (trip['vehicleRegistrationNumber'] ?? trip['vehicleId'] ?? '-')
            .toString();
    final startStr = trip['startedAt'] ?? trip['startTime'];
    final endStr = trip['endedAt'] ?? trip['endTime'];
    final startDt = startStr != null
        ? DateTime.tryParse(startStr.toString())
        : null;
    final endDt = endStr != null ? DateTime.tryParse(endStr.toString()) : null;
    final distance = trip['distanceKm'] ?? trip['distance'];
    final distStr = distance != null
        ? '${(distance is num ? distance : double.tryParse(distance.toString()) ?? 0).toStringAsFixed(1)} km'
        : '-';
    final dur = (startDt != null && endDt != null)
        ? endDt.difference(startDt)
        : Duration.zero;
    final startLoc = (trip['startLocation'] ?? trip['startAddress'] ?? '')
        .toString();
    final endLoc = (trip['endLocation'] ?? trip['endAddress'] ?? '').toString();
    final label = String.fromCharCode(65 + (index % 26));

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.cardBorder)),
        color: colors.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  vehicle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Time, duration, distance in a wrap
          Padding(
            padding: const EdgeInsets.only(left: 34),
            child: Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _infoItem(
                  Icons.schedule_rounded,
                  startDt != null && endDt != null
                      ? '${_timeFmt.format(startDt)} → ${_timeFmt.format(endDt)}'
                      : '-',
                ),
                _infoItem(Icons.timer_outlined, _formatDuration(dur)),
                _infoItem(Icons.straighten_rounded, distStr),
              ],
            ),
          ),
          // Route
          if (startLoc.isNotEmpty || endLoc.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 34, top: 6),
              child: Row(
                children: [
                  const Icon(Icons.circle, size: 6, color: Color(0xFF10B981)),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      startLoc.isNotEmpty ? startLoc : '-',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: colors.textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      '→',
                      style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                  ),
                  const Icon(Icons.circle, size: 6, color: Color(0xFFEF4444)),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      endLoc.isNotEmpty ? endLoc : '-',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: colors.textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: AppTheme.of(context).textSecondary,
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    if (d.inMinutes < 1) return '<1m';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  bool _isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  Widget _errorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(message, style: const TextStyle(color: AppTheme.danger)),
    );
  }

  Widget _emptyCard(String message) {
    final colors = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Center(
        child: Text(
          message,
          style: GoogleFonts.plusJakartaSans(color: colors.textMuted),
        ),
      ),
    );
  }
}
