import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Service that checks Firestore for app version info and shows
/// an update dialog if a newer version is available.
///
/// Firestore document: `app_config/version`
/// Fields:
///   - latest_version: String (e.g. "1.2.0")
///   - min_version: String (e.g. "1.0.0") — force update if current < this
///   - update_url: String (Play Store / APK link)
///   - release_notes: String (optional)
class AppUpdateService {
  AppUpdateService._();
  static final AppUpdateService instance = AppUpdateService._();

  // Dummy store URL — replace with real Play Store link when published
  static const _fallbackUrl =
      'https://play.google.com/store/apps/details?id=com.proximity.supervisor';

  /// Call this on app launch (e.g. splash screen).
  /// Returns true if the user can proceed, false if a forced update is blocking.
  Future<bool> checkForUpdate(BuildContext context) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version; // e.g. "1.0.0"

      final doc = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('version')
          .get();

      if (!doc.exists) return true; // No config = no update check

      final data = doc.data()!;
      final latestVersion = data['latest_version'] as String? ?? currentVersion;
      final minVersion = data['min_version'] as String? ?? '0.0.0';
      final updateUrl = data['update_url'] as String? ?? _fallbackUrl;
      final releaseNotes = data['release_notes'] as String?;

      final isForceUpdate = _compareVersions(currentVersion, minVersion) < 0;
      final isUpdateAvailable =
          _compareVersions(currentVersion, latestVersion) < 0;

      if (!isUpdateAvailable) return true;

      if (!context.mounted) return true;

      if (isForceUpdate) {
        await _showUpdateDialog(
          context,
          title: 'Update Required',
          message:
              'A critical update is available. Please update to continue using the app.',
          releaseNotes: releaseNotes,
          updateUrl: updateUrl,
          isForced: true,
        );
        return false;
      } else {
        await _showUpdateDialog(
          context,
          title: 'Update Available',
          message: 'A new version ($latestVersion) is available.',
          releaseNotes: releaseNotes,
          updateUrl: updateUrl,
          isForced: false,
        );
        return true;
      }
    } catch (e) {
      debugPrint('AppUpdateService: Error checking for update: $e');
      return true; // Don't block app on error
    }
  }

  Future<void> _showUpdateDialog(
    BuildContext context, {
    required String title,
    required String message,
    String? releaseNotes,
    required String updateUrl,
    required bool isForced,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: !isForced,
      builder: (ctx) => PopScope(
        canPop: !isForced,
        child: AlertDialog(
          backgroundColor: const Color(0xFF0F1923),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.system_update_rounded,
                  color: Color(0xFF2563EB),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              if (releaseNotes != null && releaseNotes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "What's new:",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white60,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        releaseNotes,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            if (!isForced)
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Later',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    color: Colors.white54,
                  ),
                ),
              ),
            ElevatedButton(
              onPressed: () => _openStore(updateUrl),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: Text(
                'Update Now',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openStore(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Compare semantic versions. Returns:
  /// -1 if v1 < v2, 0 if equal, 1 if v1 > v2
  int _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map(int.tryParse).toList();
    final parts2 = v2.split('.').map(int.tryParse).toList();

    for (int i = 0; i < 3; i++) {
      final p1 = i < parts1.length ? (parts1[i] ?? 0) : 0;
      final p2 = i < parts2.length ? (parts2[i] ?? 0) : 0;
      if (p1 < p2) return -1;
      if (p1 > p2) return 1;
    }
    return 0;
  }
}
