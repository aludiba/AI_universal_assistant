import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../models/writing_category_model.dart';
import '../../services/data_manager.dart';
import '../../router/app_router.dart';

/// 写作类型
enum WritingType {
  free,
  continue_,
  rewrite,
  expand,
  translate;
}

/// 写作页面 - 像素级还原 iOS 项目的 AIUAWriterViewController
class WriterScreen extends StatefulWidget {
  const WriterScreen({super.key});

  @override
  State<WriterScreen> createState() => _WriterScreenState();
}

class _WriterScreenState extends State<WriterScreen> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final DataManager _dataManager = DataManager();
  
  List<WritingCategory> _categories = [];
  bool _isLoading = true;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      // 确保 DataManager 已初始化
      await _dataManager.init();
      final categories = await _dataManager.loadWritingCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading writing categories: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onTextChanged() {
    final hasText = _textController.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  void _clearText() {
    _textController.clear();
    setState(() {
      _hasText = false;
    });
  }

  void _startCreating() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    
    context.pushNamed(
      AppRoute.aiWriting.name,
      queryParameters: {
        'type': WritingType.free.name,
        'initialContent': text,
      },
    );
  }

  void _handleCategoryItemTap(WritingCategoryItem item) {
    final fullText = '${item.title}：${item.content}';
    _textController.text = fullText;
    setState(() {
      _hasText = true;
    });
    _focusNode.requestFocus();
    
    // 滚动到顶部
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark 
          ? AppColors.backgroundDark 
          : Colors.white,
      appBar: AppBar(
        title: Text(l10n.tabWriter),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            color: AppColors.getTextPrimary(context),
            onPressed: () {
              // TODO: 导航到写作记录页面
              // context.pushNamed(AppRoute.writingRecords.name);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              behavior: HitTestBehavior.translucent,
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.zero,
                itemCount: _categories.length + 2, // +1 for input cell, +1 for divider
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildInputCell(context, l10n, isDark);
                  } else if (index == 1) {
                    // 输入部分和文案模板之间的分割线
                    return Divider(
                      height: 1,
                      thickness: 0.5,
                      color: AppColors.getDivider(context),
                    );
                  } else {
                    return _buildCategorySection(context, _categories[index - 2], isDark);
                  }
                },
              ),
            ),
    );
  }

  /// 构建输入框 Cell - 像素级还原 iOS AIUAWritingInputCell
  Widget _buildInputCell(BuildContext context, AppLocalizations l10n, bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getCardBackground(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 输入框
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.backgroundDark : Colors.white,
                  border: Border.all(
                    color: AppColors.getDivider(context),
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  maxLines: 6,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.getTextPrimary(context),
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.pleaseEnter,
                    hintStyle: TextStyle(
                      color: AppColors.getTextSecondary(context),
                    ),
                    contentPadding: const EdgeInsets.fromLTRB(12, 12, 40, 12),
                    border: InputBorder.none,
                  ),
                ),
              ),
              // 清空按钮
              if (_hasText)
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: GestureDetector(
                    onTap: _clearText,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Colors.transparent,
                      ),
                      child: Icon(
                        Icons.cancel,
                        size: 22,
                        color: AppColors.getTextSecondary(context),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // 开始创作按钮
          SizedBox(
            height: 44,
            child: ElevatedButton(
              onPressed: _hasText ? _startCreating : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _hasText 
                    ? AppColors.primary 
                    : const Color(0xFFCCCCCC),
                disabledBackgroundColor: const Color(0xFFCCCCCC),
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                l10n.startCreating,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建分类 Section - 像素级还原 iOS UITableView section
  Widget _buildCategorySection(
    BuildContext context,
    WritingCategory category,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Container(
          color: isDark ? AppColors.backgroundDark : Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            category.title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextPrimary(context),
            ),
          ),
        ),
        // Category Items
        ...category.items.map((item) => _buildCategoryItem(context, item, isDark)),
      ],
    );
  }

  /// 构建分类项 Cell - 像素级还原 iOS AIUAWritingCategoryCell
  Widget _buildCategoryItem(
    BuildContext context,
    WritingCategoryItem item,
    bool isDark,
  ) {
    return InkWell(
      onTap: () => _handleCategoryItemTap(item),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.getCardBackground(context),
          border: Border(
            bottom: BorderSide(
              color: AppColors.getDivider(context),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.content,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.getTextSecondary(context),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.keyboard_arrow_up,
              size: 20,
              color: AppColors.getTextSecondary(context),
            ),
          ],
        ),
      ),
    );
  }
}
