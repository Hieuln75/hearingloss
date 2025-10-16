import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:just_audio/just_audio.dart';

class ConversationQuizPage extends StatefulWidget {
  const ConversationQuizPage({super.key});

  @override
  State<ConversationQuizPage> createState() => _ConversationQuizPageState();
}

class _ConversationQuizPageState extends State<ConversationQuizPage> {
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
      final data = await supabase.from('conversation_quiz').select();

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
        appBar: AppBar(title: const Text('Conversation Quiz')),
        body: const Center(child: Text('Không có câu hỏi nào')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Conversation Quiz')),
      body: Padding(
       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thống kê
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

            // Nút nghe audio
            ElevatedButton.icon(
              onPressed: playAudio,
              icon: const Icon(Icons.volume_up),
              label: const Text('Nghe câu hỏi'),
            ),

            const SizedBox(height: 10),

            // Thông báo đúng / sai
            if (selectedAnswer != null)
              Text(
                isCorrect == true
                    ? '✅ Chính xác!'
                    : '❌ Sai rồi! Đáp án đúng là: ${currentQuestion!['correct_answer']}',
                style: TextStyle(
                  fontSize: 16,
                  color: isCorrect == true ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),

            const SizedBox(height: 6),

            // Chỉ hiển thị câu hỏi sau khi đã chọn
            if (selectedAnswer != null)
              Center(
  child: Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: SizedBox(
      height: 40, // Thu hẹp từ 60 -> 40
      child: selectedAnswer != null
          ? Text(
              currentQuestion!['question_text'] as String,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            )
          : const SizedBox.shrink(),
    ),
  ),
),


            const SizedBox(height: 10),

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
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: selectedAnswer == null ? () => checkAnswer(opt) : null,
                  child: Text(
                    opt,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 10),

            // Nút next
            if (selectedAnswer != null)
              Center(
                child: ElevatedButton(
                  onPressed: fetchAndPickQuestion,
                  child: const Text('➡️ Câu tiếp theo'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
