import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/app_version_service.dart';
import 'theme/app_theme.dart';

class DriverAppUpdatesView extends StatefulWidget {
  const DriverAppUpdatesView({super.key});

  @override
  State<DriverAppUpdatesView> createState() => _DriverAppUpdatesViewState();
}

class _DriverAppUpdatesViewState extends State<DriverAppUpdatesView> {
  final _formKey = GlobalKey<FormState>();
  final _versionNameController = TextEditingController();
  final _versionCodeController = TextEditingController();
  final _releaseNotesController = TextEditingController();
  
  final _versionService = AppVersionService();
 // String? _selectedApkPath;


  String? _selectedApkPath;
  String? _selectedApkName;
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _versions = [];

  @override
  void initState() {
    super.initState();
    _loadVersions();
  }

  @override
  void dispose() {
    _versionNameController.dispose();
    _versionCodeController.dispose();
    _releaseNotesController.dispose();
    super.dispose();
  }

  Future<void> _loadVersions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _versionService.fetchVersions();
      setState(() {
        _versions = data;
      });
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickApk() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['apk'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedApkPath = result.files.single.path;
          _selectedApkName = result.files.single.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick APK: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  Future<void> _publishApk() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedApkPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select an APK file to publish'),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _versionService.publishVersion(
        versionName: _versionNameController.text.trim(),
        versionCode: _versionCodeController.text.trim(),
        releaseNotes: _releaseNotesController.text.trim(),
        apkFilePath: _selectedApkPath!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New version published successfully')),
        );
      }

      // Reset form
      _versionNameController.clear();
      _versionCodeController.clear();
      _releaseNotesController.clear();
      setState(() {
        _selectedApkPath = null;
        _selectedApkName = null;
      });

      // Reload list
      await _loadVersions();
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 1024;

    final content = isWide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 4, child: _buildPublishCard()),
              const SizedBox(width: 20),
              Expanded(flex: 6, child: _buildHistoryCard()),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPublishCard(),
              const SizedBox(height: 20),
              _buildHistoryCard(),
            ],
          );

    return Scaffold(
      backgroundColor: colors.surface,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Driver App Updates',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                if (_error != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _error!,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.danger,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                content,
              ],
            ),
          ),
          if (_isLoading)
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

  Widget _buildPublishCard() {
    final colors = AppTheme.of(context);

    return Container(
      decoration: AppTheme.cardDecoration(
        context,
        borderColor: colors.cardBorder,
      ),
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Publish New Version',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _versionNameController,
                    label: 'VERSION NAME *',
                    hint: 'e.g. 1.2.0',
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _versionCodeController,
                    label: 'VERSION CODE *',
                    hint: 'e.g. 12',
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (int.tryParse(v.trim()) == null) return 'Must be integer';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'APK FILE *',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: colors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: colors.cardBorder),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickApk,
                    icon: const Icon(Icons.upload_file_outlined),
                    label: const Text('Browse'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.textPrimary,
                      side: BorderSide(color: colors.cardBorder),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedApkName ?? 'No file selected',
                      style: GoogleFonts.plusJakartaSans(
                        color: _selectedApkName != null ? colors.textPrimary : colors.textMuted,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _releaseNotesController,
              label: 'RELEASE NOTES',
              hint: "What's new in this version...",
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _publishApk,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFEF3C7), // Yellow/amber background from image
                foregroundColor: const Color(0xFF78350F), // Dark brown text from image
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Publish APK',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard() {
    final colors = AppTheme.of(context);

    return Container(
      decoration: AppTheme.cardDecoration(
        context,
        borderColor: colors.cardBorder,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Version History',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              Text(
                '${_versions.length} release(s)',
                style: GoogleFonts.plusJakartaSans(
                  color: colors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_versions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40.0),
              child: Center(
                child: Text(
                  'No version history found',
                  style: GoogleFonts.plusJakartaSans(color: colors.textMuted),
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                defaultColumnWidth: const IntrinsicColumnWidth(),
                children: [
                  TableRow(
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: colors.cardBorder)),
                    ),
                    children: [
                      _th('VERSION'),
                      _th('CODE'),
                      _th('STATUS'),
                      _th('RELEASE NOTES'),
                      _th('UPLOADED BY'),
                    ],
                  ),
                  for (int i = 0; i < _versions.length; i++) ...[
                    _buildRow(_versions[i], i == 0),
                  ]
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _th(String label) {
    final colors = AppTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: colors.textMuted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  TableRow _buildRow(Map<String, dynamic> item, bool isLatest) {
    final colors = AppTheme.of(context);
    
    final name = (item['versionName'] ?? item['version'] ?? '-').toString();
    final code = (item['versionCode'] ?? item['code'] ?? '-').toString();
    
    // Status resolution
    final statusVal = item['status'];
    String statusStr = 'Archived';
    bool isActive = false;
    if (statusVal is String) {
      statusStr = statusVal;
      isActive = statusVal.toLowerCase() == 'active';
    } else if (item['isActive'] == true) {
      statusStr = 'Active';
      isActive = true;
    }

    // Uploader resolution
    final uploadedByVal = item['uploadedBy'] ?? item['createdBy'] ?? '-';
    String uploader = '-';
    if (uploadedByVal is Map) {
      uploader = (uploadedByVal['fullName'] ?? uploadedByVal['name'] ?? '-').toString();
    } else {
      uploader = uploadedByVal.toString();
    }

    final notes = (item['releaseNotes'] ?? item['notes'] ?? '—').toString();

    return TableRow(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.cardBorder.withValues(alpha: 0.5))),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                  fontSize: 13,
                ),
              ),
              if (isLatest) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Text(
                    'LATEST',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF047857),
                      fontWeight: FontWeight.bold,
                      fontSize: 8,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Text(
            code,
            style: GoogleFonts.plusJakartaSans(
              color: colors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFF0FDF4) : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              statusStr,
              style: GoogleFonts.plusJakartaSans(
                color: isActive ? const Color(0xFF15803D) : const Color(0xFF4B5563),
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Text(
            notes,
            style: GoogleFonts.plusJakartaSans(
              color: colors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Text(
            uploader,
            style: GoogleFonts.plusJakartaSans(
              color: colors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final colors = AppTheme.of(context);

    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      keyboardType: keyboardType,
      style: GoogleFonts.plusJakartaSans(color: colors.textPrimary, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: GoogleFonts.plusJakartaSans(
          color: colors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        hintStyle: GoogleFonts.plusJakartaSans(color: colors.textMuted, fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF0A4CB1), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}
