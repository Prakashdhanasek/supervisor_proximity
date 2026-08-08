import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import 'theme/app_theme.dart';
import 'admin_device_management_view.dart';
import 'vehicle_types_view.dart';
import 'project_sites_view.dart';

class ConfigurationView extends StatelessWidget {
  const ConfigurationView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.surface,
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              AppLocalizations.of(
                context,
              ).translate('configuration_settings').toUpperCase(),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
                color: colors.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Vehicle Types
          Material(
            color: isDark ? colors.card : const Color(0xFFEEF2F6),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VehicleTypesView()),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_offer_rounded,
                      color: Color(
                        0xFFFDCB95,
                      ), // Matching the tag color from image somewhat
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      AppLocalizations.of(context).translate('vehicle_types'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Project / Sites
          Material(
            color: colors.surface,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProjectSitesView()),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.push_pin_rounded,
                      color: Color(0xFFE53935), // Red pin color
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      AppLocalizations.of(context).translate('project_sites'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Admins and Devices
          Material(
            color: isDark ? colors.card : const Color(0xFFEEF2F6),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminDeviceManagementView(),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.admin_panel_settings_rounded,
                      color: Color(0xFF2563EB),
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Admins & Devices',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
