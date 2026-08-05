import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/fleet_models.dart';
import '../services/auth_service.dart';
import 'theme/app_theme.dart';
import 'widgets/common.dart';
import 'widgets/incident_video_player.dart';

class IncidentDetailView extends StatelessWidget {
  final FleetIncident incident;

  const IncidentDetailView({super.key, required this.incident});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final color = severityColor(incident.severity);

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.card,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Incident Details',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.cardDecoration(context),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      incidentIcon(incident.type),
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              incident.type.label,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            StatusChip(
                              label: incident.severity.name,
                              color: color,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${incident.vehicleReg} · ${incident.driverName}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Evidence section
            _sectionTitle(context, 'EVIDENCE'),
            const SizedBox(height: 10),
            Row(
              children: [
                // Snapshot
                Expanded(
                  child: _evidenceCard(
                    context,
                    label: 'Driver Snapshot',
                    child:
                        incident.snapshotUrl != null &&
                            incident.snapshotUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            child: Image.network(
                              incident.snapshotUrl!,
                              headers: AuthService.instance.authHeaders,
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _placeholderImage(
                                context,
                                Icons.person_rounded,
                              ),
                            ),
                          )
                        : _placeholderImage(context, Icons.person_rounded),
                  ),
                ),
                const SizedBox(width: 12),
                // Video
                Expanded(
                  child: _evidenceCard(
                    context,
                    label: 'Video Evidence',
                    child: incident.hasVideo
                        ? GestureDetector(
                            onTap: () => _playVideo(context),
                            child: _placeholderImage(
                              context,
                              Icons.play_circle_fill_rounded,
                              subtitle: 'Play Clip',
                            ),
                          )
                        : _placeholderImage(
                            context,
                            Icons.videocam_off_rounded,
                            subtitle: 'No video',
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Incident Details section
            _sectionTitle(context, 'INCIDENT DETAILS'),
            const SizedBox(height: 10),
            Container(
              decoration: AppTheme.cardDecoration(context),
              child: Column(
                children: [
                  _detailRow(
                    context,
                    'Event Type',
                    incident.type.label,
                    valueColor: color,
                  ),
                  _divider(context),
                  _detailRow(
                    context,
                    'Risk Level',
                    incident.severity.name[0].toUpperCase() +
                        incident.severity.name.substring(1),
                  ),
                  if (incident.deviceImei != null) ...[
                    _divider(context),
                    _detailRow(context, 'Device IMEI', incident.deviceImei!),
                  ],
                  if (incident.vehicleSpeed != null) ...[
                    _divider(context),
                    _detailRow(
                      context,
                      'Vehicle Speed',
                      '${incident.vehicleSpeed!.toStringAsFixed(0)} km/h',
                    ),
                  ],
                  if (incident.confidence != null) ...[
                    _divider(context),
                    _detailRow(
                      context,
                      'Confidence',
                      '${incident.confidence!.toStringAsFixed(0)}%',
                    ),
                  ],
                  if (incident.gpsLatitude != null &&
                      incident.gpsLongitude != null) ...[
                    _divider(context),
                    _detailRow(
                      context,
                      'GPS',
                      '${incident.gpsLatitude!.toStringAsFixed(6)}, ${incident.gpsLongitude!.toStringAsFixed(6)}',
                    ),
                  ],
                  _divider(context),
                  _detailRow(
                    context,
                    'Occurred At',
                    DateFormat(
                      'dd MMM yyyy, HH:mm:ss',
                    ).format(incident.timestamp),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: AppTheme.of(context).textMuted,
      ),
    );
  }

  Widget _evidenceCard(
    BuildContext context, {
    required String label,
    required Widget child,
  }) {
    final colors = AppTheme.of(context);
    return Container(
      decoration: AppTheme.cardDecoration(context),
      child: Column(
        children: [
          SizedBox(height: 120, child: child),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderImage(
    BuildContext context,
    IconData icon, {
    String? subtitle,
  }) {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white70, size: 40),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: Colors.white60,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    final colors = AppTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: colors.textSecondary,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 0.5,
      color: AppTheme.of(context).cardBorder,
    );
  }

  void _playVideo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: AppTheme.of(context).card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.of(context).cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: incident.videoUrl != null
                    ? IncidentVideoPlayer(videoUrl: incident.videoUrl!)
                    : Container(
                        color: Colors.black87,
                        child: const Center(
                          child: Icon(
                            Icons.videocam_off_rounded,
                            color: Colors.white70,
                            size: 56,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              '${incident.type.label} — ${incident.vehicleReg}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.of(context).textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${incident.driverName} · ${incident.location}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppTheme.of(context).textMuted,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
