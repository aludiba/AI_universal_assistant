import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
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
    Locale('ja'),
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

  /// No description provided for @writerTitle.
  ///
  /// In zh, this message translates to:
  /// **'AI写作'**
  String get writerTitle;

  /// No description provided for @writingFreeTitle.
  ///
  /// In zh, this message translates to:
  /// **'自由创作'**
  String get writingFreeTitle;

  /// No description provided for @writingFreeDesc.
  ///
  /// In zh, this message translates to:
  /// **'根据您的主题和要求，AI帮您创作内容'**
  String get writingFreeDesc;

  /// No description provided for @writingContinueDesc.
  ///
  /// In zh, this message translates to:
  /// **'基于您的内容，AI帮您继续写作'**
  String get writingContinueDesc;

  /// No description provided for @writingRewriteDesc.
  ///
  /// In zh, this message translates to:
  /// **'AI帮您优化表达，改写您的内容'**
  String get writingRewriteDesc;

  /// No description provided for @writingExpandDesc.
  ///
  /// In zh, this message translates to:
  /// **'AI帮您丰富内容，增加细节'**
  String get writingExpandDesc;

  /// No description provided for @writingTranslateDesc.
  ///
  /// In zh, this message translates to:
  /// **'AI帮您翻译成多种语言'**
  String get writingTranslateDesc;

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
  /// **'输入关键字搜索模板'**
  String get searchPlaceholder;

  /// No description provided for @searchEnterKeyword.
  ///
  /// In zh, this message translates to:
  /// **'请输入关键字搜索'**
  String get searchEnterKeyword;

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

  /// No description provided for @noContent.
  ///
  /// In zh, this message translates to:
  /// **'暂无内容'**
  String get noContent;

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

  /// No description provided for @generatingShort.
  ///
  /// In zh, this message translates to:
  /// **'生成中...'**
  String get generatingShort;

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

  /// No description provided for @confirmUnfavorite.
  ///
  /// In zh, this message translates to:
  /// **'确认取消收藏吗？'**
  String get confirmUnfavorite;

  /// No description provided for @thinkAgain.
  ///
  /// In zh, this message translates to:
  /// **'再想想'**
  String get thinkAgain;

  /// No description provided for @favorited.
  ///
  /// In zh, this message translates to:
  /// **'已收藏'**
  String get favorited;

  /// No description provided for @hotWritingInputTitle.
  ///
  /// In zh, this message translates to:
  /// **'请输入创作内容'**
  String get hotWritingInputTitle;

  /// No description provided for @hotWritingInputHint.
  ///
  /// In zh, this message translates to:
  /// **'输入您的创作主题或要求...'**
  String get hotWritingInputHint;

  /// No description provided for @hotWritingResultTitle.
  ///
  /// In zh, this message translates to:
  /// **'生成结果'**
  String get hotWritingResultTitle;

  /// No description provided for @hotWritingResultHint.
  ///
  /// In zh, this message translates to:
  /// **'生成的内容将显示在这里...'**
  String get hotWritingResultHint;

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

  /// No description provided for @documentNotFound.
  ///
  /// In zh, this message translates to:
  /// **'文档不存在'**
  String get documentNotFound;

  /// No description provided for @editDocument.
  ///
  /// In zh, this message translates to:
  /// **'编辑文档'**
  String get editDocument;

  /// No description provided for @savedSuccess.
  ///
  /// In zh, this message translates to:
  /// **'保存成功'**
  String get savedSuccess;

  /// No description provided for @shareComingSoon.
  ///
  /// In zh, this message translates to:
  /// **'分享功能开发中'**
  String get shareComingSoon;

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

  /// No description provided for @untitledDocument.
  ///
  /// In zh, this message translates to:
  /// **'未命名文档'**
  String get untitledDocument;

  /// No description provided for @deleteDocumentPrompt.
  ///
  /// In zh, this message translates to:
  /// **'确定要删除「{title}」吗？'**
  String deleteDocumentPrompt(Object title);

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

  /// No description provided for @membershipAndWords.
  ///
  /// In zh, this message translates to:
  /// **'会员与字数'**
  String get membershipAndWords;

  /// No description provided for @writingWordPacks.
  ///
  /// In zh, this message translates to:
  /// **'创作字数包'**
  String get writingWordPacks;

  /// No description provided for @appSettings.
  ///
  /// In zh, this message translates to:
  /// **'应用设置'**
  String get appSettings;

  /// No description provided for @aboutSection.
  ///
  /// In zh, this message translates to:
  /// **'关于'**
  String get aboutSection;

  /// No description provided for @thanksForSupport.
  ///
  /// In zh, this message translates to:
  /// **'感谢您的支持！'**
  String get thanksForSupport;

  /// No description provided for @vipMember.
  ///
  /// In zh, this message translates to:
  /// **'VIP会员'**
  String get vipMember;

  /// No description provided for @normalUser.
  ///
  /// In zh, this message translates to:
  /// **'普通用户'**
  String get normalUser;

  /// No description provided for @permanentValid.
  ///
  /// In zh, this message translates to:
  /// **'永久有效'**
  String get permanentValid;

  /// No description provided for @remainingDays.
  ///
  /// In zh, this message translates to:
  /// **'剩余{days}天'**
  String remainingDays(Object days);

  /// No description provided for @vipBenefitsHint.
  ///
  /// In zh, this message translates to:
  /// **'开通会员享受更多特权'**
  String get vipBenefitsHint;

  /// No description provided for @openMembership.
  ///
  /// In zh, this message translates to:
  /// **'开通'**
  String get openMembership;

  /// No description provided for @themeMode.
  ///
  /// In zh, this message translates to:
  /// **'主题模式'**
  String get themeMode;

  /// No description provided for @language.
  ///
  /// In zh, this message translates to:
  /// **'语言'**
  String get language;

  /// No description provided for @selectTheme.
  ///
  /// In zh, this message translates to:
  /// **'选择主题'**
  String get selectTheme;

  /// No description provided for @themeSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In zh, this message translates to:
  /// **'浅色'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In zh, this message translates to:
  /// **'深色'**
  String get themeDark;

  /// No description provided for @selectLanguage.
  ///
  /// In zh, this message translates to:
  /// **'选择语言'**
  String get selectLanguage;

  /// No description provided for @simplifiedChinese.
  ///
  /// In zh, this message translates to:
  /// **'简体中文'**
  String get simplifiedChinese;

  /// No description provided for @clearCacheConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定要清理缓存吗？将清除搜索历史和临时数据。'**
  String get clearCacheConfirm;

  /// No description provided for @contactDialogContent.
  ///
  /// In zh, this message translates to:
  /// **'如有任何问题或建议，请发送邮件至：\\nsupport@aiwritingcat.com'**
  String get contactDialogContent;

  /// No description provided for @aboutDescription.
  ///
  /// In zh, this message translates to:
  /// **'{appName}是一款基于AI技术的智能写作助手。'**
  String aboutDescription(Object appName);

  /// No description provided for @copyright.
  ///
  /// In zh, this message translates to:
  /// **'© {year} {appName} 保留所有权利'**
  String copyright(Object appName, Object year);

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

  /// No description provided for @insufficientWordsDialogContent.
  ///
  /// In zh, this message translates to:
  /// **'您的剩余字数不足，请购买字数包或开通会员。'**
  String get insufficientWordsDialogContent;

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

  /// No description provided for @wordPackPurchasePrompt.
  ///
  /// In zh, this message translates to:
  /// **'确定要购买 {words} 字数包，需支付 ¥{price}？'**
  String wordPackPurchasePrompt(Object price, Object words);

  /// No description provided for @purchaseSuccessGainedWords.
  ///
  /// In zh, this message translates to:
  /// **'购买成功！已获得 {words} 字'**
  String purchaseSuccessGainedWords(Object words);

  /// No description provided for @restoreSuccessMsg.
  ///
  /// In zh, this message translates to:
  /// **'恢复成功'**
  String get restoreSuccessMsg;

  /// No description provided for @restoreFailedMsg.
  ///
  /// In zh, this message translates to:
  /// **'恢复失败: {error}'**
  String restoreFailedMsg(Object error);

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

  /// No description provided for @medium.
  ///
  /// In zh, this message translates to:
  /// **'适中'**
  String get medium;

  /// No description provided for @longer.
  ///
  /// In zh, this message translates to:
  /// **'更长'**
  String get longer;

  /// No description provided for @selectStyle.
  ///
  /// In zh, this message translates to:
  /// **'选择风格'**
  String get selectStyle;

  /// No description provided for @expansionLength.
  ///
  /// In zh, this message translates to:
  /// **'扩写长度'**
  String get expansionLength;

  /// No description provided for @targetLanguage.
  ///
  /// In zh, this message translates to:
  /// **'目标语言'**
  String get targetLanguage;

  /// No description provided for @generatedContentTitle.
  ///
  /// In zh, this message translates to:
  /// **'生成内容'**
  String get generatedContentTitle;

  /// No description provided for @generatedContentPlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'生成结果会显示在这里'**
  String get generatedContentPlaceholder;

  /// No description provided for @stopGenerating.
  ///
  /// In zh, this message translates to:
  /// **'停止'**
  String get stopGenerating;

  /// No description provided for @overwriteOriginal.
  ///
  /// In zh, this message translates to:
  /// **'覆盖原文'**
  String get overwriteOriginal;

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

  /// No description provided for @enterKeywordsToSearchTemplates.
  ///
  /// In zh, this message translates to:
  /// **'输入关键字搜索模板'**
  String get enterKeywordsToSearchTemplates;

  /// No description provided for @searchHistory.
  ///
  /// In zh, this message translates to:
  /// **'搜索历史'**
  String get searchHistory;

  /// No description provided for @noRelatedTemplatesFound.
  ///
  /// In zh, this message translates to:
  /// **'未找到相关模板'**
  String get noRelatedTemplatesFound;

  /// No description provided for @goToWritingModule.
  ///
  /// In zh, this message translates to:
  /// **'前往写作模块'**
  String get goToWritingModule;

  /// No description provided for @theme.
  ///
  /// In zh, this message translates to:
  /// **'主题'**
  String get theme;

  /// No description provided for @require.
  ///
  /// In zh, this message translates to:
  /// **'要求'**
  String get require;

  /// No description provided for @enter_creation_theme.
  ///
  /// In zh, this message translates to:
  /// **'请输入创作主题'**
  String get enter_creation_theme;

  /// No description provided for @enter_specific_requirements.
  ///
  /// In zh, this message translates to:
  /// **'请输入具体要求'**
  String get enter_specific_requirements;

  /// No description provided for @maximum_word_count.
  ///
  /// In zh, this message translates to:
  /// **'最大字数'**
  String get maximum_word_count;

  /// No description provided for @enter_topic.
  ///
  /// In zh, this message translates to:
  /// **'请输入主题'**
  String get enter_topic;

  /// No description provided for @prompt.
  ///
  /// In zh, this message translates to:
  /// **'提示'**
  String get prompt;

  /// No description provided for @creationDetails.
  ///
  /// In zh, this message translates to:
  /// **'创作详情'**
  String get creationDetails;

  /// No description provided for @creatingInProgress.
  ///
  /// In zh, this message translates to:
  /// **'正在创作中...'**
  String get creatingInProgress;

  /// No description provided for @creationContent.
  ///
  /// In zh, this message translates to:
  /// **'创作内容'**
  String get creationContent;

  /// No description provided for @unfinishedCreation.
  ///
  /// In zh, this message translates to:
  /// **'未完成创作'**
  String get unfinishedCreation;

  /// No description provided for @recreate.
  ///
  /// In zh, this message translates to:
  /// **'重新创作'**
  String get recreate;

  /// No description provided for @confirmRegenerateContent.
  ///
  /// In zh, this message translates to:
  /// **'确认重新生成当前内容吗？'**
  String get confirmRegenerateContent;

  /// No description provided for @format.
  ///
  /// In zh, this message translates to:
  /// **'格式'**
  String get format;

  /// No description provided for @firstLine.
  ///
  /// In zh, this message translates to:
  /// **'第一行为标题'**
  String get firstLine;

  /// No description provided for @bodyBelow.
  ///
  /// In zh, this message translates to:
  /// **'正文在下方换行展示'**
  String get bodyBelow;

  /// No description provided for @insufficientWordsMessage.
  ///
  /// In zh, this message translates to:
  /// **'本次预计消耗 {required} 字，当前仅剩 {available} 字。'**
  String insufficientWordsMessage(Object available, Object required);

  /// No description provided for @app_version.
  ///
  /// In zh, this message translates to:
  /// **'版本 {version}'**
  String app_version(Object version);

  /// No description provided for @app_intro_title.
  ///
  /// In zh, this message translates to:
  /// **'应用简介'**
  String get app_intro_title;

  /// No description provided for @app_intro_content.
  ///
  /// In zh, this message translates to:
  /// **'AI创作喵是一款基于AI技术的智能写作助手，为您提供续写、改写、扩写、翻译等多种写作功能，帮助您提升写作效率和质量。'**
  String get app_intro_content;

  /// No description provided for @main_features_title.
  ///
  /// In zh, this message translates to:
  /// **'主要功能'**
  String get main_features_title;

  /// No description provided for @main_features_content.
  ///
  /// In zh, this message translates to:
  /// **'• AI辅助写作\n• 智能续写改写\n• 多语言翻译\n• 文档管理\n• 创作记录'**
  String get main_features_content;

  /// No description provided for @copyright_text.
  ///
  /// In zh, this message translates to:
  /// **'© 2026 AI创作喵\n保留所有权利'**
  String get copyright_text;
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
      <String>['en', 'ja', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
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
