import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/video_recordings_service.dart';
import 'theme/app_theme.dart';

class VideoRecordingsView extends StatefulWidget {
  const VideoRecordingsView({super.key});

  @override
  State<VideoRecordingsView> createState() => _VideoRecordingsViewState();
}

class _VideoRecordingsViewState extends State<VideoRecordingsView> {
  final _service = VideoRecordingsService();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _records = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service.fetchRecordings();
      if (!mounted) return;
      setState(() => _records = data);
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
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              _errorCard(_error!)
            else if (_records.isEmpty)
              _emptyCard('No recordings found')
            else
              ..._records.map(_recordCard),
          ],
        ),
      ),
    );
  }

  Widget _recordCard(Map<String, dynamic> r) {
    final colors = AppTheme.of(context);
    final vehicle = (r['vehicleRegistrationNumber'] ?? r['vehicleId'] ?? '-')
        .toString();
    final driver = (r['driverName'] ?? '-').toString();
    final capturedAt = (r['capturedAt'] ?? r['createdAt'] ?? '-').toString();
    final eventType = (r['eventType'] ?? r['type'] ?? 'Recording').toString();

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
          Row(
            children: [
              Expanded(
                child: Text(
                  eventType,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  vehicle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Driver: $driver',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: colors.textSecondary,
            ),
          ),
          Text(
            'Captured: $capturedAt',
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
