import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'util.dart';

final Store store = Store();

class Rep {
  final List<Order> orders;
  final double sales, paid, direct, general;
  Rep(this.orders, this.sales, this.paid, this.direct, this.general);

  int get count => orders.length;
  double get due => sales - paid;
  double get gross => sales - direct;
  double get net => gross - general;
  double get margin => sales > 0 ? net / sales * 100 : 0;
  double get avg => count > 0 ? sales / count : 0;
}

class MonthRow {
  final String key;
  final double sales, direct, general;
  MonthRow(this.key, this.sales, this.direct, this.general);
  double get net => sales - direct - general;
}

class Store extends ChangeNotifier {
  List<Order> orders = [];
  List<Customer> customers = [];
  List<Expense> expenses = [];
  List<Ingredient> ingredients = [];
  List<Recipe> recipes = [];
  SharedPreferences? _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString('db');
    if (raw == null) return;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      List<Map<String, dynamic>> l(String k) => (m[k] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      orders = l('orders').map(Order.fromJson).toList();
      customers = l('customers').map(Customer.fromJson).toList();
      expenses = l('expenses').map(Expense.fromJson).toList();
      ingredients = l('ingredients').map(Ingredient.fromJson).toList();
      recipes = l('recipes').map(Recipe.fromJson).toList();
    } catch (_) {
      // لو الملف تالف نبدأ من الأول بدل ما التطبيق يقفل.
    }
  }

  void _save() {
    try {
      _prefs?.setString(
        'db',
        jsonEncode({
          'orders': orders.map((e) => e.toJson()).toList(),
          'customers': customers.map((e) => e.toJson()).toList(),
          'expenses': expenses.map((e) => e.toJson()).toList(),
          'ingredients': ingredients.map((e) => e.toJson()).toList(),
          'recipes': recipes.map((e) => e.toJson()).toList(),
        }),
      );
    } catch (_) {}
    notifyListeners();
  }

  // ---------- lookups ----------
  Order? orderById(String id) {
    for (final o in orders) {
      if (o.id == id) return o;
    }
    return null;
  }

  Customer? customerById(String id) {
    for (final c in customers) {
      if (c.id == id) return c;
    }
    return null;
  }

  Ingredient? ingredientById(String id) {
    for (final i in ingredients) {
      if (i.id == id) return i;
    }
    return null;
  }

  /// تكلفة الوصفة بأسعار الخامات الحالية.
  double recipeCost(Recipe r) {
    var t = 0.0;
    for (final l in r.lines) {
      final ing = ingredientById(l.ingredientId);
      t += l.qty * (ing?.unitCost ?? l.unitCost);
    }
    return t;
  }

  // ---------- writes ----------
  void putOrder(Order o) {
    final i = orders.indexWhere((x) => x.id == o.id);
    if (i >= 0) {
      orders[i] = o;
    } else {
      orders.add(o);
    }
    _save();
  }

  void deleteOrder(String id) {
    orders.removeWhere((x) => x.id == id);
    _save();
  }

  void putCustomer(Customer c) {
    final i = customers.indexWhere((x) => x.id == c.id);
    if (i >= 0) {
      customers[i] = c;
    } else {
      customers.add(c);
    }
    _save();
  }

  void deleteCustomer(String id) {
    customers.removeWhere((x) => x.id == id);
    _save();
  }

  void putExpense(Expense e) {
    final i = expenses.indexWhere((x) => x.id == e.id);
    if (i >= 0) {
      expenses[i] = e;
    } else {
      expenses.add(e);
    }
    _save();
  }

  void deleteExpense(String id) {
    expenses.removeWhere((x) => x.id == id);
    _save();
  }

  void putIngredient(Ingredient g) {
    final i = ingredients.indexWhere((x) => x.id == g.id);
    if (i >= 0) {
      ingredients[i] = g;
    } else {
      ingredients.add(g);
    }
    _save();
  }

  void deleteIngredient(String id) {
    ingredients.removeWhere((x) => x.id == id);
    _save();
  }

  void putRecipe(Recipe r) {
    final i = recipes.indexWhere((x) => x.id == r.id);
    if (i >= 0) {
      recipes[i] = r;
    } else {
      recipes.add(r);
    }
    _save();
  }

  void deleteRecipe(String id) {
    recipes.removeWhere((x) => x.id == id);
    _save();
  }

  /// بترجّع id العميل: بتدوّر برقم الموبايل (أو بالاسم لو مفيش رقم) وتعمل عميل جديد لو مش موجود.
  String ensureCustomer(String name, String phone, String address) {
    final key = digitsOf(phone);
    for (final x in customers) {
      final xd = digitsOf(x.phone);
      final same = key.isNotEmpty
          ? xd == key
          : (xd.isEmpty && x.name.trim() == name.trim());
      if (same) return x.id;
    }
    final c = Customer(id: uid(), name: name, phone: phone, address: address);
    customers.add(c);
    _save();
    return c.id;
  }

  // ---------- reports ----------
  Rep report(String from, String to, bool onlyDelivered) {
    final os = orders.where((o) {
      if (o.status == 'cancelled') return false;
      if (onlyDelivered && o.status != 'delivered') return false;
      return o.date.compareTo(from) >= 0 && o.date.compareTo(to) <= 0;
    }).toList();
    var sales = 0.0, paid = 0.0, direct = 0.0, general = 0.0;
    for (final o in os) {
      sales += o.price;
      paid += o.paid;
      direct += o.cost;
    }
    for (final e in expenses) {
      if (e.date.compareTo(from) >= 0 && e.date.compareTo(to) <= 0) {
        general += e.amount;
      }
    }
    return Rep(os, sales, paid, direct, general);
  }

  List<MonthRow> monthSeries(int n, bool onlyDelivered) {
    final now = DateTime.now();
    final out = <MonthRow>[];
    for (var i = n - 1; i >= 0; i--) {
      final a = DateTime(now.year, now.month - i, 1);
      final b = DateTime(now.year, now.month - i + 1, 0);
      final r = report(isoDate(a), isoDate(b), onlyDelivered);
      out.add(MonthRow(isoDate(a).substring(0, 7), r.sales, r.direct, r.general));
    }
    return out;
  }
}
