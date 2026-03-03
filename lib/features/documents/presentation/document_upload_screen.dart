import 'package:flutter/material.dart';

import '../../../theme/extensions/theme_context_extensions.dart';
import '../../../ui/atoms/app_button.dart';
import '../../../ui/atoms/app_text.dart';
import '../../driver_dashboard/data/driver_dashboard_repository.dart';

/// Document upload screen for driver license and vehicle registration.
///
/// Handles file selection and upload via PATCH /drivers/documents.
class DocumentUploadScreen extends StatefulWidget {
  const DocumentUploadScreen({super.key});

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  final _repository = DriverDashboardRepository();
  bool _isUploading = false;
  String? _licenseFileName;
  String? _registrationFileName;
  String? _error;
  String? _success;

  Future<void> _pickLicense() async {
    // TODO: Integrate with file_picker or image_picker package.
    setState(() {
      _licenseFileName = 'ehliyet_foto.jpg';
    });
  }

  Future<void> _pickRegistration() async {
    // TODO: Integrate with file_picker or image_picker package.
    setState(() {
      _registrationFileName = 'ruhsat_foto.jpg';
    });
  }

  Future<void> _handleUpload() async {
    if (_licenseFileName == null && _registrationFileName == null) {
      setState(() => _error = 'Lütfen en az bir belge seçin.');
      return;
    }

    setState(() {
      _isUploading = true;
      _error = null;
    });

    try {
      // TODO: First upload files to file service, then send keys/checksums.
      await _repository.uploadDocuments(
        licenseKey: _licenseFileName != null ? 'mock-license-key' : null,
        licenseChecksum:
            _licenseFileName != null ? 'mock-license-checksum' : null,
        registrationKey:
            _registrationFileName != null ? 'mock-registration-key' : null,
        registrationChecksum:
            _registrationFileName != null ? 'mock-registration-checksum' : null,
      );
      if (mounted) {
        setState(() {
          _isUploading = false;
          _success = 'Belgeler başarıyla yüklendi!';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _error = 'Belgeler yüklenirken bir hata oluştu.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final colors = context.appColors;

    return Scaffold(
      appBar: AppBar(title: const Text('Belge Yükleme')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(spacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppText.bodySmall(
              'Hesabınızın onaylanması için aşağıdaki belgeleri yükleyin.',
              color: colors.textSecondary,
            ),
            SizedBox(height: spacing.s24),

            // Error / Success messages
            if (_error != null) ...[
              Container(
                padding: EdgeInsets.all(spacing.s12),
                decoration: BoxDecoration(
                  color: colors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: AppText.bodySmall(_error!, color: colors.error),
              ),
              SizedBox(height: spacing.s16),
            ],
            if (_success != null) ...[
              Container(
                padding: EdgeInsets.all(spacing.s12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: AppText.bodySmall(_success!, color: Colors.green),
              ),
              SizedBox(height: spacing.s16),
            ],

            // License upload
            _buildDocumentCard(
              context,
              title: 'Ehliyet',
              subtitle: 'Sürücü belgesi fotoğrafı',
              icon: Icons.badge_outlined,
              fileName: _licenseFileName,
              onPick: _pickLicense,
            ),
            SizedBox(height: spacing.s16),

            // Registration upload
            _buildDocumentCard(
              context,
              title: 'Araç Ruhsatı',
              subtitle: 'Araç ruhsatı fotoğrafı',
              icon: Icons.description_outlined,
              fileName: _registrationFileName,
              onPick: _pickRegistration,
            ),
            SizedBox(height: spacing.s24),

            // Upload button
            AppButton(
              label: 'Belgeleri Yükle',
              onPressed: _isUploading ? null : _handleUpload,
              isLoading: _isUploading,
              isFullWidth: true,
              icon: const Icon(Icons.upload),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required String? fileName,
    required VoidCallback onPick,
  }) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final radius = context.appRadius;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius.card),
      ),
      child: InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(radius.card),
        child: Padding(
          padding: EdgeInsets.all(spacing.s16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: fileName != null
                      ? Colors.green.withValues(alpha: 0.1)
                      : colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  fileName != null ? Icons.check_circle : icon,
                  color: fileName != null ? Colors.green : colors.primary,
                  size: 24,
                ),
              ),
              SizedBox(width: spacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.bodySmall(title, color: colors.textPrimary),
                    SizedBox(height: spacing.s4),
                    AppText.caption(
                      fileName ?? subtitle,
                      color: fileName != null
                          ? Colors.green
                          : colors.textSecondary,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.upload_outlined,
                color: colors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
