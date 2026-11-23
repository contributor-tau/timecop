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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timecop/models/project.dart';
import 'package:timecop/screens/dashboard/state/dashboard_state.dart';
import 'package:timecop/state/projects/projects_notifier.dart';
import 'package:timecop/state/settings/settings_notifier.dart';
import 'package:timecop/state/timers/timers_notifier.dart';

export 'package:timecop/screens/dashboard/state/dashboard_state.dart';

/// Transient state of the dashboard: the timer being composed, and the
/// filters / search applied to the timer list.
final dashboardProvider =
    NotifierProvider.autoDispose<DashboardNotifier, DashboardState>(
        DashboardNotifier.new);

class DashboardNotifier extends Notifier<DashboardState> {
  @override
  DashboardState build() {
    // if the project we had selected gets deleted or archived, deselect it
    ref.listen<ProjectsState>(projectsProvider, (_, projects) {
      final selected = state.newProject;
      if (selected == null) return;
      final project = projects.getProjectByID(selected.id);
      if (project == null || project.archived) {
        setProject(null);
      }
    });

    return DashboardState(
      "",
      null,
      0,
      ref.read(settingsProvider).getFilterStartDate(),
      null,
      const <int>[],
      null,
    );
  }

  void setDescription(String description) {
    state = DashboardState(
        description,
        state.newProject,
        state.timersStarted,
        state.filterStart,
        state.filterEnd,
        state.hiddenProjects,
        state.searchString);
  }

  void setProject(Project? project) {
    state = DashboardState(
        state.newDescription,
        project,
        state.timersStarted,
        state.filterStart,
        state.filterEnd,
        state.hiddenProjects,
        state.searchString);
  }

  /// Start a new timer with the description and project currently being
  /// composed, then reset them.
  ///
  /// If [stopRunningTimers] is true, all running timers are stopped first.
  Future<void> startTimer({bool stopRunningTimers = false}) async {
    final description = state.newDescription;
    final project = state.newProject;
    state = DashboardState(
        "",
        null,
        state.timersStarted + 1,
        state.filterStart,
        state.filterEnd,
        state.hiddenProjects,
        state.searchString);

    final timers = ref.read(timersProvider.notifier);
    if (stopRunningTimers) {
      await timers.stopAllTimers();
    }
    await timers.createTimer(description: description, project: project);
  }

  void setFilterStart(DateTime? filterStart) {
    DateTime? end = state.filterEnd;
    if (end != null && filterStart != null && filterStart.isAfter(end)) {
      end = filterStart.add(const Duration(
          hours: 23, minutes: 59, seconds: 59, milliseconds: 999));
    }

    state = DashboardState(state.newDescription, state.newProject,
        state.timersStarted, filterStart, end, state.hiddenProjects,
        state.searchString);
  }

  void setFilterEnd(DateTime? filterEnd) {
    state = DashboardState(
        state.newDescription,
        state.newProject,
        state.timersStarted,
        state.filterStart,
        filterEnd,
        state.hiddenProjects,
        state.searchString);
  }

  void setHiddenProjects(List<int?> projects) {
    state = DashboardState(
        state.newDescription,
        state.newProject,
        state.timersStarted,
        state.filterStart,
        state.filterEnd,
        projects,
        state.searchString);
  }

  /// Set the search string; `null` closes the search bar.
  void setSearch(String? search) {
    state = DashboardState(
        state.newDescription,
        state.newProject,
        state.timersStarted,
        state.filterStart,
        state.filterEnd,
        state.hiddenProjects,
        search);
  }
}
