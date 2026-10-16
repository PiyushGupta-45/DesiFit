import 'package:flutter/material.dart';
import 'models.dart';

const List<CookingStyle> kStyles = [
  CookingStyle('dry', 'Dry roasted (tawa)', 'No added fat', 0, Icons.local_fire_department_rounded),
  CookingStyle('boiled', 'Boiled / Steamed', 'No added fat', 0, Icons.water_drop_rounded),
  CookingStyle('asis', 'As is / ready-made', 'Values used as listed', 0, Icons.restaurant_rounded),
  CookingStyle('tandoor', 'Tandoor / Grilled', '≈2 g oil per 100 g', 2, Icons.outdoor_grill_rounded),
  CookingStyle('light', 'Light tadka (1 tsp oil)', '≈3 g oil per 100 g', 3, Icons.soup_kitchen_rounded),
  CookingStyle('home', 'Home-style (normal oil)', '≈6 g oil per 100 g', 6, Icons.home_rounded),
  CookingStyle('shallow', 'Shallow / pan fried', '≈7 g oil per 100 g', 7, Icons.egg_alt_rounded),
  CookingStyle('ghee', 'Ghee roasted / tadka', '≈9 g ghee per 100 g', 9, Icons.opacity_rounded),
  CookingStyle('dhaba', 'Dhaba / Restaurant', '≈12 g butter, oil & cream per 100 g', 12, Icons.storefront_rounded),
  CookingStyle('fried', 'Deep fried', '≈14 g absorbed oil per 100 g', 14, Icons.whatshot_rounded),
];

CookingStyle styleById(String id) =>
    kStyles.firstWhere((s) => s.id == id, orElse: () => kStyles[2]);

