import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/ports/source_liens_recuperation.dart';
import '../controllers/recuperation_compte_controller.dart';
import '../controllers/confirmation_email_controller.dart';
import '../pages/auth/confirmation_email_page.dart';
import '../pages/auth/nouveau_mot_de_passe_page.dart';

class RecuperationCompteHost extends StatefulWidget {
  const RecuperationCompteHost({
    super.key,
    required this.controller,
    required this.navigatorKey,
    required this.child,
    required this.sourceLiens,
    this.confirmationEmail,
  });
  final ConfirmationEmailController? confirmationEmail;
  final RecuperationCompteController controller;
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;
  final SourceLiensRecuperation sourceLiens;

  @override
  State<RecuperationCompteHost> createState() => _RecuperationCompteHostState();
}

class _RecuperationCompteHostState extends State<RecuperationCompteHost> {
  bool _pageOuverte = false;
  bool _confirmationOuverte = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_actualiser);
    widget.confirmationEmail?.addListener(_actualiser);
    unawaited(
      widget.sourceLiens.demarrer((lien) async {
        final confirmation = widget.confirmationEmail;
        if (confirmation != null && confirmation.correspond(lien)) {
          await confirmation.traiterLien(lien);
        } else {
          await widget.controller.traiterLien(lien);
        }
      }),
    );
    _actualiser();
  }

  void _actualiser() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final navigator = widget.navigatorKey.currentState;
      if (navigator == null) return;
      final confirmation = widget.confirmationEmail;
      if (confirmation != null &&
          confirmation.lienActif &&
          !_confirmationOuverte) {
        _confirmationOuverte = true;
        navigator
            .push<void>(
              MaterialPageRoute(
                builder: (_) => ConfirmationEmailPage(controller: confirmation),
              ),
            )
            .whenComplete(() {
              _confirmationOuverte = false;
              confirmation.fermerLien();
            });
        return;
      }
      if (widget.controller.active && !_pageOuverte) {
        _pageOuverte = true;
        navigator
            .pushAndRemoveUntil<void>(
              MaterialPageRoute(
                builder: (_) =>
                    NouveauMotDePassePage(controller: widget.controller),
              ),
              (route) => route.isFirst,
            )
            .whenComplete(() => _pageOuverte = false);
      } else if (!widget.controller.active && _pageOuverte) {
        navigator.popUntil((route) => route.isFirst);
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_actualiser);
    widget.confirmationEmail?.removeListener(_actualiser);
    widget.sourceLiens.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
