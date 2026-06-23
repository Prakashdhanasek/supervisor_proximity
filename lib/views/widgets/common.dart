import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/fleet_models.dart';
import '../theme/app_theme.dart';

String timeAgo(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inSeconds < 60) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  return '${d.inDays}d ago';
}

Color vehicleStatusColor(VehicleStatus s) => switch (s) {
  VehicleStatus.driving => AppTheme.success,
  VehicleStatus.idle => AppTheme.warning,
  VehicleStatus.alert => AppTheme.danger,
  VehicleStatus.offline => const Color(0xFF94A3B8),
};

Color severityColor(IncidentSeverity s) => switch (s) {
  IncidentSeverity.low => AppTheme.primary,
  IncidentSeverity.medium => AppTheme.warning,
  IncidentSeverity.high => AppTheme.danger,
  IncidentSeverity.critical => const Color(0xFF991B1B),
};

Color scoreColor(int score) {
  if (score >= 85) return AppTheme.success;
  if (score >= 70) return AppTheme.primary;
  if (score >= 50) return AppTheme.warning;
  return AppTheme.danger;
}

IconData incidentIcon(IncidentType t) => switch (t) {
  IncidentType.drowsiness => Icons.bedtime_rounded,
  IncidentType.distraction => Icons.phone_android_rounded,
  IncidentType.harshBraking => Icons.warning_rounded,
  IncidentType.speeding => Icons.speed_rounded,
  IncidentType.geofence => Icons.location_off_rounded,
  IncidentType.tamper => Icons.build_circle_rounded,
  IncidentType.forwardDistance => Icons.swap_horiz_rounded,
  IncidentType.tripStart => Icons.play_arrow_rounded,
  IncidentType.tripStop => Icons.stop_rounded,
  IncidentType.seatbelt => Icons.airline_seat_recline_normal_rounded,
  IncidentType.phoneUsage => Icons.phone_in_talk_rounded,
  IncidentType.unauthorizedDriver => Icons.person_off_rounded,
};

class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class SummaryTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const SummaryTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.of(context).textPrimary,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              color: AppTheme.of(context).textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  const SectionHeader({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppTheme.of(context).textPrimary,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppTheme.of(context).textMuted,
              ),
            ),
        ],
      ),
    );
  }
}
