import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_frontend_boilerplate/core/errors/errors.dart';
import 'package:flutter_frontend_boilerplate/core/storage/preferences_storage.dart';
import 'package:flutter_frontend_boilerplate/features/documents/models/document_upload_result.dart';
import 'package:flutter_frontend_boilerplate/features/documents/models/document_upload_state.dart';
import 'package:flutter_frontend_boilerplate/features/documents/models/selected_document_file.dart';
import 'package:flutter_frontend_boilerplate/features/documents/presentation/document_upload_screen.dart';
import 'package:flutter_frontend_boilerplate/features/documents/services/document_upload_service.dart';
import 'package:flutter_frontend_boilerplate/theme/theme_notifier.dart';
import 'package:provider/provider.dart';

class _MockPreferencesStorage implements PreferencesStorage {
  @override
  Future<ThemeMode?> getThemeMode() async => null;

  @override
  Future<void> saveThemeMode(ThemeMode mode) async {}
}

class FakeUploadService extends DocumentUploadService {
  FakeUploadService({required this.handler});

  final Future<Result<DocumentUploadResult>> Function({
    SelectedDocumentFile? license,
    SelectedDocumentFile? registration,
    DocumentUploadStatusCallback? onStatusChange,
  })
  handler;

  @override
  Future<Result<DocumentUploadResult>> uploadDocuments({
    SelectedDocumentFile? license,
    SelectedDocumentFile? registration,
    DocumentUploadStatusCallback? onStatusChange,
  }) {
    return handler(
      license: license,
      registration: registration,
      onStatusChange: onStatusChange,
    );
  }
}

SelectedDocumentFile _sampleFile() {
  final bytes = Uint8List.fromList([1, 2, 3, 4]);
  return SelectedDocumentFile(
    name: 'ehliyet.jpg',
    sizeBytes: bytes.length,
    mimeType: 'image/jpeg',
    bytes: bytes,
    source: DocumentFileSource.picker,
  );
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required DocumentUploadService uploadService,
  Future<SelectedDocumentFile?> Function()? pickFromFileOverride,
}) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<ThemeNotifier>(
      create: (_) =>
          ThemeNotifier(preferencesStorage: _MockPreferencesStorage()),
      child: MaterialApp(
        home: DocumentUploadScreen(
          uploadService: uploadService,
          pickFromFileOverride: pickFromFileOverride,
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('DocumentUploadScreen', () {
    testWidgets(
      'shows validation error when upload is tapped without selection',
      (tester) async {
        final uploadService = FakeUploadService(
          handler: ({license, registration, onStatusChange}) async {
            return success(
              const DocumentUploadResult(
                succeededDocuments: <DriverDocumentType>{},
                failedDocuments: {},
              ),
            );
          },
        );

        await _pumpScreen(tester, uploadService: uploadService);

        await tester.tap(find.text('Belgeleri Yükle'));
        await tester.pumpAndSettle();

        expect(find.text('Lütfen en az bir belge seçin.'), findsOneWidget);
      },
    );

    testWidgets('enables upload flow after picking a document', (tester) async {
      final uploadService = FakeUploadService(
        handler: ({license, registration, onStatusChange}) async {
          return success(
            const DocumentUploadResult(
              succeededDocuments: {DriverDocumentType.license},
              failedDocuments: {},
            ),
          );
        },
      );

      await _pumpScreen(
        tester,
        uploadService: uploadService,
        pickFromFileOverride: () async => _sampleFile(),
      );

      await tester.tap(find.widgetWithText(OutlinedButton, 'Dosya Seç').first);
      await tester.pumpAndSettle();

      expect(find.textContaining('ehliyet.jpg'), findsOneWidget);
      expect(find.text('Dosya seçildi'), findsOneWidget);
    });

    testWidgets(
      'shows loading and disables actions while upload is in progress',
      (tester) async {
        final completer = Completer<Result<DocumentUploadResult>>();
        final uploadService = FakeUploadService(
          handler: ({license, registration, onStatusChange}) {
            onStatusChange?.call(
              DriverDocumentType.license,
              DocumentUploadState.uploadingInit,
            );
            return completer.future;
          },
        );

        await _pumpScreen(
          tester,
          uploadService: uploadService,
          pickFromFileOverride: () async => _sampleFile(),
        );

        await tester.tap(
          find.widgetWithText(OutlinedButton, 'Dosya Seç').first,
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Belgeleri Yükle'));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        final pickButton = tester.widget<OutlinedButton>(
          find.widgetWithText(OutlinedButton, 'Dosya Seç').first,
        );
        expect(pickButton.onPressed, isNull);

        completer.complete(
          success(
            const DocumentUploadResult(
              succeededDocuments: {DriverDocumentType.license},
              failedDocuments: {},
            ),
          ),
        );
        await tester.pumpAndSettle();
      },
    );

    testWidgets('shows success message after successful upload', (
      tester,
    ) async {
      final uploadService = FakeUploadService(
        handler: ({license, registration, onStatusChange}) async {
          onStatusChange?.call(
            DriverDocumentType.license,
            DocumentUploadState.success,
          );
          return success(
            const DocumentUploadResult(
              succeededDocuments: {DriverDocumentType.license},
              failedDocuments: {},
            ),
          );
        },
      );

      await _pumpScreen(
        tester,
        uploadService: uploadService,
        pickFromFileOverride: () async => _sampleFile(),
      );

      await tester.tap(find.widgetWithText(OutlinedButton, 'Dosya Seç').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Belgeleri Yükle'));
      await tester.pumpAndSettle();

      expect(find.text('Belgeler başarıyla yüklendi.'), findsOneWidget);
    });

    testWidgets('shows error message when upload fails', (tester) async {
      final uploadService = FakeUploadService(
        handler: ({license, registration, onStatusChange}) async {
          return (
            data: null,
            failure: const ValidationFailure(message: 'Belgeler yüklenemedi.'),
          );
        },
      );

      await _pumpScreen(
        tester,
        uploadService: uploadService,
        pickFromFileOverride: () async => _sampleFile(),
      );

      await tester.tap(find.widgetWithText(OutlinedButton, 'Dosya Seç').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Belgeleri Yükle'));
      await tester.pumpAndSettle();

      expect(find.text('Belgeler yüklenemedi.'), findsOneWidget);
    });
  });
}
