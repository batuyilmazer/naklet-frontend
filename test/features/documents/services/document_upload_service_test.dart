import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_frontend_boilerplate/core/errors/errors.dart';
import 'package:flutter_frontend_boilerplate/features/documents/data/files_repository.dart';
import 'package:flutter_frontend_boilerplate/features/documents/models/document_upload_state.dart';
import 'package:flutter_frontend_boilerplate/features/documents/models/selected_document_file.dart';
import 'package:flutter_frontend_boilerplate/features/documents/services/document_upload_service.dart';
import 'package:flutter_frontend_boilerplate/features/driver_dashboard/data/driver_dashboard_repository.dart';

class FakeFilesRepository extends FilesRepository {
  FakeFilesRepository({this.initUploadHandler, this.putUploadHandler});

  Future<Result<FileUrlResponse>> Function({
    required String fileName,
    required String mimeType,
    required int size,
    required String purpose,
    required String checksum,
  })?
  initUploadHandler;

  Future<Result<PresignedPutResult>> Function({
    required String url,
    required Uint8List bytes,
    required String mimeType,
  })?
  putUploadHandler;

  @override
  Future<Result<FileUrlResponse>> initUpload({
    required String fileName,
    required String mimeType,
    required int size,
    required String purpose,
    required String checksum,
  }) async {
    if (initUploadHandler != null) {
      return initUploadHandler!(
        fileName: fileName,
        mimeType: mimeType,
        size: size,
        purpose: purpose,
        checksum: checksum,
      );
    }

    return success(
      FileUrlResponse(
        url: 'https://example.com/upload',
        key: 'temp/$purpose/$fileName',
      ),
    );
  }

  @override
  Future<Result<PresignedPutResult>> uploadToPresignedUrl({
    required String url,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    if (putUploadHandler != null) {
      return putUploadHandler!(url: url, bytes: bytes, mimeType: mimeType);
    }

    return success(const PresignedPutResult(statusCode: 200, etag: 'etag'));
  }
}

class FakeDriverDashboardRepository extends DriverDashboardRepository {
  bool shouldThrow = false;
  String? uploadedLicenseKey;
  String? uploadedRegistrationKey;
  int callCount = 0;

