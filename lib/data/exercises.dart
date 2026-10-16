class Exercise {
  final String name;
  final String emoji;
  final double met; // Compendium of Physical Activities (moderate effort)
  final bool gym;
  final String category;
  const Exercise(this.name, this.emoji, this.met,
      {this.gym = false, this.category = 'Other'});
}

const _baseExercises = <Exercise>[
  Exercise('Brisk Walk', '🚶', 4.3),
  Exercise('Morning Walk', '🌄', 3.5),
  Exercise('Jogging', '🏃', 7.0),
  Exercise('Running', '💨', 9.8),
  Exercise('Cycling', '🚴', 7.5),
  Exercise('Swimming', '🏊', 6.0),
  Exercise('Yoga', '🧘', 2.5),
  Exercise('Surya Namaskar', '🌞', 3.3),
  Exercise('Weight Training', '🏋️', 5.0),
  Exercise('Bodyweight / Calisthenics', '🤸', 4.5),
  Exercise('HIIT', '⚡', 8.0),
  Exercise('Skipping Rope', '🪢', 11.8),
  Exercise('Zumba / Dance', '💃', 6.5),
  Exercise('Badminton', '🏸', 5.5),
  Exercise('Cricket', '🏏', 4.8),
  Exercise('Football', '⚽', 8.0),
  Exercise('Kabaddi', '🤼', 7.0),
  Exercise('Stair Climbing', '🪜', 8.0),
  Exercise('Pilates / Stretching', '🧎', 3.0),
  Exercise('Household Work', '🧹', 3.3),
  // Gym / strength training
  Exercise('Treadmill Walk', '🏃', 4.3, gym: true),
  Exercise('Treadmill Run', '🏃', 9.8, gym: true),
  Exercise('Incline Treadmill', '⛰️', 6.0, gym: true),
  Exercise('Cross Trainer / Elliptical', '🦵', 5.0, gym: true),
  Exercise('Rowing Machine', '🚣', 7.0, gym: true),
  Exercise('Stationary Bike', '🚴', 6.8, gym: true),
  Exercise('Bench Press', '🏋️', 5.0, gym: true),
  Exercise('Chest Press', '💪', 5.0, gym: true),
  Exercise('Lat Pulldown', '🏋️', 4.5, gym: true),
  Exercise('Seated Cable Row', '💪', 4.5, gym: true),
  Exercise('Shoulder Press', '🏋️', 5.0, gym: true),
  Exercise('Bicep Curls', '💪', 3.5, gym: true),
  Exercise('Tricep Pushdown', '💪', 3.5, gym: true),
  Exercise('Barbell Squats', '🏋️', 6.0, gym: true),
  Exercise('Deadlift', '🏋️', 6.0, gym: true),
  Exercise('Leg Press', '🦵', 5.0, gym: true),
  Exercise('Leg Extension / Curl', '🦵', 4.0, gym: true),
  Exercise('Push-ups', '💪', 3.8, gym: true),
  Exercise('Pull-ups / Chin-ups', '🏋️', 8.0, gym: true),
  Exercise('Plank / Core Workout', '🧘', 3.5, gym: true),
  Exercise('Burpees', '⚡', 8.0, gym: true),
  Exercise('Lunges', '🦵', 5.0, gym: true),
  Exercise('Romanian Deadlift', '🏋️', 5.5, gym: true),
  Exercise('Hip Thrust', '🏋️', 5.0, gym: true),
  Exercise('Calf Raises', '🦵', 3.5, gym: true),
  Exercise('Cable Fly', '💪', 4.0, gym: true),
  Exercise('Pec Deck', '💪', 4.0, gym: true),
  Exercise('Lateral Raises', '💪', 3.5, gym: true),
  Exercise('Kettlebell Workout', '🏋️', 6.0, gym: true),
  Exercise('Battle Ropes', '〰️', 8.0, gym: true),
  Exercise('Functional Training', '🤸', 6.0, gym: true),
  Exercise('Box Jumps', '⬆️', 8.0, gym: true),
  Exercise('Spin Class', '🚴', 8.5, gym: true),
];


