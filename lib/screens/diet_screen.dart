import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_state.dart';
import '../data/foods.dart';
import '../models.dart';
import '../state.dart';
import '../widgets/glass.dart';
import '../widgets/nav.dart';

class DietScreen extends StatelessWidget {
  const DietScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final d = s.selectedDate;
    final entries = s.dietOn(d);
    final n = s.totalsOn(d);
    final p = s.profile;
    final isToday = sameDay(d, DateTime.now());

    return ListView(
      padding: const EdgeInsets.only(bottom: 130),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 14),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Food diary', style: t(30, w: FontWeight.w800, ls: -0.8)),
                Text(isToday ? 'Today' : '${d.day}/${d.month}/${d.year}',
                    style: t(14, color: C.textDim)),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              LiquidButton(
                label: 'Add food',
                icon: Icons.add_rounded,
                compact: true,
                onTap: () => showGlassSheet(context, (_) => const AddFoodSheet()),
              ),
              const SizedBox(height: 6),
              Pressable(
                onTap: () => _openRecipeBuilder(context),
                child: Text('✦ Make custom recipe', style: t(12, color: C.mint, w: FontWeight.w700)),
              ),
            ]),
          ]),
        ),
        const DateStrip(),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
          child: GlassCard(
            child: Column(children: [
              Row(children: [
                Expanded(child: _big('${n.kcal.round()}', 'kcal', '/ ${p.calorieTarget}')),
                Expanded(child: _big('${n.protein.round()}g', 'protein', '/ ${p.proteinTarget}g')),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _mini('Carbs', '${n.carbs.round()} g', C.saffron)),
                Expanded(child: _mini('Fat', '${n.fat.round()} g', C.magenta)),
                Expanded(
                    child: _mini(
                        'Left',
                        '${(p.calorieTarget - n.kcal).round()}',
                        C.mint)),
              ]),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
          child: Pressable(
            onTap: () => _openRecipeBuilder(context),
            child: GlassCard(
              radius: 24,
              tint: C.violetGradient,
              child: Row(children: [
                const Icon(Icons.auto_awesome_rounded,
                    color: Colors.white, size: 26),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Custom food',
                      style: t(16, w: FontWeight.w800, color: Colors.white)),
                  Text('Build a dish from ingredients and calculate its macros',
                      style: t(12, color: Colors.white70)),
                ])),
                const Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.white, size: 18),
              ]),
            ),
          ),
        ),
        for (final m in MealType.values) ...[
          Builder(builder: (context) {
            final items = entries.where((e) => e.meal == m).toList();
            final kcal = items.fold(0.0, (a, e) => a + e.n.kcal);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SectionTitle('${m.emoji}  ${m.label}',
                    trailing: Text(items.isEmpty ? '' : '${kcal.round()} kcal',
                        style: t(14, color: C.textDim, w: FontWeight.w600))),
                if (items.isEmpty)
                  Pressable(
                    onTap: () => showGlassSheet(
                        context, (_) => AddFoodSheet(initialMeal: m)),
                    child: Container(
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18)),
                        color: Colors.white.withValues(alpha: 0.04),
                      ),
                      child: Text('+ Add ${m.label.toLowerCase()}',
                          style: t(14, color: C.textDim)),
                    ),
                  )
                else ...[
                  for (final e in items) _entryTile(context, e),
                  _addMealButton(context, m),
                ],
              ]),
            );
          }),
        ],
      ],
    );
  }

  Widget _big(String v, String label, String sub) =>
      Column(children: [
        Text(v, style: t(30, w: FontWeight.w800, ls: -0.8)),
        Text('$label $sub', style: t(12.5, color: C.textDim)),
      ]);

  void _openRecipeBuilder(BuildContext context, {FoodItem? recipe}) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => RecipeBuilderScreen(editingRecipe: recipe),
    ));
  }

  Widget _mini(String label, String v, Color c) => Column(children: [
        Text(v, style: t(17, w: FontWeight.w800, color: c)),
        Text(label, style: t(12, color: C.textDim)),
      ]);

  Widget _addMealButton(BuildContext context, MealType meal) => Pressable(
        onTap: () => showGlassSheet(
            context, (_) => AddFoodSheet(initialMeal: meal)),
        child: Container(
          height: 44,
          margin: const EdgeInsets.only(bottom: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            color: Colors.white.withValues(alpha: 0.05),
          ),
          child: Text('+ Add more',
              style: t(13.5, color: C.textDim)),
        ),
      );

  Widget _entryTile(BuildContext context, DietEntry e) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey(e.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => context.read<AppState>().removeDiet(e.id),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: C.flame.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(Icons.delete_rounded, color: Colors.white),
        ),
        child: GlassCard(
          radius: 24,
          blur: 18,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e.name, style: t(16, w: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(e.detail, style: t(12, color: C.textFaint)),
                const SizedBox(height: 6),
                Text(
                    'P ${e.n.protein.toStringAsFixed(1)}g · C ${e.n.carbs.round()}g · F ${e.n.fat.toStringAsFixed(1)}g',
                    style: t(12.5, color: C.textDim)),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${e.n.kcal.round()}', style: t(22, w: FontWeight.w800)),
              Text('kcal', style: t(11.5, color: C.textDim)),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _AmountLabel {
  const _AmountLabel(this.value, this.label);

  final String value;
  final String label;
}

// ───────────────────────────────────────────────────────────────────────────

/// Full-page recipe workspace. A modal sheet is too cramped once a recipe has
/// multiple ingredients and live nutrition values.
class RecipeBuilderScreen extends StatelessWidget {
  const RecipeBuilderScreen({super.key, this.editingRecipe});

  final FoodItem? editingRecipe;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: C.bg1,
        body: AuroraBackground(
          child: SafeArea(
            child: AddFoodSheet(
              recipeOnly: true,
              fullPage: true,
              editingRecipe: editingRecipe,
            ),
          ),
        ),
      );
}

enum _Mode { search, detail, custom }

class _RecipeIngredient {
  _RecipeIngredient(this.food)
      : byWeight = !(food.cat == 'Ingredients' && food.weightBased),
        amountController = TextEditingController(
            text: food.cat == 'Ingredients' && food.weightBased
                ? '1'
                : food.weightBased ? '100' : '1');

  final FoodItem food;
  final TextEditingController amountController;
  bool byWeight;

  double get amount => double.tryParse(amountController.text.trim()) ?? 0;
  double? get gramsPerServing {
    // Raw ingredients use a practical default: one piece/portion = 30 g.
    // Their source nutrition is still per 100 g, so weight mode remains exact.
    if (food.cat == 'Ingredients' && food.weightBased) return 30;
    if (food.weightBased) return 100;
    final match = RegExp(r'(\d+(?:\.\d+)?)\s*g', caseSensitive: false)
        .firstMatch(food.unit);
    return match == null ? null : double.tryParse(match.group(1)!);
  }

  bool get canUseWeight => gramsPerServing != null;
  double get servings {
    if (byWeight) return amount / (food.weightBased ? 100 : (gramsPerServing ?? 100));
    if (food.cat == 'Ingredients' && food.weightBased) return amount * 0.3;
    return amount;
  }
  double get totalGrams => byWeight
      ? amount
      : amount * (gramsPerServing ?? 0);
  Nutrition get nutrition => food.calc(servings, food.defaultStyle);

  void dispose() => amountController.dispose();
}

class AddFoodSheet extends StatefulWidget {
  final MealType? initialMeal;
  final bool recipeOnly;
  final bool fullPage;
  final FoodItem? editingRecipe;
  const AddFoodSheet({
    super.key,
    this.initialMeal,
    this.recipeOnly = false,
    this.fullPage = false,
    this.editingRecipe,
  });

  @override
  State<AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends State<AddFoodSheet> {
  late _Mode mode;
  String query = '';
  String cat = 'All';
  FoodItem? food;
  double qty = 1;
  CookStyle style = CookStyle.home;
  late MealType meal = widget.initialMeal ?? mealForNow();

  // custom food
  final _cName = TextEditingController();
  final _cKcal = TextEditingController();
  final _cP = TextEditingController();
  final _cC = TextEditingController();
  final _cF = TextEditingController();
  final _weight = TextEditingController();
  bool _customPer100g = false;
  bool _recipeMode = true;
  bool _recipeByWeight = false;
  final _recipeName = TextEditingController();
  final _recipeYield = TextEditingController(text: '1');
  final List<_RecipeIngredient> _ingredients = [];
  bool _refreshingCatalogue = false;

  static const cats = [
    'All', 'Bread', 'Rice', 'Dal', 'Sabzi', 'Non-veg', 'Tiffin', 'Snack',
    'Dairy', 'Drinks', 'Sweet', 'Fruit', 'Ingredients'
  ];

  @override
  void initState() {
    super.initState();
    mode = widget.recipeOnly ? _Mode.custom : _Mode.search;
    final recipe = widget.editingRecipe;
    if (recipe != null) {
      _recipeName.text = recipe.name;
      _recipeYield.text = (recipe.recipeYield ?? 1).toString();
      _recipeByWeight = recipe.recipeByWeight;
      final allFoods = searchFoods('', extra: [
        ...context.read<AppState>().customFoods,
        ...context.read<AppState>().catalogFoods,
      ]);
      for (final saved in recipe.recipeIngredients) {
        final name = saved['name']?.toString().trim().toLowerCase();
        FoodItem? source;
        for (final item in allFoods) {
          if (item.name.trim().toLowerCase() == name) {
            source = item;
            break;
          }
        }
        if (source == null) continue;
        final ingredient = _RecipeIngredient(source)
          ..byWeight = saved['byWeight'] == true;
        ingredient.amountController.text = saved['amount']?.toString() ?? '1';
        _ingredients.add(ingredient);
      }
      // Older drafts could have stored the default "1" as a recipe's total
      // weight. That makes a perfectly normal dish look 100x too caloric when
      // expressed per 100 g. Replace only that invalid value with a sensible
      // estimate from the ingredients; a valid user-entered yield is retained.
      if (_recipeByWeight &&
          (double.tryParse(_recipeYield.text.trim()) ?? 0) < 10) {
        _recipeYield.text = _recipeYieldText(_estimatedRecipeWeight);
      }
    }
  }

  @override
  void dispose() {
    for (final c in [_cName, _cKcal, _cP, _cC, _cF, _weight, _recipeName, _recipeYield]) {
      c.dispose();
    }
    for (final ingredient in _ingredients) {
      ingredient.dispose();
    }
    super.dispose();
  }

  void _pick(FoodItem f) => setState(() {
        food = f;
        qty = 1;
        style = f.defaultStyle;
        _weight.text = f.weightBased == true ? '100' : '';
        mode = _Mode.detail;
      });

  Future<void> _refreshFoodCatalogue() async {
    if (_refreshingCatalogue) return;
    setState(() => _refreshingCatalogue = true);
    final foods = await context
        .read<AuthState>()
        .downloadFoodCatalog(refreshConnection: true);
    if (!mounted) return;
    if (foods == null) {
      setState(() => _refreshingCatalogue = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Could not refresh foods. Check your internet and backend.'),
      ));
      return;
    }
    await context.read<AppState>().replaceCatalogFoods(
          foods.map(FoodItem.fromCatalogJson).toList(),
        );
    if (!mounted) return;
    setState(() => _refreshingCatalogue = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${foods.length} foods saved for offline use.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height * 0.84;
    final content = AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        switchInCurve: Curves.easeOutCubic,
        child: switch (mode) {
          _Mode.search => _search(),
          _Mode.detail => _detail(),
          _Mode.custom => _custom(),
        });
    return widget.fullPage ? content : SizedBox(height: h, child: content);
  }

  // ── search list
  Widget _search() {
    final app = context.watch<AppState>();
    final customFoods = app.customFoods;
    final remoteFoods = app.catalogFoods;
    var list = searchFoods(query, extra: [...customFoods, ...remoteFoods]);
    if (cat != 'All') list = list.where((f) => f.cat == cat).toList();
    return Column(
      key: const ValueKey('search'),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 10),
          child: Row(children: [
            Text('Add food', style: t(22, w: FontWeight.w800)),
            const Spacer(),
            if (_refreshingCatalogue)
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: C.mint),
              )
            else
              IconButton(
                onPressed: _refreshFoodCatalogue,
                tooltip: 'Refresh food database',
                icon: Icon(Icons.sync_rounded, color: C.mint),
              ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Row(children: [
            Expanded(child: Text(
              '${searchFoods('', extra: [...customFoods, ...remoteFoods]).length} foods available offline',
              style: t(12.5, color: C.textFaint),
            )),
            Pressable(
              onTap: _refreshingCatalogue ? () {} : _refreshFoodCatalogue,
              child: Text('Refresh foods', style: t(12.5, color: C.mint, w: FontWeight.w700)),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GlassField(
            hint: 'Search roti, dal, paneer, चाय…',
            icon: Icons.search_rounded,
            onChanged: (v) => setState(() => query = v),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: cats.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => GlassChip(
                label: cats[i],
                selected: cat == cats[i],
                onTap: () => setState(() => cat = cats[i])),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              for (final f in list)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Pressable(
                    onTap: () => _pick(f),
                    scale: 0.97,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Row(children: [
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${f.name}  ·  ${f.hindi}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: t(15, w: FontWeight.w700)),
                                const SizedBox(height: 2),
                                Text(f.unit,
                                    style: t(12, color: C.textFaint)),
                              ]),
                        ),
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('${f.kcal.round()} kcal',
                                  style: t(14, w: FontWeight.w700)),
                              Text('P ${f.p.toStringAsFixed(f.p < 10 ? 1 : 0)}g',
                                  style: t(12, color: C.mint)),
                            ]),
                      ]),
                    ),
                  ),
                ),
              if (list.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Center(
                      child: Text('No match for "$query"',
                          style: t(14, color: C.textDim))),
                ),
              const SizedBox(height: 8),
              Center(
                child: LiquidButton(
                  label: 'Add custom food',
                  icon: Icons.edit_rounded,
                  compact: true,
                  gradient: C.violetGradient,
                  onTap: () => setState(() => mode = _Mode.custom),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── detail: quantity + cooking style
  Widget _detail() {
    final f = food!;
    final n = f.calc(qty, style);
    final totalAmount = _totalAmount(f, qty);
    final showStyles = f.styles.length > 1;
    return SingleChildScrollView(
      key: const ValueKey('detail'),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Pressable(
            onTap: () => setState(() => mode = _Mode.search),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  size: 20, color: C.text),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(f.name,
                style: t(22, w: FontWeight.w800, ls: -0.4),
                maxLines: 2),
          ),
        ]),
        Padding(
          padding: const EdgeInsets.only(left: 40, top: 2),
          child: Text('${f.hindi} · 1 serving = ${f.unit}',
              style: t(13, color: C.textDim)),
        ),
        const SizedBox(height: 18),
        if (f.custom)
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(spacing: 2, children: [
              if (f.isRecipe)
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => RecipeBuilderScreen(editingRecipe: f),
                    ));
                  },
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text('Edit recipe'),
                ),
              TextButton.icon(
                onPressed: () => _deleteCustomFood(f),
                style: TextButton.styleFrom(foregroundColor: C.flame),
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Delete'),
              ),
            ]),
          ),

        // live nutrition
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            Row(children: [
              Expanded(
                child: Column(children: [
                  Text(totalAmount.value,
                      style: t(50, w: FontWeight.w800, ls: -2)),
                  Text(totalAmount.label, style: t(13, color: C.textDim)),
                ]),
              ),
              Container(
                width: 1,
                height: 52,
                color: Colors.white.withValues(alpha: 0.16),
              ),
              Expanded(
                child: Column(children: [
                  Text('${n.kcal.round()}',
                      style: t(50, w: FontWeight.w800, ls: -2)),
                  Text('calories', style: t(13, color: C.textDim)),
                ]),
              ),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              _macro('Protein', n.protein, C.mint),
              _macro('Carbs', n.carbs, C.saffron),
              _macro('Fat', n.fat, C.magenta),
            ]),
          ]),
        ),
        const SizedBox(height: 18),

        Text(f.weightBased == true ? 'Weight' : 'Quantity',
            style: t(15, w: FontWeight.w700)),
        const SizedBox(height: 10),
        if (f.weightBased == true)
          _weightPicker()
        else
          Row(children: [
          _stepBtn(Icons.remove_rounded,
              () => setState(() => qty = (qty - 0.5).clamp(0.5, 20).toDouble())),
          Expanded(
            child: Column(children: [
              Text(
                  qty == qty.roundToDouble()
                      ? '${qty.toInt()}'
                      : qty.toStringAsFixed(1),
                  style: t(28, w: FontWeight.w800)),
              Text('× ${f.unit}',
                  textAlign: TextAlign.center,
                  style: t(12, color: C.textFaint)),
            ]),
          ),
          _stepBtn(Icons.add_rounded,
              () => setState(() => qty = (qty + 0.5).clamp(0.5, 20).toDouble())),
          ]),

        if (showStyles) ...[
          const SizedBox(height: 20),
          Row(children: [
            Text('Cooking style', style: t(15, w: FontWeight.w700)),
            const SizedBox(width: 8),
            Text('changes fat & calories',
                style: t(12, color: C.textFaint)),
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final s in f.styles)
              GlassChip(
                label: '${s.emoji} ${s.label}',
                selected: style == s,
                onTap: () => setState(() => style = s),
              ),
          ]),
        ],

        const SizedBox(height: 20),
        Text('Meal', style: t(15, w: FontWeight.w700)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final m in MealType.values)
            GlassChip(
              label: '${m.emoji} ${m.label}',
              selected: meal == m,
              activeGradient: C.mintGradient,
              onTap: () => setState(() => meal = m),
            ),
        ]),
        const SizedBox(height: 26),
        SizedBox(
          width: double.infinity,
          child: Center(
            child: LiquidButton(
              label: 'Add to ${meal.label}',
              icon: Icons.check_rounded,
              onTap: () => _addFood(f, meal),
            ),
          ),
        ),
      ]),
    );
  }

  void _addFood(FoodItem food, MealType target) {
    context.read<AppState>().addFood(
          food: food,
          qty: qty,
          style: style,
          meal: target,
        );
    Navigator.pop(context);
  }

  Future<void> _deleteCustomFood(FoodItem food) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete custom food?'),
        content: Text('"${food.name}" will be removed from your recipes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: C.flame),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !mounted) return;
    context.read<AppState>().removeCustomFood(food);
    Navigator.pop(context);
  }

  Widget _macro(String l, double v, Color c) => Expanded(
        child: Column(children: [
          Text('${v.toStringAsFixed(v < 10 ? 1 : 0)} g',
              style: t(18, w: FontWeight.w800, color: c)),
          Text(l, style: t(12, color: C.textDim)),
        ]),
      );

  Widget _stepBtn(IconData i, VoidCallback onTap) => Pressable(
        onTap: onTap,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: Icon(i, color: Colors.white),
        ),
      );

  Widget _weightPicker() {
    final grams = qty * 100;
    void setGrams(String text) {
      final value = double.tryParse(text.trim());
      if (value != null && value > 0) {
        setState(() => qty = (value / 100).clamp(0.01, 100).toDouble());
      }
    }
    void changeGrams(double delta) {
      final value = (grams + delta).clamp(1, 10000).toDouble();
      setState(() {
        qty = value / 100;
        _weight.text = _gramsLabel(value).replaceAll(' g', '');
      });
    }

    return Row(children: [
      _stepBtn(Icons.remove_rounded,
          () => changeGrams(-10)),
      Expanded(
        child: TextField(
          controller: _weight,
          textAlign: TextAlign.center,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: setGrams,
          onSubmitted: setGrams,
          style: t(28, w: FontWeight.w800),
          decoration: InputDecoration(
            suffixText: 'g',
            suffixStyle: t(14, color: C.textDim),
            border: InputBorder.none,
          ),
        ),
      ),
      _stepBtn(Icons.add_rounded,
          () => changeGrams(10)),
    ]);
  }

  String _gramsLabel(double grams) =>
      grams == grams.roundToDouble() ? '${grams.toInt()} g' : '${grams.toStringAsFixed(1)} g';

  _AmountLabel _totalAmount(FoodItem food, double quantity) {
    if (food.weightBased == true) {
      return _AmountLabel(
        _gramsLabel(quantity * 100).replaceAll(' g', ''),
        'g total weight',
      );
    }

    // Units such as "1 glass (250 ml)" can show the actual live total.
    final match = RegExp(
      r'\((\d+(?:\.\d+)?)\s*(g|ml)\)',
      caseSensitive: false,
    ).firstMatch(food.unit);
    if (match != null) {
      final perServing = double.parse(match.group(1)!);
      final unit = match.group(2)!.toLowerCase();
      final amount = perServing * quantity;
      final value = amount == amount.roundToDouble()
          ? amount.toInt().toString()
          : amount.toStringAsFixed(1);
      return _AmountLabel(value, '$unit total');
    }

    return _AmountLabel(_quantityLabel(quantity), 'servings total');
  }

  String _quantityLabel(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);

  // ── custom food / recipe builder
  Widget _custom() => _recipeMode ? _recipeBuilder() : _manualCustom();

  Nutrition get _recipeNutrition => _ingredients.fold(
      Nutrition.zero, (total, ingredient) => total + ingredient.nutrition);

  /// Before cooking, ingredient weights are the best useful default for the
  /// prepared dish. Users can replace this with the actual cooked weight.
  double get _estimatedRecipeWeight => _ingredients.fold(
      0.0, (total, ingredient) => total + ingredient.totalGrams);

  String _recipeYieldText(double grams) {
    final safeGrams = grams < 10 ? 100.0 : grams;
    return safeGrams == safeGrams.roundToDouble()
        ? safeGrams.toInt().toString()
        : safeGrams.toStringAsFixed(1);
  }

  void _selectRecipeWeightMode() {
    final current = double.tryParse(_recipeYield.text.trim()) ?? 0;
    setState(() {
      _recipeByWeight = true;
      // "1" is the serving-mode default, not a realistic prepared weight.
      if (current < 10) {
        _recipeYield.text = _recipeYieldText(_estimatedRecipeWeight);
      }
    });
  }

  Future<void> _addRecipeIngredient() async {
    final app = context.read<AppState>();
    final foods = searchFoods('', extra: [...app.customFoods, ...app.catalogFoods]);
    final picked = await showDialog<FoodItem>(
      context: context,
      builder: (dialogContext) {
        var query = '';
        return StatefulBuilder(builder: (context, setDialogState) {
          final matches = foods.where((food) {
            final text = '${food.name} ${food.hindi} ${food.cat}'.toLowerCase();
            return text.contains(query.trim().toLowerCase());
          }).toList();
          return AlertDialog(
            backgroundColor: C.bg2,
            title: Text('Choose ingredient', style: t(20, w: FontWeight.w800)),
            content: SizedBox(
              width: double.maxFinite,
              height: 390,
              child: Column(children: [
                GlassField(
                  hint: 'Search paneer, rice, tofu...',
                  icon: Icons.search_rounded,
                  onChanged: (value) => setDialogState(() => query = value),
                ),
                const SizedBox(height: 10),
                Expanded(child: ListView.separated(
                  itemCount: matches.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final food = matches[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(food.name, style: t(15, w: FontWeight.w700)),
                      subtitle: Text(
                          food.cat == 'Ingredients' && food.weightBased
                              ? '1 piece = 30 g · weight available'
                              : food.weightBased ? 'Per 100 g' : food.unit,
                          style: t(12, color: C.textDim)),
                      trailing: Text('${food.kcal.round()} kcal',
                          style: t(12, color: C.mint, w: FontWeight.w700)),
                      onTap: () => Navigator.pop(dialogContext, food),
                    );
                  },
                )),
              ]),
            ),
          );
        });
      },
    );
    if (picked != null && mounted) {
      setState(() => _ingredients.add(_RecipeIngredient(picked)));
    }
  }

  Widget _recipeBuilder() {
    final total = _recipeNutrition;
    final yieldValue = double.tryParse(_recipeYield.text.trim()) ?? 0;
    final divisor = _recipeByWeight
        ? (yieldValue <= 0 ? 0 : yieldValue / 100)
        : yieldValue;
    // Never show a scaled nutrition result for an invalid yield. Apart from
    // being misleading, a 1 g default makes the result appear 100x larger.
    final validYield = _recipeByWeight ? yieldValue >= 10 : yieldValue > 0;
    final perUnit = !validYield || divisor <= 0
        ? Nutrition.zero
        : total.scale(1 / divisor);
    final canSave = _recipeName.text.trim().isNotEmpty &&
        _ingredients.isNotEmpty && validYield;
    return SingleChildScrollView(
      key: const ValueKey('recipe'),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Pressable(onTap: () {
            if (widget.fullPage) {
              Navigator.of(context).pop();
            } else {
              setState(() => mode = _Mode.search);
            }
          },
            child: Padding(padding: const EdgeInsets.all(6),
              child: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: C.text))),
          const SizedBox(width: 6),
          Expanded(child: Text(widget.editingRecipe == null ? 'Make a recipe' : 'Edit recipe',
              style: t(22, w: FontWeight.w800))),
          TextButton.icon(
            onPressed: () => setState(() => _recipeMode = false),
            icon: const Icon(Icons.edit_note_rounded, size: 18),
            label: const Text('Label values'),
          ),
        ]),
        Padding(padding: const EdgeInsets.only(left: 40, top: 2),
          child: Text('Pick ingredients from the food database; nutrition is calculated automatically.',
              style: t(13, color: C.textDim))),
        const SizedBox(height: 18),
        GlassField(controller: _recipeName, hint: 'Dish name, e.g. Tofu sandwich',
          icon: Icons.restaurant_menu_rounded, onChanged: (_) => setState(() {})),
        const SizedBox(height: 16),
        Text('Ingredients', style: t(16, w: FontWeight.w800)),
        const SizedBox(height: 8),
        if (_ingredients.isEmpty)
          GlassCard(child: Text('Add each ingredient and its amount. The app will total the recipe for you.',
              style: t(13, color: C.textDim))),
        for (var i = 0; i < _ingredients.length; i++)
          Padding(padding: const EdgeInsets.only(top: 8),
              child: _recipeIngredientRow(_ingredients[i], i)),
        const SizedBox(height: 10),
        Center(child: LiquidButton(label: 'Add ingredient', icon: Icons.add_rounded,
          compact: true, gradient: C.mintGradient, onTap: _addRecipeIngredient)),
        const SizedBox(height: 18),
        Text('How will you log this dish?', style: t(16, w: FontWeight.w800)),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: GlassChip(label: 'Piece / serving', selected: !_recipeByWeight,
              activeGradient: C.violetGradient,
              onTap: () => setState(() => _recipeByWeight = false))),
          const SizedBox(width: 8),
          Expanded(child: GlassChip(label: 'By weight', selected: _recipeByWeight,
              activeGradient: C.mintGradient,
              onTap: _selectRecipeWeightMode)),
        ]),
        const SizedBox(height: 10),
        GlassField(controller: _recipeYield,
          hint: _recipeByWeight ? 'Total prepared weight' : 'Number of pieces / servings made',
          suffix: _recipeByWeight ? 'g' : 'pieces',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() {})),
        if (_recipeByWeight && yieldValue > 0 && yieldValue < 10)
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Text('Enter at least 10 g as the prepared recipe weight.',
                style: t(12, color: C.flame)),
          ),
        const SizedBox(height: 16),
        GlassCard(tint: C.mintGradient, child: Column(children: [
          Text('Per ${_recipeByWeight ? '100 g' : 'piece'}', style: t(13, color: Colors.white70)),
          const SizedBox(height: 4),
          Text('${perUnit.kcal.round()} kcal', style: t(30, w: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 10),
          Row(children: [
            _recipeMacro('Protein', perUnit.protein), _recipeMacro('Carbs', perUnit.carbs),
            _recipeMacro('Fat', perUnit.fat),
          ]),
        ])),
        const SizedBox(height: 24),
        Center(child: LiquidButton(label: 'Save recipe', icon: Icons.bookmark_add_rounded,
          onTap: canSave ? () {
            final food = FoodItem(
              name: _recipeName.text.trim(), hindi: 'My recipe',
              unit: _recipeByWeight ? '100 g' : '1 piece', cat: 'Custom',
              kcal: perUnit.kcal, p: perUnit.protein, c: perUnit.carbs, f: perUnit.fat,
              oil: 0, styles: const [CookStyle.plain], defaultStyle: CookStyle.plain,
              custom: true, weightBased: _recipeByWeight,
              recipeIngredients: _ingredients.map((ingredient) => {
                'name': ingredient.food.name,
                'amount': ingredient.amount,
                'byWeight': ingredient.byWeight,
              }).toList(),
              recipeYield: yieldValue,
              recipeByWeight: _recipeByWeight,
            );
            context.read<AppState>().saveCustomFood(food);
            if (widget.fullPage) {
              Navigator.of(context).pop();
            } else {
              setState(() { query = food.name; mode = _Mode.search; });
            }
          } : null)),
      ]),
    );
  }

  Widget _recipeIngredientRow(_RecipeIngredient ingredient, int index) {
    final food = ingredient.food;
    final n = ingredient.nutrition;
    final totalGrams = ingredient.totalGrams;
    return GlassCard(
      radius: 20,
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(food.name, style: t(14, w: FontWeight.w800)),
            Text('${n.kcal.round()} kcal · P ${n.protein.toStringAsFixed(1)}g'
                '${totalGrams > 0 ? ' · ${totalGrams.round()} g' : ''}',
                style: t(12, color: C.textDim)),
          ])),
          IconButton(onPressed: () => setState(() {
            final removed = _ingredients.removeAt(index);
            removed.dispose();
          }), icon: Icon(Icons.close_rounded, color: C.flame, size: 20)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: GlassChip(
            label: 'Per serving',
            selected: !ingredient.byWeight,
            activeGradient: C.violetGradient,
            onTap: () => setState(() {
              ingredient.byWeight = false;
              ingredient.amountController.text = '1';
            }),
          )),
          const SizedBox(width: 8),
          Expanded(child: GlassChip(
            label: 'By weight',
            selected: ingredient.byWeight,
            activeGradient: C.mintGradient,
            onTap: ingredient.canUseWeight ? () => setState(() {
              ingredient.byWeight = true;
              ingredient.amountController.text =
                  (ingredient.gramsPerServing ?? 100).round().toString();
            }) : () {},
          )),
          const SizedBox(width: 10),
          SizedBox(width: 86, child: TextField(
            controller: ingredient.amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            onChanged: (_) => setState(() {}),
            style: t(15, w: FontWeight.w800),
            decoration: InputDecoration(
              isDense: true,
              suffixText: ingredient.byWeight ? 'g' : '×',
              suffixStyle: t(12, color: C.textDim),
              border: UnderlineInputBorder(
                  borderSide: BorderSide(color: C.textFaint)),
            ),
          )),
        ]),
        if (!ingredient.canUseWeight)
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Text('Weight is unavailable because this preset has no gram serving size.',
                style: t(11, color: C.textFaint)),
          ),
      ]),
    );
  }

  Widget _recipeMacro(String label, double value) => Expanded(child: Column(children: [
    Text('${value.toStringAsFixed(value < 10 ? 1 : 0)} g',
        style: t(15, w: FontWeight.w800, color: Colors.white)),
    Text(label, style: t(11, color: Colors.white70)),
  ]));

  Widget _manualCustom() {
    double val(TextEditingController c) =>
        double.tryParse(c.text.trim()) ?? 0;
    final valid = _cName.text.trim().isNotEmpty && val(_cKcal) > 0;
    return SingleChildScrollView(
      key: const ValueKey('custom'),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Pressable(
            onTap: () => setState(() => mode = _Mode.search),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  size: 20, color: C.text),
            ),
          ),
          const SizedBox(width: 6),
          Text('Custom food', style: t(22, w: FontWeight.w800)),
        ]),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 40),
          child: Text(
              _customPer100g
                  ? 'Enter label values per 100 g. Set the eaten weight next.'
                  : 'Enter values for one serving (e.g. from a label).',
              style: t(13, color: C.textDim)),
        ),
        const SizedBox(height: 18),
        Row(children: [
          GlassChip(
            label: 'Per serving',
            selected: !_customPer100g,
            onTap: () => setState(() => _customPer100g = false),
          ),
          const SizedBox(width: 8),
          GlassChip(
            label: 'Per 100 g',
            selected: _customPer100g,
            activeGradient: C.mintGradient,
            onTap: () => setState(() => _customPer100g = true),
          ),
        ]),
        const SizedBox(height: 12),
        GlassField(
            controller: _cName,
            hint: 'Dish name',
            icon: Icons.restaurant_rounded,
            onChanged: (_) => setState(() {})),
        const SizedBox(height: 10),
        GlassField(
            controller: _cKcal,
            hint: _customPer100g ? 'Calories per 100 g' : 'Calories',
            suffix: 'kcal',
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {})),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: GlassField(
                  controller: _cP,
                  hint: 'Protein',
                  suffix: 'g',
                  keyboardType: TextInputType.number)),
          const SizedBox(width: 10),
          Expanded(
              child: GlassField(
                  controller: _cC,
                  hint: 'Carbs',
                  suffix: 'g',
                  keyboardType: TextInputType.number)),
          const SizedBox(width: 10),
          Expanded(
              child: GlassField(
                  controller: _cF,
                  hint: 'Fat',
                  suffix: 'g',
                  keyboardType: TextInputType.number)),
        ]),
        const SizedBox(height: 22),
        Center(
          child: LiquidButton(
            label: 'Continue',
            icon: Icons.arrow_forward_rounded,
            onTap: valid
                ? () {
                    final f = FoodItem(
                      name: _cName.text.trim(),
                      hindi: 'custom',
                      unit: _customPer100g ? '100 g' : '1 serving',
                      cat: 'Custom',
                      kcal: val(_cKcal),
                      p: val(_cP),
                      c: val(_cC),
                      f: val(_cF),
                      oil: 0,
                      styles: const [CookStyle.plain],
                      defaultStyle: CookStyle.plain,
                      custom: true,
                      weightBased: _customPer100g,
                    );
                    context.read<AppState>().saveCustomFood(f);
                    // Keep the saved item in search. The user can then choose it
                    // exactly like any other food and select Breakfast/Lunch/etc.
                    setState(() {
                      query = f.name;
                      mode = _Mode.search;
                    });
                  }
                : null,
          ),
        ),
      ]),
    );
  }
}
