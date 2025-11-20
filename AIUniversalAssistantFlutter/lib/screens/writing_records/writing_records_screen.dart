import 'package:flutter/material.dart';
import '../../services/data_service.dart';
import '../../utils/app_localizations_helper.dart';
import '../../models/writing_model.dart';
import '../../widgets/empty_widget.dart';
import '../writing_input/writing_detail_screen.dart';

class WritingRecordsScreen extends StatefulWidget {
  final bool isAllRecords;

  const WritingRecordsScreen({
    super.key,
    this.isAllRecords = false,
  });

  @override
  State<WritingRecordsScreen> createState() => _WritingRecordsScreenState();
}

class _WritingRecordsScreenState extends State<WritingRecordsScreen> {
  final DataService _dataService = DataService();
  List<WritingRecord> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isLoading) {
      _loadRecords();
    }
  }

  Future<void> _loadRecords() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final records = await _dataService.loadAllWritings();
      setState(() {
        _records = records;
        _records.sort((a, b) => b.updateTime.compareTo(a.updateTime));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showDeleteDialog(WritingRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.translate('confirm_delete')),
        content: Text(context.l10n.translate('delete_writing_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.translate('cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await _dataService.deleteWriting(record.id);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.l10n.translate('deleted_success'))),
                );
                _loadRecords();
              }
            },
            child: Text(
              context.l10n.translate('delete'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final recordDate = DateTime(date.year, date.month, date.day);

    if (recordDate == today) {
      return context.l10n.translate('today');
    } else if (recordDate == today.subtract(const Duration(days: 1))) {
      return context.l10n.translate('yesterday');
    } else {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.translate('writing_records')),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? EmptyWidget(
                  message: context.l10n.translate('no_writing_records'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _records.length,
                  itemBuilder: (context, index) {
                    final record = _records[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(
                          record.title.isEmpty
                              ? context.l10n.translate('no_title')
                              : record.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              record.content.isEmpty
                                  ? context.l10n.translate('unfinished_creation')
                                  : record.content.length > 100
                                      ? '${record.content.substring(0, 100)}...'
                                      : record.content,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(record.updateTime),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              child: Text(context.l10n.translate('delete')),
                              onTap: () => Future.delayed(
                                Duration.zero,
                                () => _showDeleteDialog(record),
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => WritingDetailScreen(
                                record: record,
                                isNew: false,
                              ),
                            ),
                          ).then((_) => _loadRecords());
                        },
                      ),
                    );
                  },
                ),
    );
  }
}