/// Exercise names supplied for the gym library. Search keeps this large list easy
/// to use while the MET estimate drives the same weight-based calorie formula.
const _pastedExerciseNames = <String>[
  "21s biceps curls",
  "45-degree back extension",
  "45-degree back extension (hip-focused)",
  "45-degree hip extension",
  "Ab machine crunches",
  "Ab wheel rollout",
  "Air bike",
  "Alternating dumbbell curl",
  "Ankle circles",
  "Arm circles",
  "Arnold press",
  "Assisted dips",
  "Assisted or bodyweight dips (chest-focused)",
  "Assisted pull-ups",
  "Band external rotation",
  "Band pull-aparts",
  "Banded dorsiflexion",
  "Banded lateral walks",
  "Barbell back squat",
  "Barbell bench press",
  "Barbell bent-over row",
  "Barbell hip thrust",
  "Barbell holds",
  "Barbell shrugs",
  "Barbell wrist curls",
  "Battle ropes",
  "Bayesian cable curl",
  "Bear crawl",
  "Bear crawls",
  "Behind-the-back shrugs",
  "Behind-the-back wrist curls",
  "Bench dips",
  "Bent-over dumbbell reverse fly",
  "Bicycle crunches",
  "Bird dog",
  "Bird dogs",
  "Body saw",
  "Bodyweight squats",
  "Brisk walking",
  "Bulgarian split squat",
  "Bulgarian split squats",
  "Butt kicks",
  "Cable chest fly",
  "Cable crunches",
  "Cable curl",
  "Cable external rotation",
  "Cable front raise",
  "Cable glute kickback",
  "Cable internal rotation",
  "Cable lateral raise",
  "Cable pronation and supination",
  "Cable pull-through",
  "Cable reverse fly",
  "Cable serratus punches",
  "Cable shrugs",
  "Cable woodchoppers",
  "Cable wrist curls",
  "Calf raises on a step",
  "Calf stretch",
  "Captain's chair knee raises",
  "Cat-cow",
  "Chest doorway stretch",
  "Chest-supported rear-delt raise",
  "Chest-supported row",
  "Chin-ups",
  "Clamshells",
  "Clean and press",
  "Close-grip bench press",
  "Close-grip EZ-bar curl",
  "Close-grip lat pulldown",
  "Close-grip push-ups",
  "Concentration curl",
  "Conventional deadlift",
  "Copenhagen plank",
  "Cossack squats",
  "Cross-body hammer curls",
  "Crunches",
  "Cycling",
  "Dead bug",
  "Dead bugs",
  "Dead hangs",
  "Decline bench press",
  "Decline crunches",
  "Decline dumbbell press",
  "Decline push-ups",
  "Diamond push-ups",
  "Donkey calf raises",
  "Drag curl",
  "Dumbbell bench press",
  "Dumbbell curl",
  "Dumbbell floor press",
  "Dumbbell fly",
  "Dumbbell hip thrust",
  "Dumbbell lateral raise",
  "Dumbbell pronation",
  "Dumbbell Romanian deadlift",
  "Dumbbell shoulder press",
  "Dumbbell shrugs",
  "Dumbbell supination",
  "Dumbbell wrist curls",
  "Easy treadmill walk",
  "Elliptical trainer",
  "EZ-bar curl",
  "EZ-bar skull crushers",
  "Face pulls",
  "Farmer's carries",
  "Farmer's carry",
  "Farmer's walk",
  "Fire hydrants",
  "Forward lunges",
  "Four-way neck resistance with a band or harness",
  "Frog pumps",
  "Front dumbbell raise",
  "Front plank",
  "Front squat",
  "Gentle wrist mobility",
  "Glute bridge",
  "Glute bridges",
  "Glute-ham raise",
  "Goblet squat",
  "Good mornings",
  "Hack squat",
  "Hammer curls",
  "Hammer rotations",
  "Hamstring stretch",
  "Hand gripper squeezes",
  "Hanging knee raises",
  "Hanging leg raises",
  "Hanging oblique knee raises",
  "Heavy dumbbell holds",
  "Heel touches",
  "Heel walking",
  "Heel-elevated squat",
  "High cable curl",
  "High cable rows",
  "High knees",
  "High-to-low cable fly",
  "High-to-low cable rotations",
  "Hiking",
  "Hip circles",
  "Hip flexor stretch",
  "Hollow holds",
  "Hollow-body hold",
  "Incline barbell press",
  "Incline dumbbell curl",
  "Incline dumbbell press",
  "Incline machine chest press",
  "Incline push-ups",
  "Incline Smith machine press",
  "Incline treadmill walking",
  "Incline triceps extension",
  "Inverted row",
  "Inverted rows",
  "Jackknife sit-ups",
  "JM press",
  "Jogging",
  "Jogging outdoors",
  "Jump rope",
  "Jump squats",
  "Jumping jacks",
  "Kettlebell deadlift",
  "Kettlebell swings",
  "Kneeling cable leg curl",
  "Landmine rotations",
  "Lat pulldown",
  "Lat stretch",
  "Lateral lunges",
  "Lateral step-ups",
  "Leaning cable lateral raise",
  "Leg extension",
  "Leg press",
  "Leg press calf raises",
  "Leg raises",
  "Leg swings",
  "Light band pull-aparts",
  "Low-to-high cable fly",
  "Low-to-high cable rotations",
  "Low-trap raises",
  "Lunges",
  "Lying dumbbell triceps extension",
  "Lying leg curl",
  "Lying leg raises",
  "Machine biceps curl",
  "Machine chest press",
  "Machine glute kickback",
  "Machine lateral raise",
  "Machine row",
  "Machine shoulder press",
  "Meadows row",
  "Medicine-ball chest pass",
  "Medicine-ball slams",
  "Mountain climbers",
  "Neck extension",
  "Neck flexion",
  "Neck isometric holds",
  "Neck lateral flexion",
  "Neutral-grip pulldown",
  "Neutral-grip pull-ups",
  "Nordic hamstring curl",
  "One-arm dumbbell row",
  "Overhead cable triceps extension",
  "Pallof press",
  "Parallel-bar dips",
  "Partial lateral raises (controlled)",
  "Pec deck fly",
  "Plank shoulder taps",
  "Planks",
  "Plate front raise",
  "Plate pinches",
  "Power cleans",
  "Preacher curl",
  "Prone T-raises",
  "Prone W-raises",
  "Prone Y-raises",
  "Pull-ups",
  "Push-up plus",
  "Push-ups",
  "Rack pull",
  "Rear-delt machine fly",
  "Recumbent cycling",
  "Reverse barbell curls",
  "Reverse cable curls",
  "Reverse crunches",
  "Reverse EZ-bar curls",
  "Reverse hyperextension",
  "Reverse lunges",
  "Reverse pec deck",
  "Reverse wrist curls",
  "Reverse-grip pushdown",
  "Romanian deadlift",
  "Rope hammer curls",
  "Rope triceps pushdown",
  "Rowing machine",
  "Running",
  "Russian twists",
  "Sandbag carries",
  "Scapular push-ups",
  "Seated cable row",
  "Seated calf raises",
  "Seated dumbbell curl",
  "Seated dumbbell overhead extension",
  "Seated hip abductor machine",
  "Seated hip adductor machine",
  "Seated lateral raise",
  "Seated leg curl",
  "Seated shoulder press",
  "Serratus punches",
  "Shadow boxing",
  "Shoulder controlled rotations",
  "Side bends on cable",
  "Side bends with dumbbells",
  "Side plank",
  "Side planks",
  "Side-lying hip adduction",
  "Side-lying leg raises",
  "Single-arm cable pushdown",
  "Single-arm overhead cable extension",
  "Single-leg calf raises",
  "Single-leg extension",
  "Single-leg glute bridge",
  "Single-leg glute bridge with band",
  "Single-leg Romanian deadlift",
  "Single-leg squats (progressions)",
  "Sissy squat",
  "Sit-ups",
  "Ski ergometer",
  "Sled pull",
  "Sled push",
  "Smith machine bench press",
  "Smith machine calf raises",
  "Smith machine hip thrust",
  "Smith machine row",
  "Smith machine shrugs",
  "Smith machine squat",
  "Snatch variations",
  "Spanish squat",
  "Spider curl",
  "Split squats",
  "Sports such as badminton or football",
  "Stability-ball rollout",
  "Stair climber / stepper",
  "Standard push-ups",
  "Standing barbell curl",
  "Standing cable hip abduction",
  "Standing cable hip adduction",
  "Standing calf raises",
  "Standing overhead press",
  "Standing single-leg curl",
  "Stationary cycling",
  "Stationary cycling at low resistance",
  "Step-ups",
  "Stiff-leg deadlift",
  "Straight-arm cable pulldown",
  "Straight-bar pushdown",
  "Suitcase carry",
  "Sumo squat",
  "Superman",
  "Swimming",
  "T-bar row",
  "Thoracic rotations",
  "Thrusters",
  "Tibialis raise machine",
  "Tibialis raises against a wall",
  "Toe raises",
  "Toe touches",
  "Towel hangs",
  "Trap-3 raises",
  "Trap-bar deadlift",
  "Treadmill walking",
  "Turkish get-up",
  "Underhand pulldown",
  "Upright rows",
  "V-bar pushdown",
  "V-ups",
  "Walking",
  "Walking lunges",
  "Wall push-ups",
  "Wall sit",
  "Wall sits",
  "Wall slides",
  "Weighted push-ups",
  "Wide-grip barbell curl",
  "Wide-grip push-ups",
  "Wide-stance leg press",
  "Windshield wipers",
  "World's greatest stretch",
  "Wrist curls",
  "Wrist roller",
  "Wrist-to-elbow cable curls",
  "Zottman curls",
];

