// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'AI创作喵';

  @override
  String get tabHot => '热门';

  @override
  String get tabWriter => '写作';

  @override
  String get writerTitle => 'AI写作';

  @override
  String get writingFreeTitle => '自由创作';

  @override
  String get writingFreeDesc => '根据您的主题和要求，AI帮您创作内容';

  @override
  String get writingContinueDesc => '基于您的内容，AI帮您继续写作';

  @override
  String get writingRewriteDesc => 'AI帮您优化表达，改写您的内容';

  @override
  String get writingExpandDesc => 'AI帮您丰富内容，增加细节';

  @override
  String get writingTranslateDesc => 'AI帮您翻译成多种语言';

  @override
  String get tabDocs => '文档';

  @override
  String get tabSettings => '设置';

  @override
  String get searchPlaceholder => '输入关键字搜索模板';

  @override
  String get searchEnterKeyword => '请输入关键字搜索';

  @override
  String get startCreating => '开始创作';

  @override
  String get pleaseEnter => '请输入';

  @override
  String get myFollowing => '我的关注';

  @override
  String get recentlyUsed => '最近使用';

  @override
  String get noFavoriteContentYet => '暂无收藏内容';

  @override
  String get noRecentItems => '暂无最近使用';

  @override
  String get noContent => '暂无内容';

  @override
  String get success => '成功';

  @override
  String get failure => '失败';

  @override
  String get confirm => '确认';

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String get edit => '编辑';

  @override
  String get copy => '复制';

  @override
  String get export => '导出';

  @override
  String get generate => '生成';

  @override
  String get generatingShort => '生成中...';

  @override
  String get regenerate => '重新生成';

  @override
  String get insert => '插入';

  @override
  String get creating => '正在创作中...';

  @override
  String get creationFailed => '创作失败';

  @override
  String get copiedToClipboard => '已复制到剪贴板';

  @override
  String get confirmUnfavorite => '确认取消收藏吗？';

  @override
  String get thinkAgain => '再想想';

  @override
  String get favorited => '已收藏';

  @override
  String get hotWritingInputTitle => '请输入创作内容';

  @override
  String get hotWritingInputHint => '输入您的创作主题或要求...';

  @override
  String get hotWritingResultTitle => '生成结果';

  @override
  String get hotWritingResultHint => '生成的内容将显示在这里...';

  @override
  String get enterTheme => '请输入主题';

  @override
  String get enterTitle => '请输入标题';

  @override
  String get enterMainText => '请输入正文';

  @override
  String get continueWriting => '续写';

  @override
  String get rewrite => '改写';

  @override
  String get expandWriting => '扩写';

  @override
  String get translate => '翻译';

  @override
  String get documentDetails => '文档详情';

  @override
  String get documentNotFound => '文档不存在';

  @override
  String get editDocument => '编辑文档';

  @override
  String get savedSuccess => '保存成功';

  @override
  String get shareComingSoon => '分享功能开发中';

  @override
  String get writingRecords => '创作记录';

  @override
  String get noWritingRecords => '暂无写作记录';

  @override
  String get myDocuments => '我的文档';

  @override
  String get noDocuments => '暂无文档';

  @override
  String get newDocument => '新建文档';

  @override
  String get untitledDocument => '未命名文档';

  @override
  String deleteDocumentPrompt(Object title) {
    return '确定要删除「$title」吗？';
  }

  @override
  String get deleteConfirm => '确认删除';

  @override
  String get deletedSuccess => '删除成功';

  @override
  String get memberPrivileges => '会员特权';

  @override
  String get membershipAndWords => '会员与字数';

  @override
  String get writingWordPacks => '创作字数包';

  @override
  String get appSettings => '应用设置';

  @override
  String get aboutSection => '关于';

  @override
  String get thanksForSupport => '感谢您的支持！';

  @override
  String get vipMember => 'VIP会员';

  @override
  String get normalUser => '普通用户';

  @override
  String get permanentValid => '永久有效';

  @override
  String remainingDays(Object days) {
    return '剩余$days天';
  }

  @override
  String get vipBenefitsHint => '开通会员享受更多特权';

  @override
  String get openMembership => '开通';

  @override
  String get themeMode => '主题模式';

  @override
  String get language => '语言';

  @override
  String get selectTheme => '选择主题';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get selectLanguage => '选择语言';

  @override
  String get simplifiedChinese => '简体中文';

  @override
  String get clearCacheConfirm => '确定要清理缓存吗？将清除搜索历史和临时数据。';

  @override
  String get contactDialogContent =>
      '如有任何问题或建议，请发送邮件至：\\nsupport@aiwritingcat.com';

  @override
  String aboutDescription(Object appName) {
    return '$appName是一款基于AI技术的智能写作助手。';
  }

  @override
  String copyright(Object appName, Object year) {
    return '© $year $appName 保留所有权利';
  }

  @override
  String get contactUs => '联系客服';

  @override
  String get aboutUs => '关于我们';

  @override
  String get userAgreement => '用户协议';

  @override
  String get privacyPolicy => '隐私政策';

  @override
  String get restoreSubscription => '恢复订阅';

  @override
  String get activateMembership => '开通会员';

  @override
  String get insufficientWords => '字数不足';

  @override
  String get insufficientWordsDialogContent => '您的剩余字数不足，请购买字数包或开通会员。';

  @override
  String get purchaseWordPack => '购买字数包';

  @override
  String get confirmPurchase => '确认购买';

  @override
  String wordPackPurchasePrompt(Object price, Object words) {
    return '确定要购买 $words 字数包，需支付 ¥$price？';
  }

  @override
  String purchaseSuccessGainedWords(Object words) {
    return '购买成功！已获得 $words 字';
  }

  @override
  String get restoreSuccessMsg => '恢复成功';

  @override
  String restoreFailedMsg(Object error) {
    return '恢复失败: $error';
  }

  @override
  String get purchaseSuccess => '购买成功';

  @override
  String get purchaseFailed => '购买失败';

  @override
  String get vipUnlockRequired => '需要会员权限';

  @override
  String get unlockVipFeatures => '开通会员，解锁全部功能';

  @override
  String get chinese => '中文';

  @override
  String get english => '英文';

  @override
  String get japanese => '日文';

  @override
  String get general => '通用';

  @override
  String get news => '新闻';

  @override
  String get academic => '学术';

  @override
  String get official => '公务';

  @override
  String get novel => '小说';

  @override
  String get essay => '作文';

  @override
  String get words => '字';

  @override
  String get unlimited => '不限';

  @override
  String get today => '今天';

  @override
  String get yesterday => '昨天';

  @override
  String get clearCache => '清理缓存';

  @override
  String get cacheCleared => '缓存清理成功';

  @override
  String get rateApp => '前往评分';

  @override
  String get shareApp => '分享APP';

  @override
  String get enterKeywordsToSearchTemplates => '输入关键字搜索模板';

  @override
  String get searchHistory => '搜索历史';

  @override
  String get noRelatedTemplatesFound => '未找到相关模板';

  @override
  String get goToWritingModule => '前往写作模块';
}