  @override
  Future<void> uploadDocuments({
    String? licenseKey,
    String? licenseChecksum,
    String? registrationKey,
    String? registrationChecksum,
  }) async {
    callCount += 1;
    if (shouldThrow) {
      throw ApiException('Confirm failed', statusCode: 500);
    }
    uploadedLicenseKey = licenseKey;
    uploadedRegistrationKey = registrationKey;
  }
}

SelectedDocumentFile buildFile({
  required String name,
  required String mimeType,
}) {
  final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
  return SelectedDocumentFile(
    name: name,
    sizeBytes: bytes.length,
    mimeType: mimeType,
    bytes: bytes,
    source: DocumentFileSource.picker,
  );
}

void main() {
  group('DocumentUploadService', () {
    test('uploads only license document successfully', () async {
      final filesRepo = FakeFilesRepository();
      final driverRepo = FakeDriverDashboardRepository();
      final service = DocumentUploadService(
        filesRepository: filesRepo,
        driverRepository: driverRepo,
      );

      final statusLog = <DocumentUploadState>[];
      final result = await service.uploadDocuments(
        license: buildFile(name: 'ehliyet.jpg', mimeType: 'image/jpeg'),
        onStatusChange: (type, state, {message}) {
          if (type == DriverDocumentType.license) statusLog.add(state);
        },
      );

      expect(result.isSuccess, isTrue);
      final data = result.requireData;
      expect(data.succeededDocuments, contains(DriverDocumentType.license));
      expect(data.failedDocuments, isEmpty);
      expect(driverRepo.uploadedLicenseKey, isNotNull);
      expect(driverRepo.uploadedRegistrationKey, isNull);
      expect(
        statusLog,
        containsAllInOrder([
          DocumentUploadState.uploadingInit,
          DocumentUploadState.uploadingBinary,
          DocumentUploadState.confirming,
          DocumentUploadState.success,
        ]),
      );
    });

    test('uploads both documents successfully', () async {
      final filesRepo = FakeFilesRepository();
      final driverRepo = FakeDriverDashboardRepository();
      final service = DocumentUploadService(
        filesRepository: filesRepo,
        driverRepository: driverRepo,
      );

      final result = await service.uploadDocuments(
        license: buildFile(name: 'ehliyet.jpg', mimeType: 'image/jpeg'),
        registration: buildFile(
          name: 'ruhsat.pdf',
          mimeType: 'application/pdf',
        ),
      );

      expect(result.isSuccess, isTrue);
      final data = result.requireData;
      expect(data.succeededDocuments, contains(DriverDocumentType.license));
      expect(
        data.succeededDocuments,
        contains(DriverDocumentType.registration),
      );
      expect(data.failedDocuments, isEmpty);
      expect(driverRepo.uploadedLicenseKey, isNotNull);
      expect(driverRepo.uploadedRegistrationKey, isNotNull);
      expect(driverRepo.callCount, 1);
    });

    test('returns failure when init upload fails', () async {
      final filesRepo = FakeFilesRepository(
        initUploadHandler:
            ({
              required fileName,
              required mimeType,
              required size,
              required purpose,
              required checksum,
            }) async {
              return (
                data: null,
                failure: const ValidationFailure(message: 'Init failed'),
              );
            },
      );
      final driverRepo = FakeDriverDashboardRepository();
      final service = DocumentUploadService(
        filesRepository: filesRepo,
        driverRepository: driverRepo,
      );

      final result = await service.uploadDocuments(
        license: buildFile(name: 'ehliyet.jpg', mimeType: 'image/jpeg'),
      );

      expect(result.isFailure, isTrue);
      expect(result.failure!.message, 'Init failed');
      expect(driverRepo.callCount, 0);
    });

    test('returns failure when presigned PUT fails', () async {
      final filesRepo = FakeFilesRepository(
        putUploadHandler:
            ({required url, required bytes, required mimeType}) async {
              return (
                data: null,
                failure: const ClientFailure(
                  statusCode: 400,
                  message: 'PUT failed',
                ),
              );
            },
      );
      final driverRepo = FakeDriverDashboardRepository();
      final service = DocumentUploadService(
        filesRepository: filesRepo,
        driverRepository: driverRepo,
      );

      final result = await service.uploadDocuments(
        license: buildFile(name: 'ehliyet.jpg', mimeType: 'image/jpeg'),
      );

      expect(result.isFailure, isTrue);
      expect(result.failure!.message, 'PUT failed');
      expect(driverRepo.callCount, 0);
    });

    test('returns failure when document confirmation fails', () async {
      final filesRepo = FakeFilesRepository();
      final driverRepo = FakeDriverDashboardRepository()..shouldThrow = true;
      final service = DocumentUploadService(
        filesRepository: filesRepo,
        driverRepository: driverRepo,
      );

      final result = await service.uploadDocuments(
        license: buildFile(name: 'ehliyet.jpg', mimeType: 'image/jpeg'),
      );

      expect(result.isFailure, isTrue);
      expect(result.failure!.message, contains('Confirm failed'));
      expect(driverRepo.callCount, 1);
    });

    test(
      'supports partial success and confirms only successful documents',
      () async {
        final filesRepo = FakeFilesRepository(
          initUploadHandler:
              ({
                required fileName,
                required mimeType,
                required size,
                required purpose,
                required checksum,
              }) async {
                if (purpose == 'VEHICLE_REGISTRATION') {
                  return (
                    data: null,
                    failure: const ValidationFailure(
                      message: 'Registration init failed',
                    ),
                  );
                }
                return success(
                  FileUrlResponse(
                    url: 'https://example.com/upload',
                    key: 'temp/$purpose/$fileName',
                  ),
                );
              },
        );
        final driverRepo = FakeDriverDashboardRepository();
        final service = DocumentUploadService(
          filesRepository: filesRepo,
          driverRepository: driverRepo,
        );

        final result = await service.uploadDocuments(
          license: buildFile(name: 'ehliyet.jpg', mimeType: 'image/jpeg'),
          registration: buildFile(
            name: 'ruhsat.pdf',
            mimeType: 'application/pdf',
          ),
        );

        expect(result.isSuccess, isTrue);
        final data = result.requireData;
        expect(data.isPartialSuccess, isTrue);
        expect(data.succeededDocuments, contains(DriverDocumentType.license));
        expect(data.failedDocuments, contains(DriverDocumentType.registration));
        expect(driverRepo.uploadedLicenseKey, isNotNull);
        expect(driverRepo.uploadedRegistrationKey, isNull);
        expect(driverRepo.callCount, 1);
      },
    );
  });
}
