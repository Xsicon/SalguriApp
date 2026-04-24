import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global locale notifier – mirrors pattern used by themeNotifier.
final ValueNotifier<Locale> localeNotifier = ValueNotifier(const Locale('en'));

Future<void> loadSavedLocale() async {
  final prefs = await SharedPreferences.getInstance();
  final lang = prefs.getString('app_language');
  if (lang == 'Somali') {
    localeNotifier.value = const Locale('so');
  } else {
    localeNotifier.value = const Locale('en');
  }
}
