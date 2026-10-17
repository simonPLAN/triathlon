import '../models/participant.dart';
import 'database_service.dart';

class ParticipantService {
  final List<Participant> _participants = [];

  List<Participant> get participantModels => List.unmodifiable(_participants);

  List<String> get participants =>
      _participants.map((p) => p.name).toList();

  Map<String, double> get coefficients => {
        for (final p in _participants) p.name: p.coefficient,
      };

  double getCoefficient(String name) {
    final found = _participants.firstWhere(
      (p) => p.name.toLowerCase() == name.toLowerCase(),
      orElse: () => const Participant(name: '', coefficient: 1.0),
    );
    return found.coefficient;
  }

  void setParticipants(List<dynamic> newParticipants) {
    _participants.clear();
    for (final item in newParticipants) {
      if (item is Participant) {
        _participants.add(item);
      } else {
        _participants.add(Participant.fromJson(item));
      }
    }
  }

  Future<bool> addParticipant(
    DatabaseService dbService,
    String name, {
    double coefficient = 1.0,
  }) async {
    final cleaned = name.trim();

    if (cleaned.isEmpty ||
        _participants.any((p) => p.name.toLowerCase() == cleaned.toLowerCase()) ||
        coefficient <= 0) {
      return false;
    }

    final user = dbService.currentUser;
    if (user == null) return false;

    final newParticipant =
        Participant(name: cleaned, coefficient: coefficient);

    try {
      await dbService.insertParticipant(user.id, cleaned, coefficient);
      _participants.add(newParticipant);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateParticipant(
    DatabaseService dbService,
    String name,
    double newCoefficient,
  ) async {
    if (newCoefficient <= 0) return false;

    final index = _participants.indexWhere(
      (p) => p.name.toLowerCase() == name.toLowerCase(),
    );
    if (index == -1) return false;

    final user = dbService.currentUser;
    if (user == null) return false;

    try {
      await dbService.updateParticipantCoefficient(
        user.id,
        name,
        newCoefficient,
      );
      _participants[index] =
          _participants[index].copyWith(coefficient: newCoefficient);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> removeParticipant(
    DatabaseService dbService,
    String name,
  ) async {
    final user = dbService.currentUser;
    if (user == null) return false;

    try {
      await dbService.deleteParticipant(user.id, name);
      _participants.removeWhere(
        (p) => p.name.toLowerCase() == name.toLowerCase(),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  void clear() {
    _participants.clear();
  }

  List<Map<String, dynamic>> toJson() {
    return _participants.map((p) => p.toJson()).toList();
  }
}
