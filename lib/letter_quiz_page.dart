
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'review_service.dart';
import 'review_status.dart'; // 👈 Import file model
import 'package:hive/hive.dart';
import 'letter_stats_page.dart'; 

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
/*
  Future<void> fetchAndPickQuestion() async {
    setState(() {
      isLoading = true;
    });

    try {
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
*/
Future<void> fetchAndPickQuestion() async {
  setState(() {
    isLoading = true;
  });

  try {
    // 🔄 Lấy danh sách câu hỏi từ Supabase
    final data = await supabase.from('letters_quiz').select();

    if (data == null || data.isEmpty) {
      setState(() {
        isLoading = false;
        currentQuestion = null;
        shuffledOptions = [];
      });
      return;
    }

    List<Map<String, dynamic>> questions = List<Map<String, dynamic>>.from(data);

    // 🔍 Lọc ra những câu tới hạn ôn lại theo SRS
    final now = DateTime.now();
    final box = Hive.box<ReviewStatus>('reviewBox');

    List<Map<String, dynamic>> filteredQuestions = questions.where((q) {
      final id = q['id'].toString();
      final review = box.get(id);

      if (review == null) return true; // Câu mới chưa học bao giờ => cho làm
      if (review.isMastered) return false; // Câu đã mastered => bỏ qua

      return now.isAfter(review.nextReview); // Chỉ chọn câu đến hạn ôn lại
    }).toList();

    // Nếu không còn câu tới hạn ôn, fallback chọn random từ toàn bộ
    if (filteredQuestions.isEmpty) {
      filteredQuestions = questions;
    }

    filteredQuestions.shuffle();
    final randomQuestion = filteredQuestions.first;

    // 🔄 Xáo trộn đáp án
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
    print('Lỗi fetchAndPickQuestion: $e');
    setState(() {
      isLoading = false;
    });
  }
}


void checkAnswer(String answer) async {
  final correct = currentQuestion?['correct_answer'] as String?;
  if (correct == null) return;

  final questionId = currentQuestion!['id'].toString();
  final box = Hive.box<ReviewStatus>('reviewBox');
  final now = DateTime.now();

  // Lấy trạng thái cũ từ Hive
  final oldReview = box.get(questionId);

  int reviewCount = oldReview?.reviewCount ?? 0;
  bool isMastered = oldReview?.isMastered ?? false;
  DateTime nextReview;

  if (answer == correct) {
    // ✅ Trả lời đúng ➜ tăng cấp độ ôn
    reviewCount++;
    int daysToAdd;

    if (reviewCount == 1) {
      daysToAdd = 1;
    } else if (reviewCount == 2) {
      daysToAdd = 2;
    } else if (reviewCount == 3) {
      daysToAdd = 5;
    } else {
      daysToAdd = 10;
    }

    nextReview = now.add(Duration(days: daysToAdd));

    if (reviewCount >= 4) {
      isMastered = true;
    }
  } else {
    // ❌ Trả lời sai ➜ reset lại SRS
    reviewCount = 0;
    nextReview = now.add(const Duration(days: 1));
    isMastered = false;
  }

  // Tạo hoặc cập nhật trạng thái mới
  final newStatus = ReviewStatus(
    questionId: questionId,
    lastReviewed: now,
    nextReview: nextReview,
    reviewCount: reviewCount,
    isMastered: isMastered,
    moduleType: 'letters',
  );

  await box.put(questionId, newStatus); // Ghi vào Hive

  // Cập nhật UI
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
        //appBar: AppBar(title: const Text('Quiz chữ cái')),
        appBar: AppBar(
  title: const Text('Quiz chữ cái'),
 actions: [
  Padding(
    padding: const EdgeInsets.only(right: 12.0), // 👈 Khoảng cách bên phải
    child: IconButton(
      icon: const Icon(Icons.bar_chart),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => LetterStatsPage()),
        );
      },
    ),
  ),
],
),
        body: const Center(child: Text('Không có câu hỏi nào')),
      );
    }

    return Scaffold(
     //appBar: AppBar(title: const Text('Quiz chữ cái')),
     appBar: AppBar(
  title: const Text('Quiz chữ cái'),
  actions: [
  Padding(
    padding: const EdgeInsets.only(right: 12.0), // 👈 Khoảng cách bên phải
    child: IconButton(
      icon: const Icon(Icons.bar_chart),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => LetterStatsPage()),
        );
      },
    ),
  ),
],
),
 
      body: Padding(
        padding: const EdgeInsets.all(10),
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
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
                        fontSize: 14,
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox.shrink(),
            ElevatedButton(
              onPressed: playAudio,
              child: const Text('🔊 Nghe phát âm'),
            ),
            const SizedBox(height: 10),
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
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: color),
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
