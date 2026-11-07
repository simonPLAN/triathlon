import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../configuration/configuration_publication.dart';
import '../../../configuration/identite_application.dart';
import '../../widgets/commun/carte_section.dart';

class InformationsApplicationPage extends StatefulWidget {
  const InformationsApplicationPage({
    super.key,
    this.onSupprimerCompte,
    this.ouvrirLien,
    this.politiqueUrl = ConfigurationPublication.politiqueConfidentialiteUrl,
    this.suppressionUrl = ConfigurationPublication.suppressionCompteUrl,
    this.emailSupport = ConfigurationPublication.emailSupport,
  });
  final VoidCallback? onSupprimerCompte;
  final Future<bool> Function(Uri)? ouvrirLien;
  final String politiqueUrl, suppressionUrl, emailSupport;

  @override
  State<InformationsApplicationPage> createState() =>
      _InformationsApplicationPageState();
}

class _InformationsApplicationPageState
    extends State<InformationsApplicationPage> {
  bool _ouverture = false;
  String? _erreur;

  Uri? _https(String valeur) {
    final uri = Uri.tryParse(valeur);
    return uri?.scheme == 'https' &&
            uri!.host.isNotEmpty &&
            uri.userInfo.isEmpty
        ? uri
        : null;
  }

  Future<void> _ouvrir(Uri uri) async {
    if (_ouverture) return;
    setState(() {
      _ouverture = true;
      _erreur = null;
    });
    try {
      final reussi =
          await (widget.ouvrirLien?.call(uri) ??
              launchUrl(uri, mode: LaunchMode.externalApplication));
      if (!reussi) throw StateError('Ouverture refusée');
    } catch (_) {
      if (mounted) {
        setState(
          () => _erreur =
              'Impossible d’ouvrir le lien. Tu peux copier l’adresse ci-dessous '
              'et l’ouvrir dans ton navigateur ou ton application e-mail.',
        );
      }
    } finally {
      if (mounted) setState(() => _ouverture = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final politique = _https(widget.politiqueUrl);
    final suppression = _https(widget.suppressionUrl);
    final email = widget.emailSupport.trim();
    final contact = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
    return Scaffold(
      appBar: AppBar(title: const Text('Informations et confidentialité')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                CarteSection(
                  titre: IdentiteApplication.nom,
                  icone: Icons.sports_outlined,
                  child: const Text(
                    'Retrouve les informations sur tes données personnelles '
                    'et les moyens de contacter le responsable de l’application.',
                  ),
                ),
                if (_ouverture) const LinearProgressIndicator(),
                if (_erreur != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        _erreur!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                _sectionLien(
                  titre: 'Politique de confidentialité',
                  icone: Icons.privacy_tip_outlined,
                  description:
                      'Consulte les finalités de traitement, les destinataires '
                      'et les durées de conservation de tes données.',
                  uri: politique,
                  libelle: 'Lire la politique de confidentialité',
                ),
                CarteSection(
                  titre: 'Suppression du compte et des données',
                  icone: Icons.person_remove_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Le parcours de suppression explique les conséquences '
                        'avant toute confirmation. Une page publique permet '
                        'également de consulter les modalités de demande.',
                      ),
                      if (widget.onSupprimerCompte != null) ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _ouverture
                              ? null
                              : widget.onSupprimerCompte,
                          icon: const Icon(Icons.manage_accounts_outlined),
                          label: const Text('Supprimer mon compte'),
                        ),
                      ],
                      const SizedBox(height: 12),
                      if (suppression == null)
                        const Text(
                          'La page publique de suppression sera disponible prochainement.',
                        )
                      else ...[
                        TextButton.icon(
                          onPressed: _ouverture
                              ? null
                              : () => _ouvrir(suppression),
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Consulter la page publique'),
                        ),
                        SelectableText(suppression.toString()),
                      ],
                    ],
                  ),
                ),
                CarteSection(
                  titre: 'Contacter le support',
                  icone: Icons.mail_outline,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!contact)
                        const Text(
                          'Les coordonnées de contact seront disponibles prochainement.',
                        )
                      else ...[
                        SelectableText(email),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _ouverture
                              ? null
                              : () =>
                                    _ouvrir(Uri(scheme: 'mailto', path: email)),
                          icon: const Icon(Icons.send_outlined),
                          label: const Text('Écrire au support'),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLien({
    required String titre,
    required IconData icone,
    required String description,
    required Uri? uri,
    required String libelle,
  }) => CarteSection(
    titre: titre,
    icone: icone,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(description),
        const SizedBox(height: 12),
        if (uri == null)
          const Text('Ce document sera disponible prochainement.')
        else ...[
          OutlinedButton.icon(
            onPressed: _ouverture ? null : () => _ouvrir(uri),
            icon: const Icon(Icons.open_in_new),
            label: Text(libelle),
          ),
          SelectableText(uri.toString()),
        ],
      ],
    ),
  );
}
