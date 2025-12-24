import 'package:flutter/material.dart';

/// A reusable responsive wrapper for auth / form pages.
/// - Full height on all screens
/// - Centered card on tablet / desktop
/// - Scrollable when content is taller than the screen
/// - Simple to reuse in Login, Signup, etc.
class ResponsiveFormContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveFormContainer({
    super.key,
    required this.child,
    this.maxWidth = 500, // max card width on large screens
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final targetWidth = width < maxWidth ? width : maxWidth;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                // 🔑 Makes the content at least as tall as the viewport
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: targetWidth,
                    child: child,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
