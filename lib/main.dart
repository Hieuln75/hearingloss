import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:just_audio/just_audio.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Supabase
  await Supabase.initialize(
    url: 'https://hiqecekamorbjufgwzit.supabase.co',       // Thay bằng URL Supabase của bạn
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhpcWVjZWthbW9yYmp1Zmd3eml0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU3NDgwMTEsImV4cCI6MjA3MTMyNDAxMX0.Dw4jB-GhP8NJQs4IoZ0cbJWqyvkhQC3nA7TbqCGVWjg',               // Thay bằng anon key Supabase
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final SupabaseClient supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Supabase Demo',
      home: Scaffold(
        appBar: AppBar(
          title: Text('Flutter Supabase Demo'),
        ),
        body: AuthPage(),
      ),
    );
  }
}

class AuthPage extends StatefulWidget {
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final supabase = Supabase.instance.client;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();

  String message = '';

  @override
  void initState() {
    super.initState();

    // Load audio từ URL public của bạn (đặt đúng URL file audio public)
    _audioPlayer.setUrl(
      'https://hiqecekamorbjufgwzit.supabase.co/storage/v1/object/public/recordings/audio/a.m4a',
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> signUp() async {
  try {
    final response = await supabase.auth.signUp(
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (response.user != null) {
      setState(() {
        message = 'Sign Up Successful! Please check your email.';
      });
    }
  } on AuthException catch (error) {
    setState(() {
      message = 'Sign Up Error: ${error.message}';
    });
  } catch (error) {
    setState(() {
      message = 'Unexpected error: $error';
    });
  }
}

Future<void> signIn() async {
  try {
    final response = await supabase.auth.signInWithPassword(
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (response.user != null) {
      setState(() {
        message = 'Signed In! User ID: ${response.user!.id}';
      });
    }
  } on AuthException catch (error) {
    setState(() {
      message = 'Sign In Error: ${error.message}';
    });
  } catch (error) {
    setState(() {
      message = 'Unexpected error: $error';
    });
  }
}


  Future<void> signOut() async {
    await supabase.auth.signOut();
    setState(() {
      message = 'Signed Out';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: ListView(
        children: [
          TextField(
            controller: _emailController,
            decoration: InputDecoration(labelText: 'Email'),
          ),
          TextField(
            controller: _passwordController,
            decoration: InputDecoration(labelText: 'Password'),
            obscureText: true,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: signUp,
            child: Text('Sign Up'),
          ),
          ElevatedButton(
            onPressed: signIn,
            child: Text('Sign In'),
          ),
          ElevatedButton(
            onPressed: signOut,
            child: Text('Sign Out'),
          ),
          SizedBox(height: 20),
          Text(message),
          Divider(height: 40),
          Text(
            'Nghe audio (guest cũng nghe được):',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              ElevatedButton(
                onPressed: () => _audioPlayer.play(),
                child: Text('Play'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => _audioPlayer.pause(),
                child: Text('Pause'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => _audioPlayer.stop(),
                child: Text('Stop'),
              ),
            ],
          ),
          SizedBox(height: 30),
          Text(
           'Danh sách chữ cái (từ Supabase):',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(
          height: 300, // hoặc bất kỳ chiều cao nào bạn muốn
          child: LetterAudioList(),
          ),

        ],
      ),
    );
  }
}
class LetterAudioList extends StatefulWidget {
  @override
  _LetterAudioListState createState() => _LetterAudioListState();
}

class _LetterAudioListState extends State<LetterAudioList> {
  final supabase = Supabase.instance.client;
  final player = AudioPlayer();

  List<Map<String, dynamic>> letters = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchLetters();
  }

  Future<void> fetchLetters() async {
    final response = await supabase.from('letters_audio').select();
    setState(() {
      letters = List<Map<String, dynamic>>.from(response);
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
      return Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      itemCount: letters.length,
      itemBuilder: (context, index) {
        final letter = letters[index];
        return ListTile(
          title: Text('Chữ cái: ${letter['letter']}'),
          trailing: IconButton(
            icon: Icon(Icons.play_arrow),
            onPressed: () => playAudio(letter['audio_url']),
          ),
        );
      },
    );
  }
}