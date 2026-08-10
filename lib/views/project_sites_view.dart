import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/project_sites_controller.dart';
import '../models/project_site.dart';
import 'theme/app_theme.dart';
import 'widgets/register_project_site_dialog.dart';

class ProjectSitesView extends StatefulWidget {
  const ProjectSitesView({super.key});

  @override
  State<ProjectSitesView> createState() => _ProjectSitesViewState();
}

class _ProjectSitesViewState extends State<ProjectSitesView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectSitesController>().fetchProjectSites();
    });
  }

  void _showRegisterDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const RegisterProjectSiteDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = context.watch<ProjectSitesController>();

    final total = controller.projectSites.length;
    final active = controller.projectSites.where((v) => v.isActive).length;
    final inactive = total - active;

    return Scaffold(
      backgroundColor: colors.surface,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showRegisterDialog,
        backgroundColor: const Color(0xFF1E3A8A), // Dark blue
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(
          'Add Project Site',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Table Container
                Expanded(
                  child:
                      controller.error != null &&
                          controller.projectSites.isEmpty
                      ? Center(
                          child: Text(
                            'Error: ${controller.error}',
                            style: TextStyle(color: AppTheme.danger),
                          ),
                        )
                      : _buildList(
                          context,
                          controller.projectSites,
                          colors,
                          isDark,
                        ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          if (controller.isLoading)
            Positioned.fill(
              child: Container(
                color: colors.surface.withValues(alpha: 0.5),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    List<ProjectSite> items,
    AppColors colors,
    bool isDark,
  ) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          'No project sites found.',
          style: GoogleFonts.plusJakartaSans(color: colors.textMuted),
        ),
      );
    }

    final dateFormat = DateFormat('dd MMM yyyy');

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 80), // Padding for FAB
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          decoration: AppTheme.cardDecoration(
            context,
            borderColor: colors.cardBorder,
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: item.isActive
                          ? AppTheme.success.withValues(alpha: 0.1)
                          : colors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: item.isActive
                                ? AppTheme.success
                                : colors.textMuted,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          item.isActive ? 'ACTIVE' : 'INACTIVE',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: item.isActive
                                ? AppTheme.success
                                : colors.textMuted,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Created by ${item.createdByName ?? '—'} on ${dateFormat.format(item.createdAt)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: colors.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) =>
                              RegisterProjectSiteDialog(projectSite: item),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.textPrimary,
                        side: BorderSide(color: colors.cardBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        try {
                          await context
                              .read<ProjectSitesController>()
                              .toggleProjectSiteStatus(item.id, item.isActive);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Project site ${item.isActive ? 'deactivated' : 'activated'} successfully',
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: AppTheme.danger,
                              ),
                            );
                          }
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: item.isActive
                            ? AppTheme.danger
                            : AppTheme.success,
                        side: BorderSide(
                          color: item.isActive
                              ? AppTheme.danger.withValues(alpha: 0.5)
                              : AppTheme.success.withValues(alpha: 0.5),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(item.isActive ? 'Deactivate' : 'Activate'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
