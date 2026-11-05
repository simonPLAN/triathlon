import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/models.dart';
import '../infrastructure/app_repository.dart';
import 'coach_pages.dart';
import 'athlete_pages.dart';
import 'common.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.repo});
  final AppRepository repo;
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<AuthState>? sub;
  @override
  void initState() {
    super.initState();
    sub = widget.repo.client.auth.onAuthStateChange.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.repo.client.auth.currentSession == null) {
      return LoginPage(repo: widget.repo);
    }
    return FutureBuilder<ProfilUtilisateur>(
      future: widget.repo.profilConnecte(),
      builder: (c, s) {
        if (s.hasError) {
          return Scaffold(body: Center(child: Text('${s.error}')));
        }
        if (!s.hasData) {
          return const Scaffold(body: Busy(label: 'Chargement du profil...'));
        }
        return s.data!.estCoach
            ? CoachHome(repo: widget.repo, profil: s.data!)
            : AthleteHome(repo: widget.repo, profil: s.data!);
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.repo});
  final AppRepository repo;
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController(), pass = TextEditingController();
  bool busy = false;
  @override
  void dispose() {
    email.dispose();
    pass.dispose();
    super.dispose();
  }

  Future<void> login() async {
    setState(() => busy = true);
    try {
      await widget.repo.signIn(email.text, pass.text);
    } catch (e) {
      if (mounted) message(context, e.toString(), erreur: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.emoji_events, size: 60),
                  const SizedBox(height: 12),
                  Text(
                    'Connexion',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: email,
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: pass,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Mot de passe',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: busy ? null : login,
                    child: Text(busy ? 'Connexion...' : 'Se connecter'),
                  ),
                  TextButton(
                    onPressed: busy
                        ? null
                        : () => showDialog(
                            context: context,
                            builder: (_) => SignupDialog(repo: widget.repo),
                          ),
                    child: const Text('Créer un compte athlète'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class SignupDialog extends StatefulWidget {
  const SignupDialog({super.key, required this.repo});
  final AppRepository repo;
  @override
  State<SignupDialog> createState() => _SignupDialogState();
}

class _SignupDialogState extends State<SignupDialog> {
  final p = TextEditingController(),
      e = TextEditingController(),
      m = TextEditingController();
  bool busy = false;
  Future<void> go() async {
    setState(() => busy = true);
    try {
      await widget.repo.signUp(pseudo: p.text, email: e.text, password: m.text);
      if (mounted) {
        Navigator.pop(context);
        message(context, 'Compte créé. Confirmez l’e-mail si nécessaire.');
      }
    } catch (x) {
      if (mounted) message(context, x.toString(), erreur: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext c) => AlertDialog(
    title: const Text('Créer un compte athlète'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: p,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Pseudo',
              helperText: '3 à 30 caractères : lettres, chiffres, . _ -',
            ),
          ),
          TextField(
            controller: e,
            decoration: const InputDecoration(labelText: 'E-mail'),
          ),
          TextField(
            controller: m,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Mot de passe (8 caractères minimum)',
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(c),
        child: const Text('Annuler'),
      ),
      FilledButton(onPressed: busy ? null : go, child: const Text('Créer')),
    ],
  );
}
