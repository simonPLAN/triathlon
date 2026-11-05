import 'package:flutter/material.dart';

import '../commun/message_erreur.dart';

class ErreurManches extends StatelessWidget {
  const ErreurManches({
    super.key,
    required this.message,
    required this.onReessayer,
  });
  final String message;
  final Future<void> Function() onReessayer;

  @override
  Widget build(BuildContext context) => MessageErreur(
    titre: 'Impossible de charger les manches',
    message: message,
    onReessayer: onReessayer,
  );
}
