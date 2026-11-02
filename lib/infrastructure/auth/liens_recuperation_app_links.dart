import 'dart:async';

import 'package:app_links/app_links.dart';

import '../../domain/ports/source_liens_recuperation.dart';

class LiensRecuperationAppLinks implements SourceLiensRecuperation {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _abonnement;

  @override
  Future<void> demarrer(Future<void> Function(Uri) traiterLien) async {
    _abonnement = _appLinks.uriLinkStream.listen(
      (lien) => unawaited(traiterLien(lien)),
      onError: (Object _) {},
    );
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) await traiterLien(initial);
    } catch (_) {
      // Un démarrage normal sans lien reste utilisable.
    }
  }

  @override
  void dispose() {
    unawaited(_abonnement?.cancel());
  }
}
