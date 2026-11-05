import 'package:flutter/material.dart';

import '../theme/theme_application.dart';
import '../../configuration/identite_application.dart';
import '../widgets/commun/message_erreur.dart';

/// État de démarrage visible, sans fuite des détails d'une erreur serveur.
class DemarrageApplication extends StatefulWidget {
  const DemarrageApplication({super.key, required this.charger});
  final Future<Widget> Function() charger;
  @override
  State<DemarrageApplication> createState() => _DemarrageApplicationState();
}

class _DemarrageApplicationState extends State<DemarrageApplication> {
  late Future<Widget> _chargement;
  bool _initialisationEnCours = false;
  @override
  void initState() {
    super.initState();
    _chargement = _initialiser();
  }

  Future<Widget> _initialiser() async {
    _initialisationEnCours = true;
    try {
      return await widget.charger();
    } finally {
      _initialisationEnCours = false;
    }
  }

  void _reessayer() {
    if (_initialisationEnCours) return;
    setState(() {
      _chargement = _initialiser();
    });
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Widget>(
    future: _chargement,
    builder: (context, etat) {
      if (etat.hasData) return etat.data!;
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: IdentiteApplication.nom,
        theme: ThemeApplication.clair,
        darkTheme: ThemeApplication.sombre,
        home: Scaffold(
          body: SafeArea(
            child: etat.hasError
                ? MessageErreur(
                    titre: 'Impossible de démarrer',
                    message: 'Vérifie ta connexion et la configuration de l’application, puis réessaie.',
                    onReessayer: _reessayer,
                  )
                : const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 20),
                          Text(
                            'Préparation de ton espace sportif…',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      );
    },
  );
}
