import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:just_audio/just_audio.dart';

class LetterQuizPage extends StatefulWidget {
  const LetterQuizPage({super.key});

  @override
  State<LetterQuizPage> createState() => _LetterQuizPageState();
}

class _LetterQuizPageState extends State<LetterQuizPage> {
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
      // Lấy tất cả câu hỏi trong bảng letters_quiz
      final data = await supabase.from('letters_quiz').select();

      if (data == null || (data as List).isEmpty) {
        setState(() {
          isLoading = false;
          currentQuestion = null;
          shuffledOptions = [];
        });
        return;
      }

      List questions = List.from(data);

      // Xáo trộn danh sách câu hỏi để chọn ngẫu nhiên
      questions.shuffle();

      final randomQuestion = questions.first as Map<String, dynamic>;

      // Lấy options của câu hỏi
      List<String> options = [
        randomQuestion['option1'] as String,
        randomQuestion['option2'] as String,
        randomQuestion['option3'] as String,
        randomQuestion['option4'] as String,
      ];

      options.shuffle(); // Xáo trộn lựa chọn

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
        appBar: AppBar(title: const Text('Quiz chữ cái')),
        body: const Center(child: Text('Không có câu hỏi nào')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz chữ cái')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Bộ đếm câu đúng / tổng câu trả lời
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
            const SizedBox(height: 10),
            /*Text(
              'Chữ cái: ${currentQuestion!['question_letter']}',
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),*/
            SizedBox.shrink(),
            ElevatedButton(
              onPressed: playAudio,
              child: const Text('🔊 Nghe phát âm'),
            ),
            const SizedBox(height: 20),
            // Hiển thị các lựa chọn đã xáo trộn
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
                margin: const EdgeInsets.symmetric(vertical: 14),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: color),
                  onPressed: selectedAnswer == null ? () => checkAnswer(opt) : null,
                  child: Text(opt, style: const TextStyle(fontSize: 18)),
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
