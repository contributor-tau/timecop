// Copyright 2020 Kenton Hamaluik
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:async';

import 'dart:io';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/material.dart';
import 'package:timecop/data_providers/data/data_provider.dart';
import 'package:timecop/data_providers/notifications/notifications_provider.dart';
import 'package:timecop/data_providers/settings/settings_provider.dart';
import 'package:timecop/fontlicenses.dart';
import 'package:timecop/l10n.dart';
import 'package:timecop/models/theme_type.dart';
import 'package:timecop/screens/dashboard/DashboardScreen.dart';
import 'package:timecop/state/dependencies.dart';
import 'package:timecop/state/locale/locale_notifier.dart';
import 'package:timecop/state/settings/settings_notifier.dart';
import 'package:timecop/state/theme/theme_notifier.dart';
import 'package:timecop/state/timers/timers_notifier.dart';
import 'package:timecop/themes.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';

import 'package:timecop/data_providers/data/database_provider.dart';
import 'package:timecop/data_providers/settings/shared_prefs_settings_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final SettingsProvider settings = await SharedPrefsSettingsProvider.load();

  // get a path to the database file
  if (Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  final databaseFile = await DatabaseProvider.getDatabaseFile();
  await databaseFile.parent.create(recursive: true);

  final DataProvider data = await DatabaseProvider.open(databaseFile.path);
  final NotificationsProvider notifications =
      await NotificationsProvider.load();
  await runMain(settings, data, notifications);
}

/*import 'package:timecop/data_providers/data/mock_data_provider.dart';
import 'package:timecop/data_providers/settings/mock_settings_provider.dart';
Future<void> main() async {
  final SettingsProvider settings = MockSettingsProvider();
  final DataProvider data = MockDataProvider(Locale.fromSubtags(languageCode: "en"));
  await runMain(settings, data);
}*/

Future<void> runMain(SettingsProvider settings, DataProvider data,
    NotificationsProvider notifications) async {
  // setup intl date formats?
  //await initializeDateFormatting();
  LicenseRegistry.addLicense(getFontLicenses);

  runApp(ProviderScope(
    overrides: [
      settingsRepositoryProvider.overrideWithValue(settings),
      dataRepositoryProvider.overrideWithValue(data),
      notificationsServiceProvider.overrideWithValue(notifications),
    ],
    child: const TimeCopApp(),
  ));
}

class TimeCopApp extends ConsumerStatefulWidget {
  const TimeCopApp({Key? key}) : super(key: key);

  @override
  ConsumerState<TimeCopApp> createState() => _TimeCopAppState();
}

class _TimeCopAppState extends ConsumerState<TimeCopApp>
    with WidgetsBindingObserver {
  late Timer _updateTimersTimer;
  Brightness? brightness;

  @override
  void initState() {
    super.initState();
    _updateTimersTimer = Timer.periodic(const Duration(seconds: 1),
        (_) => ref.read(timersProvider.notifier).tick());
    WidgetsBinding.instance.addObserver(this);
    brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;

    // keep the app badge in sync with the number of running timers
    ref.listenManual<SettingsState>(
        settingsProvider,
        (_, settingsState) => _updateNotificationBadge(settingsState,
            ref.read(timersProvider).countRunningTimers()));
    ref.listenManual<int>(
        timersProvider.select((s) => s.countRunningTimers()),
        (_, count) =>
            _updateNotificationBadge(ref.read(settingsProvider), count),
        fireImmediately: true);
  }

  void _updateNotificationBadge(SettingsState settingsState, int count) async {
    if (Platform.isAndroid || Platform.isIOS) {
      if (!settingsState.hasAskedNotificationPermissions &&
          !settingsState.showBadgeCounts) {
        // they haven't set the permission yet
        return;
      } else if (settingsState.showBadgeCounts) {
        // need to ask permission
        if (count > 0) {
          FlutterAppBadger.updateBadgeCount(count);
        } else {
          FlutterAppBadger.removeBadge();
        }
      } else {
        // remove any and all badges if we disable the option
        FlutterAppBadger.removeBadge();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    // print("application lifecycle changed to: " + state.toString());
    if (state == AppLifecycleState.paused) {
      final settings = ref.read(settingsProvider);
      final timers = ref.read(timersProvider);

      // TODO: fix this ugly hack. The L10N we load is part of the material app
      // that we build in build(); so we don't have access to it here
      final locale = ref.read(localeProvider) ?? const Locale("en");
      final notifications = ref.read(notificationsServiceProvider);
      final l10n = await L10N.load(locale);

      if (settings.showRunningTimersAsNotifications &&
          timers.countRunningTimers() > 0) {
        // print("showing notification");
        await notifications.displayRunningTimersNotification(
            l10n.tr.runningTimersNotificationTitle,
            l10n.tr.runningTimersNotificationBody);
      } else {
        // print("not showing notification");
      }
    } else if (state == AppLifecycleState.resumed) {
      await ref.read(notificationsServiceProvider).removeAllNotifications();
    }
  }

  @override
  void dispose() {
    _updateTimersTimer.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    setState(() => brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness);
  }

  ThemeData getTheme(
      ThemeType? type, ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
    if (type == ThemeType.autoMaterialYou) {
      if (brightness == Brightness.dark) {
        type = ThemeType.darkMaterialYou;
      } else {
        type = ThemeType.lightMaterialYou;
      }
    }
    switch (type) {
      case ThemeType.light:
        return ThemeUtil.lightTheme;
      case ThemeType.dark:
        return ThemeUtil.darkTheme;
      case ThemeType.black:
        return ThemeUtil.blackTheme;
      case ThemeType.lightMaterialYou:
        return ThemeUtil.getThemeFromColors(
            brightness: Brightness.light,
            colors: lightDynamic ?? ThemeUtil.lightColors,
            appBarBackground:
                lightDynamic?.surface ?? ThemeUtil.lightColors.surface,
            appBarForeground:
                lightDynamic?.onSurface ?? ThemeUtil.lightColors.onSurface);
      case ThemeType.darkMaterialYou:
        return ThemeUtil.getThemeFromColors(
            brightness: Brightness.dark,
            colors: darkDynamic ?? ThemeUtil.darkColors,
            appBarBackground:
                darkDynamic?.surface ?? ThemeUtil.darkColors.surface,
            appBarForeground:
                darkDynamic?.onSurface ?? ThemeUtil.darkColors.onSurface);
      case ThemeType.auto:
      default:
        return brightness == Brightness.dark
            ? ThemeUtil.darkTheme
            : ThemeUtil.lightTheme;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeType = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);
    return DynamicColorBuilder(
        builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) =>
            MaterialApp(
              title: 'Time Cop',
              home: const DashboardScreen(),
              theme: getTheme(themeType, lightDynamic, darkDynamic),
              localizationsDelegates: const [
                L10N.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              locale: locale,
              supportedLocales: const [
                Locale('en'),
                Locale('ar'),
                Locale('cs'),
                Locale('da'),
                Locale('de'),
                Locale('es'),
                Locale('fr'),
                Locale('hi'),
                Locale('id'),
                Locale('it'),
                Locale('ja'),
                Locale('ko'),
                Locale('nb', 'NO'),
                Locale('pt'),
                Locale('ru'),
                Locale('tr'),
                Locale('zh', 'CN'),
                Locale('zh', 'TW'),
              ],
            ));
  }
}
