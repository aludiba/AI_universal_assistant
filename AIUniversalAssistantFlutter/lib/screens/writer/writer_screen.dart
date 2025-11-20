import 'package:flutter/material.dart';
import '../../services/data_loader_service.dart';
import '../../utils/app_localizations_helper.dart';
import '../writing_input/writing_input_screen.dart';
import '../writing_records/writing_records_screen.dart';

class WriterScreen extends StatefulWidget {
  const WriterScreen({super.key});

  @override
  State<WriterScreen> createState() => _WriterScreenState();
}

class _WriterScreenState extends State<WriterScreen> {
  final DataLoaderService _dataLoader = DataLoaderService();
  final TextEditingController _inputController = TextEditingController();
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _inputController.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    setState(() {
      _hasText = _inputController.text.trim().isNotEmpty;
    });
  }

  Future<void> _loadData() async {
    try {
      final categories = await _dataLoader.loadWritingCategories();
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onCategoryItemTap(Map<String, dynamic> item) {
    final content = item['content'] ?? '';
    _inputController.text = content;
    // 弹出键盘
    FocusScope.of(context).requestFocus(FocusNode());
    Future.delayed(const Duration(milliseconds: 300), () {
      FocusScope.of(context).requestFocus();
    });
  }

  void _onStartCreating() {
    if (_inputController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.translate('please_enter_main_content_first'))),
      );
      return;
    }

    final template = {
      'content': _inputController.text.trim(),
      'title': '创作',
    };

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WritingInputScreen(template: template),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.tabWriter),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const WritingRecordsScreen(),
                ),
              );
            },
            tooltip: context.l10n.translate('writing_records'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 输入框区域
                Container(
                  padding: const EdgeInsets.all(16),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _inputController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: context.l10n.translate('enter_specific_requirements'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _hasText ? _onStartCreating : null,
                          child: Text(context.l10n.translate('start_creating')),
                        ),
                      ),
                    ],
                  ),
                ),
                // 分类列表
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _categories.length,
                    itemBuilder: (context, sectionIndex) {
                      final category = _categories[sectionIndex];
                      final items = category['items'] as List<dynamic>? ?? [];
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              category['title'] ?? '',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ...items.map((item) {
                            final itemMap = Map<String, dynamic>.from(item);
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(itemMap['title'] ?? ''),
                                subtitle: itemMap['content'] != null
                                    ? Text(
                                        itemMap['content'],
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      )
                                    : null,
                                onTap: () => _onCategoryItemTap(itemMap),
                              ),
                            );
                          }),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

