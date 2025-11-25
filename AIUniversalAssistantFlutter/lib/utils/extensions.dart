import 'package:intl/intl.dart';

extension DateTimeExtension on DateTime {
  String toDateString() {
    return DateFormat('yyyy-MM-dd HH:mm').format(this);
  }

  String toRelativeDateString() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCheck = DateTime(year, month, day);

    if (dateToCheck == today) {
      return '今天';
    } else if (dateToCheck == yesterday) {
      return '昨天';
    } else {
      return DateFormat('yyyy-MM-dd').format(this);
    }
  }
}

extension IntExtension on int {
  String formatWords() {
    if (this >= 10000) {
      return '${(this / 10000).toStringAsFixed(0)}万';
    } else if (this >= 1000) {
      return '${(this / 1000).toStringAsFixed(0)}千';
    } else {
      return toString();
    }
  }

  String formatFileSize() {
    if (this <= 0) return '0 KB';
    if (this < 1024) return '$this B';
    if (this < 1024 * 1024) {
      return '${(this / 1024).toStringAsFixed(1)} KB';
    }
    return '${(this / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

extension StringExtension on String {
  int countWords() {
    return length;
  }
}

