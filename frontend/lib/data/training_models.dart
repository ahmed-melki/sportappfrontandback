import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum ExerciseCategory { strength, olympic, hyrox, cardio, mobility, core }

ExerciseCategory exerciseCategoryFromJson(String? value) => ExerciseCategory.values.firstWhere((category) => category.name == value, orElse: () => ExerciseCategory.strength);

extension ExerciseCategoryX on ExerciseCategory {
  String get label => switch (this) {
        ExerciseCategory.strength => 'Force',
        ExerciseCategory.olympic => 'Haltéro',
        ExerciseCategory.hyrox => 'Hyrox',
        ExerciseCategory.cardio => 'Cardio',
        ExerciseCategory.mobility => 'Mobilité',
        ExerciseCategory.core => 'Core',
      };

  Color get accent => switch (this) {
        ExerciseCategory.strength => AppColors.volt,
        ExerciseCategory.olympic => AppColors.amber,
        ExerciseCategory.hyrox => AppColors.cyan,
        ExerciseCategory.cardio => AppColors.coral,
        ExerciseCategory.mobility => AppColors.mint,
        ExerciseCategory.core => AppColors.violet,
      };
}

enum RxKind { load, distance, bodyweight }

RxKind rxKindFromJson(String? value) => RxKind.values.firstWhere((kind) => kind.name == value, orElse: () => RxKind.load);

class CatalogExercise {
  const CatalogExercise({
    required this.id,
    required this.name,
    required this.category,
    required this.equipment,
    required this.muscles,
    required this.cue,
    required this.lastPerf,
  });

  final String id;
  final String name;
  final ExerciseCategory category;
  final String equipment;
  final String muscles;
  final String cue;
  final String lastPerf;

  factory CatalogExercise.fromJson(Map<String, dynamic> json) => CatalogExercise(id: json['id'].toString(), name: json['name']?.toString() ?? '', category: exerciseCategoryFromJson(json['category']?.toString()), equipment: json['equipment']?.toString() ?? '', muscles: json['muscles']?.toString() ?? '', cue: json['cue']?.toString() ?? '', lastPerf: json['lastPerf']?.toString() ?? '');

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'category': category.name, 'equipment': equipment, 'muscles': muscles, 'cue': cue, 'lastPerf': lastPerf};
}

class SessionExercise {
  const SessionExercise({
    required this.exerciseId,
    required this.sets,
    required this.reps,
    required this.loadKg,
    required this.restSec,
    required this.kind,
    this.unitNote,
  });

  final String exerciseId;
  final int sets;
  final int reps;
  final double loadKg;
  final int restSec;
  final RxKind kind;
  final String? unitNote;

  factory SessionExercise.fromJson(Map<String, dynamic> json) => SessionExercise(exerciseId: json['exerciseId'].toString(), sets: (json['sets'] as num? ?? 0).toInt(), reps: (json['reps'] as num? ?? 0).toInt(), loadKg: (json['loadKg'] as num? ?? 0).toDouble(), restSec: (json['restSec'] as num? ?? 0).toInt(), kind: rxKindFromJson(json['kind']?.toString()), unitNote: json['unitNote']?.toString());

  Map<String, dynamic> toJson() => {'exerciseId': exerciseId, 'sets': sets, 'reps': reps, 'loadKg': loadKg, 'restSec': restSec, 'kind': kind.name, 'unitNote': unitNote};
}

class WorkoutSession {
  const WorkoutSession({
    required this.id,
    required this.title,
    required this.durationMin,
    required this.focus,
    required this.exercises,
  });

  final String id;
  final String title;
  final int durationMin;
  final String focus;
  final List<SessionExercise> exercises;

