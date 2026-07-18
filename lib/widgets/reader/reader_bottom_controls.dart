import 'package:concept_nhv/widgets/glass_container.dart';
import 'package:flutter/material.dart';

/// Animated bottom controls bar for the comic reader.
///
/// Shows the current/total page indicator, a page slider, and a settings
/// button. Fades and slides in/out based on [visible].
class ReaderBottomControls extends StatelessWidget {
  const ReaderBottomControls({
    super.key,
    required this.visible,
    required this.currentPage,
    required this.totalPages,
    required this.onPageSliderChanged,
    required this.onSettingsTap,
  });

  final bool visible;
  final int currentPage;
  final int totalPages;
  final ValueChanged<double> onPageSliderChanged;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: visible ? Offset.zero : const Offset(0, 1),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: GlassContainer.bar(
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  // Page indicator
                  Text(
                    '$currentPage',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  // Page slider
                  Expanded(
                    child: Slider(
                      value: totalPages > 1
                          ? currentPage.toDouble().clamp(
                              1.0,
                              totalPages.toDouble(),
                            )
                          : 1.0,
                      min: 1.0,
                      max: totalPages > 1 ? totalPages.toDouble() : 2.0,
                      divisions: totalPages > 1 ? totalPages - 1 : 1,
                      onChanged: totalPages > 1 ? onPageSliderChanged : null,
                      activeColor: Colors.white,
                      inactiveColor: Colors.white38,
                    ),
                  ),
                  // Total pages
                  Text(
                    '$totalPages',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  // Settings button
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    tooltip: 'Reader settings',
                    onPressed: onSettingsTap,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
