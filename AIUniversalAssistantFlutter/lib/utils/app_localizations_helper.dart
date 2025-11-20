import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/// 本地化辅助类
extension AppLocalizationsExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

