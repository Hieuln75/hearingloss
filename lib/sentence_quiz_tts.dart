import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:html' as html; // Dùng Web Speech API trên Web

class SentenceTTSQuizPage extends StatefulWidget {
  const SentenceTTSQuizPage({super.key});

  @override
  State<SentenceTTSQuizPage> createState() => _SentenceTTSQuizPageState();
}

class _SentenceTTSQuizPageState extends State<SentenceTTSQuizPage> {
  final supabase = Supabase.instance.client;
  final FlutterTts flutterTts = FlutterTts();

  Map<String, dynamic>? currentQuestion;
  List<String> shuffledOptions = [];
  bool isLoading = true;
  String? selectedAnswer;
  bool? isCorrect;

  int correctAnswered = 0;
  int totalAnswered = 0;

  @override
  void initState() {
    super.initState();
    fetchAndPickQuestion();
  }

  Future<void> fetchAndPickQuestion() async {
    setState(() {
      isLoading = true;
    });

    try {
      final data = await supabase.from('sentence_quiz').select();

      if (data == null || (data as List).isEmpty) {
        setState(() {
          isLoading = false;
          currentQuestion = null;
          shuffledOptions = [];
        });
        return;
      }

      List questions = List.from(data);
      questions.shuffle();

      final randomQuestion = questions.first as Map<String, dynamic>;

      List<String> options = [
        randomQuestion['option1'] as String,
        randomQuestion['option2'] as String,
        randomQuestion['option3'] as String,
        randomQuestion['option4'] as String,
      ];

      options.shuffle();

      setState(() {
        currentQuestion = randomQuestion;
        shuffledOptions = options;
        selectedAnswer = null;
        isCorrect = null;
        isLoading = false;
      });
    } catch (e) {
      print('Lỗi lấy câu hỏi: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void checkAnswer(String answer) {
    final correct = currentQuestion?['correct_answer'] as String?;
    if (correct == null) return;

    setState(() {
      selectedAnswer = answer;
      isCorrect = answer == correct;
      totalAnswered++;
      if (isCorrect == true) {
        correctAnswered++;
      }
    });
  }

  /// ✅ Hàm phát âm có xử lý null-safety & tương thích Edge/Safari/iPhone
  Future<void> speakText(String text) async {
    try {
      // 1️⃣ Unlock âm thanh cho Safari/iOS
      try {
        final unlock = html.AudioElement()
          ..src =
              'data:audio/wav;base64,UklGRiQAAABXQVZFZm10IBAAAAABAAEAESsAACJWAAACABAAZGF0YQAAAAA='
          ..autoplay = true;
        html.document.body?.append(unlock);
        await unlock.play();
      } catch (_) {}

      // 2️⃣ Kiểm tra xem Web Speech API có khả dụng không
      final synth = html.window.speechSynthesis;
      if (synth != null) {
        final utterance = html.SpeechSynthesisUtterance(text);
        utterance.lang = 'vi-VN';

        // Lấy danh sách voice (nếu có)
        final voices = synth.getVoices();
        if (voices.isNotEmpty) {
          final vietnamVoice = voices.firstWhere(
            (v) => (v.lang ?? '').startsWith('vi'),
            orElse: () => voices.first,
          );
          utterance.voice = vietnamVoice;
        }

        synth.cancel(); // Dừng nếu đang phát
        synth.speak(utterance);
        return;
      }

      // 3️⃣ Nếu không phải web hoặc không hỗ trợ API → fallback flutter_tts
      await flutterTts.setLanguage("vi-VN");
      await flutterTts.setPitch(1.0);
      await flutterTts.speak(text);
    } catch (e) {
      print('Lỗi phát âm: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (currentQuestion == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz câu')),
        body: const Center(child: Text('Không có câu hỏi nào')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz câu')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Đúng: $correctAnswered / Tổng: $totalAnswered',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      correctAnswered = 0;
                      totalAnswered = 0;
                    });
                  },
                  child: const Text('🔄 Reset', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),

            if (selectedAnswer != null && isCorrect == false)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '❌ Sai rồi! Đáp án đúng là: ${currentQuestion?['correct_answer']}',
                  style: const TextStyle(
                    fontSize: 22,
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () {
                speakText(currentQuestion?['correct_answer'] as String);
              },
              child: const Text('🔊 Nghe câu hỏi'),
            ),
            const SizedBox(height: 20),

            ...shuffledOptions.map((opt) {
              final isSelected = selectedAnswer == opt;
              final correctAnswer = currentQuestion!['correct_answer'] as String;
              final color = selectedAnswer == null
                  ? Colors.blue
                  : opt == correctAnswer
                      ? Colors.green
                      : isSelected
                          ? Colors.red
                          : Colors.grey;

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(vertical: 16),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: color),
                  onPressed: selectedAnswer == null ? () => checkAnswer(opt) : null,
                  child: Text(
                    opt,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            }),

            const SizedBox(height: 20),
            if (selectedAnswer != null)
              ElevatedButton(
                onPressed: fetchAndPickQuestion,
                child: const Text('Câu tiếp theo'),
              ),
          ],
        ),
      ),
    );
  }
}
