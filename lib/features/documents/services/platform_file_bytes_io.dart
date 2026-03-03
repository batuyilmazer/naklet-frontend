import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

Future<Uint8List?> loadPlatformFileBytesImpl(PlatformFile file) async {
  if (file.bytes != null) return file.bytes;

  if (file.path != null) {
    return File(file.path!).readAsBytes();
  }

  final stream = file.readStream;
  if (stream == null) return null;

  final buffer = <int>[];
  await for (final chunk in stream) {
    buffer.addAll(chunk);
  }
  return Uint8List.fromList(buffer);
}
