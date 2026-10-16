import 'database_service.dart';

class ParticipantService {
  final List<String> participants = [];

  void setParticipants(List<String> newParticipants) {
    participants
      ..clear()
      ..addAll(newParticipants);
  }

  Future<bool> addParticipant(
    DatabaseService dbService,
    String name,
  ) async {
    final cleaned = name.trim();

    if (cleaned.isEmpty ||
        participants.any((p) => p.toLowerCase() == cleaned.toLowerCase())) {
      return false;
    }

    final user = dbService.currentUser;
    if (user == null) return false;

    try {
      await dbService.insertParticipant(user.id, cleaned);
      participants.add(cleaned);
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
      participants.remove(name);
      return true;
    } catch (_) {
      return false;
    }
  }

  void clear() {
    participants.clear();
  }
}
