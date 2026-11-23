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
import 'package:timecop/state/locale/locale_notifier.dart';

class LocaleOptions extends ConsumerWidget {
  const LocaleOptions({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    return ListTile(
      title: Text(L10N.of(context).tr.language),
      subtitle: Text(L10N.of(context).tr.automaticLanguage),
      trailing: Icon(L10N.of(context).rtl
          ? FontAwesomeIcons.chevronLeft
          : FontAwesomeIcons.chevronRight),
      leading: const Icon(FontAwesomeIcons.language),
      onTap: () async {
        final localeNotifier = ref.read(localeProvider.notifier);
        Locale? newLocale = await showModalBottomSheet<Locale>(
            context: context,
            builder: (context) => ListView(
                  shrinkWrap: true,
                  children: <Widget>[
                    RadioListTile<Locale?>(
                      title: Text(L10N.of(context).tr.automaticLanguage),
                      value: null,
                      groupValue: locale,
                      onChanged: (Locale? type) {
                        localeNotifier.setLocale(type);
                        Navigator.pop(context, type);
                      },
                    ),
                  ]
                      .followedBy([
                        const Locale('ar'),
                        const Locale('cs'),
                        const Locale('da'),
                        const Locale('de'),
                        const Locale('en'),
                        const Locale('es'),
                        const Locale('fr'),
                        const Locale('hi'),
                        const Locale('id'),
                        const Locale('it'),
                        const Locale('ja'),
                        const Locale('ko'),
                        const Locale('nb', 'NO'),
                        const Locale('pt'),
                        const Locale('ru'),
                        const Locale('tr'),
                        const Locale('zh', 'CN'),
                        const Locale('zh', 'TW'),
                      ].map(
                        (l) => RadioListTile<Locale>(
                          title: Text(L10N.of(context).tr.langName(l)),
                          value: l,
                          groupValue: locale,
                          onChanged: (Locale? type) {
                            localeNotifier.setLocale(type);
                            Navigator.pop(context, type);
                          },
                        ),
                      ))
                      .toList(),
                ));

        localeNotifier.setLocale(newLocale);
      },
    );
  }
}
