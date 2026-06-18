import 'package:flutter/foundation.dart';
import '../services/storage_service.dart';

class StatsProvider extends ChangeNotifier {
  final StorageService _storage;

  StatsProvider(this._storage);

  int get totalMinutes => _storage.totalMinutes;
  int get totalSessions => _storage.totalSessions;
  int get currentStreak => _storage.currentStreak;

  Future<void> recordSession(int minutes) async {
    await _storage.recordCompletedSession(minutes);
    notifyListeners();
  }
}
