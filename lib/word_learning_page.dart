/*import 'package:flutter/material.dart';

class WordLearningPage extends StatelessWidget {
  const WordLearningPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Học từ')),
      body: const Center(
        child: Text(
          'Đây là màn hình học từ',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
*/

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:just_audio/just_audio.dart';

class WordLearningPage extends StatefulWidget {
  const WordLearningPage({Key? key}) : super(key: key);

  @override
  _WordLearningPageState createState() => _WordLearningPageState();
}

class _WordLearningPageState extends State<WordLearningPage> {
  final supabase = Supabase.instance.client;
  final player = AudioPlayer();

  List<Map<String, dynamic>> words = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchWords();
  }

  Future<void> fetchWords() async {
    final response = await supabase.from('words_audio').select();
    setState(() {
      words = List<Map<String, dynamic>>.from(response);
      isLoading = false;
    });
  }

  Future<void> playAudio(String url) async {
    try {
      await player.setUrl(url);
      await player.play();
    } catch (e) {
      print('Lỗi phát audio: $e');
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
      return Scaffold(
        appBar: AppBar(
          title: Text('Học từ'),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Học từ'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        itemCount: words.length,
        itemBuilder: (context, index) {
          final word = words[index];
          return ListTile(
            contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0), // 👈 dòng quan trọng nè
            title: Text('Từ: ${word['word']}'),
            trailing: IconButton(
              icon: Icon(Icons.play_arrow),
              onPressed: () => playAudio(word['audio_url']),
            ),
          );
        },
      ),
    );
  }
}
