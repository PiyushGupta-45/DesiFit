import 'dart:convert';

enum MealType { breakfast, lunch, snack, dinner }

extension MealTypeX on MealType {
  String get label => switch (this) {
        MealType.breakfast => 'Breakfast',
        MealType.lunch => 'Lunch',
        MealType.snack => 'Snacks',
        MealType.dinner => 'Dinner',
      };
  String get emoji => switch (this) {
        MealType.breakfast => '🌅',
        MealType.lunch => '🍛',
        MealType.snack => '🫖',
        MealType.dinner => '🌙',
      };
}

MealType mealForNow() {
  final h = DateTime.now().hour;
  if (h < 11) return MealType.breakfast;
  if (h < 16) return MealType.lunch;
  if (h < 19) return MealType.snack;
  return MealType.dinner;
}

class Nutrition {
  final double kcal, protein, carbs, fat;
  const Nutrition(this.kcal, this.protein, this.carbs, this.fat);
  static const zero = Nutrition(0, 0, 0, 0);

  Nutrition operator +(Nutrition o) => Nutrition(
      kcal + o.kcal, protein + o.protein, carbs + o.carbs, fat + o.fat);
  Nutrition scale(double m) =>
      Nutrition(kcal * m, protein * m, carbs * m, fat * m);
}

class DietEntry {
  final String id;
  final DateTime time;
  final MealType meal;
  final String name;
  final String detail; // e.g. "1.5 × katori · Tadka (ghee)"
  final Nutrition n;

  DietEntry({
    required this.id,
    required this.time,
    required this.meal,
    required this.name,
    required this.detail,
    required this.n,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        't': time.millisecondsSinceEpoch,
        'm': meal.index,
        'name': name,
        'd': detail,
        'k': n.kcal,
        'p': n.protein,
        'c': n.carbs,
        'f': n.fat,
      };

  factory DietEntry.fromJson(Map<String, dynamic> j) => DietEntry(
        id: j['id'],
        time: DateTime.fromMillisecondsSinceEpoch(j['t']),
        meal: MealType.values[j['m']],
        name: j['name'],
        detail: j['d'] ?? '',
        n: Nutrition((j['k'] as num).toDouble(), (j['p'] as num).toDouble(),
            (j['c'] as num).toDouble(), (j['f'] as num).toDouble()),
      );
}

class WorkoutEntry {
  final String id;
  final DateTime time;
  final String name;
  final String emoji;
  final int minutes;
  final String intensity; // Light / Moderate / Intense
  final bool done;
  final double kcal; // 0 when skipped
  final String note;

  WorkoutEntry({
    required this.id,
    required this.time,
    required this.name,
    required this.emoji,
    required this.minutes,
    required this.intensity,
    required this.done,
    required this.kcal,
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        't': time.millisecondsSinceEpoch,
        'name': name,
        'e': emoji,
        'min': minutes,
        'int': intensity,
        'done': done,
        'k': kcal,
        'note': note,
      };

  factory WorkoutEntry.fromJson(Map<String, dynamic> j) => WorkoutEntry(
        id: j['id'],
        time: DateTime.fromMillisecondsSinceEpoch(j['t']),
        name: j['name'],
        emoji: j['e'] ?? '🏃',
        minutes: j['min'],
        intensity: j['int'] ?? 'Moderate',
        done: j['done'] ?? true,
        kcal: (j['k'] as num).toDouble(),
        note: j['note'] ?? '',
      );
}

class Profile {
  String name;
  int age;
  bool male;
  double heightCm;
  double weightKg;
  double activity; // multiplier 1.2 .. 1.9
  int goal; // -1 lose, 0 maintain, 1 gain
  int calorieTarget;
  int proteinTarget;
  int burnTarget;

  Profile({
    this.name = '',
    this.age = 28,
    this.male = true,
    this.heightCm = 170,
    this.weightKg = 70,
    this.activity = 1.375,
    this.goal = 0,
    this.calorieTarget = 2000,
    this.proteinTarget = 90,
    this.burnTarget = 300,
  });

  /// Mifflin-St Jeor BMR
  double get bmr =>
      10 * weightKg + 6.25 * heightCm - 5 * age + (male ? 5 : -161);

  double get tdee => bmr * activity;

  int get suggestedCalories {
    final base = tdee + (goal < 0 ? -450 : goal > 0 ? 350 : 0);
    return (base / 10).round() * 10;
  }

  int get suggestedProtein {
    final perKg = goal > 0 ? 1.8 : goal < 0 ? 1.8 : 1.4;
    return (weightKg * perKg / 5).round() * 5;
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'age': age,
        'male': male,
        'h': heightCm,
        'w': weightKg,
        'act': activity,
        'goal': goal,
        'ct': calorieTarget,
        'pt': proteinTarget,
        'bt': burnTarget,
      };

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        name: j['name'] ?? '',
        age: j['age'] ?? 28,
        male: j['male'] ?? true,
        heightCm: (j['h'] as num?)?.toDouble() ?? 170,
        weightKg: (j['w'] as num?)?.toDouble() ?? 70,
        activity: (j['act'] as num?)?.toDouble() ?? 1.375,
        goal: j['goal'] ?? 0,
        calorieTarget: j['ct'] ?? 2000,
        proteinTarget: j['pt'] ?? 90,
        burnTarget: j['bt'] ?? 300,
      );
}

class Reminder {
  final int id; // base id; scheduled ids are id*10 + weekday (1-7) or id*10
  final bool diet; // true = diet log, false = workout log
  String label;
  int hour;
  int minute;
  bool enabled;
  Set<int> days; // 1 = Mon .. 7 = Sun

  Reminder({
    required this.id,
    required this.diet,
    required this.label,
    required this.hour,
    required this.minute,
    this.enabled = true,
    Set<int>? days,
  }) : days = days ?? {1, 2, 3, 4, 5, 6, 7};

  Map<String, dynamic> toJson() => {
        'id': id,
        'diet': diet,
        'label': label,
        'h': hour,
        'm': minute,
        'on': enabled,
        'days': days.toList(),
      };

  factory Reminder.fromJson(Map<String, dynamic> j) => Reminder(
        id: j['id'],
        diet: j['diet'],
        label: j['label'],
        hour: j['h'],
        minute: j['m'],
        enabled: j['on'] ?? true,
        days: ((j['days'] as List?) ?? [1, 2, 3, 4, 5, 6, 7])
            .map((e) => e as int)
            .toSet(),
      );
}

String encodeList(List<Map<String, dynamic>> l) => jsonEncode(l);
List<Map<String, dynamic>> decodeList(String? s) {
  if (s == null || s.isEmpty) return [];
  return (jsonDecode(s) as List).cast<Map<String, dynamic>>();
}
