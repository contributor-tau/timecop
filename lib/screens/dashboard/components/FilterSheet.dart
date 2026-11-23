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
import 'package:timecop/components/DateRangeTile.dart';
import 'package:timecop/components/ProjectTile.dart';
import 'package:timecop/screens/dashboard/state/dashboard_notifier.dart';
import 'package:timecop/state/projects/projects_notifier.dart';

class FilterSheet extends ConsumerWidget {
  const FilterSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsState = ref.watch(projectsProvider);
    final state = ref.watch(dashboardProvider);
    final dashboard = ref.read(dashboardProvider.notifier);

    return ListView(
      shrinkWrap: true,
      children: <Widget>[
        DateRangeTile(
          startDate: state.filterStart,
          endDate: state.filterEnd,
          onStartChosen: (dt) {
            dashboard.setFilterStart(dt);
          },
          onEndChosen: (dt) {
            dashboard.setFilterEnd(dt);
          },
        ),
        ProjectTile(
          projects: projectsState.projects.where((p) => !p.archived),
          isEnabled: (project) =>
              !state.hiddenProjects.any((p) => p == project?.id),
          onToggled: (project) {
            List<int?> hiddenProjects =
                state.hiddenProjects.map((p) => p).toList();
            if (state.hiddenProjects.any((p) => p == project?.id)) {
              hiddenProjects.removeWhere((p) => p == project?.id);
            } else {
              hiddenProjects.add(project?.id);
            }
            dashboard.setHiddenProjects(hiddenProjects);
          },
          onNoneSelected: () => dashboard.setHiddenProjects(<int?>[null]
              .followedBy(projectsState.projects.map((p) => p.id))
              .toList()),
          onAllSelected: () => dashboard.setHiddenProjects(const <int>[]),
        ),
      ],
    );
  }
}