// id, name, hindi, category, unit, unitGrams, protein, carbs, fat (per 100 g), defaultStyle
const List<FoodItem> kFoods = [
  // Breads
  FoodItem('roti', 'Roti / Chapati', 'रोटी', 'Breads', 'roti', 40, 9.5, 48, 1.5, 'dry'),
  FoodItem('phulka', 'Phulka', 'फुल्का', 'Breads', 'phulka', 30, 9.5, 48, 1.2, 'dry'),
  FoodItem('paratha', 'Paratha (plain)', 'पराठा', 'Breads', 'paratha', 70, 7, 42, 2, 'shallow'),
  FoodItem('aloo_paratha', 'Aloo Paratha', 'आलू पराठा', 'Breads', 'paratha', 100, 5.5, 35, 2, 'shallow'),
  FoodItem('naan', 'Naan', 'नान', 'Breads', 'naan', 90, 9, 50, 4, 'tandoor'),
  FoodItem('puri', 'Puri', 'पूरी', 'Breads', 'puri', 30, 8, 45, 2, 'fried'),
  FoodItem('bhatura', 'Bhatura', 'भटूरा', 'Breads', 'bhatura', 80, 8, 47, 3, 'fried'),
  // Rice
  FoodItem('rice', 'Steamed Rice', 'चावल', 'Rice', 'katori', 150, 2.7, 28, 0.3, 'boiled'),
  FoodItem('jeera_rice', 'Jeera Rice', 'जीरा राइस', 'Rice', 'katori', 150, 2.9, 28, 0.5, 'light'),
  FoodItem('veg_pulao', 'Veg Pulao', 'वेज पुलाव', 'Rice', 'katori', 150, 3, 26, 1, 'home'),
  FoodItem('chicken_biryani', 'Chicken Biryani', 'चिकन बिरयानी', 'Rice', 'plate', 250, 9, 19, 1, 'home'),
  FoodItem('khichdi', 'Dal Khichdi', 'खिचड़ी', 'Rice', 'katori', 200, 4.2, 17, 0.8, 'light'),
  // Dals
  FoodItem('toor_dal', 'Toor / Arhar Dal', 'अरहर दाल', 'Dal', 'katori', 150, 4.8, 10.5, 0.3, 'light'),
  FoodItem('moong_dal', 'Moong Dal', 'मूंग दाल', 'Dal', 'katori', 150, 5.2, 11, 0.3, 'light'),
  FoodItem('masoor_dal', 'Masoor Dal', 'मसूर दाल', 'Dal', 'katori', 150, 5.5, 11, 0.3, 'light'),
  FoodItem('chana_dal', 'Chana Dal', 'चना दाल', 'Dal', 'katori', 150, 6.5, 13, 0.6, 'home'),
  FoodItem('rajma', 'Rajma', 'राजमा', 'Dal', 'katori', 150, 6.5, 15, 0.5, 'home'),
  FoodItem('chole', 'Chole', 'छोले', 'Dal', 'katori', 150, 7, 18, 1, 'home'),
  FoodItem('dal_makhani', 'Dal Makhani', 'दाल मखनी', 'Dal', 'katori', 150, 5.5, 12, 1, 'dhaba'),
  FoodItem('sambar', 'Sambar', 'सांभर', 'Dal', 'katori', 150, 2.5, 7, 0.4, 'light'),
  // Sabzi
  FoodItem('aloo_sabzi', 'Aloo Sabzi', 'आलू की सब्ज़ी', 'Sabzi', 'katori', 120, 2, 17, 0.1, 'home'),
  FoodItem('aloo_gobi', 'Aloo Gobi', 'आलू गोभी', 'Sabzi', 'katori', 120, 2.3, 8, 0.3, 'home'),
  FoodItem('bhindi', 'Bhindi Masala', 'भिंडी', 'Sabzi', 'katori', 100, 2.2, 8, 0.3, 'home'),
  FoodItem('mixed_veg', 'Mixed Veg Sabzi', 'मिक्स वेज', 'Sabzi', 'katori', 120, 2, 7, 0.3, 'home'),
  FoodItem('baingan_bharta', 'Baingan Bharta', 'बैंगन भर्ता', 'Sabzi', 'katori', 120, 1.8, 6, 0.3, 'home'),
  FoodItem('lauki', 'Lauki Sabzi', 'लौकी', 'Sabzi', 'katori', 120, 1, 4, 0.2, 'light'),
  FoodItem('palak_paneer', 'Palak Paneer', 'पालक पनीर', 'Sabzi', 'katori', 150, 8, 4, 4, 'home'),
  FoodItem('matar_paneer', 'Matar Paneer', 'मटर पनीर', 'Sabzi', 'katori', 150, 8, 7, 5, 'home'),
  FoodItem('paneer_butter', 'Paneer Butter Masala', 'पनीर बटर मसाला', 'Sabzi', 'katori', 150, 9, 6, 6, 'dhaba'),
  // Protein
  FoodItem('paneer', 'Paneer (plain)', 'पनीर', 'Protein', '50 g serving', 50, 18, 1.2, 20, 'asis'),
  FoodItem('egg', 'Egg', 'अंडा', 'Protein', 'egg', 50, 12.6, 1.1, 10.6, 'boiled'),
  FoodItem('chicken_curry', 'Chicken Curry', 'चिकन करी', 'Protein', 'katori', 150, 18, 3, 3, 'home'),
  FoodItem('tandoori_chicken', 'Chicken Tikka / Tandoori', 'चिकन टिक्का', 'Protein', '100 g serving', 100, 27, 2, 4, 'tandoor'),
  FoodItem('fish_curry', 'Fish Curry', 'फिश करी', 'Protein', 'katori', 150, 15, 3, 3, 'home'),
  FoodItem('soya', 'Soya Chunks (cooked)', 'सोया चंक्स', 'Protein', '100 g serving', 100, 16, 10, 0.5, 'light'),
  FoodItem('sprouts', 'Moong Sprouts', 'अंकुरित मूंग', 'Protein', 'katori', 100, 6, 9, 0.5, 'boiled'),
  FoodItem('whey', 'Whey Protein', 'व्हे प्रोटीन', 'Protein', 'scoop', 30, 80, 8, 6, 'asis'),
  // Breakfast / South Indian
  FoodItem('idli', 'Idli', 'इडली', 'Breakfast', 'idli', 40, 4, 24, 0.3, 'boiled'),
  FoodItem('dosa', 'Plain Dosa', 'डोसा', 'Breakfast', 'dosa', 90, 3.5, 24, 1, 'light'),
  FoodItem('masala_dosa', 'Masala Dosa', 'मसाला डोसा', 'Breakfast', 'dosa', 180, 3.5, 24, 1.5, 'shallow'),
  FoodItem('uttapam', 'Uttapam', 'उत्तपम', 'Breakfast', 'uttapam', 120, 4, 22, 1, 'light'),
  FoodItem('poha', 'Poha', 'पोहा', 'Breakfast', 'plate', 150, 2.6, 22, 0.5, 'light'),
  FoodItem('upma', 'Upma', 'उपमा', 'Breakfast', 'plate', 150, 3, 18, 0.8, 'light'),
  FoodItem('besan_chilla', 'Besan Chilla', 'बेसन चीला', 'Breakfast', 'chilla', 70, 10, 17, 2, 'shallow'),
  FoodItem('dhokla', 'Dhokla', 'ढोकला', 'Breakfast', 'piece', 40, 6, 24, 3.5, 'asis'),
  FoodItem('oats', 'Oats Porridge', 'ओट्स', 'Breakfast', 'katori', 150, 3, 12, 1.5, 'asis'),
  // Snacks
  FoodItem('samosa', 'Samosa', 'समोसा', 'Snacks', 'samosa', 60, 4.5, 28, 2, 'fried'),
  FoodItem('pakora', 'Pakora / Bhajiya', 'पकोड़ा', 'Snacks', 'piece', 25, 6, 18, 1, 'fried'),
  FoodItem('vada_pav', 'Vada Pav', 'वड़ा पाव', 'Snacks', 'vada pav', 130, 5.5, 33, 8, 'asis'),
  FoodItem('bhel', 'Bhel Puri', 'भेल पूरी', 'Snacks', 'plate', 120, 3.5, 28, 4, 'asis'),
  FoodItem('roasted_chana', 'Roasted Chana', 'भुना चना', 'Snacks', 'handful', 30, 19, 58, 5, 'asis'),
  // Dairy & drinks
  FoodItem('dahi', 'Curd (Dahi)', 'दही', 'Dairy', 'katori', 100, 3.5, 4.7, 3.3, 'asis'),
  FoodItem('raita', 'Raita', 'रायता', 'Dairy', 'katori', 100, 3, 5, 2.5, 'asis'),
  FoodItem('milk', 'Milk', 'दूध', 'Dairy', 'glass', 250, 3.3, 4.8, 3.5, 'asis'),
  FoodItem('lassi', 'Sweet Lassi', 'लस्सी', 'Dairy', 'glass', 250, 3, 14, 3, 'asis'),
  FoodItem('chaas', 'Chaas / Buttermilk', 'छाछ', 'Dairy', 'glass', 250, 1.2, 2, 0.8, 'asis'),
  FoodItem('chai', 'Masala Chai (milk + sugar)', 'चाय', 'Dairy', 'cup', 150, 1.5, 7, 1.7, 'asis'),
  // Sweets
  FoodItem('gulab_jamun', 'Gulab Jamun', 'गुलाब जामुन', 'Sweets', 'piece', 40, 5, 48, 10, 'asis'),
  FoodItem('jalebi', 'Jalebi', 'जलेबी', 'Sweets', 'piece', 25, 2, 65, 12, 'asis'),
  FoodItem('kheer', 'Kheer', 'खीर', 'Sweets', 'katori', 100, 3.5, 19, 4, 'asis'),
  // Fruit & nuts
  FoodItem('banana', 'Banana', 'केला', 'Fruit & Nuts', 'banana', 100, 1.1, 23, 0.3, 'asis'),
  FoodItem('apple', 'Apple', 'सेब', 'Fruit & Nuts', 'apple', 150, 0.3, 14, 0.2, 'asis'),
  FoodItem('mango', 'Mango', 'आम', 'Fruit & Nuts', 'mango', 200, 0.8, 15, 0.4, 'asis'),
  FoodItem('almonds', 'Almonds (10)', 'बादाम', 'Fruit & Nuts', '10 almonds', 12, 21, 22, 50, 'asis'),
  FoodItem('peanuts', 'Roasted Peanuts', 'मूंगफली', 'Fruit & Nuts', 'handful', 30, 26, 16, 49, 'asis'),
];

