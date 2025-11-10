import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'review_status.dart';

class LetterStatsPage extends StatelessWidget {
  const LetterStatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<ReviewStatus>('reviewBox');
    final all = box.values.where((e) => e.moduleType == 'letters').toList();

    final mastered = all.where((e) => e.isMastered).toList();
    final learning = all.where((e) => !e.isMastered).toList();
    final hard = all.where((e) => e.reviewCount <= 1).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Thống kê học')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            StatTile(label: '✅ Đã thuộc:', value: mastered.length),
            StatTile(label: '📚 Đang học:', value: learning.length),
            StatTile(label: '⚠️ Câu khó (sai nhiều):', value: hard.length),
            const SizedBox(height: 30),
            const Text('Chi tiết từng câu:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: all.length,
                itemBuilder: (_, i) {
                  final e = all[i];
                  return ListTile(
                    title: Text('Câu: ${e.questionId}'),
                    subtitle: Text('Lần học: ${e.reviewCount} | Trạng thái: ${e.isMastered ? "Mastered" : "Đang học"}'),
                    trailing: Text('🔁 ${e.nextReview.difference(DateTime.now()).inHours}h nữa'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  final String label;
  final int value;

  const StatTile({required this.label, required this.value, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 18)),
          const Spacer(),
          Text('$value', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
