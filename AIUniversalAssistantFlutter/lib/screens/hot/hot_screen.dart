import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/data_service.dart';
import '../../services/data_loader_service.dart';
import '../../services/vip_service.dart';
import '../../utils/app_localizations_helper.dart';
import '../../widgets/card_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_widget.dart' show EmptyWidget;
import '../search/search_screen.dart';
import '../writing_input/writing_input_screen.dart';

class HotScreen extends StatefulWidget {
  const HotScreen({super.key});

  @override
  State<HotScreen> createState() => _HotScreenState();
}

class _HotScreenState extends State<HotScreen> {
  final DataLoaderService _dataLoader = DataLoaderService();
  final DataService _dataService = DataService();
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _currentItems = [];
  int _selectedCategoryIndex = 0;
  bool _isLoading = true;
  List<Map<String, dynamic>> _favorites = [];
  List<Map<String, dynamic>> _recentUsed = [];

  StreamSubscription? _cacheSubscription;

  @override
  void initState() {
    super.initState();
    _loadData();
    _cacheSubscription = _dataService.onCacheCleared.listen((_) {
      _refreshFavorites();
    });
  }

  @override
  void dispose() {
    _cacheSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshFavorites();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final categories = await _dataLoader.loadHotCategories();
      setState(() {
        _categories = categories;
        if (categories.isNotEmpty) {
          _currentItems = _getItemsForCategory(0);
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getItemsForCategory(int index) {
    if (index >= _categories.length) return [];
    final category = _categories[index];
    if (category['isFavoriteCategory'] == true) {
      return [];
    }
    final items = category['items'] as List<dynamic>?;
    return items?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
  }

  bool _isFavoriteCategory(int index) {
    if (index >= _categories.length) return false;
    return _categories[index]['isFavoriteCategory'] == true;
  }

  void _onCategorySelected(int index) {
    setState(() {
      _selectedCategoryIndex = index;
      if (_isFavoriteCategory(index)) {
        _refreshFavorites();
      } else {
        _currentItems = _getItemsForCategory(index);
      }
    });
  }

  void _refreshFavorites() async {
    final favorites = await _dataService.getFavorites();
    final recent = await _dataService.getRecentUsed();
    setState(() {
      _favorites = favorites;
      _recentUsed = recent;
    });
  }

  Future<void> _toggleFavorite(Map<String, dynamic> item) async {
    final itemId = _getItemId(item);
    final isFavorite = await _dataService.isFavorite(itemId);
    
    if (isFavorite) {
      await _dataService.removeFavorite(itemId);
    } else {
      await _dataService.addFavorite(item);
    }
    
    _refreshFavorites();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isFavorite ? '已取消收藏' : '已收藏'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  String _getItemId(Map<String, dynamic> item) {
    return item['id'] ?? 
           '${item['categoryId']}_${item['type']}_${item['title']}';
  }

  void _onItemTap(Map<String, dynamic> item) async {
    // 检查VIP权限
    final vipService = VIPService();
    final isVIP = await vipService.isVIP();
    
    if (!isVIP) {
      // 显示VIP提示
      if (mounted) {
        _showVIPDialog();
        return;
      }
    }

    // 添加到最近使用
    await _dataService.addRecentUsed(item);
    
    // 导航到写作输入页面
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => WritingInputScreen(template: item),
        ),
      );
    }
  }

  void _showVIPDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.translate('vip_unlock_required')),
        content: Text(context.l10n.translate('vip_general_locked_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.translate('cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // 导航到会员页面
              // Navigator.of(context).push(...);
            },
            child: Text(context.l10n.translate('unlock_vip_features')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.tabHot),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SearchScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget()
          : Column(
              children: [
                // 分类选择器
                _buildCategorySelector(),
                // 内容列表
                Expanded(
                  child: _isFavoriteCategory(_selectedCategoryIndex)
                      ? _buildFavoritesView()
                      : _buildItemsList(),
                ),
              ],
            ),
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = index == _selectedCategoryIndex;
          
          return GestureDetector(
            onTap: () => _onCategorySelected(index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? Colors.blue : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
              child: Text(
                category['title'] ?? '',
                style: TextStyle(
                  fontSize: isSelected ? 18 : 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.blue : Colors.grey[600],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildItemsList() {
    if (_currentItems.isEmpty) {
      return EmptyWidget(
        message: context.l10n.translate('no_related_templates_found'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _currentItems.length,
      itemBuilder: (context, index) {
        final item = _currentItems[index];
        return FutureBuilder<bool>(
          future: _dataService.isFavorite(_getItemId(item)),
          builder: (context, snapshot) {
            final isFavorite = snapshot.data ?? false;
            return CardWidget(
              title: item['title'] ?? '',
              subtitle: item['subtitle'] ?? '',
              iconName: item['icon'] ?? '',
              showFavorite: true,
              isFavorite: isFavorite,
              onFavoriteTap: () => _toggleFavorite(item),
              onTap: () => _onItemTap(item),
            );
          },
        );
      },
    );
  }

  Widget _buildFavoritesView() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // 我的关注
        if (_favorites.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              context.l10n.translate('my_following'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ..._favorites.map((item) => CardWidget(
                title: item['title'] ?? '',
                subtitle: item['subtitle'] ?? '',
                iconName: item['icon'] ?? '',
                onTap: () => _onItemTap(item),
              )),
        ],
        // 最近使用
        if (_recentUsed.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              context.l10n.translate('recently_used'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ..._recentUsed.map((item) => CardWidget(
                title: item['title'] ?? '',
                subtitle: item['subtitle'] ?? '',
                iconName: item['icon'] ?? '',
                onTap: () => _onItemTap(item),
              )),
        ],
        // 空状态
        if (_favorites.isEmpty && _recentUsed.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: EmptyWidget(
              message: context.l10n.translate('no_favorite_content_yet'),
            ),
          ),
      ],
    );
  }
}
