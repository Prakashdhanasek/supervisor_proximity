import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/geofence_service.dart';
import 'theme/app_theme.dart';

class GeofencingView extends StatefulWidget {
  const GeofencingView({super.key});

  @override
  State<GeofencingView> createState() => _GeofencingViewState();
}

class _GeofencingViewState extends State<GeofencingView>
    with SingleTickerProviderStateMixin {
  final _service = GeofenceService();
  late TabController _tabController;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _geofences = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _violations = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await Future.wait([
        _service.fetchGeofences(),
        _service.fetchViolations(),
      ]);
      if (!mounted) return;
      setState(() {
        _geofences = result[0];
        _violations = result[1];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);

    return Scaffold(
      backgroundColor: colors.surface,
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Geofences'),
              Tab(text: 'Violations'),
            ],
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? _errorCard(_error!)
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _listSection(
                        _geofences,
                        empty: 'No geofences found',
                        buildItem: _geofenceCard,
                      ),
                      _listSection(
                        _violations,
                        empty: 'No violations found',
                        buildItem: _violationCard,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _listSection(
    List<Map<String, dynamic>> items, {
    required String empty,
    required Widget Function(Map<String, dynamic>) buildItem,
  }) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: items.isEmpty
            ? [_emptyCard(empty)]
            : items.map(buildItem).toList(),
      ),
    );
  }

  Widget _geofenceCard(Map<String, dynamic> g) {
    final colors = AppTheme.of(context);
    final name = (g['name'] ?? 'Geofence').toString();
    final vehicle = (g['vehicleRegistrationNumber'] ?? g['vehicleId'] ?? '-')
        .toString();
    final radius = (g['radiusMeters'] ?? '-').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Vehicle: $vehicle',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: colors.textSecondary,
            ),
          ),
          Text(
            'Radius: $radius m',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _violationCard(Map<String, dynamic> v) {
    final colors = AppTheme.of(context);
    final vehicle = (v['vehicleRegistrationNumber'] ?? v['vehicleId'] ?? '-')
        .toString();
    final occurredAt = (v['occurredAt'] ?? '-').toString();
    final speed = (v['vehicleSpeed'] ?? '-').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            vehicle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Occurred: $occurredAt',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: colors.textSecondary,
            ),
          ),
          Text(
            'Speed: $speed km/h',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorCard(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.danger.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(message, style: const TextStyle(color: AppTheme.danger)),
        ),
      ),
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
