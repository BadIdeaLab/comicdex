import "package:flutter/material.dart";

/// Indigo/violet seed — change this single value to retune the entire app's
/// color palette (see .codex/phases/P47-color-and-button-modernization.md).
const Color _seedColor = Color(0xFF5B5FEF);

ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: _seedColor,
    brightness: Brightness.dark,
  );
  return _buildTheme(colorScheme);
}

ThemeData _buildTheme(ColorScheme colorScheme) => ThemeData(
  useMaterial3: true,
  brightness: colorScheme.brightness,
  colorScheme: colorScheme,
  scaffoldBackgroundColor: colorScheme.surface,
  canvasColor: colorScheme.surface,
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(shape: const StadiumBorder()),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(shape: const StadiumBorder()),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(shape: const StadiumBorder()),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: colorScheme.surfaceContainerHigh,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(28),
    ),
  ),
);
