enum Difficulty {
  easy(id: 'easy', label: 'Easy', baseIQ: 100, targetTimeSeconds: 420, minClues: 40, maxClues: 45, timeBonusCap: 12, timePenaltyCap: 10, floorTimeSeconds: 30),
  medium(id: 'medium', label: 'Medium', baseIQ: 115, targetTimeSeconds: 720, minClues: 32, maxClues: 36, timeBonusCap: 15, timePenaltyCap: 12, floorTimeSeconds: 60),
  hard(id: 'hard', label: 'Hard', baseIQ: 130, targetTimeSeconds: 1200, minClues: 28, maxClues: 31, timeBonusCap: 18, timePenaltyCap: 15, floorTimeSeconds: 90),
  expert(id: 'expert', label: 'Expert', baseIQ: 145, targetTimeSeconds: 1800, minClues: 25, maxClues: 27, timeBonusCap: 22, timePenaltyCap: 18, floorTimeSeconds: 150),
  evil(id: 'evil', label: 'Evil', baseIQ: 160, targetTimeSeconds: 2700, minClues: 22, maxClues: 24, timeBonusCap: 28, timePenaltyCap: 22, floorTimeSeconds: 240);

  const Difficulty({
    required this.id,
    required this.label,
    required this.baseIQ,
    required this.targetTimeSeconds,
    required this.minClues,
    required this.maxClues,
    required this.timeBonusCap,
    required this.timePenaltyCap,
    required this.floorTimeSeconds,
  });

  final String id;
  final String label;
  final int baseIQ;
  final int targetTimeSeconds;
  final int minClues;
  final int maxClues;
  final int timeBonusCap;
  final int timePenaltyCap;
  final int floorTimeSeconds;
}
