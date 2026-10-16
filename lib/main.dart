import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'constants/sports.dart';
import 'pages/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://dgjtfhslcbrgsdczlvdg.supabase.co',
    publishableKey: 'sb_publishable_YkkAvzFAOUZKJQwUxZKl-A_HJsJLBWT',
  );
  runApp(const TriathlonApp());
}

class TriathlonApp extends StatelessWidget {
  const TriathlonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}
