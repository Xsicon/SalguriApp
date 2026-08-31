import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/l10n/app_localizations.dart';
import 'core/l10n/locale_notifier.dart';
import 'core/l10n/material_localizations_fallback.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_notifier.dart';
import 'features/splash/splash_screen.dart';
import 'services/push_service.dart';
import 'services/supabase_service.dart';

/// Global route observer so widgets can react when routes are pushed/popped.
final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

/// Lets non-widget code (push notification tap handlers) navigate without a
/// local BuildContext.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );
  await SupabaseService.initialize();
  await loadSavedLocale();
  // Doesn't block app start on push setup — registers/refreshes in the
  // background so a slow FCM handshake never delays first paint.
  unawaited(PushService.initialize());
  runApp(const SalguriApp());
}

class SalguriApp extends StatelessWidget {
  const SalguriApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Reference design size. All `.w`/`.h`/`.sp`/`.r` values elsewhere in the
    // app scale proportionally from this against the real device's screen,
    // so layouts stay consistent across low- and high-density phones instead
    // of assuming everyone has this exact screen. Matches business-app's
    // reference size for consistency between the two apps.
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      builder: (context, child) => ValueListenableBuilder<ThemeMode>(
        valueListenable: themeNotifier,
        builder: (context, mode, _) {
          return ValueListenableBuilder<Locale>(
            valueListenable: localeNotifier,
            builder: (context, locale, _) {
              return MaterialApp(
                navigatorKey: navigatorKey,
                title: 'Salguri',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: mode,
                locale: locale,
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  MaterialLocalizationsFallback(),
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                navigatorObservers: [routeObserver],
                home: const SplashScreen(),
              );
            },
          );
        },
      ),
    );
  }
}