FoodItem foodById(String id) =>
    kFoods.firstWhere((f) => f.id == id, orElse: () => kFoods.first);

/// Auto-calculates macros for a portion of an Indian dish, adjusting for
/// the cooking style (extra oil / ghee / butter absorbed per 100 g).
Macros computeMacros(FoodItem food, CookingStyle style, double qty) {
  final g = food.unitGrams * qty;
  final fat = (food.f + style.extraFat) * g / 100;
  final p = food.p * g / 100;
  final c = food.c * g / 100;
  return Macros(p * 4 + c * 4 + fat * 9, p, c, fat);
}

// ---------------- Workouts ----------------

const List<WorkoutActivity> kActivities = [
  WorkoutActivity('walk', 'Brisk Walking', 4.3, Icons.directions_walk_rounded),
  WorkoutActivity('jog', 'Jogging', 7.0, Icons.directions_run_rounded),
  WorkoutActivity('run', 'Running', 9.8, Icons.speed_rounded),
  WorkoutActivity('cycle', 'Cycling', 7.5, Icons.directions_bike_rounded),
  WorkoutActivity('gym', 'Gym – Weights', 5.0, Icons.fitness_center_rounded),
  WorkoutActivity('hiit', 'HIIT', 8.0, Icons.bolt_rounded),
  WorkoutActivity('yoga', 'Yoga', 2.8, Icons.self_improvement_rounded),
  WorkoutActivity('surya', 'Surya Namaskar', 4.0, Icons.wb_sunny_rounded),
  WorkoutActivity('swim', 'Swimming', 6.0, Icons.pool_rounded),
  WorkoutActivity('badminton', 'Badminton', 5.5, Icons.sports_tennis_rounded),
  WorkoutActivity('cricket', 'Cricket', 4.8, Icons.sports_cricket_rounded),
  WorkoutActivity('football', 'Football', 7.0, Icons.sports_soccer_rounded),
  WorkoutActivity('skip', 'Skipping Rope', 11.0, Icons.sync_rounded),
  WorkoutActivity('zumba', 'Zumba / Dance', 6.0, Icons.music_note_rounded),
  WorkoutActivity('stairs', 'Stair Climbing', 8.8, Icons.stairs_rounded),
  WorkoutActivity('home', 'Home Workout', 4.5, Icons.home_rounded),
  WorkoutActivity('stretch', 'Stretching', 2.3, Icons.accessibility_new_rounded),
];

WorkoutActivity activityById(String id) =>
    kActivities.firstWhere((a) => a.id == id, orElse: () => kActivities.first);

const List<String> kIntensityLabels = ['Light', 'Moderate', 'Intense'];
const List<double> kIntensityFactor = [0.85, 1.0, 1.2];

/// Calories burned = MET × body weight (kg) × hours × intensity factor.
double caloriesBurned(WorkoutActivity a, double weightKg, int minutes, double intensity) =>
    a.met * weightKg * (minutes / 60.0) * intensity;
