import 'package:flutter/material.dart';

/// Shared theme mode — kept out of main.dart to avoid circular imports
/// (settings_screen used to import main.dart, which imported settings).
final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.dark);
