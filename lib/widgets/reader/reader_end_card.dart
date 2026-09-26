import 'package:concept_nhv/l10n/app_localizations.dart';
import 'package:concept_nhv/widgets/glass_container.dart';
import 'package:flutter/material.dart';

/// End-of-comic overlay card shown briefly when the reader reaches the
/// last page. Fades in/out based on [visible].
class ReaderEndCard extends StatelessWidget {
  const ReaderEndCard({super.key, required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Center(
          child: GlassContainer.card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              child: Text(
                AppLocalizations.of(context)!.readerEnd,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
