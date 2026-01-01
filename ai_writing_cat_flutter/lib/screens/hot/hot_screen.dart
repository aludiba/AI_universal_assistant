import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/hot_provider.dart';
import '../../providers/app_provider.dart';
import '../../models/hot_item_model.dart';
import '../../widgets/hot_card_widget.dart';
import '../../constants/app_styles.dart';
import '../../constants/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../router/app_router.dart';

/// 热门页面 - 像素级还原iOS版本
class HotScreen extends StatefulWidget {
  const HotScreen({super.key});

  @override
  State<HotScreen> createState() => _HotScreenState();
}

class _HotScreenState extends State<HotScreen> with AutomaticKeepAliveClientMixin {
  final ScrollController _categoryScrollController = ScrollController();
  late PageController _pageController;
  bool _isPageViewChanging = false;
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }
  
  @override
  bool get wantKeepAlive => true;
  
  @override
  void dispose() {
    _categoryScrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    // 跟随系统/应用语言切换：语言变化时重新加载本地 JSON
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<HotProvider>().ensureLocale(Localizations.localeOf(context));
    });
    
    return Scaffold(
      body: Column(
        children: [
          // 导航栏
          _buildAppBar(),
          // 分类滚动条
          _buildCategoryScroll(),
          // 内容区域 - 支持左右滑动
          Expanded(
            child: _buildContentWithSwipe(),
          ),
        ],
      ),
    );
  }
  
  /// 构建导航栏（包含假搜索框）
  Widget _buildAppBar() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 16,
        right: 16,
        bottom: 8,
      ),
      color: AppColors.getBackground(context),
      child: GestureDetector(
        onTap: () {
          context.pushNamed(AppRoute.hotSearch.name);
        },
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color.fromRGBO(51, 51, 51, 1.0)
                : const Color.fromRGBO(250, 250, 250, 1.0),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Icon(
                Icons.search,
                size: 20,
                color: AppColors.getTextSecondary(context),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.searchPlaceholder,
                style: AppStyles.bodyMedium.copyWith(
                  color: AppColors.getTextSecondary(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  double _measureTextWidth(
    String text, {
    required double fontSize,
    required FontWeight fontWeight,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: fontSize, fontWeight: fontWeight),
      ),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    return textPainter.size.width;
  }

  // --------- Responsive layout helpers (iOS/Android phones/tablets) ---------
  double _clamp(double v, double min, double max) => v < min ? min : (v > max ? max : v);

  double _contentMaxWidth(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    // phone: full width; tablet: keep content readable
    return w >= 700 ? 640 : double.infinity;
  }

  EdgeInsets _pagePadding(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final h = _clamp(w * 0.04, 14, 20);
    final v = _clamp(w * 0.03, 12, 18);
    return EdgeInsets.symmetric(horizontal: h, vertical: v);
  }

  double _sectionGap(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return _clamp(w * 0.05, 18, 28);
  }

  double _titleToGridGap(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return _clamp(w * 0.03, 10, 16);
  }

  SliverGridDelegate _gridDelegateForWidth(double width) {
    final crossAxisCount = width >= 700 ? 3 : 2;
    final spacing = width >= 700 ? 18.0 : 14.0;
    // 重要：Android（如 S22）部分机型字体渲染会更“占高”，原 1.18 容易让卡片偏矮导致副标题被裁切
    // 调小 childAspectRatio => 卡片更高 => 更稳健
    final aspect = width >= 700 ? 1.25 : 1.05;
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
      childAspectRatio: aspect,
    );
  }

  ({List<String> titles, List<double> buttonLefts, List<double> buttonWidths, double contentWidth})
      _calcCategoryLayout(HotProvider provider) {
    final titles = provider.categories.map((e) => e.title).toList(growable: false);
    final buttonWidths = <double>[];
    final buttonLefts = <double>[];

    double x = 16.0; // iOS: 起始x=16
    for (final title in titles) {
      final textWidth = _measureTextWidth(
        title,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      );
      final buttonWidth = textWidth + 24; // iOS: textSize.width + 24
      buttonLefts.add(x);
      buttonWidths.add(buttonWidth);
      x += buttonWidth + 12; // iOS: 间距12
    }
    return (
      titles: titles,
      buttonLefts: buttonLefts,
      buttonWidths: buttonWidths,
      contentWidth: x,
    );
  }
  
  /// 构建分类滚动条
  Widget _buildCategoryScroll() {
    return Consumer<HotProvider>(
      builder: (context, provider, _) {
        if (provider.categories.isEmpty) {
          return const SizedBox.shrink();
        }
        
        // iOS做法：indicatorView 是 categoryScroll 的子View（会跟随内容一起滚动）
        // Flutter要达到同样效果：按钮+指示器都放到同一个可滚动内容 Stack 里
        final layout = _calcCategoryLayout(provider);
        final titles = layout.titles;
        final buttonLefts = layout.buttonLefts;
        final buttonWidths = layout.buttonWidths;
        final contentWidth = layout.contentWidth; // iOS: contentSize = x（包含最后一个+12）
        
        final selectedIndex = provider.selectedCategoryIndex.clamp(0, titles.length - 1);
        const indicatorInset = 6.0; // 指示器比按钮略窄一些（更贴近截图观感）
        final selectedLeft = buttonLefts[selectedIndex];
        final selectedWidth = buttonWidths[selectedIndex];
        final indicatorLeft = selectedLeft + indicatorInset;
        final indicatorWidth = (selectedWidth - indicatorInset * 2).clamp(0.0, selectedWidth);
        
        return Container(
          height: 44,
          color: AppColors.getBackground(context),
          child: SingleChildScrollView(
            controller: _categoryScrollController,
            scrollDirection: Axis.horizontal,
            physics: Theme.of(context).platform == TargetPlatform.iOS
                ? const BouncingScrollPhysics()
                : const ClampingScrollPhysics(),
            child: SizedBox(
              width: contentWidth,
              height: 44,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (int i = 0; i < titles.length; i++)
                    Positioned(
                      left: buttonLefts[i],
                      top: 6, // iOS: y=6
                      width: buttonWidths[i],
                      height: 32, // iOS: buttonHeight=32
                      child: _buildCategoryButton(
                        titles[i],
                        i == provider.selectedCategoryIndex,
                        () {
                          _isPageViewChanging = true;
                          provider.selectCategory(i);
                          if (_pageController.hasClients) {
                            _pageController.animateToPage(
                              i,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                          Future.delayed(const Duration(milliseconds: 350), () {
                            _isPageViewChanging = false;
                          });
                        },
                      ),
                    ),
                  
                  // 指示器：直接放在同一个 Stack 里（不能再外层包 Positioned，否则会触发 ParentData 冲突）
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    left: indicatorLeft,
                    top: 40, // iOS: y = bounds.height - 4 = 40（height=44）
                    width: indicatorWidth,
                    height: 3, // iOS: height=3
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  /// 构建分类按钮（完全模仿iOS实现）
  /// iOS: buttonHeight = 32, y = 6, 总高度44
  /// iOS: 按钮宽度用15pt字体计算（未选中状态）
  /// iOS: 直接改变字体大小，UIButton自动处理文字居中
  Widget _buildCategoryButton(String title, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontSize: isSelected ? 18 : 15, // iOS: 选中18pt，未选中15pt
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500, // iOS: 选中Semibold，未选中Medium
            color: isSelected
                ? AppColors.primary // iOS: 选中蓝色
                : Colors.grey[600], // iOS: 未选中灰色
            height: 1.0, // 固定行高，确保文字垂直居中
          ),
          textAlign: TextAlign.center,
          child: Text(title),
        ),
      ),
    );
  }
  
  /// 滚动到指定分类
  void _scrollToCategory(int index) {
    if (_categoryScrollController.hasClients && mounted) {
      final provider = context.read<HotProvider>();
      if (index < provider.categories.length) {
        // 只在「选中的按钮不在可视区域」时才滚动，避免切换时左右颤动
        final layout = _calcCategoryLayout(provider);
        final buttonLeft = layout.buttonLefts[index];
        final buttonWidth = layout.buttonWidths[index];
        final buttonRight = buttonLeft + buttonWidth;

        final position = _categoryScrollController.position;
        final viewport = position.viewportDimension;
        final current = position.pixels;
        final maxScroll = position.maxScrollExtent;
        const edgePadding = 16.0; // 与iOS scrollRectToVisible 的 16pt 边距一致

        final visibleLeft = current + edgePadding;
        final visibleRight = current + viewport - edgePadding;

        double? target;
        if (buttonLeft < visibleLeft) {
          target = (buttonLeft - edgePadding).clamp(0.0, maxScroll);
        } else if (buttonRight > visibleRight) {
          target = (buttonRight - viewport + edgePadding).clamp(0.0, maxScroll);
        }

        if (target != null && (target - current).abs() > 0.5) {
          _categoryScrollController.animateTo(
            target,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
          );
        }
      }
    }
  }
  
  /// 构建内容区域 - 支持左右滑动切换
  Widget _buildContentWithSwipe() {
    return Consumer<HotProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        
        // 同步PageView到当前选中索引（如果是从外部触发的变化）
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_isPageViewChanging && 
              _pageController.hasClients &&
              provider.selectedCategoryIndex != _pageController.page?.round()) {
            _pageController.jumpToPage(provider.selectedCategoryIndex);
          }
        });
        
        // 使用PageView实现左右滑动
        return PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            _isPageViewChanging = true;
            provider.selectCategory(index);
            _scrollToCategory(index);
            Future.delayed(const Duration(milliseconds: 100), () {
              _isPageViewChanging = false;
            });
          },
          itemCount: provider.categories.length,
          itemBuilder: (context, index) {
            final category = provider.categories[index];
            if (category.isFavoriteCategory) {
              // 收藏分类 - 两个section
              return _buildFavoriteContent(provider);
            } else {
              // 常规分类 - 一个section
              return _buildNormalContentForCategory(provider, category.id);
            }
          },
        );
      },
    );
  }
  
  
  /// 构建收藏页面内容
  Widget _buildFavoriteContent(HotProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    final padding = _pagePadding(context);
    final sectionGap = _sectionGap(context);
    final titleGap = _titleToGridGap(context);

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: _contentMaxWidth(context)),
        child: ListView(
          padding: padding,
          children: [
            // 我的关注section
            Text(
              l10n.myFollowing,
              style: AppStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: titleGap),
            provider.favoriteItems.isEmpty
                ? EmptyStateCard(message: l10n.noFavoriteContentYet)
                : LayoutBuilder(
                    builder: (context, constraints) =>
                        _buildGridView(provider.favoriteItems, false, constraints.maxWidth),
                  ),

            SizedBox(height: sectionGap),

            // 最近使用section
            Text(
              l10n.recentlyUsed,
              style: AppStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: titleGap),
            provider.recentUsedItems.isEmpty
                ? EmptyStateCard(message: l10n.noRecentItems)
                : LayoutBuilder(
                    builder: (context, constraints) =>
                        _buildGridView(provider.recentUsedItems, false, constraints.maxWidth),
                  ),
          ],
        ),
      ),
    );
  }
  
  /// 构建指定分类的内容（用于PageView）
  Widget _buildNormalContentForCategory(HotProvider provider, String categoryId) {
    final l10n = AppLocalizations.of(context)!;
    final items = provider.categories
        .firstWhere((c) => c.id == categoryId)
        .items;
    
    if (items.isEmpty) {
      return Center(
        child: Text(l10n.noContent),
      );
    }
    
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: _contentMaxWidth(context)),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final padding = _pagePadding(context);
            return GridView.builder(
              padding: padding,
              gridDelegate: _gridDelegateForWidth(constraints.maxWidth),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return _buildHotCard(items[index], true);
              },
            );
          },
        ),
      ),
    );
  }
  
  /// 构建网格视图
  Widget _buildGridView(List<HotItemModel> items, bool showFavoriteButton, double width) {
    return GridView.builder(
      primary: false,
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: _gridDelegateForWidth(width),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildHotCard(items[index], showFavoriteButton);
      },
    );
  }
  
  /// 构建热门卡片
  Widget _buildHotCard(HotItemModel item, bool showFavoriteButton) {
    return FutureBuilder<bool>(
      future: context.read<HotProvider>().isFavorite(item.id),
      builder: (context, snapshot) {
        final isFavorite = snapshot.data ?? false;
        
        return HotCardWidget(
          title: item.title,
          subtitle: item.subtitle,
          icon: _getIconData(item.icon),
          isFavorite: isFavorite,
          showFavoriteButton: showFavoriteButton,
          onTap: () => _handleItemTap(item),
          onFavoriteTap: () => _handleFavoriteTap(item, isFavorite),
        );
      },
    );
  }
  
  /// 处理卡片点击
  void _handleItemTap(HotItemModel item) {
    final appProvider = context.read<AppProvider>();
    final hotProvider = context.read<HotProvider>();
    
    // 检查VIP权限（简化版，实际应该有完整的VIP检查）
    if (!appProvider.isVip && !hotProvider.isFavoriteCategorySelected) {
      // 可以显示VIP弹窗或试用次数检查
    }
    
    // 添加到最近使用
    if (!hotProvider.isFavoriteCategorySelected) {
      hotProvider.addRecentUsed(item);
    }
    
    // 跳转到写作输入页面
    context.pushNamed(AppRoute.hotWrite.name, extra: item);
  }
  
  /// 处理收藏点击
  void _handleFavoriteTap(HotItemModel item, bool currentFavorite) async {
    final provider = context.read<HotProvider>();
    final l10n = AppLocalizations.of(context)!;
    
    if (currentFavorite) {
      // 取消收藏 - 显示确认对话框
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.confirmUnfavorite),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.thinkAgain),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.confirm),
            ),
          ],
        ),
      );
      
      if (confirmed == true) {
        await provider.toggleFavorite(item);
      }
    } else {
      // 添加收藏
      await provider.toggleFavorite(item);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.favorited),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }
  
  /// 获取图标数据
  IconData _getIconData(String iconName) {
    final iconMap = {
      'mic': Icons.mic,
      'heart': Icons.favorite,
      'edit': Icons.edit,
      'school': Icons.school,
      'article': Icons.article,
      'book': Icons.menu_book,
      'newspaper': Icons.newspaper,
      'help': Icons.help_outline,
      'people': Icons.people,
      'play_circle': Icons.play_circle_outline,
      'menu_book': Icons.menu_book,
      'description': Icons.description,
      'language': Icons.language,
      'lightbulb': Icons.lightbulb_outline,
      'calendar_today': Icons.calendar_today,
      'bar_chart': Icons.bar_chart,
      'layers': Icons.layers,
      'track_changes': Icons.track_changes,
      'email': Icons.email,
      'chat_bubble': Icons.chat_bubble_outline,
      'local_fire_department': Icons.local_fire_department,
      'campaign': Icons.campaign,
      'label': Icons.label,
      'celebration': Icons.celebration,
      'restaurant': Icons.restaurant,
      'flight': Icons.flight,
      'favorite': Icons.favorite,
      'pan_tool': Icons.pan_tool,
      'auto_awesome': Icons.auto_awesome,
    };
    
    return iconMap[iconName] ?? Icons.description;
  }
}
