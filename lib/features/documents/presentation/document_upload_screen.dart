import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/errors/result.dart';
import '../../../theme/extensions/theme_context_extensions.dart';
import '../../../ui/atoms/app_button.dart';
import '../../../ui/atoms/app_text.dart';
import '../models/document_upload_result.dart';
import '../models/document_upload_state.dart';
import '../models/selected_document_file.dart';
import '../services/document_file_validator.dart';
import '../services/document_upload_service.dart';
import '../services/platform_file_bytes.dart';

/// Document upload screen for driver license and vehicle registration.
class DocumentUploadScreen extends StatefulWidget {
  const DocumentUploadScreen({
    super.key,
    this.uploadService,
    this.validator,
    this.pickFromFileOverride,
    this.captureFromCameraOverride,
  });

  final DocumentUploadService? uploadService;
  final DocumentFileValidator? validator;
  final Future<SelectedDocumentFile?> Function()? pickFromFileOverride;
  final Future<SelectedDocumentFile?> Function()? captureFromCameraOverride;

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  late final DocumentUploadService _uploadService;
  late final DocumentFileValidator _validator;
  final ImagePicker _imagePicker = ImagePicker();

  SelectedDocumentFile? _licenseFile;
  SelectedDocumentFile? _registrationFile;

  DocumentUploadState _licenseStatus = DocumentUploadState.idle;
  DocumentUploadState _registrationStatus = DocumentUploadState.idle;

  String? _licenseStatusMessage;
  String? _registrationStatusMessage;

