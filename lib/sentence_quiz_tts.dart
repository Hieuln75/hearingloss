import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';

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
      // Lấy tất cả câu hỏi trong bảng sentence_quiz
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

      // Xáo trộn danh sách câu hỏi trong Flutter
      questions.shuffle();

      final randomQuestion = questions.first as Map<String, dynamic>;

      List<String> options = [
        randomQuestion['option1'] as String,
        randomQuestion['option2'] as String,
        randomQuestion['option3'] as String,
        randomQuestion['option4'] as String,
      ];

      options.shuffle(); // Xáo trộn các lựa chọn

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

  Future<void> speakText(String text) async {
    await flutterTts.setLanguage("vi-VN");  // Chọn ngôn ngữ là tiếng Việt
    await flutterTts.setPitch(1);  // Điều chỉnh tông giọng nếu cần
    await flutterTts.speak(text);  // Phát âm
  }

  @override
  void dispose() {
    flutterTts.stop(); // Dừng phát âm khi thoát trang
    super.dispose();
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
            // Bộ đếm + thông báo sai nếu cần
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
              ],
            ),
            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () {
                // Phát âm câu hỏi từ trường `correct_answer` (vì câu hỏi được lưu tại đây)
                speakText(currentQuestion?['correct_answer'] as String);
              },
              child: const Text('🔊 Nghe câu hỏi'),
            ),
            const SizedBox(height: 20),

            // Các lựa chọn
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
                margin: const EdgeInsets.symmetric(vertical: 24),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: color),
                  onPressed: selectedAnswer == null ? () => checkAnswer(opt) : null,
                  child: Text(
                    opt,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
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