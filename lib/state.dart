import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/foods.dart';
import 'models.dart';
import 'notifications.dart';

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

class AppState extends ChangeNotifier {
  late SharedPreferences _prefs;
  bool loaded = false;
  bool lightMode = false;

  Profile profile = Profile();
  bool onboarded = false;
  List<DietEntry> diet = [];
  /// Global foods downloaded from the backend. Built-in foods remain an
  /// offline fallback while this catalogue is refreshed in the background.
  List<FoodItem> catalogFoods = [];
  List<FoodItem> customFoods = [];
  List<WorkoutEntry> workouts = [];
  List<WeightEntry> weightLogs = [];
  List<Reminder> reminders = [];
  DateTime selectedDate = DateTime.now();

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs.getString('profile');
    if (p != null) {
      profile = Profile.fromJson(jsonDecode(p) as Map<String, dynamic>);
    }
    onboarded = _prefs.getBool('onboarded') ?? false;
    lightMode = _prefs.getBool('light_mode') ?? false;
    diet = decodeList(_prefs.getString('diet')).map(DietEntry.fromJson).toList();
    customFoods = decodeList(_prefs.getString('custom_foods'))
        .map(_customFoodFromJson)
        .toList();
    catalogFoods = decodeList(_prefs.getString('catalog_foods'))
        .map(FoodItem.fromCatalogJson)
        .toList();
    workouts = decodeList(_prefs.getString('workouts'))
        .map(WorkoutEntry.fromJson)
        .toList();
    weightLogs = decodeList(_prefs.getString('weight_logs'))
        .map(WeightEntry.fromJson)
        .toList();
    reminders = decodeList(_prefs.getString('reminders'))
        .map(Reminder.fromJson)
        .toList();
    loaded = true;
    notifyListeners();
    NotificationService.instance
        .init()
        .then((_) => NotificationService.instance.rescheduleAll(reminders));
  }

  // ── persistence
  Future<void> _saveProfile() async {
    await _prefs.setString('profile', jsonEncode(profile.toJson()));
  }

  Future<void> _saveDiet() =>
      _prefs.setString('diet', encodeList(diet.map((e) => e.toJson()).toList()));
  Future<void> _saveCustomFoods() => _prefs.setString('custom_foods',
      encodeList(customFoods.map(_customFoodToJson).toList()));
  Future<void> _saveCatalogFoods() => _prefs.setString(
      'catalog_foods', encodeList(catalogFoods.map((food) => food.toCatalogJson()).toList()));
  Future<void> _saveWorkouts() => _prefs.setString(
      'workouts', encodeList(workouts.map((e) => e.toJson()).toList()));
  Future<void> _saveWeightLogs() => _prefs.setString(
      'weight_logs', encodeList(weightLogs.map((e) => e.toJson()).toList()));
  Future<void> _saveReminders() => _prefs.setString(
      'reminders', encodeList(reminders.map((e) => e.toJson()).toList()));

  /// Complete user-owned payload for the authenticated cloud backup.
  Map<String, dynamic> cloudSnapshot() => {
        'onboarded': onboarded,
        'profile': profile.toJson(),
        'diet': diet.map((entry) => entry.toJson()).toList(),
        'workouts': workouts.map((entry) => entry.toJson()).toList(),
        'weightLogs': weightLogs.map((entry) => entry.toJson()).toList(),
        'customFoods': customFoods.map(_customFoodToJson).toList(),
        'reminders': reminders.map((entry) => entry.toJson()).toList(),
      };

  /// Applies the cloud backup. During first sign-in, [preserveLocal] prevents
  /// records created offline on this device from being erased by an older
  /// server snapshot.
  Future<void> applyCloudSnapshot(
    Map<String, dynamic> cloud, {
    bool preserveLocal = false,
  }) async {
    final hadLocalProfile = onboarded;
    onboarded = preserveLocal
        ? (onboarded || cloud['onboarded'] == true)
        : cloud['onboarded'] == true;
    final remoteProfile = cloud['profile'];
    if (remoteProfile is Map<String, dynamic> &&
        remoteProfile.isNotEmpty &&
        (!preserveLocal || !hadLocalProfile)) {
      profile = Profile.fromJson(remoteProfile);
    }
    final remoteDiet = _maps(cloud['diet']).map(DietEntry.fromJson).toList();
    final remoteWorkouts = _maps(cloud['workouts']).map(WorkoutEntry.fromJson).toList();
    final remoteWeights = _maps(cloud['weightLogs']).map(WeightEntry.fromJson).toList();
    final remoteFoods = _maps(cloud['customFoods']).map(_customFoodFromJson).toList();
    final remoteReminders = _maps(cloud['reminders']).map(Reminder.fromJson).toList();

    if (preserveLocal) {
      diet = _mergeByKey(remoteDiet, diet, (entry) => entry.id);
      workouts = _mergeByKey(remoteWorkouts, workouts, (entry) => entry.id);
      weightLogs = _mergeByKey(remoteWeights, weightLogs,
          (entry) => '${entry.date.year}-${entry.date.month}-${entry.date.day}')
        ..sort((a, b) => a.date.compareTo(b.date));
      customFoods = _mergeByKey(remoteFoods, customFoods,
          (food) => food.name.trim().toLowerCase());
      reminders = _mergeByKey(remoteReminders, reminders, (entry) => entry.id);
    } else {
      diet = remoteDiet;
      workouts = remoteWorkouts;
      weightLogs = remoteWeights;
      customFoods = remoteFoods;
      reminders = remoteReminders;
    }
    await Future.wait([
      _saveProfile(), _saveDiet(), _saveWorkouts(), _saveWeightLogs(),
      _saveCustomFoods(), _saveReminders(),
    ]);
    await _prefs.setBool('onboarded', onboarded);
    // Cloud-only alerts must be scheduled on this device after a sign-in too.
    await NotificationService.instance.rescheduleAll(reminders);
    notifyListeners();
  }

  List<Map<String, dynamic>> _maps(dynamic value) => (value as List? ?? const [])
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();

  /// Local values are placed last deliberately: a freshly saved device value
  /// wins when it has the same identity as a stale cloud value.
  List<T> _mergeByKey<T>(
    List<T> remote,
    List<T> local,
    Object Function(T item) key,
  ) {
    final merged = <Object, T>{};
    for (final item in remote) {
      merged[key(item)] = item;
    }
    for (final item in local) {
      merged[key(item)] = item;
    }
    return merged.values.toList();
  }

  // ── date
  void selectDate(DateTime d) {
    selectedDate = DateTime(d.year, d.month, d.day);
    notifyListeners();
  }

  Future<void> setLightMode(bool value) async {
    if (lightMode == value) return;
    lightMode = value;
    await _prefs.setBool('light_mode', value);
    notifyListeners();
  }

  // ── profile / targets
  void updateProfile(void Function(Profile p) edit) {
    edit(profile);
    _saveProfile();
    notifyListeners();
  }

  void finishOnboarding() {
    onboarded = true;
    _prefs.setBool('onboarded', true);
    _saveProfile();
    notifyListeners();
  }

  // ── diet
  List<DietEntry> dietOn(DateTime d) =>
      diet.where((e) => sameDay(e.time, d)).toList()
        ..sort((a, b) => a.time.compareTo(b.time));

  Nutrition totalsOn(DateTime d) =>
      dietOn(d).fold(Nutrition.zero, (s, e) => s + e.n);

  void addFood({
    required FoodItem food,
    required double qty,
    required CookStyle style,
    required MealType meal,
  }) {
    final now = DateTime.now();
    final d = selectedDate;
    final t = DateTime(d.year, d.month, d.day, now.hour, now.minute, now.second);
    final qtyTxt = qty == qty.roundToDouble()
        ? qty.toInt().toString()
        : qty.toStringAsFixed(1);
    final grams = qty * 100;
    final gramsTxt = grams == grams.roundToDouble()
        ? grams.toInt().toString()
        : grams.toStringAsFixed(1);
    diet.add(DietEntry(
      id: '${now.microsecondsSinceEpoch}',
      time: t,
      meal: meal,
      name: food.name,
      detail: food.weightBased == true
          ? '$gramsTxt g'
          : '$qtyTxt × ${food.unit}${food.styles.length > 1 || food.oil > 0 ? ' · ${style.label}' : ''}',
      n: food.calc(qty, style),
    ));
    _saveDiet();
    notifyListeners();
  }

  void removeDiet(String id) {
    diet.removeWhere((e) => e.id == id);
    _saveDiet();
    notifyListeners();
  }

  /// Saves a custom item once so it is available in future food searches.
  void saveCustomFood(FoodItem food) {
    if (!food.custom) return;
    customFoods.removeWhere((item) =>
        item.name.trim().toLowerCase() == food.name.trim().toLowerCase());
    customFoods.insert(0, food);
    _saveCustomFoods();
    notifyListeners();
  }

  /// Replaces the locally cached global food catalogue with the backend's
  /// active list. The list is persisted so food search still works offline.
  Future<void> replaceCatalogFoods(List<FoodItem> foods) async {
    catalogFoods = foods;
    await _saveCatalogFoods();
    notifyListeners();
  }

  Map<String, dynamic> _customFoodToJson(FoodItem food) => {
        'name': food.name,
        'hindi': food.hindi,
        'unit': food.unit,
        'cat': food.cat,
        'kcal': food.kcal,
        'p': food.p,
        'c': food.c,
        'f': food.f,
        'oil': food.oil,
        'styles': food.styles.map((style) => style.index).toList(),
        'default': food.defaultStyle.index,
        'weightBased': food.weightBased,
        'recipeIngredients': food.recipeIngredients,
        'recipeYield': food.recipeYield,
        'recipeByWeight': food.recipeByWeight,
      };

  FoodItem _customFoodFromJson(Map<String, dynamic> json) {
    final styleIndexes = (json['styles'] as List? ?? [CookStyle.plain.index])
        .whereType<num>()
        .map((value) => CookStyle.values[value.toInt()])
        .toList();
    final styles = styleIndexes.isEmpty ? [CookStyle.plain] : styleIndexes;
    final defaultIndex = (json['default'] as num?)?.toInt() ?? styles.first.index;
    return FoodItem(
      name: json['name'] as String? ?? 'Custom food',
      hindi: json['hindi'] as String? ?? 'custom',
      unit: json['unit'] as String? ?? '1 serving',
      cat: json['cat'] as String? ?? 'Custom',
      kcal: (json['kcal'] as num?)?.toDouble() ?? 0,
      p: (json['p'] as num?)?.toDouble() ?? 0,
      c: (json['c'] as num?)?.toDouble() ?? 0,
      f: (json['f'] as num?)?.toDouble() ?? 0,
      oil: (json['oil'] as num?)?.toDouble() ?? 0,
      styles: styles,
      defaultStyle: CookStyle.values[defaultIndex.clamp(0, CookStyle.values.length - 1)],
      custom: true,
      weightBased: json['weightBased'] == true,
      recipeIngredients: (json['recipeIngredients'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(),
      recipeYield: (json['recipeYield'] as num?)?.toDouble(),
      recipeByWeight: json['recipeByWeight'] == true,
    );
  }

  // ── workouts
  List<WorkoutEntry> workoutsOn(DateTime d) =>
      workouts.where((e) => sameDay(e.time, d)).toList()
        ..sort((a, b) => a.time.compareTo(b.time));

  double burnedOn(DateTime d) =>
      workoutsOn(d).where((w) => w.done).fold(0.0, (s, w) => s + w.kcal);

  void addWorkout(WorkoutEntry w) {
    workouts.add(w);
    _saveWorkouts();
    notifyListeners();
  }

  void removeWorkout(String id) {
    workouts.removeWhere((e) => e.id == id);
    _saveWorkouts();
    notifyListeners();
  }

  // â”€â”€ body weight
  WeightEntry? weightOn(DateTime date) {
    for (final entry in weightLogs) {
      if (sameDay(entry.date, date)) return entry;
    }
    return null;
  }

  void logWeight(DateTime date, double kg) {
    final day = DateTime(date.year, date.month, date.day);
    weightLogs.removeWhere((entry) => sameDay(entry.date, day));
    weightLogs.add(WeightEntry(date: day, kg: kg));
    weightLogs.sort((a, b) => a.date.compareTo(b.date));
    // The newest reading remains the active profile weight for calorie estimates.
    if (sameDay(day, DateTime.now())) profile.weightKg = kg;
    _saveWeightLogs();
    _saveProfile();
    notifyListeners();
  }

  // ── reminders
  Future<void> upsertReminder(Reminder r) async {
    final i = reminders.indexWhere((e) => e.id == r.id);
    if (i >= 0) {
      reminders[i] = r;
    } else {
      reminders.add(r);
    }
    await _saveReminders();
    notifyListeners();
    await NotificationService.instance.schedule(r);
  }

  Future<void> removeReminder(Reminder r) async {
    reminders.removeWhere((e) => e.id == r.id);
    await _saveReminders();
    notifyListeners();
    await NotificationService.instance.cancel(r);
  }

  int newReminderId() =>
      (DateTime.now().millisecondsSinceEpoch ~/ 1000) % 100000000;

  TimeOfDay reminderTime(Reminder r) => TimeOfDay(hour: r.hour, minute: r.minute);
}
