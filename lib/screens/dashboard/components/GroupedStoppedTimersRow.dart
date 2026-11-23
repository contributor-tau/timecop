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

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timecop/models/project.dart';
import 'package:timecop/models/timer_entry.dart';
import 'package:timecop/utils/responsiveness_utils.dart';
import 'package:timecop/screens/dashboard/components/GroupedStoppedTimersRowNarrowDense.dart';
import 'package:timecop/screens/dashboard/components/GroupedStoppedTimersRowNarrowSimple.dart';
import 'package:timecop/screens/dashboard/components/GroupedStoppedTimersRowWide.dart';
import 'package:timecop/state/projects/projects_notifier.dart';
import 'package:timecop/state/settings/settings_notifier.dart';
import 'package:timecop/state/timers/timers_notifier.dart';

class GroupedStoppedTimersRow extends ConsumerWidget {
  final List<TimerEntry> timers;
  final bool isWidescreen;
  final bool showProjectName;

  const GroupedStoppedTimersRow(
      {Key? key,
      required this.timers,
      required this.isWidescreen,
      required this.showProjectName})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalDuration = Duration(
        seconds: timers.fold(
            0,
            (int sum, TimerEntry t) =>
                sum + t.endTime!.difference(t.startTime).inSeconds));
    return ResponsivenessUtils.isWidescreen(context)
        ? GroupedStoppedTimersRowWide(
            showProjectName: showProjectName,
            timers: timers,
            totalDuration: totalDuration,
            resumeTimer: _resumeTimer,
          )
        : ref.watch(settingsProvider.select((s) => s.showProjectNames))
            ? GroupedStoppedTimersRowNarrowDense(
                timers: timers,
                totalDuration: totalDuration,
                resumeTimer: _resumeTimer,
              )
            : GroupedStoppedTimersRowNarrowSimple(
                timers: timers,
                totalDuration: totalDuration,
                resumeTimer: _resumeTimer,
              );
  }

  void _resumeTimer(BuildContext context) async {
    final container = ProviderScope.containerOf(context, listen: false);
    final timersNotifier = container.read(timersProvider.notifier);
    Project? project =
        container.read(projectsProvider).getProjectByID(timers.first.projectID);
    if (container.read(settingsProvider).oneTimerAtATime) {
      await timersNotifier.stopAllTimers();
    }
    await timersNotifier.createTimer(
        description: timers.first.description ?? "", project: project);
  }
}
