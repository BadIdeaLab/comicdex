import 'package:concept_nhv/widgets/glass_container.dart';
import 'package:flutter/material.dart';

/// Drop-in replacement for [showModalBottomSheet] that wraps [builder]'s
/// content in [GlassContainer.sheet] so every bottom sheet gets consistent
/// blur/opacity without each call site reimplementing it.
Future<T?> showGlassModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool useRootNavigator = false,
  bool useSafeArea = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: isScrollControlled,
    useRootNavigator: useRootNavigator,
    useSafeArea: useSafeArea,
    builder: (sheetContext) => GlassContainer.sheet(child: builder(sheetContext)),
  );
}
