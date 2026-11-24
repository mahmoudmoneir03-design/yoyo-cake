import 'dart:math';

const List<String> months = [
  'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
  'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
];
const List<String> weekdays = [
  'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'
];

const Map<String, String> statusLabel = {
  'new': 'جديد',
  'baking': 'قيد التحضير',
  'ready': 'جاهز',
  'delivered': 'اتسلّم',
  'cancelled': 'ملغي',
};

const List<String> occasions = [
  'عيد ميلاد', 'خطوبة', 'فرح', 'تخرج', 'مولود', 'عيد / مناسبة', 'أخرى'
];

const List<String> expenseCats = [
  'خامات عامة', 'إيجار', 'معدات وأدوات', 'إعلانات', 'مواصلات', 'كهرباء وغاز', 'أخرى'
];

String uid() =>
    DateTime.now().microsecondsSinceEpoch.toRadixString(36) +
    Random().nextInt(1 << 20).toRadixString(36);

/// يحوّل الأرقام العربية والفارسية إلى أرقام لاتينية.
String toLatin(String s) {
  const ar = '٠١٢٣٤٥٦٧٨٩';
  const fa = '۰۱۲۳۴۵۶۷۸۹';
  final b = StringBuffer();
  for (final r in s.runes) {
    final c = String.fromCharCode(r);
    var i = ar.indexOf(c);
    if (i < 0) i = fa.indexOf(c);
    if (i >= 0) {
      b.write(i);
    } else if (c == '٫') {
      b.write('.');
    } else if (c == '٬') {
      b.write(',');
    } else {
      b.write(c);
    }
  }
  return b.toString();
}

double parseNum(String s) =>
    double.tryParse(toLatin(s).replaceAll(',', '').trim()) ?? 0;

String digitsOf(String s) => toLatin(s).replaceAll(RegExp(r'[^0-9]'), '');

String _group(int n) {
  final s = n.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

String fmtInt(num n) => _group(n.round());

String money(num n) {
  final r = n.round();
  return '${r < 0 ? '−' : ''}${_group(r)} ج.م';
}

/// رقم عشري بحد أقصى 3 خانات من غير أصفار زيادة.
String fmtDec(double n) {
  var s = n.toStringAsFixed(3);
  s = s.replaceAll(RegExp(r'0+$'), '');
  s = s.replaceAll(RegExp(r'\.$'), '');
  return s;
}

String isoDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime parseDate(String s) {
  final p = s.split('-').map(int.parse).toList();
  return DateTime(p[0], p[1], p[2]);
}

String today() => isoDate(DateTime.now());

String addDays(String s, int n) {
  final d = parseDate(s);
  return isoDate(DateTime(d.year, d.month, d.day + n));
}

int dayDiff(String a, String b) {
  final da = parseDate(a);
  final db = parseDate(b);
  return DateTime.utc(da.year, da.month, da.day)
      .difference(DateTime.utc(db.year, db.month, db.day))
      .inDays;
}

String fmtDay(String s) {
  final d = parseDate(s);
  return '${weekdays[d.weekday - 1]} ${d.day} ${months[d.month - 1]}';
}

String monthName(String key) => months[int.parse(key.split('-')[1]) - 1];

String fmtMonth(String key) {
  final p = key.split('-');
  return '${months[int.parse(p[1]) - 1]} ${p[0]}';
}

String relDay(String s) {
  final d = dayDiff(s, today());
  if (d == 0) return 'النهارده';
  if (d == 1) return 'بكره';
  if (d == 2) return 'بعد بكره';
  if (d > 2 && d <= 10) return 'بعد $d أيام';
  if (d == -1) return 'امبارح';
  if (d < 0) return 'فات ${d.abs()} يوم';
  return fmtDay(s);
}

/// (من، إلى) للفترة المطلوبة في التقارير.
List<String> periodRange(String p) {
  final n = DateTime.now();
  final y = n.year;
  final m = n.month;
  switch (p) {
    case 'month':
      return [isoDate(DateTime(y, m, 1)), isoDate(DateTime(y, m + 1, 0))];
    case 'last':
      return [isoDate(DateTime(y, m - 1, 1)), isoDate(DateTime(y, m, 0))];
    case 'q3':
      return [isoDate(DateTime(y, m - 2, 1)), isoDate(DateTime(y, m + 1, 0))];
    case 'year':
      return ['$y-01-01', '$y-12-31'];
    default:
      return ['0000-01-01', '9999-12-31'];
  }
}

String waLink(String phone) {
  var d = digitsOf(phone);
  if (d.isEmpty) return '';
  if (d.startsWith('00')) {
    d = d.substring(2);
  } else if (d.startsWith('0')) {
    d = '20${d.substring(1)}';
  }
  return 'https://wa.me/$d';
}

/// كمية بوحدتها: الجرام بيتحوّل لكجم والمللي للتر لما يزيدوا عن ١٠٠٠.
String fmtQty(double q, String unit) {
  final a = q.abs();
  String s;
  if (unit == 'جرام' && a >= 1000) {
    s = '${fmtDec(a / 1000)} كجم';
  } else if (unit == 'مللي' && a >= 1000) {
    s = '${fmtDec(a / 1000)} لتر';
  } else {
    s = '${fmtDec(a)} $unit';
  }
  return q < 0 ? '−$s' : s;
}
