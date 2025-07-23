import 'package:flutter/material.dart';

/// A utility class for color-related operations.
class ColorUtils {
  /// Creates a color with the given opacity.
  ///
  /// This is a replacement for the deprecated `withOpacity` method.
  /// It uses `Color.alphaBlend` to properly handle opacity.
  ///
  /// Example:
  /// ```dart
  /// // Instead of:
  /// // color.withOpacity(0.5)
  /// // Use:
  /// ColorUtils.withOpacity(color, 0.5)
  /// ```
  static Color withOpacity(Color color, double opacity) {
    assert(opacity >= 0.0 && opacity <= 1.0);
    return Color.alphaBlend(
      color.withAlpha((opacity * 255).round()),
      Colors.transparent,
    );
  }

  /// Creates a black color with the given opacity.
  static Color blackOpacity(double opacity) {
    return withOpacity(Colors.black, opacity);
  }

  /// Creates a white color with the given opacity.
  static Color whiteOpacity(double opacity) {
    return withOpacity(Colors.white, opacity);
  }

  /// Creates a primary color with the given opacity.
  static Color primaryOpacity(BuildContext context, double opacity) {
    return withOpacity(Theme.of(context).primaryColor, opacity);
  }
}
