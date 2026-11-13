import 'package:flutter/material.dart';

import '../../../domain/entities/affiche_epreuve.dart';
import '../../controllers/affiches_epreuve_controller.dart';
import '../commun/message_erreur.dart';

class GalerieAffichesEpreuve extends StatefulWidget {
  const GalerieAffichesEpreuve({
    super.key,
    required this.epreuveId,
    required this.controller,
    this.afficherEtatVide = true,
  });

  final String epreuveId;
  final AffichesEpreuveController controller;
  final bool afficherEtatVide;

  @override
  State<GalerieAffichesEpreuve> createState() => _GalerieAffichesEpreuveState();
}

class _GalerieAffichesEpreuveState extends State<GalerieAffichesEpreuve> {
  int _selection = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_actualiser);
    widget.controller.reinitialiser();
    widget.controller.charger(widget.epreuveId);
  }

  @override
  void didUpdateWidget(covariant GalerieAffichesEpreuve oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_actualiser);
      widget.controller.addListener(_actualiser);
    }
    if (oldWidget.epreuveId != widget.epreuveId) {
      _selection = 0;
      widget.controller.reinitialiser();
      widget.controller.charger(widget.epreuveId);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_actualiser);
    super.dispose();
  }

  void _actualiser() {
    if (!mounted) return;
    final maximum = widget.controller.affiches.length - 1;
    if (_selection > maximum) _selection = maximum < 0 ? 0 : maximum;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    if (controller.chargement && controller.affiches.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (controller.erreur != null && controller.affiches.isEmpty) {
      return MessageErreur(
        message: controller.erreur!,
        onReessayer: () => controller.charger(widget.epreuveId),
      );
    }
    if (controller.affiches.isEmpty) {
      return widget.afficherEtatVide
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Aucune affiche n’a été ajoutée pour cette épreuve.',
                textAlign: TextAlign.center,
              ),
            )
          : const SizedBox.shrink();
    }

    final affiche = controller.affiches[_selection];
    final url = controller.urlPour(affiche.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ImageAffiche(
          affiche: affiche,
          url: url,
          onOuvrir: url == null
              ? null
              : () => _ouvrirPleinEcran(context, affiche, url),
          onReessayer: () => controller.charger(widget.epreuveId),
        ),
        if (controller.affiches.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Affiche précédente',
                onPressed: _selection == 0
                    ? null
                    : () => setState(() => _selection--),
                icon: const Icon(Icons.chevron_left),
              ),
              Text('${_selection + 1} sur ${controller.affiches.length}'),
              IconButton(
                tooltip: 'Affiche suivante',
                onPressed: _selection == controller.affiches.length - 1
                    ? null
                    : () => setState(() => _selection++),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _ouvrirPleinEcran(
    BuildContext context,
    AfficheEpreuve affiche,
    Uri url,
  ) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              affiche.estPrincipale ? 'Affiche principale' : 'Affiche 2',
            ),
            leading: IconButton(
              tooltip: 'Fermer',
              onPressed: () => Navigator.pop(dialogContext),
              icon: const Icon(Icons.close),
            ),
          ),
          body: Semantics(
            image: true,
            label: affiche.texteAlternatif,
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 5,
              child: Center(
                child: Image.network(
                  url.toString(),
                  fit: BoxFit.contain,
                  semanticLabel: affiche.texteAlternatif,
                  errorBuilder: (_, _, _) => const _ImageIndisponible(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ImageAffiche extends StatelessWidget {
  const _ImageAffiche({
    required this.affiche,
    required this.url,
    required this.onOuvrir,
    required this.onReessayer,
  });

  final AfficheEpreuve affiche;
  final Uri? url;
  final VoidCallback? onOuvrir;
  final VoidCallback onReessayer;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onOuvrir != null,
      label: affiche.texteAlternatif,
      child: InkWell(
        onTap: onOuvrir,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 180, maxHeight: 420),
              child: url == null
                  ? _ImageIndisponible(onReessayer: onReessayer)
                  : Image.network(
                      url.toString(),
                      fit: BoxFit.contain,
                      semanticLabel: affiche.texteAlternatif,
                      loadingBuilder: (context, child, progression) =>
                          progression == null
                          ? child
                          : const Center(child: CircularProgressIndicator()),
                      errorBuilder: (_, _, _) =>
                          _ImageIndisponible(onReessayer: onReessayer),
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              affiche.texteAlternatif,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (onOuvrir != null)
              const Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text('Appuie pour agrandir'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ImageIndisponible extends StatelessWidget {
  const _ImageIndisponible({this.onReessayer});

  final VoidCallback? onReessayer;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.broken_image_outlined, size: 48),
          const SizedBox(height: 8),
          const Text('Image indisponible'),
          if (onReessayer != null)
            TextButton(onPressed: onReessayer, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}

Future<void> ouvrirGalerieAffichesEpreuve({
  required BuildContext context,
  required String epreuveId,
  required AffichesEpreuveController controller,
  required String titre,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 780),
        child: Scaffold(
          appBar: AppBar(
            title: Text(titre),
            leading: IconButton(
              tooltip: 'Fermer',
              onPressed: () => Navigator.pop(dialogContext),
              icon: const Icon(Icons.close),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: GalerieAffichesEpreuve(
              epreuveId: epreuveId,
              controller: controller,
            ),
          ),
        ),
      ),
    ),
  );
}
