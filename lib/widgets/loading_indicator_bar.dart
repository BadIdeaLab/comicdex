import 'package:flutter/material.dart';

class LoadingIndicatorBar extends StatelessWidget
    implements PreferredSizeWidget {
  const LoadingIndicatorBar({super.key, required this.isLoading});

  final bool isLoading;

  @override
  Size get preferredSize =>
      isLoading ? const Size(double.infinity, 4) : Size.zero;

  @override
  Widget build(BuildContext context) {
    if (!isLoading) {
      return const SizedBox.shrink();
    }

    return const LinearProgressIndicator();
  }
}