  bool _isUploading = false;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _uploadService = widget.uploadService ?? DocumentUploadService();
    _validator = widget.validator ?? const DocumentFileValidator();
  }

  bool get _supportsCamera {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  bool get _hasAnySelection =>
      _licenseFile != null || _registrationFile != null;

  Future<void> _pickDocument(DriverDocumentType type) async {
    if (_isUploading) return;

    final pickedFile = widget.pickFromFileOverride != null
        ? await widget.pickFromFileOverride!()
        : await _pickFromFilePicker();

    if (!mounted || pickedFile == null) return;

    setState(() {
      _setSelectedFile(type, pickedFile);
      _setStatus(type, DocumentUploadState.selected);
      _error = null;
      _success = null;
    });
  }

  Future<void> _captureDocument(DriverDocumentType type) async {
    if (_isUploading) return;

    final pickedFile = widget.captureFromCameraOverride != null
        ? await widget.captureFromCameraOverride!()
        : await _captureFromCamera();

    if (!mounted || pickedFile == null) return;

    setState(() {
      _setSelectedFile(type, pickedFile);
      _setStatus(type, DocumentUploadState.selected);
      _error = null;
      _success = null;
    });
  }

  Future<SelectedDocumentFile?> _pickFromFilePicker() async {
    try {
      final isMacOs = !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;
      final withData = !isMacOs;
      final withReadStream = !isMacOs;
      _debugPickerLog(
        'start platform=$defaultTargetPlatform, isWeb=$kIsWeb, '
        'withData=$withData, withReadStream=$withReadStream',
      );

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
        allowMultiple: false,
        withData: withData,
        withReadStream: withReadStream,
      );

      if (result == null) {
        _debugPickerLog(
          'picker returned null (user canceled or plugin returned empty result).',
        );
        return null;
      }

      if (result.files.isEmpty) {
        _debugPickerLog('picker returned empty files list.');
        return null;
      }

      final platformFile = result.files.single;
      _debugPickerLog('selected file: ${_describePlatformFile(platformFile)}');

      final bytes = await loadPlatformFileBytes(platformFile);
      if (bytes == null) {
        _debugPickerLog(
          'byte load failed: loadPlatformFileBytes returned null.',
        );
        _setError('Seçilen dosya okunamadı.');
        return null;
      }
      _debugPickerLog('byte load success: bytesLength=${bytes.length}.');

      final mimeType = _validator.resolveMimeType(
        fileName: platformFile.name,
        bytes: bytes,
      );

      final selectedFile = SelectedDocumentFile(
        name: platformFile.name,
        sizeBytes: bytes.length,
        mimeType: mimeType,
        bytes: bytes,
        source: DocumentFileSource.picker,
      );

      final validationFailure = _validator.validate(selectedFile);
      if (validationFailure != null) {
        _debugPickerLog(
          'validation failed: message=${validationFailure.message}, '
          'file=${_describePlatformFile(platformFile)}',
        );
        _setError(validationFailure.message);
        return null;
      }

      _debugPickerLog('selection completed successfully.');
      return selectedFile;
    } on MissingPluginException catch (error, stack) {
      _debugPickerLog('MissingPluginException message=$error, stack=$stack');
      _setError(
        'Dosya seçici eklentisi yüklenemedi. Uygulamayı tamamen kapatıp yeniden başlatın.',
      );
      return null;
    } on PlatformException catch (error, stack) {
      _debugPickerLog(
        'PlatformException code=${error.code}, message=${error.message}, '
        'details=${error.details}, stack=$stack',
      );
      final details = [
        error.code,
        error.message ?? '',
        '${error.details ?? ''}',
      ].join(' ').toLowerCase();
      if (details.contains('unsupported') &&
          (details.contains('macos') || details.contains('bytes'))) {
        _setError(
          'macOS dosya seçimi yapılandırması uyumsuz. Uygulamayı yeniden başlatıp tekrar deneyin.',
        );
        return null;
      }
      _setError('Dosya seçimi sırasında bir hata oluştu.');
      return null;
    } on Exception catch (error, stack) {
      _debugPickerLog(
        'Exception type=${error.runtimeType}, message=$error, stack=$stack',
      );
      final details = error.toString().toLowerCase();
      if (details.contains('unsupported') &&
          (details.contains('macos') || details.contains('bytes'))) {
        _setError(
          'macOS dosya seçimi yapılandırması uyumsuz. Uygulamayı yeniden başlatıp tekrar deneyin.',
        );
        return null;
      }
      _setError('Dosya seçimi sırasında bir hata oluştu.');
      return null;
    }
  }

  Future<SelectedDocumentFile?> _captureFromCamera() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );
      if (image == null) return null;

      final bytes = await image.readAsBytes();
      final fileName = _extractFileName(image.path);
      final mimeType = _validator.resolveMimeType(
        fileName: fileName,
        bytes: bytes,
      );

      final selectedFile = SelectedDocumentFile(
        name: fileName,
        sizeBytes: bytes.length,
        mimeType: mimeType,
        bytes: bytes,
        source: DocumentFileSource.camera,
      );

      final validationFailure = _validator.validate(selectedFile);
      if (validationFailure != null) {
        _setError(validationFailure.message);
        return null;
      }

      return selectedFile;
    } catch (_) {
      _setError('Kamera ile belge alınırken bir hata oluştu.');
      return null;
    }
  }

  Future<void> _handleUpload() async {
    if (!_hasAnySelection) {
      _setError('Lütfen en az bir belge seçin.');
      return;
    }

    final licenseToUpload = _licenseStatus == DocumentUploadState.success
        ? null
        : _licenseFile;
    final registrationToUpload =
        _registrationStatus == DocumentUploadState.success
        ? null
        : _registrationFile;

    if (licenseToUpload == null && registrationToUpload == null) {
      _setError('Yüklenecek yeni belge bulunmuyor.');
      return;
    }

    setState(() {
      _isUploading = true;
      _error = null;
      _success = null;
    });

    final result = await _uploadService.uploadDocuments(
      license: licenseToUpload,
      registration: registrationToUpload,
      onStatusChange: (type, state, {message}) {
        if (!mounted) return;
        setState(() {
          _setStatus(type, state, message: message);
        });
      },
    );

    if (!mounted) return;

    setState(() {
      _isUploading = false;
      if (result.isFailure) {
        _error = result.failure!.message;
        _success = null;
        return;
      }

      final data = result.requireData;
      _applyUploadSummary(data);
    });
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
            SizedBox(height: spacing.s16),
            AppText.caption(
              'Desteklenen formatlar: JPG, PNG, PDF (maks. 10 MB)',
              color: colors.textSecondary,
            ),
            SizedBox(height: spacing.s24),
            if (_error != null) ...[
              _buildNotice(
                context,
                text: _error!,
                textColor: colors.error,
                backgroundColor: colors.error.withValues(alpha: 0.1),
              ),
              SizedBox(height: spacing.s16),
            ],
            if (_success != null) ...[
              _buildNotice(
                context,
                text: _success!,
                textColor: Colors.green,
                backgroundColor: Colors.green.withValues(alpha: 0.1),
              ),
              SizedBox(height: spacing.s16),
            ],
            _buildDocumentCard(
              context,
              type: DriverDocumentType.license,
              title: 'Ehliyet',
              subtitle: 'Sürücü belgesi fotoğrafı veya PDF',
              icon: Icons.badge_outlined,
              selectedFile: _licenseFile,
              status: _licenseStatus,
              statusMessage: _licenseStatusMessage,
            ),
            SizedBox(height: spacing.s16),
            _buildDocumentCard(
              context,
              type: DriverDocumentType.registration,
              title: 'Araç Ruhsatı',
              subtitle: 'Ruhsat fotoğrafı veya PDF',
              icon: Icons.description_outlined,
              selectedFile: _registrationFile,
              status: _registrationStatus,
              statusMessage: _registrationStatusMessage,
            ),
            SizedBox(height: spacing.s24),
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
    required DriverDocumentType type,
    required String title,
    required String subtitle,
    required IconData icon,
    required SelectedDocumentFile? selectedFile,
    required DocumentUploadState status,
    required String? statusMessage,
  }) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final radius = context.appRadius;

    final statusColor = switch (status) {
      DocumentUploadState.success => Colors.green,
      DocumentUploadState.failed => colors.error,
      DocumentUploadState.uploadingInit ||
      DocumentUploadState.uploadingBinary ||
      DocumentUploadState.confirming => Colors.orange,
      _ => colors.textSecondary,
    };

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius.card),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: selectedFile != null
                        ? Colors.green.withValues(alpha: 0.1)
                        : colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    selectedFile != null ? Icons.check_circle : icon,
                    color: selectedFile != null ? Colors.green : colors.primary,
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
                        selectedFile != null
                            ? '${selectedFile.name} (${_formatFileSize(selectedFile.sizeBytes)})'
                            : subtitle,
                        color: selectedFile != null
                            ? colors.textPrimary
                            : colors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.s12),
            Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: statusColor),
                SizedBox(width: spacing.s6),
                AppText.caption(status.label, color: statusColor),
              ],
            ),
            if (statusMessage != null) ...[
              SizedBox(height: spacing.s6),
              AppText.caption(statusMessage, color: statusColor),
            ],
            SizedBox(height: spacing.s12),
            Wrap(
              spacing: spacing.s8,
              runSpacing: spacing.s8,
              children: [
                OutlinedButton.icon(
                  onPressed: _isUploading ? null : () => _pickDocument(type),
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Dosya Seç'),
                ),
                if (_supportsCamera)
                  OutlinedButton.icon(
                    onPressed: _isUploading
                        ? null
                        : () => _captureDocument(type),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Kamera'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotice(
    BuildContext context, {
    required String text,
    required Color textColor,
    required Color backgroundColor,
  }) {
    final spacing = context.appSpacing;
    return Container(
      padding: EdgeInsets.all(spacing.s12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: AppText.bodySmall(text, color: textColor),
    );
  }

  void _applyUploadSummary(DocumentUploadResult result) {
    if (result.isCompleteSuccess) {
      _success = 'Belgeler başarıyla yüklendi.';
      _error = null;
      return;
    }

    if (result.isPartialSuccess) {
      _success = 'Bazı belgeler yüklendi. Başarısız belgeleri tekrar deneyin.';
      _error = _formatFailedDocuments(result.failedDocuments);
      return;
    }

    _success = 'Belgeler işlendi.';
  }

  String _formatFailedDocuments(
    Map<DriverDocumentType, String> failedDocuments,
  ) {
    return failedDocuments.entries
        .map((entry) => '${_documentLabel(entry.key)}: ${entry.value}')
        .join('\n');
  }

  String _documentLabel(DriverDocumentType type) {
    return switch (type) {
      DriverDocumentType.license => 'Ehliyet',
      DriverDocumentType.registration => 'Araç ruhsatı',
    };
  }

  void _setSelectedFile(DriverDocumentType type, SelectedDocumentFile file) {
    switch (type) {
      case DriverDocumentType.license:
        _licenseFile = file;
        break;
      case DriverDocumentType.registration:
        _registrationFile = file;
        break;
    }
  }

  void _setStatus(
    DriverDocumentType type,
    DocumentUploadState state, {
    String? message,
  }) {
    switch (type) {
      case DriverDocumentType.license:
        _licenseStatus = state;
        _licenseStatusMessage = message;
        break;
      case DriverDocumentType.registration:
        _registrationStatus = state;
        _registrationStatusMessage = message;
        break;
    }
  }

  void _setError(String message) {
    if (!mounted) return;
    setState(() {
      _error = message;
      _success = null;
    });
  }

  String _extractFileName(String path) {
    final normalized = path.replaceAll('\\', '/');
    final fileName = normalized.split('/').last.trim();
    if (fileName.isEmpty) {
      return 'camera_${DateTime.now().millisecondsSinceEpoch}.jpg';
    }
    return fileName;
  }

  String _formatFileSize(int sizeBytes) {
    if (sizeBytes < 1024) return '$sizeBytes B';
    final kb = sizeBytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }

  void _debugPickerLog(String message) {
    if (!kDebugMode) return;
    debugPrint('[DocumentUploadScreen][FilePicker] $message');
  }

  String _describePlatformFile(PlatformFile file) {
    return 'name=${file.name}, size=${file.size}, ext=${file.extension}, '
        'hasBytes=${file.bytes != null}, hasPath=${file.path != null}, '
        'hasReadStream=${file.readStream != null}, '
        'pathTail=${_pathTail(file.path)}';
  }

  String _pathTail(String? path) {
    if (path == null || path.isEmpty) return 'null';
    final normalized = path.replaceAll('\\', '/');
    final segments = normalized
        .split('/')
        .where((segment) => segment.isNotEmpty)
        .toList();
    if (segments.isEmpty) return 'null';
    if (segments.length == 1) return segments.first;
    return '${segments[segments.length - 2]}/${segments.last}';
  }
}
