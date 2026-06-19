import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../controllers/fleet_controller.dart';
import '../models/fleet_models.dart';
import 'theme/app_theme.dart';
import 'widgets/common.dart';

class IncidentsView extends StatefulWidget {
  const IncidentsView({super.key});

  @override
  State<IncidentsView> createState() => _IncidentsViewState();
}

enum _Filter { all, unreviewed, resolved }

class _IncidentsViewState extends State<IncidentsView> {
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final fleet = context.watch<FleetController>();
    final colors = AppTheme.of(context);

    final incidents = fleet.incidents.where((i) {
      return switch (_filter) {
        _Filter.all => true,
        _Filter.unreviewed => i.reviewState == ReviewState.unreviewed,
        _Filter.resolved => i.reviewState == ReviewState.resolved,
      };
    }).toList();

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(AppLocalizations.of(context).translate('incidents'), style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                  Text('${fleet.unreviewedIncidents.length} need review',
                      style: GoogleFonts.poppins(fontSize: 12, color: colors.textMuted)),
                ]),
              ]),
            ),
            _filters(context),
            Expanded(
              child: incidents.isEmpty
                  ? _empty(context)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: incidents.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _incidentCard(context, fleet, incidents[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filters(BuildContext context) {
    Widget chip(_Filter f, String label) {
      final active = _filter == f;
      return GestureDetector(
        onTap: () => setState(() => _filter = f),
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppTheme.primary : AppTheme.of(context).card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: active ? AppTheme.primary : AppTheme.of(context).cardBorder),
          ),
          child: Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : AppTheme.of(context).textSecondary)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        chip(_Filter.all, 'All'),
        chip(_Filter.unreviewed, 'Unreviewed'),
        chip(_Filter.resolved, 'Resolved'),
      ]),
    );
  }

  Widget _empty(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.inbox_rounded, size: 46, color: AppTheme.of(context).textMuted.withValues(alpha: 0.4)),
        const SizedBox(height: 12),
        Text('Nothing here', style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.of(context).textMuted)),
      ]),
    );
  }

  Widget _incidentCard(BuildContext context, FleetController fleet, FleetIncident inc) {
    final color = severityColor(inc.severity);
    final resolved = inc.reviewState == ReviewState.resolved;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration(context,
          borderColor: resolved ? null : color.withValues(alpha: 0.3)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(incidentIcon(inc.type), color: color, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(inc.type.label,
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.of(context).textPrimary)),
                  const SizedBox(width: 8),
                  StatusChip(label: inc.severity.name, color: color),
                ]),
                Text('${inc.vehicleReg} · ${inc.driverName}',
                    style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.of(context).textMuted)),
              ]),
            ),
            Text(timeAgo(inc.timestamp), style: GoogleFonts.poppins(fontSize: 10, color: AppTheme.of(context).textMuted)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Icon(Icons.place_rounded, size: 13, color: AppTheme.of(context).textMuted),
            const SizedBox(width: 4),
            Expanded(
              child: Text(inc.location,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.of(context).textSecondary)),
            ),
            if (inc.hasVideo)
              Row(children: [
                Icon(Icons.videocam_rounded, size: 14, color: AppTheme.primary),
                const SizedBox(width: 3),
                Text('Clip', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primary)),
              ]),
          ]),
          const SizedBox(height: 12),
          if (resolved)
            Row(children: [
              const Icon(Icons.check_circle_rounded, size: 16, color: AppTheme.success),
              const SizedBox(width: 6),
              Text(AppLocalizations.of(context).translate('resolved'),
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.success)),
            ])
          else
            Row(children: [
              if (inc.hasVideo) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewEvidence(context, inc),
                    icon: const Icon(Icons.play_circle_outline_rounded, size: 16),
                    label: Text(AppLocalizations.of(context).translate('evidence')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.primary),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () => fleet.setReviewState(inc.id, ReviewState.resolved),
                  icon: const Icon(Icons.done_all_rounded, size: 16),
                  label: const Text('Mark resolved'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary, foregroundColor: Colors.white, elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ]),
        ],
      ),
    );
  }

  void _viewEvidence(BuildContext context, FleetIncident inc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: AppTheme.of(context).card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.of(context).cardBorder, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(14)),
              child: const Center(child: Icon(Icons.play_circle_fill_rounded, color: Colors.white70, size: 56)),
            ),
          ),
          const SizedBox(height: 14),
          Text('${inc.type.label} — ${inc.vehicleReg}',
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.of(context).textPrimary)),
          Text('${inc.driverName} · ${inc.location}',
              style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.of(context).textMuted)),
          const SizedBox(height: 8),
          Text('Pre/post-event clip, GPS, speed and driver identity would be packaged here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.of(context).textSecondary)),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }
}