final List<Exercise> exercises = _deduplicateExercises([
  for (final exercise in _baseExercises)
    Exercise(exercise.name, exercise.emoji, exercise.met,
        gym: exercise.gym, category: _exerciseCategory(exercise.name)),
  for (final name in _pastedExerciseNames)
    Exercise(name, _exerciseEmoji(name), _estimatedMet(name),
        gym: true, category: _exerciseCategory(name)),
]);

const exerciseCategories = <String>[
  'Chest', 'Back', 'Shoulders', 'Traps', 'Biceps', 'Triceps',
  'Forearms & Grip', 'Quads', 'Hamstrings', 'Glutes', 'Calves',
  'Core & Abs', 'Neck', 'Full Body', 'Cardio', 'Mobility & Recovery', 'Sports',
];

String _exerciseCategory(String name) {
  final value = name.toLowerCase();
  if (value.contains('walk') || value.contains('run') || value.contains('jog') ||
      value.contains('cycling') || value.contains('bike') || value.contains('swim') ||
      value.contains('elliptical') || value.contains('rower') || value.contains('ski erg') ||
      value.contains('stair climber') || value.contains('jump rope')) return 'Cardio';
  if (value.contains('badminton') || value.contains('cricket') || value.contains('football') ||
      value.contains('kabaddi')) return 'Sports';
  if (value.contains('stretch') || value.contains('mobility') || value.contains('cat-cow') ||
      value.contains('arm circles') || value.contains('hip circles') || value.contains('ankle circles') ||
      value.contains('leg swings') || value.contains('yoga')) return 'Mobility & Recovery';
  if (value.contains('neck')) return 'Neck';
  if (value.contains('curl') || value.contains('bicep') || value.contains('zottman') ||
      value.contains('bayesian') || value.contains('concentration')) return 'Biceps';
  if (value.contains('tricep') || value.contains('pushdown') || value.contains('skull') ||
      value.contains('jm press')) return 'Triceps';
  if (value.contains('shrug') || value.contains('upright row') || value.contains('trap-')) return 'Traps';
  if (value.contains('wrist') || value.contains('grip') || value.contains('farmer') ||
      value.contains('hang') || value.contains('pronation') || value.contains('supination') ||
      value.contains('pinch')) return 'Forearms & Grip';
  if (value.contains('shoulder') || value.contains('delt') || value.contains('lateral raise') ||
      value.contains('arnold') || value.contains('face pull') || value.contains('rotator')) return 'Shoulders';
  if (value.contains('bench') || value.contains('chest') || value.contains('pec') ||
      value.contains('cable fly') || value.contains('dumbbell fly')) return 'Chest';
  if (value.contains('pulldown') || value.contains('pull-up') || value.contains('chin-up') ||
      value.contains(' row') || value.startsWith('row') || value.contains('back extension') ||
      value.contains('superman')) return 'Back';
  if (value.contains('calf') || value.contains('tibialis') || value.contains('toe raise')) return 'Calves';
  if (value.contains('hamstring') || value.contains('leg curl') || value.contains('romanian') ||
      value.contains('good morning') || value.contains('nordic')) return 'Hamstrings';
  if (value.contains('glute') || value.contains('hip thrust') || value.contains('kickback') ||
      value.contains('frog pump')) return 'Glutes';
  if (value.contains('squat') || value.contains('leg press') || value.contains('lunge') ||
      value.contains('leg extension') || value.contains('step-up')) return 'Quads';
  if (value.contains('crunch') || value.contains('plank') || value.contains('sit-up') ||
      value.contains('leg raise') || value.contains('core') || value.contains('russian twist') ||
      value.contains('pallof') || value.contains('dead bug')) return 'Core & Abs';
  if (value.contains('deadlift') || value.contains('kettlebell') || value.contains('sled') ||
      value.contains('battle rope') || value.contains('clean') || value.contains('snatch') ||
      value.contains('thruster') || value.contains('burpee')) return 'Full Body';
  return 'Full Body';
}

