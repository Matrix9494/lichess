import 'package:deep_pick/deep_pick.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:lichess_mobile/src/model/common/id.dart';

const kThePinPracticeStudyId = StudyId('9ogFv8Ac');

class PracticeIndex {
  const PracticeIndex({required this.sections, required this.progress});

  final IList<PracticeSection> sections;
  final IMap<StudyChapterId, int> progress;

  PracticeStudyMeta? get thePinStudy {
    for (final study in sections.expand((section) => section.studies)) {
      if (study.id == kThePinPracticeStudyId) return study;
    }
    return null;
  }

  factory PracticeIndex.fromJson(Map<String, Object?> json) {
    return PracticeIndex(
      sections: pick(
        json,
        'sections',
      ).asListOrThrow((pick) => PracticeSection.fromPick(pick.required())).lock,
      progress: pick(json, 'progress')
          .asMapOrThrow<String, int>()
          .map((key, value) => MapEntry(StudyChapterId(key), value))
          .toIMap(),
    );
  }
}

class PracticeSection {
  const PracticeSection({required this.id, required this.name, required this.studies});

  final String id;
  final String name;
  final IList<PracticeStudyMeta> studies;

  factory PracticeSection.fromPick(RequiredPick pick) {
    return PracticeSection(
      id: pick('id').asStringOrThrow(),
      name: pick('name').asStringOrThrow(),
      studies: pick(
        'studies',
      ).asListOrThrow((pick) => PracticeStudyMeta.fromPick(pick.required())).lock,
    );
  }
}

class PracticeStudyMeta {
  const PracticeStudyMeta({
    required this.id,
    required this.slug,
    required this.name,
    this.description,
  });

  final StudyId id;
  final String slug;
  final String name;
  final String? description;

  factory PracticeStudyMeta.fromPick(RequiredPick pick) {
    return PracticeStudyMeta(
      id: pick('id').asStudyIdOrThrow(),
      slug: pick('slug').asStringOrThrow(),
      name: pick('name').asStringOrThrow(),
      description: pick('desc').asStringOrNull(),
    );
  }
}

sealed class PracticeGoal {
  const PracticeGoal();

  factory PracticeGoal.fromJson(Map<String, Object?> json) {
    final result = json['result'] as String?;
    final moves = json['moves'] as int?;
    final cp = json['cp'] as int?;
    return switch (result) {
      'mate' => const PracticeGoalMate(),
      'mateIn' when moves != null => PracticeGoalMateIn(moves),
      'drawIn' when moves != null => PracticeGoalDrawIn(moves),
      'equalIn' when moves != null => PracticeGoalEqualIn(moves),
      'evalIn' when moves != null && cp != null => PracticeGoalEvalIn(cp: cp, moves: moves),
      'promotion' when cp != null => PracticeGoalPromotion(cp),
      _ => const PracticeGoalUnknown(),
    };
  }
}

class PracticeGoalMate extends PracticeGoal {
  const PracticeGoalMate();
}

class PracticeGoalMateIn extends PracticeGoal {
  const PracticeGoalMateIn(this.moves);

  final int moves;
}

class PracticeGoalDrawIn extends PracticeGoal {
  const PracticeGoalDrawIn(this.moves);

  final int moves;
}

class PracticeGoalEqualIn extends PracticeGoal {
  const PracticeGoalEqualIn(this.moves);

  final int moves;
}

class PracticeGoalEvalIn extends PracticeGoal {
  const PracticeGoalEvalIn({required this.cp, required this.moves});

  final int cp;
  final int moves;
}

class PracticeGoalPromotion extends PracticeGoal {
  const PracticeGoalPromotion(this.cp);

  final int cp;
}

class PracticeGoalUnknown extends PracticeGoal {
  const PracticeGoalUnknown();
}
