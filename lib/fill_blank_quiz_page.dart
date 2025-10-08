import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:just_audio/just_audio.dart';

class FillBlankQuizPage extends StatefulWidget {
  const FillBlankQuizPage({super.key});

  @override
  State<FillBlankQuizPage> createState() => _FillBlankQuizPageState();
}

class _FillBlankQuizPageState extends State<FillBlankQuizPage> {
  final supabase = Supabase.instance.client;
  final player = AudioPlayer();

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
      final data = await supabase.from('fill_in_blank_quiz').select();

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

  Future<void> playAudio() async {
    final url = currentQuestion?['audio_url'] as String?;
    if (url != null && url.isNotEmpty) {
      try {
        await player.setUrl(url);
        await player.play();
      } catch (e) {
        print('Lỗi phát audio: $e');
      }
    }
  }

  @override
  void dispose() {
    player.dispose();
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
        appBar: AppBar(title: const Text('Quiz điền từ')),
        body: const Center(child: Text('Không có câu hỏi nào')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz điền từ')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Phần thống kê + nút reset
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

            // Thông báo đúng/sai
            if (selectedAnswer != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  isCorrect == true
                      ? '✅ Chính xác!'
                      : '❌ Sai rồi! Đáp án đúng là: ${currentQuestion!['correct_answer']}',
                  style: TextStyle(
                    fontSize: 22,
                    color: isCorrect == true ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            const SizedBox(height: 10),

            // Nút play audio
            ElevatedButton(
              onPressed: playAudio,
              child: const Text('🔊 Nghe câu hỏi'),
            ),

            const SizedBox(height: 20),

            // Hiển thị câu hỏi
            Center(
              child: Text(
                currentQuestion!['question_text'] as String,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 30),

            // Danh sách lựa chọn
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
                margin: const EdgeInsets.symmetric(vertical: 12),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: selectedAnswer == null ? () => checkAnswer(opt) : null,
                  child: Text(
                    opt,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 20),

            if (selectedAnswer != null)
              Center(
                child: ElevatedButton(
                  onPressed: fetchAndPickQuestion,
                  child: const Text('Câu tiếp theo'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
