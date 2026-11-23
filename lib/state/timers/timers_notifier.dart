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

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timecop/models/project.dart';
import 'package:timecop/models/timer_entry.dart';
import 'package:timecop/state/dependencies.dart';
import 'package:timecop/state/timers/timers_state.dart';

export 'package:timecop/state/timers/timers_state.dart';

/// All timers, sorted by start time, plus the current time (refreshed by
/// [TimersNotifier.tick]).
final timersProvider =
    NotifierProvider<TimersNotifier, TimersState>(TimersNotifier.new);

class TimersNotifier extends Notifier<TimersState> {
  @override
  TimersState build() {
    unawaited(load());
    return TimersState.initial();
  }

  /// (Re)load all timers from the database.
  Future<void> load() async {
    final timers = await ref.read(dataRepositoryProvider).listTimers();
    if (!ref.mounted) return;
    state = TimersState(timers, DateTime.now());
  }

  Future<void> createTimer({String? description, Project? project}) async {
    final TimerEntry timer = await ref
        .read(dataRepositoryProvider)
        .createTimer(description: description, projectID: project?.id);
    if (!ref.mounted) return;
    final timers = state.timers.map((t) => TimerEntry.clone(t)).toList();
    timers.add(timer);
    timers.sort((a, b) => a.startTime.compareTo(b.startTime));
    state = TimersState(timers, DateTime.now());
  }

  /// Refresh [TimersState.now] so running timers update, and nag about
  /// missing timers if enabled.
  void tick() {
    state = TimersState(state.timers, DateTime.now());
    final activeTimers = state.timers.where((t) => t.endTime == null).toList();
    final nagAboutMissingTimer =
        ref.read(settingsRepositoryProvider).getBool("nagAboutMissingTimer") ??
            true;
    if (nagAboutMissingTimer && activeTimers.isEmpty) {
      final now = DateTime.now();
      if (now.hour >= 9 &&
          now.hour < 17 &&
          now.second == 37 &&
          now.minute % 10 == 2) {
        debugPrint("Nagging about missing timer");
        ref
            .read(notificationsServiceProvider)
            .displayNoRunningTimersNotification(
              "No Running Timers Detected",
              "You don't have any timers running right now. Click here to start one.",
            );
      }
    }
  }

  Future<void> stopTimer(TimerEntry timer) async {
    final stopped = TimerEntry.clone(timer, endTime: DateTime.now());
    await ref.read(dataRepositoryProvider).editTimer(stopped);
    if (!ref.mounted) return;
    final timers = state.timers.map((t) {
      if (t.id == stopped.id) return TimerEntry.clone(stopped);
      return TimerEntry.clone(t);
    }).toList();
    timers.sort((a, b) => a.startTime.compareTo(b.startTime));
    state = TimersState(timers, DateTime.now());
  }

  Future<void> editTimer(TimerEntry timer) async {
    await ref.read(dataRepositoryProvider).editTimer(timer);
    if (!ref.mounted) return;
    final timers = state.timers.map((t) {
      if (t.id == timer.id) return TimerEntry.clone(timer);
      return TimerEntry.clone(t);
    }).toList();
    timers.sort((a, b) => a.startTime.compareTo(b.startTime));
    state = TimersState(timers, DateTime.now());
  }

  Future<void> deleteTimer(TimerEntry timer) async {
    await ref.read(dataRepositoryProvider).deleteTimer(timer);
    if (!ref.mounted) return;
    final timers = state.timers
        .where((t) => t.id != timer.id)
        .map((t) => TimerEntry.clone(t))
        .toList();
    state = TimersState(timers, DateTime.now());
  }

  Future<void> stopAllTimers() async {
    final data = ref.read(dataRepositoryProvider);
    final List<Future<TimerEntry>> timerEdits = state.timers.map((t) async {
      if (t.endTime == null) {
        final timer = TimerEntry.clone(t, endTime: DateTime.now());
        await data.editTimer(timer);
        return timer;
      }
      return TimerEntry.clone(t);
    }).toList();

    final timers = await Future.wait(timerEdits);
    if (!ref.mounted) return;
    timers.sort((a, b) => a.startTime.compareTo(b.startTime));
    state = TimersState(timers, DateTime.now());
  }
}