List<Exercise> _deduplicateExercises(List<Exercise> source) {
  final byName = <String, Exercise>{};
  for (final exercise in source) {
    byName.putIfAbsent(exercise.name.toLowerCase(), () => exercise);
  }
  return List.unmodifiable(byName.values);
}

String _exerciseEmoji(String name) {
  final value = name.toLowerCase();
  if (value.contains('walk') || value.contains('run') || value.contains('jog')) {
    return '🏃';
  }
  if (value.contains('cycle') || value.contains('bike')) return '🚴';
  if (value.contains('core') || value.contains('plank') || value.contains('crunch')) {
    return '🧘';
  }
  if (value.contains('stretch') || value.contains('mobility') || value.contains('yoga')) {
    return '🤸';
  }
  return '🏋️';
}

double _estimatedMet(String name) {
  final value = name.toLowerCase();
  // Closest Adult Compendium activity values for cardio modalities.
  if (value.contains('running')) return 9.8;
  if (value.contains('jogging')) return 7.0;
  if (value.contains('brisk walk')) return 4.8;
  if (value.contains('walk')) return 3.5;
  if (value.contains('jump rope')) return 12.3;
  if (value.contains('cycling') || value.contains('bike')) return 6.8;
  if (value.contains('rowing')) return 4.8;
  if (value.contains('elliptical')) return 5.0;
  if (value.contains('stair climber')) return 8.8;
  if (value.contains('swim')) return 6.0;
  if (value.contains('stretch') ||
      value.contains('mobility') ||
      value.contains('circles') ||
      value.contains('cat-cow') ||
      value.contains('wall slides')) {
    return 2.3;
  }
  if (value.contains('run') ||
      value.contains('jog') ||
      value.contains('jump') ||
      value.contains('rope') ||
      value.contains('burpee') ||
      value.contains('mountain climber') ||
      value.contains('sled') ||
      value.contains('battle rope') ||
      value.contains('clean') ||
      value.contains('snatch')) {
    return 6.0;
  }
  if (value.contains('squat') ||
      value.contains('deadlift') ||
      value.contains('press') ||
      value.contains('pull-up') ||
      value.contains('chin-up') ||
      value.contains('pulldown') ||
      value.contains('bench') ||
      value.contains('lunge') ||
      value.contains('thruster') ||
      value.contains('kettlebell')) {
    return 4.3;
  }
  if (value.contains('plank') ||
      value.contains('crunch') ||
      value.contains('sit-up') ||
      value.contains('leg raise') ||
      value.contains('core')) {
    return 3.5;
  }
  // 4.3 is the Compendium's multiple-resistance-exercise, 8–15 rep value.
  return 4.3;
}


const intensities = <String, double>{
  'Light': 0.8,
  'Moderate': 1.0,
  'Intense': 1.25,
};

/// Standard MET estimate: kcal/min = MET × 3.5 × body-weight(kg) / 200.
/// This is an estimate; machine readings and real energy expenditure vary.
double caloriesBurned({
  required double met,
  required double weightKg,
  required double minutes,
  required String intensity,
}) =>
    met * 3.5 * weightKg / 200 * minutes * (intensities[intensity] ?? 1.0);
