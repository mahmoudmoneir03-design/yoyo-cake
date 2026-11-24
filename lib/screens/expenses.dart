import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../util.dart';
import '../widgets.dart';

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  String month = today().substring(0, 7);

  void _shift(int n) {
    final p = parseDate('$month-01');
    setState(() => month = isoDate(DateTime(p.year, p.month + n, 1)).substring(0, 7));
  }

  void _open([Expense? e]) {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => ExpenseFormPage(expense: e)));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('المصروفات')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _open(),
        icon: const Icon(Icons.add),
        label: const Text('مصروف جديد'),
      ),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final list = store.expenses
              .where((e) => e.date.startsWith(month))
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));
          final total = list.fold<double>(0, (s, e) => s + e.amount);
          final by = <String, double>{};
          for (final e in list) {
            by[e.cat] = (by[e.cat] ?? 0) + e.amount;
          }
          final cats = by.keys.toList()..sort((a, b) => by[b]!.compareTo(by[a]!));
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                      tooltip: 'الشهر اللي فات',
                      onPressed: () => _shift(-1),
                      icon: const Icon(Icons.chevron_right)),
                  Text(fmtMonth(month),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                  IconButton(
                      tooltip: 'الشهر الجاي',
                      onPressed: () => _shift(1),
                      icon: const Icon(Icons.chevron_left)),
                ],
              ),
              StatTile('إجمالي المصروفات العامة', money(total)),
              if (cats.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final c in cats) Pill('$c ${fmtInt(by[c]!)}'),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'دي مصروفات الورشة العامة (إيجار، معدات، إعلانات…). تكلفة خامات كل تورتة بتتسجّل جوه الطلب نفسه.',
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              if (list.isEmpty)
                const EmptyState(
                  title: 'مفيش مصروفات في الشهر ده',
                  text: 'سجّل الإيجار والإعلانات والمعدات عشان صافي الربح يطلع صح.',
                ),
              for (final e in list) ...[
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
                    title: Text(e.cat,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                        '${fmtDay(e.date)}${e.note.isEmpty ? '' : ' · ${e.note}'}'),
                    trailing: Text(money(e.amount),
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    onTap: () => _open(e),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
          );
        },
      ),
    );
  }
}

class ExpenseFormPage extends StatefulWidget {
  final Expense? expense;
  const ExpenseFormPage({super.key, this.expense});

  @override
  State<ExpenseFormPage> createState() => _ExpenseFormPageState();
}

class _ExpenseFormPageState extends State<ExpenseFormPage> {
  late final TextEditingController amount, note;
  late String date, cat;

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    amount = TextEditingController(text: e == null ? '' : fmtDec(e.amount));
    note = TextEditingController(text: e?.note ?? '');
    date = e?.date ?? today();
    cat = e?.cat ?? expenseCats.first;
  }

  @override
  void dispose() {
    amount.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: parseDate(date),
      firstDate: DateTime(2000),
      lastDate: DateTime(2040),
    );
    if (d != null) setState(() => date = isoDate(d));
  }

  void _save() {
    final a = parseNum(amount.text);
    if (a <= 0) {
      snack(context, 'اكتب المبلغ');
      return;
    }
    final e = widget.expense ??
        Expense(id: uid(), date: date, cat: cat, amount: a);
    e.date = date;
    e.cat = cat;
    e.amount = a;
    e.note = note.text.trim();
    store.putExpense(e);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.expense;
    return Scaffold(
      appBar: AppBar(title: Text(e == null ? 'مصروف جديد' : 'تعديل مصروف')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          PickField(
            label: 'التاريخ',
            value: fmtDay(date),
            icon: Icons.calendar_month,
            onTap: _pickDate,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final c in expenseCats)
                ChoiceChip(
                  label: Text(c),
                  selected: cat == c,
                  onSelected: (_) => setState(() => cat = c),
                ),
            ],
          ),
          const SizedBox(height: 14),
          numField('المبلغ', amount),
          const SizedBox(height: 12),
          textField('ملاحظة', note),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: const Text('حفظ'),
          ),
          if (e != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () async {
                final ok = await confirmDialog(context, 'تمسح المصروف ده؟');
                if (ok) {
                  store.deleteExpense(e.id);
                  if (context.mounted) Navigator.pop(context);
                }
              },
              style: OutlinedButton.styleFrom(
                  foregroundColor: badC(context),
                  minimumSize: const Size.fromHeight(48)),
              child: const Text('مسح المصروف'),
            ),
          ],
        ],
      ),
    );
  }
}
