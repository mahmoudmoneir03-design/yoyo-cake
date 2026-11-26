double _d(dynamic v) =>
    v is num ? v.toDouble() : (double.tryParse('${v ?? ''}') ?? 0);
String _s(dynamic v) => v == null ? '' : '$v';
List<Map<String, dynamic>> _list(dynamic v) => v is List
    ? v.map((e) => Map<String, dynamic>.from(e as Map)).toList()
    : <Map<String, dynamic>>[];

/// خامة بتشتريها: كمية العبوة وسعرها (مثلاً 1000 جرام سكر بـ 40 جنيه).
class Ingredient {
  String id, name, unit;
  double packQty, packPrice, minQty;
  Ingredient({
    required this.id,
    required this.name,
    required this.unit,
    required this.packQty,
    required this.packPrice,
    this.minQty = 0,
  });

  double get unitCost => packQty > 0 ? packPrice / packQty : 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'unit': unit,
        'packQty': packQty,
        'packPrice': packPrice,
        'minQty': minQty,
      };

  factory Ingredient.fromJson(Map<String, dynamic> j) => Ingredient(
        id: _s(j['id']),
        name: _s(j['name']),
        unit: _s(j['unit']),
        packQty: _d(j['packQty']),
        packPrice: _d(j['packPrice']),
        minQty: _d(j['minQty']),
      );
}

/// سطر مكوّن: خامة بكمية وسعر وحدتها وقت التسجيل.
class Line {
  String ingredientId, name, unit;
  double qty, unitCost;
  Line({
    required this.ingredientId,
    required this.name,
    required this.unit,
    required this.qty,
    required this.unitCost,
  });

  double get cost => qty * unitCost;

  Map<String, dynamic> toJson() => {
        'ingredientId': ingredientId,
        'name': name,
        'unit': unit,
        'qty': qty,
        'unitCost': unitCost,
      };

  factory Line.fromJson(Map<String, dynamic> j) => Line(
        ingredientId: _s(j['ingredientId']),
        name: _s(j['name']),
        unit: _s(j['unit']),
        qty: _d(j['qty']),
        unitCost: _d(j['unitCost']),
      );
}

class Recipe {
  String id, name;
  List<Line> lines;
  Recipe({required this.id, required this.name, List<Line>? lines})
      : lines = lines ?? [];

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'lines': lines.map((l) => l.toJson()).toList()};

  factory Recipe.fromJson(Map<String, dynamic> j) => Recipe(
        id: _s(j['id']),
        name: _s(j['name']),
        lines: _list(j['lines']).map(Line.fromJson).toList(),
      );
}

class Payment {
  String id, date, note;
  double amount;
  Payment({
    required this.id,
    required this.amount,
    required this.date,
    this.note = '',
  });

  Map<String, dynamic> toJson() =>
      {'id': id, 'amount': amount, 'date': date, 'note': note};

  factory Payment.fromJson(Map<String, dynamic> j) => Payment(
        id: _s(j['id']),
        amount: _d(j['amount']),
        date: _s(j['date']),
        note: _s(j['note']),
      );
}

class Customer {
  String id, name, phone, address, notes;
  Customer({
    required this.id,
    required this.name,
    this.phone = '',
    this.address = '',
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'address': address,
        'notes': notes,
      };

  factory Customer.fromJson(Map<String, dynamic> j) => Customer(
        id: _s(j['id']),
        name: _s(j['name']),
        phone: _s(j['phone']),
        address: _s(j['address']),
        notes: _s(j['notes']),
      );
}

class Expense {
  String id, date, cat, note;
  double amount;
  Expense({
    required this.id,
    required this.date,
    required this.cat,
    required this.amount,
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'cat': cat,
        'amount': amount,
        'note': note,
      };

  factory Expense.fromJson(Map<String, dynamic> j) => Expense(
        id: _s(j['id']),
        date: _s(j['date']),
        cat: _s(j['cat']),
        amount: _d(j['amount']),
        note: _s(j['note']),
      );
}

class Order {
  String id, customerId, name, phone, address;
  String occasion, size, desc, flavor, date, time, notes, status;
  String photo;
  double price, cPack, cDel, cOther;
  List<Line> lines;
  List<Payment> payments;
  int created;

  Order({
    required this.id,
    required this.name,
    required this.date,
    required this.price,
    this.customerId = '',
    this.phone = '',
    this.address = '',
    this.occasion = 'عيد ميلاد',
    this.size = '',
    this.desc = '',
    this.flavor = '',
    this.time = '',
    this.notes = '',
    this.status = 'new',
    this.photo = '',
    this.cPack = 0,
    this.cDel = 0,
    this.cOther = 0,
    List<Line>? lines,
    List<Payment>? payments,
    int? created,
  })  : lines = lines ?? [],
        payments = payments ?? [],
        created = created ?? DateTime.now().millisecondsSinceEpoch;

  /// تكلفة الخامات من المكونات.
  double get ingCost => lines.fold<double>(0, (s, l) => s + l.cost);
  double get extraCost => cPack + cDel + cOther;
  double get cost => ingCost + extraCost;
  double get paid => payments.fold<double>(0, (s, p) => s + p.amount);
  double get balance => price - paid;
  double get profit => price - cost;
  bool get isOpen => status != 'delivered' && status != 'cancelled';

  Map<String, dynamic> toJson() => {
        'id': id,
        'customerId': customerId,
        'name': name,
        'phone': phone,
        'address': address,
        'occasion': occasion,
        'size': size,
        'desc': desc,
        'flavor': flavor,
        'date': date,
        'time': time,
        'notes': notes,
        'status': status,
        'photo': photo,
        'price': price,
        'cPack': cPack,
        'cDel': cDel,
        'cOther': cOther,
        'lines': lines.map((l) => l.toJson()).toList(),
        'payments': payments.map((p) => p.toJson()).toList(),
        'created': created,
      };

  factory Order.fromJson(Map<String, dynamic> j) => Order(
        id: _s(j['id']),
        customerId: _s(j['customerId']),
        name: _s(j['name']),
        phone: _s(j['phone']),
        address: _s(j['address']),
        occasion: _s(j['occasion']),
        size: _s(j['size']),
        desc: _s(j['desc']),
        flavor: _s(j['flavor']),
        date: _s(j['date']),
        time: _s(j['time']),
        notes: _s(j['notes']),
        status: j['status'] == null ? 'new' : _s(j['status']),
        photo: _s(j['photo']),
        price: _d(j['price']),
        cPack: _d(j['cPack']),
        cDel: _d(j['cDel']),
        cOther: _d(j['cOther']),
        lines: _list(j['lines']).map(Line.fromJson).toList(),
        payments: _list(j['payments']).map(Payment.fromJson).toList(),
        created: j['created'] is num ? (j['created'] as num).toInt() : null,
      );
}

/// شراء خامة: الكمية وإجمالي اللي اتدفع فيها.
class Purchase {
  String id, ingredientId, date, note;
  double qty, price;
  Purchase({
    required this.id,
    required this.ingredientId,
    required this.qty,
    required this.price,
    required this.date,
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'ingredientId': ingredientId,
        'qty': qty,
        'price': price,
        'date': date,
        'note': note,
      };

  factory Purchase.fromJson(Map<String, dynamic> j) => Purchase(
        id: _s(j['id']),
        ingredientId: _s(j['ingredientId']),
        qty: _d(j['qty']),
        price: _d(j['price']),
        date: _s(j['date']),
        note: _s(j['note']),
      );
}
