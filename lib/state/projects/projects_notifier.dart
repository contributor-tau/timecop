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
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timecop/models/project.dart';
import 'package:timecop/state/dependencies.dart';
import 'package:timecop/state/projects/projects_state.dart';

export 'package:timecop/state/projects/projects_state.dart';

/// All projects, sorted by name.
final projectsProvider =
    NotifierProvider<ProjectsNotifier, ProjectsState>(ProjectsNotifier.new);

class ProjectsNotifier extends Notifier<ProjectsState> {
  @override
  ProjectsState build() {
    unawaited(load());
    return ProjectsState.initial();
  }

  /// (Re)load all projects from the database.
  Future<void> load() async {
    final projects = await ref.read(dataRepositoryProvider).listProjects();
    if (!ref.mounted) return;
    state = ProjectsState(projects);
  }

  Future<void> createProject(String name, Color colour) async {
    final Project newProject = await ref
        .read(dataRepositoryProvider)
        .createProject(name: name, colour: colour);
    if (!ref.mounted) return;
    final projects =
        state.projects.map((project) => Project.clone(project)).toList();
    projects.add(newProject);
    projects.sort((a, b) => a.name.compareTo(b.name));
    state = ProjectsState(projects);
  }

  Future<void> editProject(Project project) async {
    await ref.read(dataRepositoryProvider).editProject(project);
    if (!ref.mounted) return;
    final projects = state.projects.map((p) {
      if (p.id == project.id) return Project.clone(project);
      return Project.clone(p);
    }).toList();
    projects.sort((a, b) => a.name.compareTo(b.name));
    state = ProjectsState(projects);
  }

  Future<void> deleteProject(Project project) async {
    await ref.read(dataRepositoryProvider).deleteProject(project);
    if (!ref.mounted) return;
    final projects = state.projects
        .where((p) => p.id != project.id)
        .map((p) => Project.clone(p))
        .toList();
    state = ProjectsState(projects);
  }
}
