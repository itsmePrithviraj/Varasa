import 'package:file_picker/file_picker.dart';
import '../../domain/models.dart';

Future<UploadFile?> pickUploadFile({
  bool imagesOnly = false,
  int maxBytes = 10 * 1024 * 1024,
}) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: imagesOnly
        ? ['jpg', 'jpeg', 'png', 'webp']
        : ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
    withData: true,
  );
  if (result == null) return null;
  final file = result.files.single;
  if (file.size > maxBytes || file.bytes == null || file.bytes!.isEmpty) {
    throw FormatException(
      'Choose a readable file up to ${maxBytes ~/ (1024 * 1024)} MB.',
    );
  }
  final type = switch (file.extension?.toLowerCase()) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'webp' => 'image/webp',
    'pdf' => 'application/pdf',
    _ => throw const FormatException('This file type is not supported.'),
  };
  final upload = UploadFile(
    name: file.name,
    bytes: file.bytes!,
    contentType: type,
  );
  upload.validate(maxBytes: maxBytes, imagesOnly: imagesOnly);
  return upload;
}
