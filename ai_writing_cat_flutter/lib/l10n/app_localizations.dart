import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appName.
  ///
  /// In zh, this message translates to:
  /// **'AI创作喵'**
  String get appName;

  /// No description provided for @tabHot.
  ///
  /// In zh, this message translates to:
  /// **'热门'**
  String get tabHot;

  /// No description provided for @tabWriter.
  ///
  /// In zh, this message translates to:
  /// **'写作'**
  String get tabWriter;

  /// No description provided for @tabDocs.
  ///
  /// In zh, this message translates to:
  /// **'文档'**
  String get tabDocs;

  /// No description provided for @tabSettings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get tabSettings;

  /// No description provided for @searchPlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'输入关键字搜索模版'**
  String get searchPlaceholder;

  /// No description provided for @startCreating.
  ///
  /// In zh, this message translates to:
  /// **'开始创作'**
  String get startCreating;

  /// No description provided for @pleaseEnter.
  ///
  /// In zh, this message translates to:
  /// **'请输入'**
  String get pleaseEnter;

  /// No description provided for @myFollowing.
  ///
  /// In zh, this message translates to:
  /// **'我的关注'**
  String get myFollowing;

  /// No description provided for @recentlyUsed.
  ///
  /// In zh, this message translates to:
  /// **'最近使用'**
  String get recentlyUsed;

  /// No description provided for @noFavoriteContentYet.
  ///
  /// In zh, this message translates to:
  /// **'暂无收藏内容'**
  String get noFavoriteContentYet;

  /// No description provided for @noRecentItems.
  ///
  /// In zh, this message translates to:
  /// **'暂无最近使用'**
  String get noRecentItems;

  /// No description provided for @success.
  ///
  /// In zh, this message translates to:
  /// **'成功'**
  String get success;

  /// No description provided for @failure.
  ///
  /// In zh, this message translates to:
  /// **'失败'**
  String get failure;

  /// No description provided for @confirm.
  ///
  /// In zh, this message translates to:
  /// **'确认'**
  String get confirm;

  /// No description provided for @cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In zh, this message translates to:
  /// **'编辑'**
  String get edit;

  /// No description provided for @copy.
  ///
  /// In zh, this message translates to:
  /// **'复制'**
  String get copy;

  /// No description provided for @export.
  ///
  /// In zh, this message translates to:
  /// **'导出'**
  String get export;

  /// No description provided for @generate.
  ///
  /// In zh, this message translates to:
  /// **'生成'**
  String get generate;

  /// No description provided for @regenerate.
  ///
  /// In zh, this message translates to:
  /// **'重新生成'**
  String get regenerate;

  /// No description provided for @insert.
  ///
  /// In zh, this message translates to:
  /// **'插入'**
  String get insert;

  /// No description provided for @creating.
  ///
  /// In zh, this message translates to:
  /// **'正在创作中...'**
  String get creating;

  /// No description provided for @creationFailed.
  ///
  /// In zh, this message translates to:
  /// **'创作失败'**
  String get creationFailed;

  /// No description provided for @copiedToClipboard.
  ///
  /// In zh, this message translates to:
  /// **'已复制到剪贴板'**
  String get copiedToClipboard;

  /// No description provided for @enterTheme.
  ///
  /// In zh, this message translates to:
  /// **'请输入主题'**
  String get enterTheme;

  /// No description provided for @enterTitle.
  ///
  /// In zh, this message translates to:
  /// **'请输入标题'**
  String get enterTitle;

  /// No description provided for @enterMainText.
  ///
  /// In zh, this message translates to:
  /// **'请输入正文'**
  String get enterMainText;

  /// No description provided for @continueWriting.
  ///
  /// In zh, this message translates to:
  /// **'续写'**
  String get continueWriting;

  /// No description provided for @rewrite.
  ///
  /// In zh, this message translates to:
  /// **'改写'**
  String get rewrite;

  /// No description provided for @expandWriting.
  ///
  /// In zh, this message translates to:
  /// **'扩写'**
  String get expandWriting;

  /// No description provided for @translate.
  ///
  /// In zh, this message translates to:
  /// **'翻译'**
  String get translate;

  /// No description provided for @documentDetails.
  ///
  /// In zh, this message translates to:
  /// **'文档详情'**
  String get documentDetails;

  /// No description provided for @writingRecords.
  ///
  /// In zh, this message translates to:
  /// **'创作记录'**
  String get writingRecords;

  /// No description provided for @noWritingRecords.
  ///
  /// In zh, this message translates to:
  /// **'暂无写作记录'**
  String get noWritingRecords;

  /// No description provided for @myDocuments.
  ///
  /// In zh, this message translates to:
  /// **'我的文档'**
  String get myDocuments;

  /// No description provided for @noDocuments.
  ///
  /// In zh, this message translates to:
  /// **'暂无文档'**
  String get noDocuments;

  /// No description provided for @newDocument.
  ///
  /// In zh, this message translates to:
  /// **'新建文档'**
  String get newDocument;

  /// No description provided for @deleteConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认删除'**
  String get deleteConfirm;

  /// No description provided for @deletedSuccess.
  ///
  /// In zh, this message translates to:
  /// **'删除成功'**
  String get deletedSuccess;

  /// No description provided for @memberPrivileges.
  ///
  /// In zh, this message translates to:
  /// **'会员特权'**
  String get memberPrivileges;

  /// No description provided for @writingWordPacks.
  ///
  /// In zh, this message translates to:
  /// **'创作字数包'**
  String get writingWordPacks;

  /// No description provided for @contactUs.
  ///
  /// In zh, this message translates to:
  /// **'联系客服'**
  String get contactUs;

  /// No description provided for @aboutUs.
  ///
  /// In zh, this message translates to:
  /// **'关于我们'**
  String get aboutUs;

  /// No description provided for @userAgreement.
  ///
  /// In zh, this message translates to:
  /// **'用户协议'**
  String get userAgreement;

  /// No description provided for @privacyPolicy.
  ///
  /// In zh, this message translates to:
  /// **'隐私政策'**
  String get privacyPolicy;

  /// No description provided for @restoreSubscription.
  ///
  /// In zh, this message translates to:
  /// **'恢复订阅'**
  String get restoreSubscription;

  /// No description provided for @activateMembership.
  ///
  /// In zh, this message translates to:
  /// **'开通会员'**
  String get activateMembership;

  /// No description provided for @insufficientWords.
  ///
  /// In zh, this message translates to:
  /// **'字数不足'**
  String get insufficientWords;

  /// No description provided for @purchaseWordPack.
  ///
  /// In zh, this message translates to:
  /// **'购买字数包'**
  String get purchaseWordPack;

  /// No description provided for @confirmPurchase.
  ///
  /// In zh, this message translates to:
  /// **'确认购买'**
  String get confirmPurchase;

  /// No description provided for @purchaseSuccess.
  ///
  /// In zh, this message translates to:
  /// **'购买成功'**
  String get purchaseSuccess;

  /// No description provided for @purchaseFailed.
  ///
  /// In zh, this message translates to:
  /// **'购买失败'**
  String get purchaseFailed;

  /// No description provided for @vipUnlockRequired.
  ///
  /// In zh, this message translates to:
  /// **'需要会员权限'**
  String get vipUnlockRequired;

  /// No description provided for @unlockVipFeatures.
  ///
  /// In zh, this message translates to:
  /// **'开通会员，解锁全部功能'**
  String get unlockVipFeatures;

  /// No description provided for @chinese.
  ///
  /// In zh, this message translates to:
  /// **'中文'**
  String get chinese;

  /// No description provided for @english.
  ///
  /// In zh, this message translates to:
  /// **'英文'**
  String get english;

  /// No description provided for @japanese.
  ///
  /// In zh, this message translates to:
  /// **'日文'**
  String get japanese;

  /// No description provided for @general.
  ///
  /// In zh, this message translates to:
  /// **'通用'**
  String get general;

  /// No description provided for @news.
  ///
  /// In zh, this message translates to:
  /// **'新闻'**
  String get news;

  /// No description provided for @academic.
  ///
  /// In zh, this message translates to:
  /// **'学术'**
  String get academic;

  /// No description provided for @official.
  ///
  /// In zh, this message translates to:
  /// **'公务'**
  String get official;

  /// No description provided for @novel.
  ///
  /// In zh, this message translates to:
  /// **'小说'**
  String get novel;

  /// No description provided for @essay.
  ///
  /// In zh, this message translates to:
  /// **'作文'**
  String get essay;

  /// No description provided for @words.
  ///
  /// In zh, this message translates to:
  /// **'字'**
  String get words;

  /// No description provided for @unlimited.
  ///
  /// In zh, this message translates to:
  /// **'不限'**
  String get unlimited;

  /// No description provided for @today.
  ///
  /// In zh, this message translates to:
  /// **'今天'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In zh, this message translates to:
  /// **'昨天'**
  String get yesterday;

  /// No description provided for @clearCache.
  ///
  /// In zh, this message translates to:
  /// **'清理缓存'**
  String get clearCache;

  /// No description provided for @cacheCleared.
  ///
  /// In zh, this message translates to:
  /// **'缓存清理成功'**
  String get cacheCleared;

  /// No description provided for @rateApp.
  ///
  /// In zh, this message translates to:
  /// **'前往评分'**
  String get rateApp;

  /// No description provided for @shareApp.
  ///
  /// In zh, this message translates to:
  /// **'分享APP'**
  String get shareApp;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
