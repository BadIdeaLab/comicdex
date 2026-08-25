import 'package:concept_nhv/services/backup/pairing_payload.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Picks an image and reads a pairing code out of it.
///
/// Reading from the photo library matters more than it looks. Besides the real
/// case — someone screenshots the desktop window, or is sent one — it is the
/// **only way to exercise pairing on an emulator**, which has no usable camera
/// and is where this project does most of its pre-device testing. Building the
/// camera path first would have meant building something that could not be
/// tried until a physical device was on hand.
///
/// The two collaborators are injected so tests can drive the whole flow without
/// a camera, a photo library, or platform channels.
class PairingCodeReader {
  PairingCodeReader({
    required Future<String?> Function() pickImagePath,
    required Future<List<String>> Function(String path) readCodesFromImage,
  }) : _pickImagePath = pickImagePath,
       _readCodesFromImage = readCodesFromImage;

  /// Wires up the real photo picker and decoder.
  factory PairingCodeReader.platform({
    ImagePicker? picker,
    MobileScannerController? scanner,
  }) {
    final imagePicker = picker ?? ImagePicker();
    final controller = scanner ?? MobileScannerController();
    return PairingCodeReader(
      pickImagePath: () async {
        final file = await imagePicker.pickImage(source: ImageSource.gallery);
        return file?.path;
      },
      readCodesFromImage: (path) async {
        final capture = await controller.analyzeImage(path);
        return <String>[
          for (final barcode in capture?.barcodes ?? const <Barcode>[])
            if (barcode.rawValue != null) barcode.rawValue!,
        ];
      },
    );
  }

  final Future<String?> Function() _pickImagePath;
  final Future<List<String>> Function(String path) _readCodesFromImage;

  /// Returns the payload, or null when the user backed out of the picker.
  ///
  /// Throws [PairingScanException] when an image was chosen but cannot be used,
  /// so the caller can tell the four reasons apart — "cancelled" is not one of
  /// them and deserves silence rather than an error.
  Future<PairingPayload?> readFromGallery() async {
    final path = await _pickImagePath();
    if (path == null) {
      return null;
    }

    // Shared with the camera path so both behave identically: a screenshot and
    // a camera frame can each hold more than one code.
    return parseFirstPairingCode(await _readCodesFromImage(path));
  }
}
