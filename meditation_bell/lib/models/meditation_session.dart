class MeditationSession {
  final int durationMinutes;
  final int intervalSeconds;
  final DateTime startedAt;
  final bool completed;

  const MeditationSession({
    required this.durationMinutes,
    required this.intervalSeconds,
    required this.startedAt,
    this.completed = false,
  });

  MeditationSession copyWith({
    int? durationMinutes,
    int? intervalSeconds,
    DateTime? startedAt,
    bool? completed,
  }) {
    return MeditationSession(
      durationMinutes: durationMinutes ?? this.durationMinutes,
      intervalSeconds: intervalSeconds ?? this.intervalSeconds,
      startedAt: startedAt ?? this.startedAt,
      completed: completed ?? this.completed,
    );
  }
}
