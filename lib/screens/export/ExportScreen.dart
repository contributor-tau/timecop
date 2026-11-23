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
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timecop/components/DateRangeTile.dart';
import 'package:timecop/components/ProjectTile.dart';
import 'package:timecop/l10n.dart';
import 'package:timecop/models/project.dart';
import 'package:timecop/models/timer_entry.dart';
import 'package:timecop/screens/export/components/ExportMenu.dart';
import 'package:timecop/state/projects/projects_notifier.dart';
import 'package:timecop/state/settings/settings_notifier.dart';
import 'package:timecop/utils/export_utils.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class DayGroup {
  final DateTime date;
  List<TimerEntry> timers = [];

  DayGroup(this.date);
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  List<Project?> selectedProjects = [];

  @override
  void initState() {
    super.initState();
    final projects = ref.read(projectsProvider);
    selectedProjects = <Project?>[null]
        .followedBy(projects.projects
            .where((p) => !p.archived)
            .map((p) => Project.clone(p)))
        .toList();

    _startDate = ref.read(settingsProvider).getFilterStartDate();
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final projectsState = ref.watch(projectsProvider);

    final dateFormat = DateFormat.yMMMEd();

    return Scaffold(
      appBar: AppBar(
        title: Text(L10N.of(context).tr.exportImport),
        actions: <Widget>[
          ExportMenu(dateFormat: dateFormat),
        ],
      ),
      body: Stack(children: [
        ListView(
          children: <Widget>[
            DateRangeTile(
                startDate: _startDate,
                endDate: _endDate,
                onStartChosen: (DateTime? dt) =>
                    setState(() => _startDate = dt),
                onEndChosen: (DateTime? dt) => setState(() => _endDate = dt)),
            ExpansionTile(
              key: const Key("optionColumns"),
              title: Text(L10N.of(context).tr.columns,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700)),
              children: <Widget>[
                SwitchListTile.adaptive(
                  title: Text(L10N.of(context).tr.date),
                  value: settingsState.exportIncludeDate,
                  onChanged: (bool value) => settingsNotifier
                      .setBoolValues(exportIncludeDate: value),
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
                SwitchListTile.adaptive(
                  title: Text(L10N.of(context).tr.project),
                  value: settingsState.exportIncludeProject,
                  onChanged: (bool value) => settingsNotifier
                      .setBoolValues(exportIncludeProject: value),
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
                SwitchListTile.adaptive(
                  title: Text(L10N.of(context).tr.description),
                  value: settingsState.exportIncludeDescription,
                  onChanged: (bool value) => settingsNotifier
                      .setBoolValues(exportIncludeDescription: value),
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
                SwitchListTile.adaptive(
                  title: Text(L10N.of(context).tr.combinedProjectDescription),
                  value: settingsState.exportIncludeProjectDescription,
                  onChanged: (bool value) => settingsNotifier
                      .setBoolValues(exportIncludeProjectDescription: value),
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
                SwitchListTile.adaptive(
                  title: Text(L10N.of(context).tr.startTime),
                  value: settingsState.exportIncludeStartTime,
                  onChanged: (bool value) => settingsNotifier
                      .setBoolValues(exportIncludeStartTime: value),
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
                SwitchListTile.adaptive(
                  title: Text(L10N.of(context).tr.endTime),
                  value: settingsState.exportIncludeEndTime,
                  onChanged: (bool value) => settingsNotifier
                      .setBoolValues(exportIncludeEndTime: value),
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
                SwitchListTile.adaptive(
                  title: Text(L10N.of(context).tr.timeH),
                  value: settingsState.exportIncludeDurationHours,
                  onChanged: (bool value) => settingsNotifier
                      .setBoolValues(exportIncludeDurationHours: value),
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
                SwitchListTile.adaptive(
                  title: Text(L10N.of(context).tr.notes),
                  value: settingsState.exportIncludeNotes,
                  onChanged: (bool value) => settingsNotifier
                      .setBoolValues(exportIncludeNotes: value),
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
            ProjectTile(
              projects: projectsState.projects.where((p) => !p.archived),
              isEnabled: (project) =>
                  selectedProjects.any((p) => p?.id == project?.id),
              onToggled: (project) => setState(() {
                if (selectedProjects.any((p) => p?.id == project?.id)) {
                  selectedProjects.removeWhere((p) => p?.id == project?.id);
                } else {
                  selectedProjects.add(project);
                }
              }),
              onNoneSelected: () => setState(() {
                selectedProjects.clear();
              }),
              onAllSelected: () => selectedProjects = <Project?>[null]
                  .followedBy(projectsState.projects
                      .where((p) => !p.archived)
                      .map((p) => Project.clone(p)))
                  .toList(),
            ),
            ExpansionTile(
              title: Text(L10N.of(context).tr.options,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700)),
              children: <Widget>[
                SwitchListTile.adaptive(
                  title: Text(L10N.of(context).tr.groupTimers),
                  value: settingsState.exportGroupTimers,
                  onChanged: (bool value) => settingsNotifier.setBoolValues(
                      exportGroupTimers: value),
                  activeColor: Theme.of(context).colorScheme.primary,
                )
              ],
            ),
            const SizedBox(
              height: 128,
            )
          ],
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FloatingActionButton.extended(
                    heroTag: "csv",
                    label: Text(L10N.of(context).tr.exportCSV),
                    icon: const Icon(FontAwesomeIcons.fileCsv),
                    onPressed: () async {
                      final localizations = L10N.of(context);
                      await _export(
                          localizations: localizations,
                          stringContent: ExportUtils.toCSVString(
                              context, _startDate, _endDate, selectedProjects),
                          mimetype: "text/csv",
                          fileName:
                              "timecop_${DateTime.now().toIso8601String().split('T').first}.csv",
                          dateFormat: dateFormat);
                    }),
                FloatingActionButton.extended(
                    heroTag: "pdf",
                    label: Text(L10N.of(context).tr.exportPDF),
                    icon: const Icon(FontAwesomeIcons.solidFilePdf),
                    onPressed: () async {
                      final localizations = L10N.of(context);
                      final pdf = await ExportUtils.toPDF(context, _startDate,
                          _endDate ?? DateTime.now(), selectedProjects);
                      final pdfBytes = await pdf.save();
                      await _export(
                          localizations: localizations,
                          byteContent: pdfBytes,
                          mimetype: "application/pdf",
                          fileName:
                              "timecop_${DateTime.now().toIso8601String().split('T').first}.pdf",
                          dateFormat: dateFormat);
                    })
              ],
            ),
          ),
        )
      ]),
    );
  }

  Future<void> _export(
      {required L10N localizations,
      String? stringContent,
      Uint8List? byteContent,
      required String mimetype,
      required String fileName,
      required DateFormat dateFormat}) async {
    assert((stringContent == null) !=
        (byteContent ==
            null)); //Either stringContent or byteContent is provided, not both
    if (Platform.isMacOS || Platform.isLinux) {
      final outputFile = await FilePicker.platform.saveFile(
        dialogTitle: "",
        fileName: fileName,
      );

      if (outputFile != null) {
        if (stringContent != null) {
          await File(outputFile).writeAsString(stringContent, flush: true);
        } else {
          await File(outputFile).writeAsBytes(byteContent!);
        }
      }
    } else {
      final directory = (Platform.isAndroid)
          ? await getExternalStorageDirectory()
          : await getApplicationDocumentsDirectory();
      final localPath = '${directory!.path}/$fileName';

      if (stringContent != null) {
        await File(localPath).writeAsString(stringContent, flush: true);
      } else {
        await File(localPath).writeAsBytes(byteContent!);
      }
      await Share.shareXFiles([XFile(localPath, mimeType: mimetype)],
          subject: localizations.tr
              .timeCopEntries(dateFormat.format(DateTime.now())));
    }
  }
}
