import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../controllers/fleet_controller.dart';
import '../models/fleet_models.dart';
import 'theme/app_theme.dart';
import 'widgets/common.dart';

class ApprovalsView extends StatefulWidget {
  const ApprovalsView({super.key});

  @override
  State<ApprovalsView> createState() => _ApprovalsViewState();
}

class _ApprovalsViewState extends State<ApprovalsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<String> _collapsed = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
    final all = fleet.approvals.toList();
    final pending = all
        .where((a) => a.status == ApprovalStatus.pending)
        .toList();
    final approved = all
        .where((a) => a.status == ApprovalStatus.approved)
        .toList();
    final denied = all.where((a) => a.status == ApprovalStatus.denied).toList();

    List<ApprovalRequest> activeList;
    switch (_tabController.index) {
      case 1:
        activeList = pending;
        break;
      case 2:
        activeList = approved;
        break;
      case 3:
        activeList = denied;
        break;
      default:
        activeList = all;
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      activeList = activeList.where((a) {
        return a.driverName.toLowerCase().contains(_searchQuery) ||
            a.vehicleReg.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ── Tab bar (white bg, underline style) ─────────────────────
          _buildTabBar(
            all.length,
            pending.length,
            approved.length,
            denied.length,
          ),

          // ── Card list ────────────────────────────────────────────────
          Expanded(
            child: activeList.isEmpty
                ? _buildEmpty()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: activeList.length,
                    itemBuilder: (_, i) =>
                        _buildCard(context, fleet, activeList[i]),
                  ),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    final controller = TextEditingController(text: _searchQuery);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(ctx).viewPadding.bottom + 16,
          ),
          decoration: BoxDecoration(
            color: AppTheme.of(context).surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppTheme.of(context).textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Search driver, vehicle...',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: AppTheme.of(context).textMuted,
                  ),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      setState(() => _searchQuery = '');
                      Navigator.pop(ctx);
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: AppTheme.of(context).cardBorder,
                    ),
                  ),
                  filled: true,
                  fillColor: AppTheme.of(context).card,
                ),
                onSubmitted: (v) {
                  setState(() => _searchQuery = v.toLowerCase());
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────
  // Tab bar
  // ────────────────────────────────────────────────────────────────────
  Widget _buildTabBar(int all, int pending, int approved, int denied) {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: const Color(0xFF2B72F5),
            indicatorWeight: 2.5,
            labelColor: const Color(0xFF2B72F5),
            unselectedLabelColor: const Color(0xFF94A3B8),
            dividerColor: const Color(0xFFE2E8F0),
            labelStyle: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            tabs: [
              _tab('All', all),
              _tab('Pending', pending),
              _tab('Approved', approved),
              _tab('Reject', denied),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tab(String label, int count) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color:
                    _tabController.index ==
                        ['All', 'Pending', 'Approved', 'Reject'].indexOf(label)
                    ? const Color(0xFF2B72F5)
                    : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color:
                      _tabController.index ==
                          [
                            'All',
                            'Pending',
                            'Approved',
                            'Reject',
                          ].indexOf(label)
                      ? Colors.white
                      : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────
  // Empty state
  // ────────────────────────────────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_user_rounded,
            size: 56,
            color: const Color(0xFF10B981).withOpacity(0.35),
          ),
          const SizedBox(height: 14),
          Text(
            'No requests here',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'New start requests will appear here',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────
  // Approval card
  // ────────────────────────────────────────────────────────────────────
  Widget _buildCard(
    BuildContext context,
    FleetController fleet,
    ApprovalRequest a,
  ) {
    final isPending = a.status == ApprovalStatus.pending;
    final risky =
        !a.driverAssigned ||
        (a.method == AuthMethod.face && a.faceConfidence < 70);
    final isCollapsed = _collapsed.contains(a.id);

    // Avatar
    final avatarLetter = a.driverName.startsWith('Unknown')
        ? 'U'
        : a.driverName[0];
    final avatarColor = risky
        ? const Color(0xFFEF4444)
        : const Color(0xFF10B981);

    // Status pill
    final statusLabel = !isPending
        ? (a.status == ApprovalStatus.approved ? 'Approved' : 'Rejected')
        : (risky ? 'Review' : 'Verified');
    final statusColor = !isPending
        ? (a.status == ApprovalStatus.approved
              ? const Color(0xFF10B981)
              : const Color(0xFFEF4444))
        : (risky ? const Color(0xFFEF4444) : const Color(0xFF10B981));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Top row: avatar | name | status pill | chevron ──────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 12, 10),
            child: Row(
              children: [
                // Avatar circle
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: avatarColor,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    avatarLetter,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Name
                Expanded(
                  child: Text(
                    a.driverName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                // Status pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    statusLabel,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Chevron
                GestureDetector(
                  onTap: () => setState(() {
                    if (isCollapsed) {
                      _collapsed.remove(a.id);
                    } else {
                      _collapsed.add(a.id);
                    }
                  }),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCollapsed
                          ? Icons.keyboard_arrow_down_rounded
                          : Icons.keyboard_arrow_up_rounded,
                      size: 18,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Vehicle reg + time ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Row(
              children: [
                const Icon(
                  Icons.local_shipping_outlined,
                  size: 13,
                  color: Color(0xFF94A3B8),
                ),
                const SizedBox(width: 5),
                Text(
                  '${a.vehicleReg}  ·  ${timeAgo(a.requestedAt)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),

          // ── Expandable content ───────────────────────────────────────
          if (!isCollapsed) ...[
            const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Method
                  Expanded(
                    child: _metricCol(
                      icon: Icons.fingerprint_rounded,
                      label: 'Method',
                      value: _methodLabel(a.method),
                      valueColor: const Color(0xFF1E293B),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 56,
                    color: const Color(0xFFE2E8F0),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  // Face match
                  Expanded(
                    child: _metricCol(
                      icon: Icons.shield_outlined,
                      label: 'Face match',
                      value: a.method == AuthMethod.face
                          ? '${a.faceConfidence}%'
                          : '—',
                      valueColor: a.method == AuthMethod.face
                          ? (a.faceConfidence >= 70
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444))
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 56,
                    color: const Color(0xFFE2E8F0),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  // Assignment
                  Expanded(
                    child: _metricCol(
                      icon: Icons.local_shipping_outlined,
                      label: 'Assignment',
                      value: a.driverAssigned ? 'Assigned' : 'Not assigned',
                      valueColor: a.driverAssigned
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
            ),

            // Alert banner
            if (risky && isPending)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 14,
                        color: Color(0xFFEF4444),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          !a.driverAssigned
                              ? 'Driver not assigned to this vehicle'
                              : 'Low face confidence — verify identity',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Reject + Approve buttons (pending only)
            if (isPending)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: OutlinedButton.icon(
                          onPressed: () => fleet.deny(a.id),
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: Color(0xFFEF4444),
                          ),
                          label: Text(
                            'Reject',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFEF4444),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFFEF4444),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton.icon(
                          onPressed: () => fleet.approve(a.id),
                          icon: const Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                          label: Text(
                            'Approve',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────
  // Helpers
  // ────────────────────────────────────────────────────────────────────
  Widget _metricCol({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            color: const Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  String _methodLabel(AuthMethod method) {
    switch (method) {
      case AuthMethod.face:
        return 'Face+ liveness';
      case AuthMethod.rfid:
        return 'RFID card';
      case AuthMethod.pin:
        return 'PIN';
      case AuthMethod.mobileOverride:
        return 'Mobile override';
    }
  }
}