  factory WorkoutSession.fromJson(Map<String, dynamic> json) => WorkoutSession(id: json['id'].toString(), title: json['title']?.toString() ?? '', durationMin: (json['durationMin'] as num? ?? 0).toInt(), focus: json['focus']?.toString() ?? '', exercises: (json['exercises'] as List? ?? const []).map((item) => SessionExercise.fromJson(Map<String, dynamic>.from(item as Map))).toList());

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'durationMin': durationMin, 'focus': focus, 'exercises': exercises.map((item) => item.toJson()).toList()};
}

class TrainingProgram {
  const TrainingProgram({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.weeks,
    required this.daysPerWeek,
    required this.level,
    required this.sessionIds,
  });

  final String id;
  final String title;
  final String subtitle;
  final int weeks;
  final int daysPerWeek;
  final String level;
  final List<String> sessionIds;

  factory TrainingProgram.fromJson(Map<String, dynamic> json) => TrainingProgram(id: json['id'].toString(), title: json['title']?.toString() ?? '', subtitle: json['subtitle']?.toString() ?? '', weeks: (json['weeks'] as num? ?? 0).toInt(), daysPerWeek: (json['daysPerWeek'] as num? ?? 0).toInt(), level: json['level']?.toString() ?? 'beginner', sessionIds: (json['sessionIds'] as List? ?? const []).map((item) => item.toString()).toList());

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'subtitle': subtitle, 'weeks': weeks, 'daysPerWeek': daysPerWeek, 'level': level, 'sessionIds': sessionIds};
}

class SessionLog {
  const SessionLog({
    required this.date,
    required this.sessionTitle,
    required this.programTitle,
    required this.durationMin,
    required this.volumeKg,
    required this.highlight,
  });

  final DateTime date;
  final String sessionTitle;
  final String programTitle;
  final int durationMin;
  final int volumeKg;
  final String highlight;

  factory SessionLog.fromJson(Map<String, dynamic> json) => SessionLog(date: DateTime.tryParse(json['completedAt']?.toString() ?? json['date']?.toString() ?? '') ?? DateTime.now(), sessionTitle: json['sessionTitle']?.toString() ?? '', programTitle: json['programTitle']?.toString() ?? '', durationMin: (json['durationMin'] as num? ?? 0).toInt(), volumeKg: (json['volumeKg'] as num? ?? 0).toInt(), highlight: json['highlight']?.toString() ?? '');

  Map<String, dynamic> toJson() => {'completedAt': date.toUtc().toIso8601String().replaceFirst('+00:00', 'Z'), 'sessionTitle': sessionTitle, 'programTitle': programTitle, 'durationMin': durationMin, 'volumeKg': volumeKg, 'highlight': highlight};
}

class LiftProgress {
  const LiftProgress({
    required this.name,
    required this.unit,
    required this.points,
  });

  final String name;
  final String unit;
  final List<double> points;

  factory LiftProgress.fromJson(Map<String, dynamic> json) => LiftProgress(name: json['name']?.toString() ?? '', unit: json['unit']?.toString() ?? 'kg', points: (json['points'] as List? ?? const []).map((point) => (point as num).toDouble()).toList());

  Map<String, dynamic> toJson() => {'name': name, 'unit': unit, 'points': points};
}

class TrainingCatalog {
  const TrainingCatalog({
    required this.exercises,
    required this.programs,
    required this.sessions,
    required this.logs,
    required this.lifts,
  });

  final List<CatalogExercise> exercises;
  final List<TrainingProgram> programs;
  final List<WorkoutSession> sessions;
  final List<SessionLog> logs;
  final List<LiftProgress> lifts;

  CatalogExercise exerciseById(String id) =>
      exercises.firstWhere((e) => e.id == id);

  WorkoutSession sessionById(String id) =>
      sessions.firstWhere((e) => e.id == id);

  TrainingCatalog copyWith({List<SessionLog>? logs}) {
    return TrainingCatalog(
      exercises: exercises,
      programs: programs,
      sessions: sessions,
      logs: logs ?? this.logs,
      lifts: lifts,
    );
  }
}
