

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:just_audio/just_audio.dart';

class ConversationLearningPage extends StatefulWidget {
  const ConversationLearningPage({Key? key}) : super(key: key);

  @override
  _ConversationLearningPageState createState() => _ConversationLearningPageState();
}

class _ConversationLearningPageState extends State<ConversationLearningPage> {
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
    final response = await supabase.from('conversations_audio').select();
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
        title: Text('Đàm thoại'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
 
      body: ListView(
       children: [
    
    // Hiển thị danh sách từ
    ...words.map((word) {
      return ListTile(
        contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        title: Text('Câu: ${word['word']}'),
        trailing: IconButton(
          icon: Icon(Icons.play_arrow),
          onPressed: () => playAudio(word['audio_url']),
        ),
      );
    }).toList(),
  ],
),
    );
  }
}
