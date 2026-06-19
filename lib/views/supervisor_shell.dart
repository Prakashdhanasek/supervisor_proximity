import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supervisor_proximity/views/masterview.dart';
import '../controllers/fleet_controller.dart';
import 'theme/app_theme.dart';
import 'dashboard_overview_view.dart';
import 'fleet_map_view.dart';
import 'incidents_view.dart';
import 'scorecards_view.dart';
import 'configuration_view.dart';
import '../l10n/app_localizations.dart';

class SupervisorShell extends StatefulWidget {
  const SupervisorShell({super.key});

  @override
  State<SupervisorShell> createState() => _SupervisorShellState();
}

class _SupervisorShellState extends State<SupervisorShell> {
  int _index = 0;

  late final List<Widget> _pages = [
    DashboardOverviewView(onNavigateToMap: () => setState(() => _index = 1)),
    const FleetMapView(),
    const IncidentsView(),
    const ScorecardsView(),
    const MasterView(),
    const ConfigurationView(),
  ];

  @override
  Widget build(BuildContext context) {
    final fleet = context.watch<FleetController>();
    final colors = AppTheme.of(context);

    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colors.card,
          border: Border(top: BorderSide(color: colors.cardBorder)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _tab(0, Icons.grid_view_rounded, 'Overview'),
                _tab(
                  1,
                  Icons.map_rounded,
                  AppLocalizations.of(
                    context,
                  ).translate('fleet_map').split(' ')[0],
                ),
                _tab(
                  2,
                  Icons.warning_amber_rounded,
                  AppLocalizations.of(context).translate('incidents'),
                  badge: fleet.unreviewedIncidents.length,
                ),
                _tab(
                  3,
                  Icons.bar_chart_rounded,
                  AppLocalizations.of(context).translate('drivers'),
                ),
                _tab(
                  4,
                  Icons.dashboard_customize_rounded,
                  AppLocalizations.of(
                    context,
                  ).translate('master_enrollment').split(' ')[0],
                ),
                _tab(
                  5,
                  Icons.settings_rounded,
                  AppLocalizations.of(context).translate('settings'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tab(int i, IconData icon, String label, {int badge = 0}) {
    final active = _index == i;
    final color = active ? AppTheme.primary : AppTheme.of(context).textMuted;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _index = i),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, color: color, size: 24),
                  if (badge > 0)
                    Positioned(
                      top: -5,
                      right: -8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.danger,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.of(context).card,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$badge',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
