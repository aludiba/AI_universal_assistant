// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'AI Writing Cat';

  @override
  String get tabHot => 'Hot';

  @override
  String get tabWriter => 'Writer';

  @override
  String get writerTitle => 'AI Writing';

  @override
  String get writingFreeTitle => 'Free writing';

  @override
  String get writingFreeDesc =>
      'Create content based on your topic and requirements';

  @override
  String get writingContinueDesc => 'Continue writing based on your text';

  @override
  String get writingRewriteDesc => 'Improve expression and rewrite your text';

  @override
  String get writingExpandDesc => 'Enrich content and add details';

  @override
  String get writingTranslateDesc => 'Translate into multiple languages';

  @override
  String get tabDocs => 'Docs';

  @override
  String get tabSettings => 'Settings';

  @override
  String get searchPlaceholder => 'Search templates';

  @override
  String get searchEnterKeyword => 'Please enter keywords to search';

  @override
  String get startCreating => 'Start Creating';

  @override
  String get pleaseEnter => 'Please enter';

  @override
  String get myFollowing => 'My Following';

  @override
  String get recentlyUsed => 'Recently Used';

  @override
  String get noFavoriteContentYet => 'No favorites yet';

  @override
  String get noRecentItems => 'No recent items';

  @override
  String get noContent => 'No content';

  @override
  String get success => 'Success';

  @override
  String get failure => 'Failure';

  @override
  String get confirm => 'Confirm';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get copy => 'Copy';

  @override
  String get export => 'Export';

  @override
  String get generate => 'Generate';

  @override
  String get generatingShort => 'Generating...';

  @override
  String get regenerate => 'Regenerate';

  @override
  String get insert => 'Insert';

  @override
  String get creating => 'Creating...';

  @override
  String get creationFailed => 'Creation failed';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get confirmUnfavorite => 'Remove from favorites?';

  @override
  String get thinkAgain => 'Think again';

  @override
  String get favorited => 'Added to favorites';

  @override
  String get hotWritingInputTitle => 'Please enter content';

  @override
  String get hotWritingInputHint => 'Enter your topic or requirements...';

  @override
  String get hotWritingResultTitle => 'Result';

  @override
  String get hotWritingResultHint => 'Generated content will appear here...';

  @override
  String get enterTheme => 'Enter theme';

  @override
  String get enterTitle => 'Enter title';

  @override
  String get enterMainText => 'Enter main text';

  @override
  String get continueWriting => 'Continue';

  @override
  String get rewrite => 'Rewrite';

  @override
  String get expandWriting => 'Expand';

  @override
  String get translate => 'Translate';

  @override
  String get documentDetails => 'Document Details';

  @override
  String get documentNotFound => 'Document not found';

  @override
  String get editDocument => 'Edit document';

  @override
  String get savedSuccess => 'Saved successfully';

  @override
  String get shareComingSoon => 'Share is coming soon';

  @override
  String get writingRecords => 'Writing Records';

  @override
  String get noWritingRecords => 'No writing records';

  @override
  String get myDocuments => 'My Documents';

  @override
  String get noDocuments => 'No documents';

  @override
  String get newDocument => 'New Document';

  @override
  String get untitledDocument => 'Untitled document';

  @override
  String deleteDocumentPrompt(Object title) {
    return 'Are you sure you want to delete \"$title\"?';
  }

  @override
  String get deleteConfirm => 'Confirm Delete';

  @override
  String get deletedSuccess => 'Deleted successfully';

  @override
  String get memberPrivileges => 'Member Privileges';

  @override
  String get membershipAndWords => 'Membership & words';

  @override
  String get writingWordPacks => 'Word Packs';

  @override
  String get appSettings => 'App settings';

  @override
  String get aboutSection => 'About';

  @override
  String get thanksForSupport => 'Thanks for your support!';

  @override
  String get vipMember => 'VIP member';

  @override
  String get normalUser => 'Standard user';

  @override
  String get permanentValid => 'Permanent';

  @override
  String remainingDays(Object days) {
    return '$days days left';
  }

  @override
  String get vipBenefitsHint => 'Activate membership to enjoy more benefits';

  @override
  String get openMembership => 'Activate';

  @override
  String get themeMode => 'Theme mode';

  @override
  String get language => 'Language';

  @override
  String get selectTheme => 'Select theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get selectLanguage => 'Select language';

  @override
  String get simplifiedChinese => 'Simplified Chinese';

  @override
  String get clearCacheConfirm =>
      'Clear cache? This will remove search history and temporary data.';

  @override
  String get contactDialogContent =>
      'For any questions or suggestions, please email:\\nsupport@aiwritingcat.com';

  @override
  String aboutDescription(Object appName) {
    return '$appName is an AI-powered writing assistant.';
  }

  @override
  String copyright(Object appName, Object year) {
    return '© $year $appName. All rights reserved.';
  }

  @override
  String get contactUs => 'Contact Us';

  @override
  String get aboutUs => 'About Us';

  @override
  String get userAgreement => 'User Agreement';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get restoreSubscription => 'Restore Subscription';

  @override
  String get activateMembership => 'Activate Membership';

  @override
  String get insufficientWords => 'Insufficient Words';

  @override
  String get insufficientWordsDialogContent =>
      'Your remaining words are not enough. Please purchase a word pack or activate VIP.';

  @override
  String get purchaseWordPack => 'Purchase Word Pack';

  @override
  String get confirmPurchase => 'Confirm Purchase';

  @override
  String wordPackPurchasePrompt(Object price, Object words) {
    return 'Buy $words words for ¥$price?';
  }

  @override
  String purchaseSuccessGainedWords(Object words) {
    return 'Purchase successful! You got $words words.';
  }

  @override
  String get restoreSuccessMsg => 'Restored successfully';

  @override
  String restoreFailedMsg(Object error) {
    return 'Restore failed: $error';
  }

  @override
  String get purchaseSuccess => 'Purchase Success';

  @override
  String get purchaseFailed => 'Purchase Failed';

  @override
  String get vipUnlockRequired => 'VIP Required';

  @override
  String get unlockVipFeatures => 'Unlock VIP Features';

  @override
  String get chinese => 'Chinese';

  @override
  String get english => 'English';

  @override
  String get japanese => 'Japanese';

  @override
  String get general => 'General';

  @override
  String get news => 'News';

  @override
  String get academic => 'Academic';

  @override
  String get official => 'Official';

  @override
  String get novel => 'Novel';

  @override
  String get essay => 'Essay';

  @override
  String get medium => 'Medium';

  @override
  String get longer => 'Longer';

  @override
  String get selectStyle => 'Select style';

  @override
  String get expansionLength => 'Expansion length';

  @override
  String get targetLanguage => 'Target language';

  @override
  String get generatedContentTitle => 'Generated content';

  @override
  String get generatedContentPlaceholder =>
      'Generated content will appear here';

  @override
  String get stopGenerating => 'Stop';

  @override
  String get overwriteOriginal => 'Overwrite original';

  @override
  String get words => 'words';

  @override
  String get unlimited => 'Unlimited';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get clearCache => 'Clear Cache';

  @override
  String get cacheCleared => 'Cache cleared';

  @override
  String get rateApp => 'Rate App';

  @override
  String get shareApp => 'Share App';

  @override
  String get enterKeywordsToSearchTemplates =>
      'Enter keywords to search templates';

  @override
  String get searchHistory => 'Search History';

  @override
  String get noRelatedTemplatesFound => 'No related templates found';

  @override
  String get goToWritingModule => 'Go to Writing Module';

  @override
  String get theme => 'Theme';

  @override
  String get require => 'Requirements';

  @override
  String get enter_creation_theme => 'Enter creation theme';

  @override
  String get enter_specific_requirements => 'Enter specific requirements';

  @override
  String get maximum_word_count => 'Max words';

  @override
  String get enter_topic => 'Enter topic';

  @override
  String get prompt => 'Prompt';

  @override
  String get creationDetails => 'Creation Details';

  @override
  String get creatingInProgress => 'Creating...';

  @override
  String get creationContent => 'Generated Content';

  @override
  String get unfinishedCreation => 'Unfinished Creation';

  @override
  String get recreate => 'Recreate';

  @override
  String get confirmRegenerateContent => 'Regenerate the current content?';

  @override
  String get format => 'Format';

  @override
  String get firstLine => 'First line should be the title';

  @override
  String get bodyBelow => 'Body should continue below on new lines';

  @override
  String insufficientWordsMessage(Object available, Object required) {
    return 'This generation needs about $required words, but only $available are available.';
  }
}
