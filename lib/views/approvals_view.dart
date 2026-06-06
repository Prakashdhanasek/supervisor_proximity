import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../controllers/fleet_controller.dart';
import '../models/fleet_models.dart';
import 'theme/app_theme.dart';
import 'widgets/common.dart';

class ApprovalsView extends StatelessWidget {
  const ApprovalsView({super.key});

  @override
  Widget build(BuildContext context) {
    final fleet = context.watch<FleetController>();
    final colors = AppTheme.of(context);
    final pending = fleet.pendingApprovals;
    final history = fleet.approvals.where((a) => a.status != ApprovalStatus.pending).toList();

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Start Approvals',
                          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                      Text('Authorise or block vehicle start requests',
                          style: GoogleFonts.poppins(fontSize: 12, color: colors.textMuted)),
                    ],
                  ),
                  const Spacer(),
                  if (pending.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                      decoration: BoxDecoration(color: AppTheme.warning.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                      child: Text('${pending.length} pending',
                          style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.warning)),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  if (pending.isEmpty)
                    _empty(context)
                  else
                    ...pending.map((a) => _pendingCard(context, fleet, a)),
                  if (history.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text('Recent decisions',
                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                    const SizedBox(height: 8),
                    ...history.take(10).map((a) => _historyRow(context, a)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 44),
      alignment: Alignment.center,
      child: Column(children: [
        Icon(Icons.verified_user_rounded, size: 46, color: AppTheme.success.withValues(alpha: 0.5)),
        const SizedBox(height: 12),
        Text('No requests waiting',
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.of(context).textSecondary)),
        Text('New start requests will appear here',
            style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.of(context).textMuted)),
      ]),
    );
  }

  Widget _pendingCard(BuildContext context, FleetController fleet, ApprovalRequest a) {
    final risky = !a.driverAssigned || (a.method == AuthMethod.face && a.faceConfidence < 70);
    final accent = risky ? AppTheme.danger : AppTheme.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(context, borderColor: accent.withValues(alpha: 0.3)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(13)),
              child: Icon(risky ? Icons.gpp_maybe_rounded : Icons.verified_user_rounded, color: accent, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(a.driverName,
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.of(context).textPrimary)),
                Text('${a.vehicleReg} · ${timeAgo(a.requestedAt)}',
                    style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.of(context).textMuted)),
              ]),
            ),
            StatusChip(
              label: risky ? 'Review' : 'Looks OK',
              color: accent,
              icon: risky ? Icons.warning_amber_rounded : Icons.check_rounded,
            ),
          ]),
          const SizedBox(height: 14),
          _detailRow(context, Icons.fingerprint_rounded, 'Method', a.method.label),
          if (a.method == AuthMethod.face)
            _detailRow(context, Icons.face_rounded, 'Face match', '${a.faceConfidence}%',
                valueColor: a.faceConfidence >= 70 ? AppTheme.success : AppTheme.danger),
          _detailRow(context, Icons.assignment_ind_rounded, 'Assignment',
              a.driverAssigned ? 'Assigned to this vehicle' : 'NOT assigned to this vehicle',
              valueColor: a.driverAssigned ? AppTheme.success : AppTheme.danger),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => fleet.deny(a.id),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.danger,
                  side: const BorderSide(color: AppTheme.danger),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Deny'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () => fleet.approve(a.id),
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('Approve start'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success, foregroundColor: Colors.white, elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _detailRow(BuildContext context, IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(icon, size: 15, color: AppTheme.of(context).textMuted),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.of(context).textSecondary)),
        const Spacer(),
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: 12, fontWeight: FontWeight.w600, color: valueColor ?? AppTheme.of(context).textPrimary)),
      ]),
    );
  }

  Widget _historyRow(BuildContext context, ApprovalRequest a) {
    final approved = a.status == ApprovalStatus.approved;
    final color = approved ? AppTheme.success : AppTheme.danger;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.cardDecoration(context),
      child: Row(children: [
        Icon(approved ? Icons.check_circle_rounded : Icons.cancel_rounded, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(a.driverName, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.of(context).textPrimary)),
            Text('${a.vehicleReg} · ${a.method.label}', style: GoogleFonts.poppins(fontSize: 10, color: AppTheme.of(context).textMuted)),
          ]),
        ),
        StatusChip(label: approved ? 'Approved' : 'Denied', color: color),
      ]),
    );
  }
}
