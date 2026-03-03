import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../../../core/errors/errors.dart';
import '../../driver_dashboard/data/driver_dashboard_repository.dart';
import '../data/files_repository.dart';
import '../models/document_upload_result.dart';
import '../models/document_upload_state.dart';
import '../models/selected_document_file.dart';
import 'document_file_validator.dart';

typedef DocumentUploadStatusCallback =
    void Function(
      DriverDocumentType type,
      DocumentUploadState state, {
      String? message,
    });

/// Orchestrates the full upload flow:
/// validate -> checksum -> /files/init -> presigned PUT -> /drivers/documents
class DocumentUploadService {
  DocumentUploadService({
    FilesRepository? filesRepository,
    DriverDashboardRepository? driverRepository,
    DocumentFileValidator? validator,
  }) : _filesRepository = filesRepository ?? FilesRepository(),
       _driverRepository = driverRepository ?? DriverDashboardRepository(),
       _validator = validator ?? const DocumentFileValidator();

  final FilesRepository _filesRepository;
  final DriverDashboardRepository _driverRepository;
  final DocumentFileValidator _validator;

  Future<Result<DocumentUploadResult>> uploadDocuments({
    SelectedDocumentFile? license,
    SelectedDocumentFile? registration,
    DocumentUploadStatusCallback? onStatusChange,
  }) async {
    _debugUploadFlowLog(
      'uploadDocuments start: hasLicense=${license != null}, hasRegistration=${registration != null}',
    );
    if (license == null && registration == null) {
      return fail(
        const ValidationFailure(message: 'Lütfen en az bir belge seçin.'),
      );
    }

    final failedDocuments = <DriverDocumentType, String>{};
    final succeededDocuments = <DriverDocumentType>{};

    String? licenseKey;
    String? registrationKey;

    if (license != null) {
      _debugUploadFlowLog(
        'license upload start: name=${license.name}, size=${license.sizeBytes}, mime=${license.mimeType}',
      );
      final result = await _uploadSingle(
        type: DriverDocumentType.license,
        file: license,
        purpose: 'DRIVER_LICENSE',
        onStatusChange: onStatusChange,
      );
      if (result.isFailure) {
        _debugUploadFlowLog(
          'license upload failed: ${result.failure!.message}',
        );
        failedDocuments[DriverDocumentType.license] = result.failure!.message;
      } else {
        licenseKey = result.requireData;
        _debugUploadFlowLog('license upload success: key=$licenseKey');
      }
    }

    if (registration != null) {
      _debugUploadFlowLog(
        'registration upload start: name=${registration.name}, size=${registration.sizeBytes}, mime=${registration.mimeType}',
      );
      final result = await _uploadSingle(
        type: DriverDocumentType.registration,
        file: registration,
        purpose: 'VEHICLE_REGISTRATION',
        onStatusChange: onStatusChange,
      );
      if (result.isFailure) {
        _debugUploadFlowLog(
          'registration upload failed: ${result.failure!.message}',
        );
        failedDocuments[DriverDocumentType.registration] =
            result.failure!.message;
      } else {
        registrationKey = result.requireData;
        _debugUploadFlowLog(
          'registration upload success: key=$registrationKey',
        );
      }
    }

    if (licenseKey == null && registrationKey == null) {
      final firstError = failedDocuments.isNotEmpty
          ? failedDocuments.values.first
          : 'Belgeler yüklenemedi. Lütfen tekrar deneyin.';
      return fail(ValidationFailure(message: firstError));
    }

    if (licenseKey != null) {
      onStatusChange?.call(
        DriverDocumentType.license,
        DocumentUploadState.confirming,
      );
    }
    if (registrationKey != null) {
      onStatusChange?.call(
        DriverDocumentType.registration,
        DocumentUploadState.confirming,
      );
    }

    try {
      _debugUploadFlowLog(
        'confirm start: licenseKey=$licenseKey, registrationKey=$registrationKey',
      );
      await _driverRepository.uploadDocuments(
        licenseKey: licenseKey,
        registrationKey: registrationKey,
      );
      _debugUploadFlowLog('confirm success');
    } catch (error) {
      final mappedFailure = ErrorMapper.mapException(error);
      _debugUploadFlowLog(
        'confirm failed: type=${error.runtimeType}, message=${mappedFailure.message}',
      );
      if (licenseKey != null) {
        failedDocuments[DriverDocumentType.license] = mappedFailure.message;
        onStatusChange?.call(
          DriverDocumentType.license,
          DocumentUploadState.failed,
          message: mappedFailure.message,
        );
      }
      if (registrationKey != null) {
        failedDocuments[DriverDocumentType.registration] =
            mappedFailure.message;
        onStatusChange?.call(
          DriverDocumentType.registration,
          DocumentUploadState.failed,
          message: mappedFailure.message,
        );
      }
      return fail(mappedFailure);
    }

    if (licenseKey != null) {
      succeededDocuments.add(DriverDocumentType.license);
      onStatusChange?.call(
        DriverDocumentType.license,
        DocumentUploadState.success,
      );
    }
    if (registrationKey != null) {
      succeededDocuments.add(DriverDocumentType.registration);
      onStatusChange?.call(
        DriverDocumentType.registration,
        DocumentUploadState.success,
      );
    }

    return success(
      DocumentUploadResult(
        succeededDocuments: succeededDocuments,
        failedDocuments: failedDocuments,
        licenseKey: licenseKey,
        registrationKey: registrationKey,
      ),
    );
  }

  Future<Result<String>> _uploadSingle({
    required DriverDocumentType type,
    required SelectedDocumentFile file,
    required String purpose,
    DocumentUploadStatusCallback? onStatusChange,
  }) async {
    final validationFailure = _validator.validate(file);
    if (validationFailure != null) {
      _debugUploadFlowLog(
        '${type.name} validation failed: ${validationFailure.message}',
      );
      onStatusChange?.call(
        type,
        DocumentUploadState.failed,
        message: validationFailure.message,
      );
      return fail(validationFailure);
    }

    onStatusChange?.call(type, DocumentUploadState.uploadingInit);
    _debugUploadFlowLog('${type.name} init upload requested');

    final checksum = base64Encode(sha256.convert(file.bytes).bytes);
    final initResult = await _filesRepository.initUpload(
      fileName: file.name,
      mimeType: file.mimeType,
      size: file.sizeBytes,
      purpose: purpose,
      checksum: checksum,
    );

    if (initResult.isFailure) {
      final failure = initResult.failure!;
      _debugUploadFlowLog(
        '${type.name} init upload failed: ${failure.message}',
      );
      onStatusChange?.call(
        type,
        DocumentUploadState.failed,
        message: failure.message,
      );
      return fail(failure);
    }

    onStatusChange?.call(type, DocumentUploadState.uploadingBinary);
    _debugUploadFlowLog('${type.name} binary upload requested');

    final initData = initResult.requireData;
    final putResult = await _filesRepository.uploadToPresignedUrl(
      url: initData.url,
      bytes: file.bytes,
      mimeType: file.mimeType,
    );

    if (putResult.isFailure) {
      final failure = putResult.failure!;
      _debugUploadFlowLog(
        '${type.name} binary upload failed: ${failure.message}',
      );
      onStatusChange?.call(
        type,
        DocumentUploadState.failed,
        message: failure.message,
      );
      return fail(failure);
    }

    _debugUploadFlowLog(
      '${type.name} binary upload success: key=${initData.key}',
    );
    return success(initData.key);
  }

  void _debugUploadFlowLog(String message) {
    if (!kDebugMode) return;
    debugPrint('[DocumentUploadService][Flow] $message');
  }
}
