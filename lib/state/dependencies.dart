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
import 'package:timecop/data_providers/data/data_provider.dart';
import 'package:timecop/data_providers/notifications/notifications_provider.dart';
import 'package:timecop/data_providers/settings/settings_provider.dart';

/// The persistent settings store.
///
/// Must be overridden in the root `ProviderScope` once the store has been
/// loaded (see `main.dart`).
final settingsRepositoryProvider = Provider<SettingsProvider>(
  (ref) => throw UnimplementedError(
      'settingsRepositoryProvider must be overridden in the ProviderScope'),
);

/// The timer / project database.
///
/// Must be overridden in the root `ProviderScope` once the database has been
/// opened (see `main.dart`).
final dataRepositoryProvider = Provider<DataProvider>(
  (ref) => throw UnimplementedError(
      'dataRepositoryProvider must be overridden in the ProviderScope'),
);

/// Local notifications service.
///
/// Must be overridden in the root `ProviderScope` once the service has been
/// initialised (see `main.dart`).
final notificationsServiceProvider = Provider<NotificationsProvider>(
  (ref) => throw UnimplementedError(
      'notificationsServiceProvider must be overridden in the ProviderScope'),
);
