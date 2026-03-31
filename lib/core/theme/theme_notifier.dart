import 'package:flutter/material.dart';

/// App-wide theme mode notifier.
/// Access via [themeNotifier] singleton; listen in MaterialApp.
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);
