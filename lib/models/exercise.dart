enum BodyPart { gambe, braccia, cardio, petto, schiena, addome }

class Exercise {
  BodyPart bodyPart;
  String exerciseName;
  int numSets;
  int numRepetitions;
  int recoveryTime;
  String? id;

  Exercise(
      {required this.bodyPart,
      required this.exerciseName,
      required this.numSets,
      required this.numRepetitions,
      required this.recoveryTime,
      required this.id});
}
