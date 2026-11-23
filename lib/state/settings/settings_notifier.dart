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

import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timecop/data_providers/data/database_provider.dart';
import 'package:timecop/state/dependencies.dart';
import 'package:timecop/state/projects/projects_notifier.dart';
import 'package:timecop/state/settings/settings_state.dart';
import 'package:timecop/state/timers/timers_notifier.dart';

export 'package:timecop/state/settings/settings_state.dart';

/// User-configurable application settings.
final settingsProvider =
    NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);

class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    final settings = ref.watch(settingsRepositoryProvider);
    final defaults = SettingsState.initial();
    return SettingsState(
      exportGroupTimers:
          settings.getBool("exportGroupTimers") ?? defaults.exportGroupTimers,
      exportIncludeDate:
          settings.getBool("exportIncludeDate") ?? defaults.exportIncludeDate,
      exportIncludeProject: settings.getBool("exportIncludeProject") ??
          defaults.exportIncludeProject,
      exportIncludeDescription: settings.getBool("exportIncludeDescription") ??
          defaults.exportIncludeDescription,
      exportIncludeProjectDescription:
          settings.getBool("exportIncludeProjectDescription") ??
              defaults.exportIncludeProjectDescription,
      exportIncludeStartTime: settings.getBool("exportIncludeStartTime") ??
          defaults.exportIncludeStartTime,
      exportIncludeEndTime: settings.getBool("exportIncludeEndTime") ??
          defaults.exportIncludeEndTime,
      exportIncludeDurationHours:
          settings.getBool("exportIncludeDurationHours") ??
              defaults.exportIncludeDurationHours,
      exportIncludeNotes:
          settings.getBool("exportIncludeNotes") ?? defaults.exportIncludeNotes,
      groupTimers: settings.getBool("groupTimers") ?? defaults.groupTimers,
      collapseDays: settings.getBool("collapseDays") ?? defaults.collapseDays,
      autocompleteDescription: settings.getBool("autocompleteDescription") ??
          defaults.autocompleteDescription,
      defaultFilterStartDateToMonday:
          settings.getBool("defaultFilterStartDateToMonday") ??
              defaults.defaultFilterStartDateToMonday,
      oneTimerAtATime:
          settings.getBool("oneTimerAtATime") ?? defaults.oneTimerAtATime,
      showBadgeCounts:
          settings.getBool("showBadgeCounts") ?? defaults.showBadgeCounts,
      defaultFilterDays: settings.getInt("defaultFilterDays") ?? 30,
      hasAskedNotificationPermissions:
          settings.getBool("hasAskedNotificationPermissions") ??
              defaults.hasAskedNotificationPermissions,
      showRunningTimersAsNotifications:
          settings.getBool("showRunningTimersAsNotifications") ??
              defaults.showRunningTimersAsNotifications,
      showProjectNames:
          settings.getBool("showProjectNames") ?? defaults.showProjectNames,
      nagAboutMissingTimer: settings.getBool("nagAboutMissingTimer") ??
          defaults.nagAboutMissingTimer,
    );
  }

  /// Persist and apply any of the given boolean settings; `null` values are
  /// left unchanged.
  Future<void> setBoolValues({
    bool? exportGroupTimers,
    bool? exportIncludeDate,
    bool? exportIncludeProject,
    bool? exportIncludeDescription,
    bool? exportIncludeProjectDescription,
    bool? exportIncludeStartTime,
    bool? exportIncludeEndTime,
    bool? exportIncludeDurationHours,
    bool? exportIncludeNotes,
    bool? groupTimers,
    bool? collapseDays,
    bool? autocompleteDescription,
    bool? defaultFilterStartDateToMonday,
    bool? oneTimerAtATime,
    bool? showBadgeCounts,
    bool? showRunningTimersAsNotifications,
    bool? showProjectNames,
    bool? nagAboutMissingTimer,
  }) async {
    final settings = ref.read(settingsRepositoryProvider);
    Future<void> persist(String key, bool? value) async {
      if (value != null) await settings.setBool(key, value);
    }

    await persist("exportGroupTimers", exportGroupTimers);
    await persist("exportIncludeDate", exportIncludeDate);
    await persist("exportIncludeProject", exportIncludeProject);
    await persist("exportIncludeDescription", exportIncludeDescription);
    await persist(
        "exportIncludeProjectDescription", exportIncludeProjectDescription);
    await persist("exportIncludeStartTime", exportIncludeStartTime);
    await persist("exportIncludeEndTime", exportIncludeEndTime);
    await persist("exportIncludeDurationHours", exportIncludeDurationHours);
    await persist("exportIncludeNotes", exportIncludeNotes);
    await persist("groupTimers", groupTimers);
    await persist("collapseDays", collapseDays);
    await persist("autocompleteDescription", autocompleteDescription);
    await persist(
        "defaultFilterStartDateToMonday", defaultFilterStartDateToMonday);
    await persist("oneTimerAtATime", oneTimerAtATime);

    bool? hasAskedNotificationPermissions;
    if (showBadgeCounts != null) {
      await settings.setBool("showBadgeCounts", showBadgeCounts);
      if (showBadgeCounts) {
        // trigger a notification permission window
        if (Platform.isIOS || Platform.isAndroid) {
          FlutterAppBadger.removeBadge();
        }
        await settings.setBool("hasAskedNotificationPermissions", true);
        hasAskedNotificationPermissions = true;
      }
    }
    if (showRunningTimersAsNotifications != null) {
      await settings.setBool(
          "showRunningTimersAsNotifications", showRunningTimersAsNotifications);
      if (showRunningTimersAsNotifications) {
        // trigger a notification permission window
        if (Platform.isIOS || Platform.isAndroid) {
          FlutterAppBadger.removeBadge();
        }
        await settings.setBool("hasAskedNotificationPermissions", true);
        hasAskedNotificationPermissions = true;
      }
    }
    await persist("showProjectNames", showProjectNames);
    await persist("nagAboutMissingTimer", nagAboutMissingTimer);

    if (!ref.mounted) return;
    state = SettingsState.clone(
      state,
      exportGroupTimers: exportGroupTimers,
      exportIncludeDate: exportIncludeDate,
      exportIncludeProject: exportIncludeProject,
      exportIncludeDescription: exportIncludeDescription,
      exportIncludeProjectDescription: exportIncludeProjectDescription,
      exportIncludeStartTime: exportIncludeStartTime,
      exportIncludeEndTime: exportIncludeEndTime,
      exportIncludeDurationHours: exportIncludeDurationHours,
      exportIncludeNotes: exportIncludeNotes,
      groupTimers: groupTimers,
      collapseDays: collapseDays,
      autocompleteDescription: autocompleteDescription,
      defaultFilterStartDateToMonday: defaultFilterStartDateToMonday,
      oneTimerAtATime: oneTimerAtATime,
      showBadgeCounts: showBadgeCounts,
      hasAskedNotificationPermissions: hasAskedNotificationPermissions,
      showRunningTimersAsNotifications: showRunningTimersAsNotifications,
      showProjectNames: showProjectNames,
      nagAboutMissingTimer: nagAboutMissingTimer,
    );
  }

  /// Set the default dashboard filter window in days; `null` disables it.
  Future<void> setDefaultFilterDays(int? days) async {
    await ref
        .read(settingsRepositoryProvider)
        .setInt("defaultFilterDays", days ?? -1);
    if (!ref.mounted) return;
    state = SettingsState.clone(state, defaultFilterDays: days ?? -1);
  }

  /// Import all projects and timers from the database at [path], then reload
  /// the projects and timers.
  Future<void> importDatabase(String path) async {
    final DatabaseProvider importData = await DatabaseProvider.open(path);
    await ref.read(dataRepositoryProvider).import(importData);
    if (ref.mounted) {
      await Future.wait([
        ref.read(projectsProvider.notifier).load(),
        ref.read(timersProvider.notifier).load(),
      ]);
    }
    await importData.close();
  }
}
