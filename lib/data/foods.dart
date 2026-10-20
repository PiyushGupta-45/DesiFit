import '../models.dart';

/// Indian cooking styles. [fat] is the extra fat (grams) absorbed per serving
/// of a food whose oilFactor is 1.0 (e.g. a katori of sabzi/dal).
/// Fat has 9 kcal/g, so a ghee tadka on dal adds ~72 kcal.
enum CookStyle {
  plain('Boiled / Steamed', '♨️', 0),
  tawa('Dry roast / Tawa', '🫓', 0.5),
  tandoor('Tandoor / Grilled', '🔥', 2),
  air('Air fried', '💨', 3),
  home('Home style · 1 tsp oil', '🏠', 5),
  tadka('Ghee tadka', '🧈', 8),
  shallow('Shallow fried', '🍳', 11),
  restaurant('Restaurant · butter & cream', '🍽️', 15),
  deep('Deep fried', '🛢️', 20);

  final String label;
  final String emoji;
  final double fat;
  const CookStyle(this.label, this.emoji, this.fat);
}

class FoodItem {
  final String name;
  final String hindi;
  final String unit; // serving description
  final String cat;
  final double kcal, p, c, f; // per serving, with NO added cooking fat
  final double oil; // how much cooking fat this food soaks up (0..1.5)
  final List<CookStyle> styles;
  final CookStyle defaultStyle;
  final bool custom;
  /// True when one quantity means 100 g instead of a household serving.
  final bool weightBased;
  /// Preserved only for user-made recipes so they can be opened and edited.
  final List<Map<String, dynamic>> recipeIngredients;
  final double? recipeYield;
  final bool recipeByWeight;

  bool get isRecipe => recipeIngredients.isNotEmpty;

  const FoodItem({
    required this.name,
    required this.hindi,
    required this.unit,
    required this.cat,
    required this.kcal,
    required this.p,
    required this.c,
    required this.f,
    required this.oil,
    required this.styles,
    required this.defaultStyle,
    this.custom = false,
    this.weightBased = false,
    this.recipeIngredients = const <Map<String, dynamic>>[],
    this.recipeYield,
    this.recipeByWeight = false,
  });

  /// Wire format used by the global MongoDB food catalogue.
  factory FoodItem.fromCatalogJson(Map<String, dynamic> json) {
    final parsedStyles = (json['styles'] as List? ?? const [])
        .map(_styleFromWire)
        .whereType<CookStyle>()
        .toList();
    final styles = parsedStyles.isEmpty ? <CookStyle>[CookStyle.plain] : parsedStyles;
    final defaultStyle = _styleFromWire(json['defaultStyle']) ?? styles.first;
    return FoodItem(
      name: json['name']?.toString().trim().isNotEmpty == true
          ? json['name'].toString().trim()
          : 'Unnamed food',
      hindi: json['hindi']?.toString() ?? '',
      unit: json['unit']?.toString() ?? '1 serving',
      cat: json['cat']?.toString() ?? 'Other',
      kcal: (json['kcal'] as num?)?.toDouble() ?? 0,
      p: (json['p'] as num?)?.toDouble() ?? 0,
      c: (json['c'] as num?)?.toDouble() ?? 0,
      f: (json['f'] as num?)?.toDouble() ?? 0,
      oil: (json['oil'] as num?)?.toDouble() ?? 0,
      styles: styles,
      defaultStyle: styles.contains(defaultStyle) ? defaultStyle : styles.first,
      weightBased: json['weightBased'] == true,
    );
  }

  Map<String, dynamic> toCatalogJson() => {
        'name': name,
        'hindi': hindi,
        'unit': unit,
        'cat': cat,
        'kcal': kcal,
        'p': p,
        'c': c,
        'f': f,
        'oil': oil,
        'styles': styles.map((style) => style.name).toList(),
        'defaultStyle': defaultStyle.name,
        'weightBased': weightBased,
      };

  /// Nutrition for [qty] servings cooked in [style].
  Nutrition calc(double qty, CookStyle style) {
    final extraFat = style.fat * oil;
    return Nutrition(
      (kcal + extraFat * 9) * qty,
      p * qty,
      c * qty,
      (f + extraFat) * qty,
    );
  }
}

CookStyle? _styleFromWire(dynamic value) {
  final name = value?.toString();
  for (final style in CookStyle.values) {
    if (style.name == name) return style;
  }
  return null;
}

const _veg = [CookStyle.home, CookStyle.tadka, CookStyle.restaurant, CookStyle.plain];
const _dal = [CookStyle.plain, CookStyle.home, CookStyle.tadka, CookStyle.restaurant];
const _curry = [CookStyle.home, CookStyle.tadka, CookStyle.restaurant, CookStyle.shallow];
const _bread = [CookStyle.tawa, CookStyle.home, CookStyle.tadka, CookStyle.shallow, CookStyle.restaurant];
const _fry = [CookStyle.deep, CookStyle.shallow, CookStyle.air, CookStyle.tawa];
const _rice = [CookStyle.plain, CookStyle.home, CookStyle.tadka, CookStyle.restaurant];
const _tiffin = [CookStyle.tawa, CookStyle.home, CookStyle.shallow, CookStyle.restaurant];
const _steam = [CookStyle.plain, CookStyle.home];
const _grill = [CookStyle.tandoor, CookStyle.air, CookStyle.shallow, CookStyle.deep, CookStyle.restaurant];
const _raw = [CookStyle.plain];
const _sweet = [CookStyle.plain, CookStyle.tadka];

FoodItem _f(String name, String hindi, String unit, String cat, double kcal,
        double p, double c, double f, double oil, List<CookStyle> styles,
        [CookStyle? def, bool weightBased = false]) =>
    FoodItem(
      name: name,
      hindi: hindi,
      unit: unit,
      cat: cat,
      kcal: kcal,
      p: p,
      c: c,
      f: f,
      oil: oil,
      styles: styles,
      defaultStyle: def ?? styles.first,
      weightBased: weightBased,
    );

