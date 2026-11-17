import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';

import 'catalogs.dart';

class AppStrings {
  AppStrings(this.values);
  final Map<String, dynamic> values;
  String text(String key) => values[key] as String? ?? key;
  static AppStrings of(BuildContext context) =>
      Localizations.of<AppStrings>(context, AppStrings)!;
  static const delegate = _StringsDelegate();
}

class _StringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _StringsDelegate();
  @override
  bool isSupported(Locale locale) => ['ru', 'en'].contains(locale.languageCode);
  @override
  Future<AppStrings> load(Locale locale) =>
      SynchronousFuture(AppStrings(catalogs[locale.languageCode]!));
  @override
  bool shouldReload(_StringsDelegate old) => false;
}

extension Translate on BuildContext {
  String t(String key) => AppStrings.of(this).text(key);
}
