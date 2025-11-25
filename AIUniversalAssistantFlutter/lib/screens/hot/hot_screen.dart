import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/data_provider.dart';
import '../../utils/app_colors.dart';

class HotScreen extends StatefulWidget {
  const HotScreen({super.key});

  @override
  State<HotScreen> createState() => _HotScreenState();
}

class _HotScreenState extends State<HotScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    await dataProvider.loadHotCategories();
    await dataProvider.loadFavorites();
    await dataProvider.loadRecentUsed();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('热门'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: 跳转到搜索页面
            },
          ),
        ],
      ),
      body: Consumer<DataProvider>(
        builder: (context, dataProvider, child) {
          if (dataProvider.hotCategories.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: dataProvider.hotCategories.length,
            itemBuilder: (context, index) {
              final category = dataProvider.hotCategories[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      category.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...category.items.map((item) => Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const Icon(
                            Icons.article,
                            color: AppColors.primary,
                          ),
                          title: Text(item.title),
                          subtitle: Text(item.subtitle),
                          trailing: IconButton(
                            icon: Icon(
                              dataProvider.isFavorite(item.uniqueId)
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: dataProvider.isFavorite(item.uniqueId)
                                  ? Colors.red
                                  : Colors.grey,
                            ),
                            onPressed: () {
                              if (dataProvider.isFavorite(item.uniqueId)) {
                                dataProvider.removeFavorite(item.uniqueId);
                              } else {
                                dataProvider.addFavorite(item.uniqueId);
                              }
                            },
                          ),
                          onTap: () {
                            dataProvider.addRecentUsed(item.uniqueId);
                            // TODO: 跳转到写作详情页面
                          },
                        ),
                      )),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