/// Built-in Indian food database. Values are typical per-serving averages
/// (IFCT / NIN style home portions) before added oil, ghee or butter.
final List<FoodItem> indianFoods = [
  // ── Rotis & breads
  _f('Roti / Chapati', 'रोटी', '1 medium (40 g)', 'Bread', 104, 3.1, 18, 0.7, 0.3, _bread, CookStyle.tawa),
  _f('Phulka', 'फुलका', '1 small (30 g)', 'Bread', 78, 2.4, 14, 0.5, 0.2, _bread, CookStyle.tawa),
  _f('Paratha', 'पराठा', '1 medium (80 g)', 'Bread', 170, 4.5, 30, 3.5, 0.7, _bread, CookStyle.shallow),
  _f('Aloo Paratha', 'आलू पराठा', '1 medium (110 g)', 'Bread', 210, 5, 36, 4.5, 0.8, _bread, CookStyle.shallow),
  _f('Puri', 'पूरी', '1 piece (30 g)', 'Bread', 70, 2, 12, 1, 0.4, [CookStyle.deep, CookStyle.air]),
  _f('Naan', 'नान', '1 piece (90 g)', 'Bread', 250, 8, 45, 4, 0.5, [CookStyle.tandoor, CookStyle.tadka, CookStyle.restaurant]),
  _f('Bajra Roti', 'बाजरा रोटी', '1 medium (50 g)', 'Bread', 130, 3.5, 25, 1.8, 0.3, _bread, CookStyle.tawa),
  _f('Jowar Bhakri', 'ज्वार भाखरी', '1 medium (45 g)', 'Bread', 110, 3.2, 23, 0.8, 0.3, _bread, CookStyle.tawa),
  _f('Makki Roti', 'मक्की रोटी', '1 medium (50 g)', 'Bread', 120, 3, 24, 1.5, 0.4, _bread, CookStyle.tawa),
  _f('Thepla', 'थेपला', '1 piece (45 g)', 'Bread', 95, 3, 15, 2.5, 0.6, _bread, CookStyle.home),
  _f('Missi Roti', 'मिस्सी रोटी', '1 medium (50 g)', 'Bread', 125, 5.5, 20, 2.5, 0.4, _bread, CookStyle.tawa),

  // ── Rice
  _f('Steamed Rice', 'चावल', '1 katori (150 g)', 'Rice', 195, 4, 43, 0.4, 0.2, _rice),
  _f('Jeera Rice', 'जीरा राइस', '1 katori (150 g)', 'Rice', 195, 4, 43, 0.5, 0.8, _rice, CookStyle.tadka),
  _f('Veg Pulao', 'वेज पुलाव', '1 plate (200 g)', 'Rice', 250, 5, 44, 4, 0.8, _rice, CookStyle.home),
  _f('Vegetable Biryani', 'वेज बिरयानी', '1 plate (250 g)', 'Rice', 330, 7, 55, 8, 1.0, _rice, CookStyle.restaurant),
  _f('Chicken Biryani', 'चिकन बिरयानी', '1 plate (300 g)', 'Rice', 400, 22, 50, 12, 1.1, _rice, CookStyle.restaurant),
  _f('Khichdi', 'खिचड़ी', '1 katori (200 g)', 'Rice', 200, 7, 34, 3, 0.7, _rice, CookStyle.home),
  _f('Curd Rice', 'दही चावल', '1 katori (200 g)', 'Rice', 210, 6, 34, 5, 0.3, _rice, CookStyle.plain),
  _f('Lemon Rice', 'नींबू चावल', '1 katori (150 g)', 'Rice', 215, 4, 38, 5, 0.9, _rice, CookStyle.home),

  // ── Dal & legumes
  _f('Toor / Arhar Dal', 'तूर दाल', '1 katori (150 g)', 'Dal', 110, 6.5, 18, 0.5, 1.0, _dal, CookStyle.tadka),
  _f('Moong Dal', 'मूंग दाल', '1 katori (150 g)', 'Dal', 105, 7, 17, 0.4, 1.0, _dal, CookStyle.home),
  _f('Masoor Dal', 'मसूर दाल', '1 katori (150 g)', 'Dal', 115, 8, 19, 0.5, 1.0, _dal, CookStyle.home),
  _f('Chana Dal', 'चना दाल', '1 katori (150 g)', 'Dal', 150, 9, 25, 1.5, 1.0, _dal, CookStyle.home),
  _f('Dal Tadka', 'दाल तड़का', '1 katori (150 g)', 'Dal', 112, 6.5, 18, 0.6, 1.0, _dal, CookStyle.tadka),
  _f('Dal Makhani', 'दाल मखनी', '1 katori (150 g)', 'Dal', 150, 7, 18, 5, 1.0, _dal, CookStyle.restaurant),
  _f('Rajma', 'राजमा', '1 katori (150 g)', 'Dal', 150, 8, 25, 1.5, 0.9, _curry, CookStyle.home),
  _f('Chole', 'छोले', '1 katori (150 g)', 'Dal', 170, 8, 27, 3, 0.9, _curry, CookStyle.home),
  _f('Sambar', 'सांभर', '1 katori (150 g)', 'Dal', 70, 3.5, 11, 1.5, 0.5, _dal, CookStyle.home),
  _f('Kadhi', 'कढ़ी', '1 katori (150 g)', 'Dal', 90, 3, 9, 4, 0.6, _dal, CookStyle.home),
  _f('Sprouts Salad', 'अंकुरित मूंग', '1 katori (100 g)', 'Dal', 90, 7, 15, 0.6, 0, _raw),
  _f('Soya Chunks (dry)', 'सोया चंक्स', '100 g dry', 'Dal', 345, 52, 33, 1, 0.3, _veg, CookStyle.plain, true),

  // ── Recipe-builder basics (mostly raw values per 100 g)
  
  // ── Raw vegetables & herbs
  _f('Potato (raw)', 'आलू', '100 g', 'Ingredients', 77, 2, 17, 0.1, 0, _raw, CookStyle.plain, true),
  _f('Sweet Potato (raw)', 'शकरकंद', '100 g', 'Ingredients', 86, 1.6, 20.1, 0.1, 0, _raw, CookStyle.plain, true),
  _f('Green Peas', 'हरे मटर', '100 g', 'Ingredients', 81, 5.4, 14.5, 0.4, 0, _raw, CookStyle.plain, true),
  _f('French Beans', 'फ्रेंच बीन्स', '100 g', 'Ingredients', 31, 1.8, 7, 0.1, 0, _raw, CookStyle.plain, true),
  _f('Cauliflower (raw)', 'फूलगोभी', '100 g', 'Ingredients', 25, 1.9, 5, 0.3, 0, _raw, CookStyle.plain, true),
  _f('Eggplant (raw)', 'बैंगन', '100 g', 'Ingredients', 25, 1, 6, 0.2, 0, _raw, CookStyle.plain, true),
  _f('Beetroot (raw)', 'चुकंदर', '100 g', 'Ingredients', 43, 1.6, 10, 0.2, 0, _raw, CookStyle.plain, true),
  _f('Lettuce', 'लेट्यूस', '100 g', 'Ingredients', 15, 1.4, 2.9, 0.2, 0, _raw, CookStyle.plain, true),
  _f('Spring Onion', 'हरा प्याज़', '100 g', 'Ingredients', 32, 1.8, 7.3, 0.2, 0, _raw, CookStyle.plain, true),
  _f('Green Chilli', 'हरी मिर्च', '100 g', 'Ingredients', 40, 2, 9, 0.2, 0, _raw, CookStyle.plain, true),
  _f('Coriander Leaves', 'हरा धनिया', '100 g', 'Ingredients', 23, 2.1, 3.7, 0.5, 0, _raw, CookStyle.plain, true),
  _f('Mint Leaves', 'पुदीना', '100 g', 'Ingredients', 44, 3.3, 8.4, 0.7, 0, _raw, CookStyle.plain, true),
  _f('Lemon Juice', 'नींबू का रस', '100 g', 'Ingredients', 22, 0.4, 6.9, 0.2, 0, _raw, CookStyle.plain, true),
  _f('Olives', 'ऑलिव्स', '100 g', 'Ingredients', 145, 1, 4, 15, 0, _raw, CookStyle.plain, true),
  _f('Jalapeno', 'जलेपीनो', '100 g', 'Ingredients', 29, 0.9, 6.5, 0.4, 0, _raw, CookStyle.plain, true),
  _f('Pickled Cucumber', 'खीरे का अचार', '100 g', 'Ingredients', 12, 0.5, 2.4, 0.2, 0, _raw, CookStyle.plain, true),

  // ── Flour, bread & coating ingredients
  _f('Maida', 'मैदा', '100 g', 'Ingredients', 364, 10, 76, 1, 0, _raw, CookStyle.plain, true),
  _f('Whole Wheat Flour', 'गेहूं का आटा', '100 g', 'Ingredients', 340, 13.2, 72, 2.5, 0, _raw, CookStyle.plain, true),
  _f('Besan (dry)', 'बेसन', '100 g', 'Ingredients', 387, 22, 58, 6.7, 0, _raw, CookStyle.plain, true),
  _f('Cornflour', 'कॉर्नफ्लोर', '100 g', 'Ingredients', 381, 0.3, 91, 0.1, 0, _raw, CookStyle.plain, true),
  _f('Rice Flour', 'चावल का आटा', '100 g', 'Ingredients', 366, 6, 80, 1.4, 0, _raw, CookStyle.plain, true),
  _f('Breadcrumbs', 'ब्रेडक्रम्ब्स', '100 g', 'Ingredients', 350, 12, 72, 5, 0, _raw, CookStyle.plain, true),
  _f('Rolled Oats (dry)', 'ओट्स', '100 g', 'Ingredients', 389, 16.9, 66.3, 6.9, 0, _raw, CookStyle.plain, true),
  _f('Semolina / Suji (dry)', 'सूजी', '100 g', 'Ingredients', 360, 12, 73, 1, 0, _raw, CookStyle.plain, true),
  _f('Cornmeal', 'मक्के का आटा', '100 g', 'Ingredients', 370, 7, 79, 4, 0, _raw, CookStyle.plain, true),
  _f('White Bread', 'सफेद ब्रेड', '100 g', 'Ingredients', 265, 9, 49, 3.2, 0, _raw, CookStyle.plain, true),
  _f('Whole Wheat Bread', 'ब्राउन ब्रेड', '100 g', 'Ingredients', 247, 13, 41, 4.2, 0, _raw, CookStyle.plain, true),
  _f('Burger Bun', 'बर्गर बन', '1 bun (60 g)', 'Ingredients', 170, 5.5, 30, 3, 0, _raw),
  _f('Pav Bread', 'पाव', '1 piece (40 g)', 'Ingredients', 120, 4, 22, 2, 0, _raw),

  // ── Dairy & fats for recipes
  _f('Butter', 'मक्खन', '100 g', 'Ingredients', 717, 0.9, 0.1, 81, 0, _raw, CookStyle.plain, true),
  _f('Olive Oil', 'ऑलिव ऑयल', '100 g', 'Ingredients', 884, 0, 0, 100, 0, _raw, CookStyle.plain, true),
  _f('Sunflower Oil', 'सूरजमुखी तेल', '100 g', 'Ingredients', 884, 0, 0, 100, 0, _raw, CookStyle.plain, true),
  _f('Fresh Cream', 'फ्रेश क्रीम', '100 g', 'Ingredients', 340, 2.1, 2.8, 36, 0, _raw, CookStyle.plain, true),
  _f('Hung Curd', 'हंग कर्ड', '100 g', 'Ingredients', 120, 8, 5, 7, 0, _raw, CookStyle.plain, true),
  _f('Tofu', 'टोफू', '100 g', 'Ingredients', 76, 8, 1.9, 4.8, 0, _raw, CookStyle.plain, true),
  _f('Paneer (ingredient)', 'पनीर', '100 g', 'Ingredients', 265, 18.3, 1.2, 20.8, 0, _raw, CookStyle.plain, true),
  _f('Cheddar Cheese', 'चेडर चीज़', '100 g', 'Ingredients', 403, 25, 1.3, 33, 0, _raw, CookStyle.plain, true),
  _f('Parmesan Cheese', 'पार्मेज़ान चीज़', '100 g', 'Ingredients', 431, 38, 4.1, 29, 0, _raw, CookStyle.plain, true),

  // ── Sauces, spreads & seasonings
  _f('Mustard Sauce', 'मस्टर्ड सॉस', '100 g', 'Ingredients', 66, 4, 6, 4, 0, _raw, CookStyle.plain, true),
  _f('Green Chutney', 'हरी चटनी', '100 g', 'Ingredients', 70, 3, 12, 2, 0, _raw, CookStyle.plain, true),
  _f('Tamarind Chutney', 'इमली की चटनी', '100 g', 'Ingredients', 150, 1, 37, 0.5, 0, _raw, CookStyle.plain, true),
  _f('Mint Mayonnaise', 'मिंट मेयोनेज़', '100 g', 'Ingredients', 600, 1, 8, 63, 0, _raw, CookStyle.plain, true),
  _f('Red Chilli Sauce', 'रेड चिली सॉस', '100 g', 'Ingredients', 90, 1.5, 20, 0.5, 0, _raw, CookStyle.plain, true),
  _f('Soy Sauce', 'सोया सॉस', '100 g', 'Ingredients', 53, 8, 5, 0.6, 0, _raw, CookStyle.plain, true),
  _f('Vinegar', 'सिरका', '100 g', 'Ingredients', 18, 0, 0.5, 0, 0, _raw, CookStyle.plain, true),
  _f('Black Pepper', 'काली मिर्च', '100 g', 'Ingredients', 251, 10.4, 64, 3.3, 0, _raw, CookStyle.plain, true),
  _f('Red Chilli Powder', 'लाल मिर्च पाउडर', '100 g', 'Ingredients', 282, 13.5, 50, 14, 0, _raw, CookStyle.plain, true),
  _f('Turmeric Powder', 'हल्दी पाउडर', '100 g', 'Ingredients', 312, 9.7, 67, 3.3, 0, _raw, CookStyle.plain, true),
  _f('Cumin Seeds', 'जीरा', '100 g', 'Ingredients', 375, 18, 44, 22, 0, _raw, CookStyle.plain, true),
  _f('Mixed Herbs', 'मिक्स्ड हर्ब्स', '100 g', 'Ingredients', 250, 10, 50, 5, 0, _raw, CookStyle.plain, true),
  _f('Oregano', 'ओरेगैनो', '100 g', 'Ingredients', 265, 9, 69, 4, 0, _raw, CookStyle.plain, true),
  _f('Chilli Flakes', 'चिली फ्लेक्स', '100 g', 'Ingredients', 318, 12, 57, 17, 0, _raw, CookStyle.plain, true),
  _f('Salt', 'नमक', '100 g', 'Ingredients', 0, 0, 0, 0, 0, _raw, CookStyle.plain, true),

  _f('Onion (raw)', 'प्याज़', '100 g', 'Ingredients', 40, 1.1, 9.3, 0.1, 0, _raw, CookStyle.plain, true),
  _f('Tomato (raw)', 'टमाटर', '100 g', 'Ingredients', 18, 0.9, 3.9, 0.2, 0, _raw, CookStyle.plain, true),
  _f('Green Capsicum', 'हरी शिमला मिर्च', '100 g', 'Ingredients', 20, 0.9, 4.6, 0.2, 0, _raw, CookStyle.plain, true),
  _f('Red Capsicum', 'लाल शिमला मिर्च', '100 g', 'Ingredients', 31, 1, 6, 0.3, 0, _raw, CookStyle.plain, true),
  _f('Yellow Capsicum', 'पीली शिमला मिर्च', '100 g', 'Ingredients', 27, 1, 6.3, 0.2, 0, _raw, CookStyle.plain, true),
  _f('Cucumber (raw)', 'खीरा', '100 g', 'Ingredients', 15, 0.7, 3.6, 0.1, 0, _raw, CookStyle.plain, true),
  _f('Carrot (raw)', 'गाजर', '100 g', 'Ingredients', 41, 0.9, 9.6, 0.2, 0, _raw, CookStyle.plain, true),
  _f('Cabbage (raw)', 'पत्तागोभी', '100 g', 'Ingredients', 25, 1.3, 5.8, 0.1, 0, _raw, CookStyle.plain, true),
  _f('Broccoli (raw)', 'ब्रोकोली', '100 g', 'Ingredients', 34, 2.8, 6.6, 0.4, 0, _raw, CookStyle.plain, true),
  _f('Spinach (raw)', 'पालक', '100 g', 'Ingredients', 23, 2.9, 3.6, 0.4, 0, _raw, CookStyle.plain, true),
  _f('Mushroom (raw)', 'मशरूम', '100 g', 'Ingredients', 22, 3.1, 3.3, 0.3, 0, _raw, CookStyle.plain, true),
  _f('Sweet Corn (boiled)', 'स्वीट कॉर्न', '100 g', 'Ingredients', 96, 3.4, 21, 1.5, 0, _raw, CookStyle.plain, true),
  _f('Garlic', 'लहसुन', '100 g', 'Ingredients', 149, 6.4, 33, 0.5, 0, _raw, CookStyle.plain, true),
  _f('Ginger', 'अदरक', '100 g', 'Ingredients', 80, 1.8, 18, 0.8, 0, _raw, CookStyle.plain, true),
  _f('Mayonnaise', 'मेयोनेज़', '100 g', 'Ingredients', 680, 1, 1, 75, 0, _raw, CookStyle.plain, true),
  _f('Low-fat Mayonnaise', 'लो फैट मेयोनेज़', '100 g', 'Ingredients', 260, 1, 14, 22, 0, _raw, CookStyle.plain, true),
  _f('Tomato Ketchup', 'टोमैटो केचप', '100 g', 'Ingredients', 112, 1.3, 26, 0.2, 0, _raw, CookStyle.plain, true),
  _f('Pizza Sauce', 'पिज़्ज़ा सॉस', '100 g', 'Ingredients', 65, 1.5, 13, 0.5, 0, _raw, CookStyle.plain, true),
  _f('Cheese Slice', 'चीज़ स्लाइस', '1 slice (20 g)', 'Ingredients', 60, 3.5, 0.5, 5, 0, _raw),
  _f('Mozzarella Cheese', 'मोज़ेरेला चीज़', '100 g', 'Ingredients', 280, 28, 3, 17, 0, _raw, CookStyle.plain, true),
  _f('Processed Cheese', 'प्रोसेस्ड चीज़', '100 g', 'Ingredients', 330, 20, 4, 26, 0, _raw, CookStyle.plain, true),
  _f('Pizza Dough - Regular', 'पिज़्ज़ा डो', '100 g', 'Ingredients', 265, 8, 52, 3, 0, _raw, CookStyle.plain, true),
  _f('Pizza Dough - Whole Wheat', 'व्होल व्हीट पिज़्ज़ा डो', '100 g', 'Ingredients', 245, 10, 47, 3, 0, _raw, CookStyle.plain, true),
  _f('Pizza Base - Thin Crust', 'थिन क्रस्ट पिज़्ज़ा बेस', '100 g', 'Ingredients', 270, 8, 54, 3, 0, _raw, CookStyle.plain, true),
  _f('Pizza Base - Multigrain', 'मल्टीग्रेन पिज़्ज़ा बेस', '100 g', 'Ingredients', 250, 10, 47, 4, 0, _raw, CookStyle.plain, true),

  // ── Sabzi & veg curries
  _f('Aloo Gobi', 'आलू गोभी', '1 katori (150 g)', 'Sabzi', 100, 2.5, 15, 2, 1.0, _veg, CookStyle.home),
  _f('Aloo Matar', 'आलू मटर', '1 katori (150 g)', 'Sabzi', 110, 3.5, 17, 2.5, 1.0, _veg, CookStyle.home),
  _f('Bhindi Masala', 'भिंडी मसाला', '1 katori (100 g)', 'Sabzi', 50, 2, 7, 1, 1.2, _veg, CookStyle.home),
  _f('Baingan Bharta', 'बैंगन भर्ता', '1 katori (150 g)', 'Sabzi', 80, 2, 10, 1.5, 1.2, _veg, CookStyle.home),
  _f('Lauki Sabzi', 'लौकी सब्ज़ी', '1 katori (150 g)', 'Sabzi', 40, 1, 7, 0.5, 0.9, _veg, CookStyle.home),
  _f('Mixed Veg', 'मिक्स वेज', '1 katori (150 g)', 'Sabzi', 70, 2.5, 11, 1, 1.0, _veg, CookStyle.home),
  _f('Palak Paneer', 'पालक पनीर', '1 katori (150 g)', 'Sabzi', 140, 9, 6, 9, 0.9, _curry, CookStyle.home),
  _f('Paneer Butter Masala', 'पनीर बटर मसाला', '1 katori (150 g)', 'Sabzi', 200, 9, 8, 14, 0.9, _curry, CookStyle.restaurant),
  _f('Matar Paneer', 'मटर पनीर', '1 katori (150 g)', 'Sabzi', 170, 9, 9, 10, 0.9, _curry, CookStyle.home),
  _f('Paneer Bhurji', 'पनीर भुर्जी', '1 katori (100 g)', 'Sabzi', 190, 12, 4, 14, 0.7, _curry, CookStyle.home),
  _f('Tofu', 'टोफू', '100 g', 'Dairy', 144, 15.7, 2.8, 8.7, 0.2, _veg, CookStyle.plain, true),
  _f('Tofu Bhurji', 'टोफू भुर्जी', '1 katori (180 g)', 'Sabzi', 220, 20, 12, 11, 0.8, _curry, CookStyle.home),
  _f('Soya Bhurji', 'सोया भुर्जी', '1 katori (180 g)', 'Sabzi', 245, 23, 18, 10, 0.7, _curry, CookStyle.home),
  _f('Malai Kofta', 'मलाई कोफ्ता', '2 pieces + gravy', 'Sabzi', 260, 7, 16, 18, 0.9, _curry, CookStyle.restaurant),
  _f('Dum Aloo', 'दम आलू', '1 katori (150 g)', 'Sabzi', 150, 3, 22, 5, 1.0, _curry, CookStyle.home),
  _f('Kadai Paneer', 'Kadai paneer', '1 katori (150 g)', 'Sabzi', 190, 10, 10, 12, 0.9, _curry, CookStyle.home),
  _f('Shahi Paneer', 'Shahi paneer', '1 katori (150 g)', 'Sabzi', 230, 10, 12, 16, 0.9, _curry, CookStyle.restaurant),
  _f('Kadai Mushroom', 'Kadai mushroom', '1 katori (150 g)', 'Sabzi', 100, 4, 10, 5, 0.9, _curry, CookStyle.home),
  _f('Mushroom Matar', 'Mushroom matar', '1 katori (150 g)', 'Sabzi', 110, 5, 13, 4, 0.9, _curry, CookStyle.home),
  _f('Vegetable Korma', 'Veg korma', '1 katori (150 g)', 'Sabzi', 160, 4, 16, 9, 0.9, _curry, CookStyle.home),
  _f('Methi Aloo', 'Methi aloo', '1 katori (150 g)', 'Sabzi', 105, 3, 16, 3, 1.0, _veg, CookStyle.home),
  _f('Cabbage Sabzi', 'Patta gobhi sabzi', '1 katori (150 g)', 'Sabzi', 65, 2.5, 10, 2, 0.9, _veg, CookStyle.home),
  _f('Beetroot Sabzi', 'Chukandar sabzi', '1 katori (150 g)', 'Sabzi', 75, 2, 13, 1.5, 0.8, _veg, CookStyle.home),

  // ── Regional dishes & hearty meals
  _f('Chole Bhature', 'Chole bhature', '1 plate (2 bhature)', 'Meal', 520, 15, 76, 18, 0.8, _fry, CookStyle.deep),
  _f('Rajma Chawal', 'Rajma chawal', '1 plate', 'Meal', 410, 15, 74, 6, 0.8, _rice, CookStyle.home),
  _f('Dal Chawal', 'Dal chawal', '1 plate', 'Meal', 330, 12, 62, 4, 0.8, _rice, CookStyle.home),
  _f('Kadak Roti Dal', 'Roti dal', '2 rotis + 1 katori dal', 'Meal', 320, 13, 55, 5, 0.7, _dal, CookStyle.home),
  _f('Dal Fry', 'Dal fry', '1 katori (150 g)', 'Dal', 135, 7, 18, 4, 1.0, _dal, CookStyle.tadka),
  _f('Misal Pav', 'Misal pav', '1 plate (2 pav)', 'Meal', 380, 12, 58, 10, 0.8, _curry, CookStyle.home),
  _f('Sabudana Khichdi', 'Sabudana khichdi', '1 katori (200 g)', 'Tiffin', 330, 4, 58, 9, 0.6, _veg, CookStyle.home),
  _f('Pesarattu', 'Pesarattu', '1 medium', 'Tiffin', 170, 8, 27, 3, 0.5, _tiffin, CookStyle.home),
  _f('Ven Pongal', 'Ven pongal', '1 katori (200 g)', 'Tiffin', 260, 7, 39, 8, 0.7, _veg, CookStyle.home),
  _f('Appam', 'Appam', '2 pieces', 'Tiffin', 180, 3, 36, 3, 0.2, _steam),
  _f('Puttu', 'Puttu', '1 serving (150 g)', 'Tiffin', 210, 4, 43, 3, 0, _steam),
  _f('Avial', 'Avial', '1 katori (150 g)', 'Sabzi', 120, 3, 14, 6, 0.6, _veg, CookStyle.home),
  _f('Dal Dhokli', 'Dal dhokli', '1 bowl (250 g)', 'Meal', 310, 12, 51, 6, 0.8, _dal, CookStyle.home),
  _f('Undhiyu', 'Undhiyu', '1 katori (150 g)', 'Sabzi', 170, 5, 20, 8, 0.8, _veg, CookStyle.home),
  _f('Litti Chokha', 'Litti chokha', '2 litti + chokha', 'Meal', 360, 10, 58, 9, 0.6, _tiffin, CookStyle.tawa),
  _f('Chicken Sukka', 'Chicken sukka', '1 katori (150 g)', 'Non-veg', 240, 24, 5, 14, 0.9, _curry, CookStyle.home),
  _f('Keema Pav', 'Keema pav', '1 plate', 'Meal', 400, 22, 42, 16, 0.9, _curry, CookStyle.home),
  _f('Hakka Noodles', 'Hakka noodles', '1 plate (250 g)', 'Meal', 360, 9, 56, 11, 0.8, _tiffin, CookStyle.home),
  _f('Veg Manchurian', 'Veg manchurian', '6 pieces + gravy', 'Snack', 280, 7, 38, 10, 0.8, _fry, CookStyle.shallow),

  // ── Eggs, chicken, fish, mutton
  _f('Boiled Egg', 'उबला अंडा', '1 large (50 g)', 'Non-veg', 78, 6.3, 0.6, 5.3, 0, _raw),
  _f('Omelette (2 eggs)', 'ऑमलेट', '2 eggs', 'Non-veg', 156, 12.6, 1.2, 10.6, 0.5, [CookStyle.tawa, CookStyle.home, CookStyle.shallow, CookStyle.restaurant], CookStyle.home),
  _f('Egg Bhurji (2 eggs)', 'अंडा भुर्जी', '2 eggs', 'Non-veg', 175, 13, 3, 12, 0.7, _curry, CookStyle.home),
  _f('Egg Curry (2 eggs)', 'अंडा करी', '2 eggs + gravy', 'Non-veg', 180, 13, 5, 12, 0.9, _curry, CookStyle.home),
  _f('Chicken Curry', 'चिकन करी', '1 katori (150 g)', 'Non-veg', 190, 22, 5, 9, 1.0, _curry, CookStyle.home),
  _f('Butter Chicken', 'बटर चिकन', '1 katori (150 g)', 'Non-veg', 230, 18, 8, 14, 1.0, _curry, CookStyle.restaurant),
  _f('Tandoori Chicken', 'तंदूरी चिकन', '2 pieces (150 g)', 'Non-veg', 220, 30, 4, 9, 0.5, _grill, CookStyle.tandoor),
  _f('Chicken Tikka', 'चिकन टिक्का', '6 pieces (150 g)', 'Non-veg', 210, 28, 5, 8, 0.5, _grill, CookStyle.tandoor),
  _f('Fish Curry', 'फिश करी', '1 katori (150 g)', 'Non-veg', 150, 18, 4, 7, 0.9, _curry, CookStyle.home),
  _f('Fish Fry', 'फिश फ्राई', '1 piece (100 g)', 'Non-veg', 160, 20, 4, 7, 0.6, [CookStyle.shallow, CookStyle.deep, CookStyle.air, CookStyle.tandoor]),
  _f('Mutton Curry', 'मटन करी', '1 katori (150 g)', 'Non-veg', 250, 20, 5, 16, 1.0, _curry, CookStyle.home),

  // ── South Indian & breakfast
  _f('Idli', 'इडली', '1 piece (40 g)', 'Tiffin', 58, 2, 12, 0.3, 0, _steam),
  _f('Plain Dosa', 'डोसा', '1 medium', 'Tiffin', 120, 3, 22, 2, 0.5, _tiffin, CookStyle.home),
  _f('Masala Dosa', 'मसाला डोसा', '1 medium', 'Tiffin', 200, 5, 36, 4, 0.8, _tiffin, CookStyle.home),
  _f('Uttapam', 'उत्तपम', '1 medium', 'Tiffin', 160, 5, 28, 3, 0.7, _tiffin, CookStyle.home),
  _f('Medu Vada', 'मेदू वड़ा', '1 piece (40 g)', 'Tiffin', 70, 3, 8, 1, 0.3, _fry, CookStyle.deep),
  _f('Poha', 'पोहा', '1 plate (150 g)', 'Tiffin', 170, 3.5, 33, 2.5, 0.8, _veg, CookStyle.home),
  _f('Upma', 'उपमा', '1 katori (200 g)', 'Tiffin', 190, 4, 32, 4, 0.8, _veg, CookStyle.home),
  _f('Besan Chilla', 'बेसन चीला', '1 piece', 'Tiffin', 110, 6, 12, 3, 0.6, _tiffin, CookStyle.home),
  _f('Moong Dal Chilla', 'मूंग चीला', '1 piece', 'Tiffin', 100, 6.5, 12, 2, 0.6, _tiffin, CookStyle.home),
  _f('Dhokla', 'ढोकला', '2 pieces (60 g)', 'Tiffin', 90, 3.5, 15, 1.5, 0.2, _steam),
  _f('Oats Porridge', 'ओट्स', '1 bowl (40 g dry)', 'Tiffin', 150, 5, 27, 3, 0, [CookStyle.plain]),
  _f('Daliya', 'दलिया', '1 katori (200 g)', 'Tiffin', 160, 5, 30, 1.5, 0.3, _steam),

  // ── Street food & snacks
  _f('Samosa', 'समोसा', '1 piece (100 g)', 'Snack', 170, 4, 27, 5, 0.5, _fry, CookStyle.deep),
  _f('Onion Pakora', 'प्याज़ पकौड़ा', '4 pieces (60 g)', 'Snack', 110, 4, 14, 3, 0.6, _fry, CookStyle.deep),
  _f('Vada Pav', 'वड़ा पाव', '1 piece', 'Snack', 220, 5, 38, 5, 0.4, _fry, CookStyle.deep),
  _f('Pav Bhaji', 'पाव भाजी', '1 plate (2 pav)', 'Snack', 300, 8, 48, 8, 0.9, [CookStyle.home, CookStyle.restaurant, CookStyle.tadka], CookStyle.restaurant),
  _f('Pani Puri', 'पानी पूरी', '6 pieces', 'Snack', 180, 3, 30, 5, 0.4, _fry, CookStyle.deep),
  _f('Bhel Puri', 'भेल पूरी', '1 plate (100 g)', 'Snack', 170, 4, 30, 4, 0.2, _raw),
  _f('Kachori', 'कचौड़ी', '1 piece', 'Snack', 150, 3, 20, 5, 0.6, _fry, CookStyle.deep),
  _f('Roasted Chana', 'भुना चना', '30 g', 'Snack', 110, 6, 18, 2, 0, _raw),
  _f('Makhana (roasted)', 'मखाना', '30 g', 'Snack', 105, 3.5, 22, 0.2, 0.3, [CookStyle.tawa, CookStyle.tadka]),
  _f('Peanuts', 'मूंगफली', '30 g', 'Snack', 170, 7.5, 5, 14, 0, _raw),
  _f('Almonds', 'बादाम', '10 pieces', 'Snack', 70, 2.5, 2.5, 6, 0, _raw),
  _f('Khakhra', 'खाखरा', '2 pieces', 'Snack', 100, 3, 17, 2, 0.2, _raw),

  // ── Dairy & drinks
  _f('Curd / Dahi', 'दही', '1 katori (100 g)', 'Dairy', 60, 3.5, 4.5, 3, 0, _raw),
  _f('Raita', 'रायता', '1 katori (100 g)', 'Dairy', 55, 3, 5, 2.5, 0, _raw),
  _f('Paneer (raw)', 'पनीर', '50 g', 'Dairy', 130, 9, 1, 10, 0, _raw),
  _f('Milk (full fat)', 'दूध', '1 glass (250 ml)', 'Dairy', 150, 8, 12, 8, 0, _raw),
  _f('Masala Chai', 'मसाला चाय', '1 cup (150 ml)', 'Drinks', 70, 2, 9, 3, 0, _raw),
  _f('Chai (no sugar)', 'फीकी चाय', '1 cup (150 ml)', 'Drinks', 45, 2, 3.5, 3, 0, _raw),
  _f('Sweet Lassi', 'लस्सी', '1 glass (250 ml)', 'Drinks', 190, 6, 28, 5, 0, _raw),
  _f('Chaas / Buttermilk', 'छाछ', '1 glass (200 ml)', 'Drinks', 40, 2, 3, 2, 0, _raw),
  _f('Coconut Water', 'नारियल पानी', '1 glass (250 ml)', 'Drinks', 45, 0.5, 10, 0.2, 0, _raw),
  _f('Sattu Drink', 'सत्तू शरबत', '1 glass (250 ml)', 'Drinks', 170, 8, 30, 2, 0, _raw),
  _f('Whey Protein', 'व्हे प्रोटीन', '1 scoop (30 g)', 'Drinks', 120, 24, 3, 1.5, 0, _raw),
  
  // ── Sandwiches & burgers
  _f('Veg Sandwich', 'वेज सैंडविच', '2 slices (120 g)', 'Snack', 280, 8, 38, 10, 0.3, _tiffin, CookStyle.tawa),
  _f('Bombay Masala Sandwich', 'बॉम्बे मसाला सैंडविच', '1 sandwich (180 g)', 'Snack', 350, 9, 52, 11, 0.5, _tiffin, CookStyle.tawa),
  _f('Grilled Sandwich', 'ग्रिल्ड सैंडविच', '1 sandwich (150 g)', 'Snack', 320, 10, 42, 12, 0.4, _tiffin, CookStyle.tawa),
  _f('Cheese Sandwich', 'चीज़ सैंडविच', '1 sandwich (130 g)', 'Snack', 350, 12, 38, 16, 0.2, _tiffin, CookStyle.tawa),
  _f('Paneer Sandwich', 'पनीर सैंडविच', '1 sandwich (150 g)', 'Snack', 350, 14, 40, 14, 0.3, _tiffin, CookStyle.tawa),
  _f('Corn Cheese Sandwich', 'कॉर्न चीज़ सैंडविच', '1 sandwich (150 g)', 'Snack', 380, 12, 44, 17, 0.3, _tiffin, CookStyle.tawa),
  _f('Cucumber Sandwich', 'खीरा सैंडविच', '2 slices (100 g)', 'Snack', 220, 6, 34, 6, 0.2, _tiffin, CookStyle.tawa),
  _f('Club Sandwich Veg', 'वेज क्लब सैंडविच', '1 sandwich (220 g)', 'Snack', 420, 13, 55, 16, 0.4, _tiffin, CookStyle.tawa),
  _f('Bread Pakora', 'ब्रेड पकौड़ा', '1 piece (100 g)', 'Snack', 250, 6, 32, 11, 0.8, _fry, CookStyle.deep),
  _f('Burger Aloo Tikki', 'आलू टिक्की बर्गर', '1 burger (180 g)', 'Snack', 400, 9, 57, 15, 0.6, _fry, CookStyle.shallow),
  _f('Veg Burger', 'वेज बर्गर', '1 burger (180 g)', 'Snack', 380, 10, 50, 15, 0.5, _fry, CookStyle.shallow),

  // ── Chaat & street snacks
  _f('Aloo Tikki', 'आलू टिक्की', '2 pieces (120 g)', 'Snack', 240, 4, 38, 8, 0.8, _fry, CookStyle.shallow),
  _f('Aloo Tikki Chaat', 'आलू टिक्की चाट', '1 plate (200 g)', 'Snack', 330, 8, 48, 12, 0.6, _fry, CookStyle.shallow),
  _f('Dahi Bhalla', 'दही भल्ला', '2 pieces (180 g)', 'Snack', 280, 9, 38, 9, 0.4, _fry, CookStyle.deep),
  _f('Papdi Chaat', 'पापड़ी चाट', '1 plate (180 g)', 'Snack', 320, 7, 45, 13, 0.5, _raw),
  _f('Sev Puri', 'सेव पूरी', '1 plate (150 g)', 'Snack', 280, 6, 38, 12, 0.3, _raw),
  _f('Dahi Puri', 'दही पूरी', '6 pieces', 'Snack', 300, 7, 43, 11, 0.4, _raw),
  _f('Ragda Pattice', 'रगड़ा पेटिस', '1 plate (250 g)', 'Snack', 350, 10, 55, 10, 0.5, _fry, CookStyle.shallow),
  _f('Samosa Chaat', 'समोसा चाट', '1 plate (200 g)', 'Snack', 380, 9, 52, 16, 0.5, _fry, CookStyle.deep),
  _f('Chana Chaat', 'चना चाट', '1 bowl (180 g)', 'Snack', 240, 10, 38, 5, 0.2, _raw),
  _f('Sprouts Chaat', 'स्प्राउट्स चाट', '1 bowl (180 g)', 'Snack', 160, 9, 27, 2, 0, _raw),
  _f('Sweet Corn Chaat', 'स्वीट कॉर्न चाट', '1 bowl (150 g)', 'Snack', 180, 5, 32, 4, 0.2, _raw),
  _f('Masala Corn', 'मसाला कॉर्न', '1 cup (150 g)', 'Snack', 170, 5, 30, 4, 0.2, _raw),
  _f('Fruit Chaat', 'फ्रूट चाट', '1 bowl (200 g)', 'Snack', 140, 2, 34, 1, 0, _raw),

  // ── More Indian fried snacks
  _f('Aloo Bonda', 'आलू बोंडा', '2 pieces (120 g)', 'Snack', 300, 5, 40, 13, 0.8, _fry, CookStyle.deep),
  _f('Onion Bhaji', 'प्याज़ भजिया', '4 pieces (100 g)', 'Snack', 260, 6, 32, 12, 0.8, _fry, CookStyle.deep),
  _f('Mirchi Bajji', 'मिर्ची बज्जी', '2 pieces (100 g)', 'Snack', 240, 5, 30, 11, 0.8, _fry, CookStyle.deep),
  _f('Moong Dal Pakora', 'मूंग दाल पकौड़ा', '5 pieces (100 g)', 'Snack', 280, 10, 32, 12, 0.8, _fry, CookStyle.deep),
  _f('Palak Pakora', 'पालक पकौड़ा', '5 pieces (100 g)', 'Snack', 250, 6, 30, 11, 0.8, _fry, CookStyle.deep),
  _f('Paneer Pakora', 'पनीर पकौड़ा', '4 pieces (120 g)', 'Snack', 350, 14, 30, 19, 0.8, _fry, CookStyle.deep),
  _f('Dabeli', 'दाबेली', '1 piece', 'Snack', 300, 7, 45, 10, 0.4, _tiffin, CookStyle.home),
  _f('Khaman', 'खमन', '1 plate (150 g)', 'Snack', 220, 9, 32, 6, 0.2, _steam),
  _f('Khandvi', 'खंडवी', '1 plate (100 g)', 'Snack', 180, 6, 22, 7, 0.2, _steam),
  _f('Fafda', 'फाफड़ा', '1 serving (100 g)', 'Snack', 400, 10, 48, 19, 0.8, _fry, CookStyle.deep),
  _f('Muthiya', 'मुठिया', '1 serving (150 g)', 'Snack', 260, 8, 38, 8, 0.4, _tiffin, CookStyle.home),
  _f('Handvo', 'हांडवो', '1 piece (150 g)', 'Snack', 280, 9, 38, 10, 0.4, _tiffin, CookStyle.home),
  _f('Sabudana Vada', 'साबूदाना वड़ा', '2 pieces (120 g)', 'Snack', 320, 3, 48, 13, 0.8, _fry, CookStyle.deep),
  _f('Thayir Vadai', 'दही वड़ा', '2 pieces (180 g)', 'Snack', 280, 9, 38, 9, 0.4, _fry, CookStyle.deep),
  _f('Pazham Pori', 'पजहं पोरी', '2 pieces (120 g)', 'Snack', 300, 4, 45, 12, 0.8, _fry, CookStyle.deep),

  // ── Regional & baked snacks
  _f('Momos Veg Steamed', 'वेज मोमोज', '6 pieces (180 g)', 'Snack', 240, 7, 42, 4, 0.1, _steam),
  _f('Momos Veg Fried', 'फ्राइड वेज मोमोज', '6 pieces (180 g)', 'Snack', 340, 7, 44, 14, 0.7, _fry, CookStyle.deep),
  _f('Spring Roll Veg', 'वेज स्प्रिंग रोल', '2 pieces (120 g)', 'Snack', 300, 6, 38, 14, 0.8, _fry, CookStyle.deep),
  _f('Dhokla Sandwich', 'ढोकला सैंडविच', '1 serving (150 g)', 'Snack', 240, 8, 35, 7, 0.2, _steam),
  _f('Khari Biscuit', 'खारी बिस्कुट', '2 pieces (40 g)', 'Snack', 200, 3, 23, 10, 0, _raw),
  _f('Namak Pare', 'नमक पारे', '30 g', 'Snack', 150, 3, 20, 7, 0.5, _fry, CookStyle.deep),
  _f('Mathri', 'मठरी', '2 pieces (40 g)', 'Snack', 180, 3, 22, 9, 0.5, _fry, CookStyle.deep),
  _f('Chakli', 'चकली', '30 g', 'Snack', 150, 3, 18, 7, 0.5, _fry, CookStyle.deep),
  _f('Sev Namkeen', 'सेव नमकीन', '30 g', 'Snack', 170, 5, 14, 11, 0.2, _raw),
  _f('Aloo Bhujia', 'आलू भुजिया', '30 g', 'Snack', 170, 3, 17, 10, 0.2, _raw),
  _f('Murukku', 'मुरुक्कू', '30 g', 'Snack', 150, 3, 20, 7, 0.5, _fry, CookStyle.deep),
  _f('Shakarpara', 'शकरपारा', '30 g', 'Snack', 150, 2, 22, 6, 0.5, _fry, CookStyle.deep),
  _f('Khakhra Masala', 'मसाला खाखरा', '2 pieces (50 g)', 'Snack', 180, 5, 30, 5, 0.2, _raw),



  // ── Sweets & fruit
  _f('Gulab Jamun', 'गुलाब जामुन', '1 piece (40 g)', 'Sweet', 150, 2, 22, 6, 0, _raw),
  _f('Jalebi', 'जलेबी', '50 g', 'Sweet', 150, 1.5, 28, 4, 0, _raw),
  _f('Rasgulla', 'रसगुल्ला', '1 piece', 'Sweet', 110, 3, 24, 1, 0, _raw),
  _f('Kheer', 'खीर', '1 katori (150 g)', 'Sweet', 190, 5, 28, 6, 0, _raw),
  _f('Gajar Halwa', 'गाजर हलवा', '1 katori (100 g)', 'Sweet', 230, 3, 28, 12, 0, _raw),
  _f('Besan Laddu', 'बेसन लड्डू', '1 piece (40 g)', 'Sweet', 190, 3, 20, 11, 0, _raw),
  _f('Kaju Katli', 'Kaju katli', '2 pieces (30 g)', 'Sweet', 165, 3, 17, 9, 0, _raw),
  _f('Milk Peda', 'Doodh peda', '1 piece (25 g)', 'Sweet', 110, 2.5, 15, 4.5, 0, _raw),
  _f('Motichoor Laddu', 'Motichoor laddu', '1 piece (35 g)', 'Sweet', 160, 2.5, 20, 8, 0, _raw),
  _f('Rava Laddu', 'Sooji laddu', '1 piece (35 g)', 'Sweet', 155, 2, 20, 7, 0, _raw),
  _f('Coconut Laddu', 'Nariyal laddu', '1 piece (30 g)', 'Sweet', 145, 1.5, 16, 8, 0, _raw),
  _f('Rasmalai', 'Rasmalai', '2 pieces (100 g)', 'Sweet', 220, 7, 27, 9, 0, _raw),
  _f('Barfi', 'Barfi', '1 piece (35 g)', 'Sweet', 160, 3, 20, 8, 0, _raw),
  _f('Mysore Pak', 'Mysore pak', '1 piece (30 g)', 'Sweet', 175, 2, 16, 11, 0, _raw),
  _f('Soan Papdi', 'Soan papdi', '1 piece (30 g)', 'Sweet', 160, 2, 20, 8, 0, _raw),
  _f('Balushahi', 'Balushahi', '1 piece (45 g)', 'Sweet', 190, 2, 27, 8, 0, _raw),
  _f('Gujiya', 'Gujiya', '1 piece (45 g)', 'Sweet', 185, 3, 21, 10, 0, _raw),
  _f('Modak', 'Modak', '1 piece (35 g)', 'Sweet', 120, 2, 20, 3, 0, _raw),
  _f('Malpua', 'Malpua', '1 piece (50 g)', 'Sweet', 180, 3, 25, 7, 0, _raw),
  _f('Sandesh', 'Sandesh', '2 pieces (50 g)', 'Sweet', 140, 5, 18, 5, 0, _raw),
  _f('Mishti Doi', 'Mishti doi', '1 katori (100 g)', 'Sweet', 170, 4, 25, 6, 0, _raw),
  _f('Phirni', 'Phirni', '1 katori (150 g)', 'Sweet', 210, 5, 32, 7, 0, _raw),
  _f('Banana', 'केला', '1 medium', 'Fruit', 105, 1.3, 27, 0.4, 0, _raw),
  _f('Apple', 'सेब', '1 medium', 'Fruit', 95, 0.5, 25, 0.3, 0, _raw),
  _f('Mango', 'आम', '1 cup (165 g)', 'Fruit', 100, 1.4, 25, 0.6, 0, _raw),
  _f('Papaya', 'पपीता', '1 katori (150 g)', 'Fruit', 60, 0.7, 15, 0.2, 0, _raw),
  _f('Guava', 'Amrood', '1 medium (100 g)', 'Fruit', 68, 2.6, 14, 1, 0, _raw),
  _f('Orange', 'Santra', '1 medium', 'Fruit', 62, 1.2, 15, 0.2, 0, _raw),
  _f('Sweet Lime / Mosambi', 'Mosambi', '1 medium', 'Fruit', 43, 0.8, 10, 0.1, 0, _raw),
  _f('Grapes', 'Angoor', '1 katori (150 g)', 'Fruit', 104, 1.1, 27, 0.2, 0, _raw),
  _f('Pomegranate', 'Anaar', '1 katori (150 g)', 'Fruit', 125, 2.5, 28, 1.8, 0, _raw),
  _f('Watermelon', 'Tarbooz', '1 large slice (280 g)', 'Fruit', 85, 1.7, 21, 0.4, 0, _raw),
  _f('Muskmelon', 'Kharbooja', '1 katori (160 g)', 'Fruit', 55, 1.3, 13, 0.3, 0, _raw),
  _f('Pineapple', 'Ananas', '1 katori (165 g)', 'Fruit', 82, 0.9, 22, 0.2, 0, _raw),
  _f('Chikoo / Sapota', 'Chikoo', '1 medium (100 g)', 'Fruit', 83, 0.4, 20, 1.1, 0, _raw),
  _f('Litchi', 'Litchi', '10 pieces (100 g)', 'Fruit', 66, 0.8, 17, 0.4, 0, _raw),
  _f('Pear', 'Nashpati', '1 medium', 'Fruit', 101, 0.6, 27, 0.2, 0, _raw),
  _f('Amla', 'Amla', '2 fruits (70 g)', 'Fruit', 31, 0.6, 7, 0.4, 0, _raw),
  _f('Jamun', 'Jamun', '1 katori (100 g)', 'Fruit', 60, 0.7, 14, 0.2, 0, _raw),
  _f('Custard Apple', 'Sitaphal', '1 medium (150 g)', 'Fruit', 150, 2.5, 36, 1.1, 0, _raw),
  _f('Dates', 'Khajoor', '3 pieces (24 g)', 'Fruit', 67, 0.4, 18, 0.1, 0, _raw),
  _f('Ghee', 'घी', '1 tsp (5 g)', 'Fats', 45, 0, 0, 5, 0, _raw),
];

List<FoodItem> searchFoods(String q, {List<FoodItem> extra = const []}) {
  // Remote catalogue entries win over offline defaults with the same name.
  final seen = <String>{};
  final all = [...extra, ...indianFoods]
      .where((food) => seen.add(food.name.trim().toLowerCase()))
      .toList();
  final s = q.trim().toLowerCase();
  if (s.isEmpty) return all;
  return all
      .where((f) =>
          f.name.toLowerCase().contains(s) ||
          f.hindi.contains(s) ||
          f.cat.toLowerCase().contains(s))
      .toList();
}
