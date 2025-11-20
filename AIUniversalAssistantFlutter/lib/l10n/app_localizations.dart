import 'package:flutter/material.dart';
import 'app_localizations_zh.dart';
import 'app_localizations_en.dart';

class AppLocalizations {
  final Locale locale;
  final Map<String, String> _strings;

  AppLocalizations(this.locale)
      : _strings = locale.languageCode == 'zh'
            ? AppLocalizationsZh.strings
            : AppLocalizationsEn.strings;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  String translate(String key, [List<dynamic>? args]) {
    String value = _strings[key] ?? key;
    if (args != null && args.isNotEmpty) {
      for (var i = 0; i < args.length; i++) {
        value = value.replaceAll('%s', args[i].toString());
        value = value.replaceAll('%d', args[i].toString());
      }
    }
    return value;
  }

  // 便捷方法
  String get tabHot => translate('tab_hot');
  String get tabWriter => translate('tab_writer');
  String get tabDocs => translate('tab_docs');
  String get tabSettings => translate('tab_settings');
  String get searchPlaceholder => translate('search_placeholder');
  String get confirm => translate('confirm');
  String get cancel => translate('cancel');
  String get delete => translate('delete');
  String get success => translate('success');
  String get failure => translate('failure');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['zh', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

