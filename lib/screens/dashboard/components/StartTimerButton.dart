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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:timecop/l10n.dart';
import 'package:timecop/screens/dashboard/components/StartTimerSpeedDial.dart';
import 'package:timecop/screens/dashboard/state/dashboard_notifier.dart';
import 'package:timecop/state/settings/settings_notifier.dart';
import 'package:timecop/state/timers/timers_notifier.dart';

class StartTimerButton extends ConsumerWidget {
  const StartTimerButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final oneTimerAtATime =
        ref.watch(settingsProvider.select((s) => s.oneTimerAtATime));
    final runningTimers =
        ref.watch(timersProvider.select((s) => s.countRunningTimers()));

    if (runningTimers == 0) {
      return FloatingActionButton(
        key: const Key("startTimerButton"),
        tooltip: L10N.of(context).tr.startTimer,
        onPressed: () => ref.read(dashboardProvider.notifier).startTimer(),
        child: const Stack(
          // shenanigans to properly centre the icon (font awesome glyphs are variable
          // width but the library currently doesn't deal with that)
          fit: StackFit.expand,
          children: <Widget>[
            Positioned(
              top: 15,
              left: 18,
              child: Icon(FontAwesomeIcons.play),
            )
          ],
        ),
      );
    } else if (oneTimerAtATime && runningTimers == 1) {
      return FloatingActionButton(
        tooltip: L10N.of(context).tr.stopAllTimers,
        key: const Key("stopAllTimersButton"),
        backgroundColor: Colors.pink[600],
        foregroundColor: Colors.white,
        onPressed: () => ref.read(timersProvider.notifier).stopAllTimers(),
        child: const Stack(
          // shenanigans to properly centre the icon (font awesome glyphs are variable
          // width but the library currently doesn't deal with that)
          fit: StackFit.expand,
          children: <Widget>[
            Positioned(
              top: 15,
              left: 16,
              child: Icon(FontAwesomeIcons.stop),
            )
          ],
        ),
      );
    } else {
      return const StartTimerSpeedDial();
    }
  }
}
