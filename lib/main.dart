import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dashboard.dart';
import 'login_page.dart';
import 'create_profile.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ghfryfhjckqvyfbpuckj.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdoZnJ5ZmhqY2txdnlmYnB1Y2tqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE3NjA0OTgsImV4cCI6MjA4NzMzNjQ5OH0.r-UpwwiA_dCdM49V-ZTH10ton9sD3GodacT5sWiFCRc',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> getInitialScreen() async {
    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;

    if (session == null) return const LoginPage();

    final email = supabase.auth.currentUser?.email;
    if (email == null) return const LoginPage();

    final res = await supabase
        .from('Users')
        .select('email')
        .eq('email', email)
        .maybeSingle();

    // ✅ Fix: check both null and empty map
    if (res == null || res.isEmpty) {
      return CreateProfile(email: email);
    } else {
      return const Dashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgroSmart',
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<Widget>(
        future: getInitialScreen(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return snapshot.data!;
        },
      ),
    );
  }
}
