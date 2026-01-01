// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appName => 'AI創作ネコ';

  @override
  String get tabHot => '人気';

  @override
  String get tabWriter => '作成';

  @override
  String get writerTitle => 'AIライティング';

  @override
  String get writingFreeTitle => '自由作成';

  @override
  String get writingFreeDesc => 'テーマと要件に基づいてAIが文章を作成します';

  @override
  String get writingContinueDesc => 'あなたの文章を元に続きを作成します';

  @override
  String get writingRewriteDesc => '表現を整えて文章を書き直します';

  @override
  String get writingExpandDesc => '内容を膨らませて詳細を追加します';

  @override
  String get writingTranslateDesc => '複数の言語に翻訳します';

  @override
  String get tabDocs => 'ドキュメント';

  @override
  String get tabSettings => '設定';

  @override
  String get searchPlaceholder => 'キーワードでテンプレートを検索';

  @override
  String get searchEnterKeyword => 'キーワードを入力して検索してください';

  @override
  String get startCreating => '作成を開始';

  @override
  String get pleaseEnter => '入力してください';

  @override
  String get myFollowing => 'フォロー中';

  @override
  String get recentlyUsed => '最近使用';

  @override
  String get noFavoriteContentYet => 'お気に入りはまだありません';

  @override
  String get noRecentItems => '最近使用はありません';

  @override
  String get noContent => 'コンテンツはありません';

  @override
  String get success => '成功';

  @override
  String get failure => '失敗';

  @override
  String get confirm => '確認';

  @override
  String get cancel => 'キャンセル';

  @override
  String get delete => '削除';

  @override
  String get edit => '編集';

  @override
  String get copy => 'コピー';

  @override
  String get export => 'エクスポート';

  @override
  String get generate => '生成';

  @override
  String get generatingShort => '生成中…';

  @override
  String get regenerate => '再生成';

  @override
  String get insert => '挿入';

  @override
  String get creating => '作成中…';

  @override
  String get creationFailed => '作成に失敗しました';

  @override
  String get copiedToClipboard => 'クリップボードにコピーしました';

  @override
  String get confirmUnfavorite => 'お気に入りを解除しますか？';

  @override
  String get thinkAgain => 'やめる';

  @override
  String get favorited => 'お気に入りに追加しました';

  @override
  String get hotWritingInputTitle => '内容を入力してください';

  @override
  String get hotWritingInputHint => 'テーマや要件を入力してください…';

  @override
  String get hotWritingResultTitle => '生成結果';

  @override
  String get hotWritingResultHint => '生成された内容がここに表示されます…';

  @override
  String get enterTheme => 'テーマを入力してください';

  @override
  String get enterTitle => 'タイトルを入力してください';

  @override
  String get enterMainText => '本文を入力してください';

  @override
  String get continueWriting => '続きを書く';

  @override
  String get rewrite => '書き直し';

  @override
  String get expandWriting => '拡張';

  @override
  String get translate => '翻訳';

  @override
  String get documentDetails => 'ドキュメント詳細';

  @override
  String get documentNotFound => 'ドキュメントが見つかりません';

  @override
  String get editDocument => 'ドキュメントを編集';

  @override
  String get savedSuccess => '保存しました';

  @override
  String get shareComingSoon => '共有機能は準備中です';

  @override
  String get writingRecords => '作成履歴';

  @override
  String get noWritingRecords => '作成履歴はありません';

  @override
  String get myDocuments => 'マイドキュメント';

  @override
  String get noDocuments => 'ドキュメントはありません';

  @override
  String get newDocument => '新規ドキュメント';

  @override
  String get untitledDocument => '無題のドキュメント';

  @override
  String deleteDocumentPrompt(Object title) {
    return '「$title」を削除しますか？';
  }

  @override
  String get deleteConfirm => '削除の確認';

  @override
  String get deletedSuccess => '削除しました';

  @override
  String get memberPrivileges => '会員特典';

  @override
  String get membershipAndWords => '会員と文字数';

  @override
  String get writingWordPacks => '文字数パック';

  @override
  String get appSettings => 'アプリ設定';

  @override
  String get aboutSection => '情報';

  @override
  String get thanksForSupport => 'ご支援ありがとうございます！';

  @override
  String get vipMember => 'VIP会員';

  @override
  String get normalUser => '一般ユーザー';

  @override
  String get permanentValid => '永久';

  @override
  String remainingDays(Object days) {
    return '残り$days日';
  }

  @override
  String get vipBenefitsHint => '会員登録して特典を利用';

  @override
  String get openMembership => '加入';

  @override
  String get themeMode => 'テーマ';

  @override
  String get language => '言語';

  @override
  String get selectTheme => 'テーマを選択';

  @override
  String get themeSystem => 'システム';

  @override
  String get themeLight => 'ライト';

  @override
  String get themeDark => 'ダーク';

  @override
  String get selectLanguage => '言語を選択';

  @override
  String get simplifiedChinese => '簡体中文';

  @override
  String get clearCacheConfirm => 'キャッシュを削除しますか？検索履歴と一時データが消去されます。';

  @override
  String get contactDialogContent =>
      'ご意見・ご要望はメールでご連絡ください：\\nsupport@aiwritingcat.com';

  @override
  String aboutDescription(Object appName) {
    return '$appNameはAI搭載の文章作成アシスタントです。';
  }

  @override
  String copyright(Object appName, Object year) {
    return '© $year $appName. All rights reserved.';
  }

  @override
  String get contactUs => 'お問い合わせ';

  @override
  String get aboutUs => 'このアプリについて';

  @override
  String get userAgreement => '利用規約';

  @override
  String get privacyPolicy => 'プライバシーポリシー';

  @override
  String get restoreSubscription => '購入を復元';

  @override
  String get activateMembership => '会員を有効化';

  @override
  String get insufficientWords => '文字数が不足しています';

  @override
  String get insufficientWordsDialogContent =>
      '残りの文字数が不足しています。文字数パックを購入するか、VIPを有効化してください。';

  @override
  String get purchaseWordPack => '文字数パックを購入';

  @override
  String get confirmPurchase => '購入確認';

  @override
  String wordPackPurchasePrompt(Object price, Object words) {
    return '「$words」文字を¥$priceで購入しますか？';
  }

  @override
  String purchaseSuccessGainedWords(Object words) {
    return '購入しました：$words文字を追加しました。';
  }

  @override
  String get restoreSuccessMsg => '復元しました';

  @override
  String restoreFailedMsg(Object error) {
    return '復元に失敗しました: $error';
  }

  @override
  String get purchaseSuccess => '購入成功';

  @override
  String get purchaseFailed => '購入失敗';

  @override
  String get vipUnlockRequired => 'VIPが必要です';

  @override
  String get unlockVipFeatures => 'VIPを有効化して全機能を解除';

  @override
  String get chinese => '中国語';

  @override
  String get english => '英語';

  @override
  String get japanese => '日本語';

  @override
  String get general => '一般';

  @override
  String get news => 'ニュース';

  @override
  String get academic => '学術';

  @override
  String get official => '公務';

  @override
  String get novel => '小説';

  @override
  String get essay => '作文';

  @override
  String get words => '文字';

  @override
  String get unlimited => '無制限';

  @override
  String get today => '今日';

  @override
  String get yesterday => '昨日';

  @override
  String get clearCache => 'キャッシュを削除';

  @override
  String get cacheCleared => 'キャッシュを削除しました';

  @override
  String get rateApp => '評価する';

  @override
  String get shareApp => 'アプリを共有';

  @override
  String get enterKeywordsToSearchTemplates => 'キーワードを入力してテンプレートを検索';

  @override
  String get searchHistory => '検索履歴';

  @override
  String get noRelatedTemplatesFound => '関連するテンプレートが見つかりません';

  @override
  String get goToWritingModule => '作成モジュールへ';
}
