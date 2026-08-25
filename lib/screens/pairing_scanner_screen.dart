import 'package:concept_nhv/l10n/app_localizations.dart';
import 'package:concept_nhv/services/backup/pairing_payload.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Points the camera at the desktop's pairing QR and pops the payload.
///
/// Pops `null` when the user backs out, so the caller can tell "cancelled" from
/// "failed" without an exception.
class PairingScannerScreen extends StatefulWidget {
  const PairingScannerScreen({super.key});

  @override
  State<PairingScannerScreen> createState() => _PairingScannerScreenState();
}

class _PairingScannerScreenState extends State<PairingScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const <BarcodeFormat>[BarcodeFormat.qrCode],
  );

  /// Set once a code has been accepted, so the stream of frames that keeps
  /// arriving during the pop animation cannot pop the route twice.
  bool _handled = false;

  /// Shown under the viewfinder for codes that are not ours.
  ///
  /// Deliberately not an error dialog: the camera sees a frame many times a
  /// second, and anything modal would fire repeatedly and make the screen
  /// unusable while the user is still aiming.
  String? _hint;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) {
      return;
    }
    final codes = <String>[
      for (final barcode in capture.barcodes)
        if (barcode.rawValue != null) barcode.rawValue!,
    ];
    if (codes.isEmpty) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    try {
      // Same rule as the photo-library path: take the first *pairing* code, not
      // the first code, so an unrelated QR in frame cannot mask ours.
      final payload = parseFirstPairingCode(codes);
      _handled = true;
      Navigator.of(context).pop(payload);
    } on PairingScanException catch (error) {
      // Keep scanning. The user is probably still moving the camera, and the
      // reason tells them whether aiming better will help at all.
      final hint = switch (error.failure) {
        PairingScanFailure.noCodeFound => null,
        PairingScanFailure.notAPairingCode => l10n.backupScanNotOurCode,
        PairingScanFailure.unsupportedVersion => l10n.backupScanNeedsAppUpdate,
        PairingScanFailure.noAddresses => l10n.backupScanNoAddresses,
      };
      if (hint != _hint) {
        setState(() => _hint = hint);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.backupScanTitle)),
      body: Stack(
        children: <Widget>[
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            // Without this a denied permission shows the plugin's own bare
            // error, which says nothing about what the camera was for or how to
            // carry on without it.
            errorBuilder: (context, error) => _ScannerUnavailable(
              message: switch (error.errorCode) {
                MobileScannerErrorCode.permissionDenied =>
                  l10n.backupScanCameraDenied,
                _ => l10n.backupScanCameraUnavailable,
              },
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 32,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (_hint != null)
                  _ScannerBanner(text: _hint!, isWarning: true)
                else
                  _ScannerBanner(text: l10n.backupScanAimHint),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerBanner extends StatelessWidget {
  const _ScannerBanner({required this.text, this.isWarning = false});

  final String text;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        // Fixed dark backing rather than a theme colour: this sits over a live
        // camera feed, not over the app's own surface.
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: isWarning ? theme.colorScheme.error : Colors.white,
        ),
      ),
    );
  }
}

class _ScannerUnavailable extends StatelessWidget {
  const _ScannerUnavailable({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.no_photography_outlined, size: 48),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            // The way out matters as much as the message: pairing still works
            // from a screenshot or by typing, and this is where someone who
            // just refused the camera needs to be told so.
            FilledButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: Text(l10n.backupScanUseAnotherWay),
            ),
          ],
        ),
      ),
    );
  }
}
