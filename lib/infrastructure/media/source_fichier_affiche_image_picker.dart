import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image_picker/image_picker.dart';

import '../../domain/entities/fichier_affiche_epreuve.dart';

abstract interface class SourceFichierAffiche {
  Future<FichierAfficheEpreuve?> selectionner();
}

class SourceFichierAfficheImagePicker implements SourceFichierAffiche {
  SourceFichierAfficheImagePicker([ImagePicker? imagePicker])
    : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  @override
  Future<FichierAfficheEpreuve?> selectionner() async {
    final selection = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (selection == null) return null;
    final contenu = await selection.readAsBytes();
    final typeMime = _detecterTypeMime(contenu);
    if (typeMime == null) {
      throw const FormatException(
        'Format non accepté. Utilise une image JPEG, PNG ou WebP.',
      );
    }
    final imageFuture = Completer<ui.Image>();
    ui.decodeImageFromList(contenu, imageFuture.complete);
    final image = await imageFuture.future;
    try {
      return FichierAfficheEpreuve(
        contenu: contenu,
        typeMime: typeMime,
        largeurPixels: image.width,
        hauteurPixels: image.height,
      );
    } finally {
      image.dispose();
    }
  }

  String? _detecterTypeMime(Uint8List octets) {
    if (octets.length >= 3 &&
        octets[0] == 0xff &&
        octets[1] == 0xd8 &&
        octets[2] == 0xff) {
      return 'image/jpeg';
    }
    if (octets.length >= 8 &&
        octets[0] == 0x89 &&
        octets[1] == 0x50 &&
        octets[2] == 0x4e &&
        octets[3] == 0x47 &&
        octets[4] == 0x0d &&
        octets[5] == 0x0a &&
        octets[6] == 0x1a &&
        octets[7] == 0x0a) {
      return 'image/png';
    }
    if (octets.length >= 12 &&
        octets[0] == 0x52 &&
        octets[1] == 0x49 &&
        octets[2] == 0x46 &&
        octets[3] == 0x46 &&
        octets[8] == 0x57 &&
        octets[9] == 0x45 &&
        octets[10] == 0x42 &&
        octets[11] == 0x50) {
      return 'image/webp';
    }
    return null;
  }
}
