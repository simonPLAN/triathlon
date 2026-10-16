import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/sports.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  String? errorMessage;

  Future<void> login() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
    } catch (e, stackTrace) {
      debugPrint('ERREUR CONNEXION : $e');
      debugPrint('$stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppTexts.errorLoginPrefix}$e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppTexts.appBarLogin)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.directions_bike, size: 64),
                const SizedBox(height: 24),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: AppTexts.labelEmail,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: AppTexts.labelPassword,
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) {
                    if (!loading) login();
                  },
                ),
                const SizedBox(height: 16),
                if (errorMessage != null)
                  Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loading ? null : login,
                    child: Text(
                      loading ? AppTexts.labelLoggingIn : AppTexts.labelLogin,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
