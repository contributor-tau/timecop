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

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timecop/l10n.dart';
import 'package:timecop/state/dependencies.dart';
import 'package:timecop/state/settings/settings_notifier.dart';

import 'components/locale_options.dart';
import 'components/theme_options.dart';

class SettingsScreen extends ConsumerWidget {
  SettingsScreen({Key? key}) : super(key: key);

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // bool _switchValue = false;
  // bool _notificationPermissionGranted = false;

  void requestAndroidNotificationPermission(BuildContext context) async {
    var status = await Permission.notification.status;
    bool? result = await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()!
        .requestPermission();
    if ((result != null && !result) && status.isDenied) {
      if (context.mounted) {
        dialogNotificationPermission(context);
      }
    }
    // else if(status.isGranted || result!){
    //   _notificationPermissionGranted = true;
    // }
  }

  Future<void> dialogNotificationPermission(BuildContext context) async {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(L10N.of(context).tr.notificationPermissionRequired),
          content: Text(L10N.of(context).tr.notificationPermissionDialogBody),
          actions: [
            TextButton(
              child: Text(L10N.of(context).tr.cancel),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: Text(L10N.of(context).tr.settings),
              onPressed: () => openAppSettings(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    return Scaffold(
        appBar: AppBar(
          title: Text(L10N.of(context).tr.settings),
        ),
        body: ListView(
          children: <Widget>[
            const ThemeOptions(),
            const LocaleOptions(),
            SwitchListTile.adaptive(
              title: Text(L10N.of(context).tr.groupTimers),
              value: settings.groupTimers,
              onChanged: (bool value) =>
                  settingsNotifier.setBoolValues(groupTimers: value),
              activeColor: Theme.of(context).colorScheme.primary,
            ),
            SwitchListTile.adaptive(
              title: Text(L10N.of(context).tr.showProjectNames),
              value: settings.showProjectNames,
              onChanged: (bool value) => settingsNotifier
                  .setBoolValues(showProjectNames: value),
              activeColor: Theme.of(context).colorScheme.primary,
            ),
            SwitchListTile.adaptive(
              title: Text(L10N.of(context).tr.collapseDays),
              value: settings.collapseDays,
              onChanged: (bool value) =>
                  settingsNotifier.setBoolValues(collapseDays: value),
              activeColor: Theme.of(context).colorScheme.primary,
            ),
            SwitchListTile.adaptive(
              title: Text(L10N.of(context).tr.autocompleteDescription),
              value: settings.autocompleteDescription,
              onChanged: (bool value) => settingsNotifier
                  .setBoolValues(autocompleteDescription: value),
              activeColor: Theme.of(context).colorScheme.primary,
            ),
            SwitchListTile.adaptive(
              title: Text(L10N.of(context).tr.defaultFilterStartDateToMonday),
              value: settings.defaultFilterStartDateToMonday,
              onChanged: (bool value) => settingsNotifier
                  .setBoolValues(defaultFilterStartDateToMonday: value),
              activeColor: Theme.of(context).colorScheme.primary,
            ),
            ListTile(
              title: Text(L10N.of(context).tr.defaultFilterDays),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                settings.defaultFilterDays == -1
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 18),
                        child: Text("--"))
                    : Text(settings.defaultFilterDays.toString()),
                if (settings.defaultFilterDays != -1)
                  IconButton(
                    tooltip: L10N.of(context).tr.remove,
                    icon: const Icon(FontAwesomeIcons.circleMinus),
                    onPressed: () {
                      settingsNotifier.setDefaultFilterDays(null);
                    },
                  )
              ]),
              onTap: () async {
                int tempDays = settings.defaultFilterDays > 0
                    ? settings.defaultFilterDays
                    : 30;
                int? days = await showDialog<int>(
                    context: context,
                    builder: (BuildContext context) {
                      return StatefulBuilder(builder: (context, setState) {
                        return AlertDialog(
                          content: NumberPicker(
                            minValue: 1,
                            maxValue: 365,
                            onChanged: (int value) {
                              setState(() => tempDays = value);
                            },
                            value: tempDays,
                            infiniteLoop: true,
                            haptics: true,
                          ),
                          title: Text(L10N.of(context).tr.defaultFilterDays),
                          actions: <Widget>[
                            TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text(L10N.of(context).tr.cancel)),
                            TextButton(
                                onPressed: () {
                                  Navigator.pop(context, tempDays);
                                },
                                child: Text(L10N.of(context).tr.ok))
                          ],
                        );
                      });
                    });
                if (days != null) {
                  settingsNotifier.setDefaultFilterDays(days);
                }
              },
            ),
            SwitchListTile.adaptive(
              title: Text(L10N.of(context).tr.oneTimerAtATime),
              value: settings.oneTimerAtATime,
              onChanged: (bool value) =>
                  settingsNotifier.setBoolValues(oneTimerAtATime: value),
              activeColor: Theme.of(context).colorScheme.primary,
            ),
            if (Platform.isIOS || Platform.isAndroid)
              SwitchListTile.adaptive(
                title: Text(L10N.of(context).tr.showBadgeCounts),
                value: settings.showBadgeCounts,
                onChanged: (bool value) => settingsNotifier
                    .setBoolValues(showBadgeCounts: value),
                activeColor: Theme.of(context).colorScheme.primary,
              ),
            SwitchListTile.adaptive(
              title: Text(L10N.of(context).tr.enableRunningTimersNotification),
              value: settings.showRunningTimersAsNotifications,
              // value: _switchValue,

              onChanged: (bool value) {
                if (value) {
                  ref.read(notificationsServiceProvider).requestPermissions();
                  if (Platform.isAndroid) {
                    requestAndroidNotificationPermission(context);
                  }
                }
                settingsNotifier.setBoolValues(
                    showRunningTimersAsNotifications: value);
              },
              activeColor: Theme.of(context).colorScheme.primary,
            ),
            SwitchListTile.adaptive(
              title: Text(L10N.of(context).tr.nagAboutMissingTimer),
              value: settings.nagAboutMissingTimer,
              // value: _switchValue,

              onChanged: (bool value) {
                if (value) {
                  ref.read(notificationsServiceProvider).requestPermissions();
                  if (Platform.isAndroid) {
                    requestAndroidNotificationPermission(context);
                  }
                }
                settingsNotifier.setBoolValues(nagAboutMissingTimer: value);
              },
              activeColor: Theme.of(context).colorScheme.primary,
            ),
          ],
        ));
  }
}
