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
import 'package:timecop/l10n.dart';
import 'package:timecop/screens/dashboard/state/dashboard_notifier.dart';
import 'package:timecop/state/projects/projects_notifier.dart';
import 'package:timecop/state/settings/settings_notifier.dart';
import 'package:timecop/state/timers/timers_notifier.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class DescriptionField extends ConsumerStatefulWidget {
  const DescriptionField({Key? key}) : super(key: key);

  @override
  ConsumerState<DescriptionField> createState() => _DescriptionFieldState();
}

class _DescriptionFieldState extends ConsumerState<DescriptionField> {
  TextEditingController? _controller;
  FocusNode? _focus;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
        text: ref.read(dashboardProvider).newDescription);
    _focus = FocusNode();
  }

  @override
  void dispose() {
    _controller!.dispose();
    _focus!.dispose();
    super.dispose();
  }

  void _startTimer(String description) {
    _focus!.unfocus();
    final dashboard = ref.read(dashboardProvider.notifier);
    dashboard.setDescription(description);
    dashboard.startTimer(
        stopRunningTimers: ref.read(settingsProvider).oneTimerAtATime);
  }

  @override
  Widget build(BuildContext context) {
    // clear the field whenever a timer gets started from the dashboard
    ref.listen<int>(dashboardProvider.select((s) => s.timersStarted),
        (previous, next) {
      _controller!.clear();
      _focus!.unfocus();
    });

    final dashboard = ref.read(dashboardProvider.notifier);
    final autocompleteDescription = ref
        .watch(settingsProvider.select((s) => s.autocompleteDescription));

    if (autocompleteDescription) {
      return TypeAheadField<String?>(
        direction: AxisDirection.up,
        textFieldConfiguration: TextFieldConfiguration(
            focusNode: _focus,
            controller: _controller,
            autocorrect: true,
            decoration:
                InputDecoration(hintText: L10N.of(context).tr.whatAreYouDoing),
            onChanged: (dynamic description) =>
                dashboard.setDescription(description as String),
            onSubmitted: (dynamic description) =>
                _startTimer(description as String)),
        itemBuilder: (BuildContext context, String? desc) =>
            ListTile(title: Text(desc!)),
        noItemsFoundBuilder: (context) => ListTile(
            title: Text(L10N.of(context).tr.noItemsFound), enabled: false),
        onSuggestionSelected: (String? description) {
          _controller!.text = description!;
          dashboard.setDescription(description);
        },
        suggestionsCallback: (pattern) async {
          if (pattern.length < 2) return [];

          final projects = ref.read(projectsProvider);
          final descriptions = ref
              .read(timersProvider)
              .timers
              .where((timer) => timer.description != null)
              .where((timer) =>
                  !(projects.getProjectByID(timer.projectID)?.archived ==
                      true))
              .where((timer) =>
                  timer.description
                      ?.toLowerCase()
                      .contains(pattern.toLowerCase()) ??
                  false)
              .map((timer) => timer.description)
              .toSet()
              .toList();
          return descriptions;
        },
      );
    } else {
      return TextField(
        key: const Key("descriptionField"),
        focusNode: _focus,
        controller: _controller,
        autocorrect: true,
        decoration: InputDecoration(
          hintText: L10N.of(context).tr.whatAreYouDoing,
        ),
        onChanged: (String description) =>
            dashboard.setDescription(description),
        onSubmitted: _startTimer,
      );
    }
  }
}
