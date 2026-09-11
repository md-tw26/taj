/// Formats a number with Arabic thousands separators and Western digits.
/// e.g. 48250 → «48٬250».
String arNum(num v) {
  final neg = v < 0;
  final abs = v.abs();
  final s = abs == abs.roundToDouble()
      ? abs.toStringAsFixed(0)
      : abs.toStringAsFixed(2);
  final grouped = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && s[i] != '.' && (_intLen(s) - i) % 3 == 0 && i < _intLen(s)) {
      grouped.write('٬');
    }
    grouped.write(s[i]);
  }
  return neg ? '-$grouped' : grouped.toString();
}

int _intLen(String s) {
  final dot = s.indexOf('.');
  return dot < 0 ? s.length : dot;
}

/// «{amount} د.ل» — Libyan dinar suffix.
String arDinar(num v) => '${arNum(v)} د.ل';

/// Trims a fixed-2-decimal string of any trailing zeros / dangling point,
/// e.g. 2.00 → «2», 1.20 → «1.2».
String _trimDecimals(double v) =>
    v.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');

/// A compact rendering for very large amounts used only in tight card layouts:
/// millions collapse to «{n} مليون», thousands to «{n} ألف». It rounds, so it
/// is always paired with a tooltip/tap that reveals the exact [arNum]/[arDinar]
/// value — a compact balance is never the only way to read the figure.
String arNumCompact(num v) {
  final abs = v.abs();
  final neg = v < 0;
  final String body;
  if (abs >= 1000000) {
    body = '${_trimDecimals(abs / 1000000)} مليون';
  } else if (abs >= 100000) {
    body = '${_trimDecimals(abs / 1000)} ألف';
  } else {
    body = arNum(abs);
  }
  return neg ? '-$body' : body;
}

/// «{compact} د.ل».
String arDinarCompact(num v) => '${arNumCompact(v)} د.ل';

/// The full grouped dinar amount, or its compact form when the full text would
/// exceed [maxChars] — for balance cards where a very long figure would need a
/// second line or a shrink. Callers must still expose the exact value via a
/// tooltip/tap (see [arDinar]); nothing is ever silently truncated.
String arDinarFit(num v, {int maxChars = 16}) {
  final full = arDinar(v);
  return full.length <= maxChars ? full : arDinarCompact(v);
}
