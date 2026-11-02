import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/ports/source_liens_recuperation.dart';
import '../controllers/recuperation_compte_controller.dart';
import '../pages/auth/nouveau_mot_de_passe_page.dart';

class RecuperationCompteHost extends StatefulWidget {
  const RecuperationCompteHost({
    super.key,
    required this.controller,
    required this.navigatorKey,
    required this.child,
    required this.sourceLiens,
  });
  final RecuperationCompteController controller;
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;
  final SourceLiensRecuperation sourceLiens;

  @override
  State<RecuperationCompteHost> createState() => _RecuperationCompteHostState();
}

class _RecuperationCompteHostState extends State<RecuperationCompteHost> {
  bool _pageOuverte = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_actualiser);
    unawaited(widget.sourceLiens.demarrer(widget.controller.traiterLien));
    _actualiser();
  }

  void _actualiser() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final navigator = widget.navigatorKey.currentState;
      if (navigator == null) return;
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
    widget.sourceLiens.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
