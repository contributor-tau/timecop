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
import 'package:timecop/models/theme_type.dart';
import 'package:timecop/state/theme/theme_notifier.dart';

class ThemeOptions extends ConsumerWidget {
  const ThemeOptions({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    return ListTile(
      key: const Key("themeOption"),
      title: Text(L10N.of(context).tr.theme),
      subtitle: Text(theme?.display(context) ?? ""),
      trailing: Icon(L10N.of(context).rtl
          ? FontAwesomeIcons.chevronLeft
          : FontAwesomeIcons.chevronRight),
      leading: const Icon(FontAwesomeIcons.palette),
      onTap: () async {
        final themeNotifier = ref.read(themeProvider.notifier);
        ThemeType? oldTheme = theme;
        ThemeType? newTheme = await showModalBottomSheet<ThemeType>(
            context: context,
            builder: (context) => ListView(
                  shrinkWrap: true,
                  children: <Widget>[
                    RadioListTile<ThemeType>(
                      key: const Key("themeAuto"),
                      title: Text(L10N.of(context).tr.auto),
                      value: ThemeType.auto,
                      groupValue: theme,
                      onChanged: (ThemeType? type) =>
                          Navigator.pop(context, type),
                    ),
                    RadioListTile<ThemeType>(
                      key: const Key("themeLight"),
                      title: Text(L10N.of(context).tr.light),
                      value: ThemeType.light,
                      groupValue: theme,
                      onChanged: (ThemeType? type) =>
                          Navigator.pop(context, type),
                    ),
                    RadioListTile<ThemeType>(
                      key: const Key("themeDark"),
                      title: Text(L10N.of(context).tr.dark),
                      value: ThemeType.dark,
                      groupValue: theme,
                      onChanged: (ThemeType? type) =>
                          Navigator.pop(context, type),
                    ),
                    RadioListTile<ThemeType>(
                      key: const Key("themeBlack"),
                      title: Text(L10N.of(context).tr.black),
                      value: ThemeType.black,
                      groupValue: theme,
                      onChanged: (ThemeType? type) =>
                          Navigator.pop(context, type),
                    ),
                    RadioListTile<ThemeType>(
                      key: const Key("themeAutoMaterialYou"),
                      title: Text(L10N.of(context).tr.autoMaterialYou),
                      value: ThemeType.autoMaterialYou,
                      groupValue: theme,
                      onChanged: (ThemeType? type) =>
                          Navigator.pop(context, type),
                    ),
                    RadioListTile<ThemeType>(
                      key: const Key("themeLightMaterialYou"),
                      title: Text(L10N.of(context).tr.lightMaterialYou),
                      value: ThemeType.lightMaterialYou,
                      groupValue: theme,
                      onChanged: (ThemeType? type) =>
                          Navigator.pop(context, type),
                    ),
                    RadioListTile<ThemeType>(
                      key: const Key("themeDarkMaterialYou"),
                      title: Text(L10N.of(context).tr.darkMaterialYou),
                      value: ThemeType.darkMaterialYou,
                      groupValue: theme,
                      onChanged: (ThemeType? type) =>
                          Navigator.pop(context, type),
                    ),
                  ],
                ));

        themeNotifier.setTheme(newTheme ?? oldTheme);
      },
    );
  }
}
