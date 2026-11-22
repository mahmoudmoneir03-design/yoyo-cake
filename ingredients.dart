import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../util.dart';
import '../widgets.dart';

class IngredientsPage extends StatelessWidget {
  const IngredientsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('المكونات والوصفات'),
          bottom: const TabBar(
            tabs: [Tab(text: 'الخامات'), Tab(text: 'الوصفات')],
          ),
        ),
        body: const TabBarView(children: [_IngredientsTab(), _RecipesTab()]),
      ),
    );
  }
}

class _IngredientsTab extends StatelessWidget {
  const _IngredientsTab();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final list = [...store.ingredients]
          ..sort((a, b) => a.name.compareTo(b.name));
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Text(
              'الخامة هي اللي بتشتريها (سكر، دقيق، كريمة، بيض…) بسعر شرائها. بعد كده تقدر تحدد كمية كل خامة في كل تورتة وتكلفتها بتتحسب لوحدها.',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const IngredientFormPage())),
              icon: const Icon(Icons.add),
              label: const Text('خامة جديدة'),
            ),
            const SizedBox(height: 12),
            if (list.isEmpty)
              const EmptyState(
                title: 'لسه مفيش خامات',
                text: 'سجّل أول خامة بكمية العبوة وسعرها.',
              ),
            for (final g in list) ...[
              Card(
                margin: EdgeInsets.zero,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: cs.outlineVariant),
                ),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  title: Text(g.name,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                      '${money(g.packPrice)} لكل ${fmtDec(g.packQty)} ${g.unit}'),
                  trailing: Text('${fmtDec(g.unitCost)} ج.م\nلكل ${g.unit}',
                      textAlign: TextAlign.end,
                      style: const TextStyle(fontSize: 12.5)),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => IngredientFormPage(ing: g))),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }
}

class _RecipesTab extends StatelessWidget {
  const _RecipesTab();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final list = [...store.recipes]..sort((a, b) => a.name.compareTo(b.name));
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Text(
              'الوصفة هي كميات الخامات في نوع تورتة معين (مثلاً: تورتة شوكولاتة ٢ كيلو). بتختارها في الطلب وتتحسب تكلفتها بأسعار الخامات الحالية.',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const RecipeFormPage())),
              icon: const Icon(Icons.add),
              label: const Text('وصفة جديدة'),
            ),
            const SizedBox(height: 12),
            if (list.isEmpty)
              const EmptyState(
                title: 'لسه مفيش وصفات',
                text: 'سجّل الخامات الأول، وبعدها اعمل وصفة بكمياتها.',
              ),
            for (final r in list) ...[
              Card(
                margin: EdgeInsets.zero,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: cs.outlineVariant),
                ),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  title: Text(r.name,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('${r.lines.length} خامة'),
                  trailing: Text(money(store.recipeCost(r)),
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => RecipeFormPage(recipe: r))),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }
}

class IngredientFormPage extends StatefulWidget {
  final Ingredient? ing;
  const IngredientFormPage({super.key, this.ing});

  @override
  State<IngredientFormPage> createState() => _IngredientFormPageState();
}

class _IngredientFormPageState extends State<IngredientFormPage> {
  late final TextEditingController name, unit, qty, price;

  @override
  void initState() {
    super.initState();
    final g = widget.ing;
    name = TextEditingController(text: g?.name ?? '');
    unit = TextEditingController(text: g?.unit ?? 'جرام');
    qty = TextEditingController(text: g == null ? '' : fmtDec(g.packQty));
    price = TextEditingController(text: g == null ? '' : fmtDec(g.packPrice));
  }

  @override
  void dispose() {
    name.dispose();
    unit.dispose();
    qty.dispose();
    price.dispose();
    super.dispose();
  }

