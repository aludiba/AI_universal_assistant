import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/hot_item_model.dart';
import '../../providers/hot_provider.dart';
import '../../providers/hot_writing_provider.dart';
import '../../services/data_manager.dart';
import '../../l10n/app_localizations.dart';
import '../../router/app_router.dart';
import 'hot_writing_detail_screen.dart';

// iOS 像素级颜色常量
const Color _kInputBg = Color(0xFFF9FAFB);
const Color _kInputBorder = Color(0xFFE5E7EB);
const Color _kBlue = Color(0xFF3B82F6);
const Color _kSubtitleGray = Color(0xFF6B7280);
const Color _kLabelColor = Color(0xFF222222);
const Color _kPlaceholderGray = Color(0xFF9CA3AF);
const Color _kWordCountText = Color(0xFF444444);

/// 热门模板写作输入页面（像素级还原 iOS 模板页）
class HotWritingInputScreen extends StatefulWidget {
  final HotItemModel item;

  const HotWritingInputScreen({
    super.key,
    required this.item,
  });

  @override
  State<HotWritingInputScreen> createState() => _HotWritingInputScreenState();
}

class _HotWritingInputScreenState extends State<HotWritingInputScreen> {
  bool? _isFavorite;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFavorite());
  }

  Future<void> _loadFavorite() async {
    if (!mounted) return;
    final value = await DataManager().isFavorite(widget.item.id);
    if (mounted) setState(() => _isFavorite = value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final writingProvider = context.watch<HotWritingProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? theme.cardColor : Colors.white;
    final dividerColor = isDark ? theme.dividerColor : _kInputBorder;

    if (writingProvider.item?.id != widget.item.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        writingProvider.initWriting(widget.item);
        _loadFavorite();
      });
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.goNamed(AppRoute.hot.name);
            }
          },
        ),
        title: _buildCustomTitle(theme, isDark),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: _onRecordsTap,
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputContainer(
                      context,
                      writingProvider,
                      l10n,
                      cardColor,
                      dividerColor,
                      isDark,
                    ),
                  ],
                ),
              ),
            ),
          ),
          _buildBottomBar(
            context,
            writingProvider,
            l10n,
            cardColor,
            dividerColor,
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildCustomTitle(ThemeData theme, bool isDark) {
    final titleColor = isDark ? theme.colorScheme.onSurface : _kLabelColor;
    final subtitleColor = isDark ? theme.colorScheme.onSurfaceVariant : _kSubtitleGray;
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          widget.item.title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ).copyWith(color: titleColor),
        ),
        const SizedBox(height: 2),
        Text(
          widget.item.subtitle,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: subtitleColor,
          ),
        ),
      ],
    );
  }

  Widget _buildInputContainer(
    BuildContext context,
    HotWritingProvider provider,
    AppLocalizations l10n,
    Color cardColor,
    Color dividerColor,
    bool isDark,
  ) {
    final inputBg = isDark ? themeCardInputBg(context) : _kInputBg;
    final inputBorder = isDark ? dividerColor : _kInputBorder;
    final labelColor = isDark ? Theme.of(context).colorScheme.onSurface : _kLabelColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dividerColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 主题
          Text(l10n.theme, style: TextStyle(fontSize: 16, color: labelColor)),
          const SizedBox(height: 8),
          _buildThemeField(context, provider, l10n, inputBg, inputBorder, isDark),
          const SizedBox(height: 24),
          // 要求
          Text(l10n.require, style: TextStyle(fontSize: 16, color: labelColor)),
          const SizedBox(height: 8),
          _buildRequirementField(context, provider, l10n, inputBg, inputBorder, isDark),
          const SizedBox(height: 24),
          // 最大字数
          Text(
            l10n.maximum_word_count,
            style: TextStyle(fontSize: 16, color: labelColor),
          ),
          const SizedBox(height: 12),
          _buildWordCountButtons(context, provider, l10n, isDark),
        ],
      ),
    );
  }

  Widget _buildThemeField(
    BuildContext context,
    HotWritingProvider provider,
    AppLocalizations l10n,
    Color inputBg,
    Color inputBorder,
    bool isDark,
  ) {
    return ListenableBuilder(
      listenable: provider.themeController,
      builder: (context, _) {
        final hasText = provider.themeController.text.isNotEmpty;
        return Container(
          height: 48,
          decoration: BoxDecoration(
            color: inputBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: inputBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: provider.themeController,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? null : _kLabelColor,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.enter_creation_theme,
                    hintStyle: TextStyle(color: _kPlaceholderGray, fontSize: 16),
                    filled: true,
                    fillColor: inputBg,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                  onChanged: (_) {},
                ),
              ),
              if (hasText)
                GestureDetector(
                  onTap: () => provider.themeController.clear(),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Icon(
                      Icons.cancel,
                      size: 20,
                      color: _kPlaceholderGray,
                    ),
                  ),
                )
              else
                const SizedBox(width: 20, height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRequirementField(
    BuildContext context,
    HotWritingProvider provider,
    AppLocalizations l10n,
    Color inputBg,
    Color inputBorder,
    bool isDark,
  ) {
    return ListenableBuilder(
      listenable: provider.requirementController,
      builder: (context, _) {
        final hasText = provider.requirementController.text.isNotEmpty;
        return Container(
          height: 120,
          decoration: BoxDecoration(
            color: inputBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: inputBorder),
          ),
          child: Stack(
            children: [
              TextField(
                controller: provider.requirementController,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? null : _kLabelColor,
                ),
                maxLines: null,
                decoration: InputDecoration(
                  hintText: l10n.enter_specific_requirements,
                  hintStyle: TextStyle(color: _kPlaceholderGray, fontSize: 16),
                  filled: true,
                  fillColor: inputBg,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.fromLTRB(12, 12, 36, 12),
                ),
                onChanged: (_) {},
              ),
              if (hasText)
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () => provider.requirementController.clear(),
                    child: Icon(
                      Icons.cancel,
                      size: 20,
                      color: _kPlaceholderGray,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWordCountButtons(
    BuildContext context,
    HotWritingProvider provider,
    AppLocalizations l10n,
    bool isDark,
  ) {
    final borderColor = isDark ? Theme.of(context).dividerColor : _kInputBorder;
    final labels = [
      l10n.unlimited,
      '100${l10n.words}',
      '300${l10n.words}',
      '600${l10n.words}',
      '1000${l10n.words}',
    ];

    return SizedBox(
      height: 40,
      child: Row(
        children: List.generate(5, (i) {
          final count = HotWritingProvider.wordCountOptions[i];
          final selected = provider.selectedWordCount == count;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < 4 ? 4 : 0),
              child: SizedBox(
                height: 36,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => provider.setSelectedWordCount(count),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      decoration: BoxDecoration(
                        color: selected ? _kBlue : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: selected ? _kBlue : borderColor,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        labels[i],
                        style: TextStyle(
                          fontSize: 14,
                          color: selected ? Colors.white : (isDark ? null : _kWordCountText),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    HotWritingProvider provider,
    AppLocalizations l10n,
    Color cardColor,
    Color dividerColor,
  ) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final isFavorite = _isFavorite ?? false;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding),
      child: Row(
        children: [
          _FavoriteButton(
            isFavorite: isFavorite,
            cardColor: cardColor,
            dividerColor: dividerColor,
            onTap: () => _toggleFavorite(context, isFavorite),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _GenerateButton(
              isLoading: provider.isGenerating,
              onTap: () => _generate(context, provider),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleFavorite(BuildContext context, bool current) async {
    final dataManager = DataManager();
    final hotProvider = context.read<HotProvider>();
    if (current) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.confirmUnfavorite),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(AppLocalizations.of(context)!.thinkAgain),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(AppLocalizations.of(context)!.confirm),
            ),
          ],
        ),
      );
      if (confirm == true && context.mounted) {
        await dataManager.removeFavorite(widget.item.id);
        await hotProvider.refreshFavorites();
        if (mounted) setState(() => _isFavorite = false);
      }
    } else {
      await dataManager.addFavorite(widget.item);
      await hotProvider.refreshFavorites();
      if (mounted) setState(() => _isFavorite = true);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.favorited)),
        );
      }
    }
  }

  void _onRecordsTap() {
    // 传入当前热门条目的 id，只展示该话题下的创作记录（与 iOS 一致）
    context.pushNamed(AppRoute.writingRecords.name, extra: widget.item.id);
  }

  Future<void> _generate(BuildContext context, HotWritingProvider provider) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = provider.themeController.text.trim();
    final requirement = provider.requirementController.text.trim();

    if (theme.isEmpty) {
      _showAlert(context, l10n.prompt, l10n.enter_topic);
      return;
    }
    if (requirement.isEmpty) {
      _showAlert(context, l10n.prompt, l10n.enter_specific_requirements);
      return;
    }

    final prompt = '${l10n.theme}:$theme，${l10n.require}:$requirement';
    context.pushNamed(
      AppRoute.hotWriteDetail.name,
      extra: HotWritingDetailArgs(
        item: widget.item,
        prompt: prompt,
        wordCount: provider.selectedWordCount,
      ),
    );
  }

  void _showAlert(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.confirm),
          ),
        ],
      ),
    );
  }

  Color themeCardInputBg(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2C2C2E)
        : _kInputBg;
  }
}

class _FavoriteButton extends StatelessWidget {
  final bool isFavorite;
  final Color cardColor;
  final Color dividerColor;
  final VoidCallback onTap;

  const _FavoriteButton({
    required this.isFavorite,
    required this.cardColor,
    required this.dividerColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 60,
      child: Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: dividerColor),
            ),
            child: Icon(
              isFavorite ? Icons.star : Icons.star_border,
              color: isFavorite ? const Color(0xFFFF3333) : const Color(0xFF999999),
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

class _GenerateButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _GenerateButton({
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: 60,
      child: Material(
        color: _kBlue,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    l10n.generate,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
