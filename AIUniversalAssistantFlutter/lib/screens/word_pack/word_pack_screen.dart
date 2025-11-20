import 'package:flutter/material.dart';
import '../../services/word_pack_service.dart';
import '../../utils/app_localizations_helper.dart';

class WordPackScreen extends StatelessWidget {
  const WordPackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.translate('writing_word_packs')),
      ),
      body: FutureBuilder<int>(
        future: WordPackService().totalAvailableWords(),
        builder: (context, snapshot) {
          final words = snapshot.data ?? 0;
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  context.l10n.translate('total_remaining_words', [words]),
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 20),
                const Text('字数包购买页面 - 待完善'),
              ],
            ),
          );
        },
      ),
    );
  }
}