  void _save() {
    final nm = name.text.trim();
    final u = unit.text.trim();
    final q = parseNum(qty.text);
    final p = parseNum(price.text);
    if (nm.isEmpty) {
      snack(context, 'اكتب اسم الخامة');
      return;
    }
    if (u.isEmpty) {
      snack(context, 'اكتب الوحدة (جرام، مللي، قطعة…)');
      return;
    }
    if (q <= 0) {
      snack(context, 'اكتب كمية العبوة');
      return;
    }
    final g = widget.ing ??
        Ingredient(id: uid(), name: nm, unit: u, packQty: q, packPrice: p);
    g.name = nm;
    g.unit = u;
    g.packQty = q;
    g.packPrice = p;
    store.putIngredient(g);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.ing;
    final q = parseNum(qty.text);
    final p = parseNum(price.text);
    final u = unit.text.trim();
    return Scaffold(
      appBar: AppBar(title: Text(g == null ? 'خامة جديدة' : 'تعديل خامة')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          textField('اسم الخامة', name, hint: 'مثلاً: سكر، دقيق، كريمة'),
          const SizedBox(height: 12),
          textField('الوحدة', unit,
              hint: 'جرام، مللي، قطعة', onChanged: (_) => setState(() {})),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              for (final x in ['جرام', 'مللي', 'قطعة'])
                ActionChip(
                  label: Text(x),
                  onPressed: () => setState(() => unit.text = x),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: numField('الكمية اللي اشتريتها', qty,
                      suffix: u, onChanged: (_) => setState(() {}))),
              const SizedBox(width: 10),
              Expanded(
                  child: numField('بسعر', price,
                      onChanged: (_) => setState(() {}))),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'مثال: كيس سكر ١٠٠٠ جرام بـ ٤٠ جنيه. لو بتشتري بالكيلو وبتحسب بالجرام اكتب ١٠٠٠ جرام.',
            style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          if (q > 0)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'تكلفة ال${u.isEmpty ? 'وحدة' : u} الواحد: ${fmtDec(p / q)} ج.م',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: const Text('حفظ'),
          ),
          if (g != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () async {
                final ok = await confirmDialog(context,
                    'تمسح الخامة دي؟ الطلبات القديمة هتحتفظ بتكلفتها.');
                if (ok) {
                  store.deleteIngredient(g.id);
                  if (context.mounted) Navigator.pop(context);
                }
              },
              style: OutlinedButton.styleFrom(
                  foregroundColor: badC(context),
                  minimumSize: const Size.fromHeight(48)),
              child: const Text('مسح الخامة'),
            ),
          ],
        ],
      ),
    );
  }
}

class RecipeFormPage extends StatefulWidget {
  final Recipe? recipe;
  const RecipeFormPage({super.key, this.recipe});

  @override
  State<RecipeFormPage> createState() => _RecipeFormPageState();
}

class _RecipeFormPageState extends State<RecipeFormPage> {
  late final TextEditingController name;
  late List<Line> lines;

  @override
  void initState() {
    super.initState();
    final r = widget.recipe;
    name = TextEditingController(text: r?.name ?? '');
    lines = r == null ? [] : r.lines.map((l) => Line.fromJson(l.toJson())).toList();
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  void _save() {
    final nm = name.text.trim();
    if (nm.isEmpty) {
      snack(context, 'اكتب اسم الوصفة');
      return;
    }
    if (lines.isEmpty) {
      snack(context, 'ضيف خامة واحدة على الأقل');
      return;
    }
    final r = widget.recipe ?? Recipe(id: uid(), name: nm);
    r.name = nm;
    r.lines = lines;
    store.putRecipe(r);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.recipe;
    return Scaffold(
      appBar: AppBar(title: Text(r == null ? 'وصفة جديدة' : 'تعديل وصفة')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          textField('اسم الوصفة', name, hint: 'مثلاً: تورتة شوكولاتة ٢ كيلو'),
          const SizedBox(height: 14),
          FormCard('الخامات والكميات', [
            LinesEditor(lines: lines, onChanged: () => setState(() {})),
          ]),
          const SizedBox(height: 6),
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: const Text('حفظ'),
          ),
          if (r != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () async {
                final ok = await confirmDialog(context, 'تمسح الوصفة دي؟');
                if (ok) {
                  store.deleteRecipe(r.id);
                  if (context.mounted) Navigator.pop(context);
                }
              },
              style: OutlinedButton.styleFrom(
                  foregroundColor: badC(context),
                  minimumSize: const Size.fromHeight(48)),
              child: const Text('مسح الوصفة'),
            ),
          ],
        ],
      ),
    );
  }
}
