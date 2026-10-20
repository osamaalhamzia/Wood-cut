/// يحيط النص بعازل اتجاه (يسار-يمين) حتى لا ينقلب ترتيب الأرقام مثل 200×60
/// داخل النص العربي.
String ltr(String s) => '\u2066$s\u2069';

/// تنسيق الرقم: بدون أصفار زائدة، وبأرقام إنجليزية دائماً.
String fmtNum(double v) {
  if (v == v.roundToDouble()) return v.round().toString();
  var s = v.toStringAsFixed(2);
  if (s.contains('.')) {
    s = s.replaceFirst(RegExp(r'0+$'), '');
    s = s.replaceFirst(RegExp(r'\.$'), '');
  }
  return s;
}

/// يحوّل الأرقام العربية-الهندية (٠١٢٣…) والفارسية (۰۱۲…) إلى أرقام إنجليزية،
/// ويحوّل الفاصلة العشرية العربية إلى نقطة.
String normalizeDigits(String s) {
  final b = StringBuffer();
  for (final r in s.runes) {
    if (r >= 0x0660 && r <= 0x0669) {
      b.writeCharCode(0x30 + (r - 0x0660));
    } else if (r >= 0x06F0 && r <= 0x06F9) {
      b.writeCharCode(0x30 + (r - 0x06F0));
    } else if (r == 0x066B || r == 0x060C || r == 0x2C) {
      b.write('.');
    } else if (r == 0x066C) {
      // فاصل الآلاف: يُتجاهل
    } else {
      b.writeCharCode(r);
    }
  }
  return b.toString();
}

double parseNum(String s) => double.tryParse(normalizeDigits(s).trim()) ?? 0;

String fmtArea(double cm2) {
  final m2 = cm2 / 10000;
  return '${m2.toStringAsFixed(2)} م²';
}
