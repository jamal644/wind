import 'package:flutter/material.dart';

class NoteColors {
  static const Map<String, Color> colors = {
    'yellow': Color(0xFFFFF9C4),
    'blue': Color(0xFFE3F2FD),
    'green': Color(0xFFE8F5E8),
    'pink': Color(0xFFFCE4EC),
    'orange': Color(0xFFFFF3E0),
    'purple': Color(0xFFF3E5F5),
    'teal': Color(0xFFE0F2F1),
    'red': Color(0xFFFFEBEE),
  };

  static const List<String> colorNames = [
    'yellow',
    'blue',
    'green',
    'pink',
    'orange',
    'purple',
    'teal',
    'red',
  ];

  static Color getColor(String colorName) {
    return colors[colorName] ?? colors['yellow']!;
  }

  static String getColorName(int index) {
    return colorNames[index % colorNames.length];
  }
}
