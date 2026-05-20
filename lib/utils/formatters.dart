import 'package:intl/intl.dart';

class Fmt {
  Fmt._();

  static final _locale = 'pl_PL';

  static String kwh(num? value, {int fractionDigits = 0}) {
    if (value == null) return '—';
    final f = NumberFormat.decimalPattern(_locale)
      ..minimumFractionDigits = fractionDigits
      ..maximumFractionDigits = fractionDigits;
    return '${f.format(value)} kWh';
  }

  static String kvarh(num? value, {int fractionDigits = 0}) {
    if (value == null) return '—';
    final f = NumberFormat.decimalPattern(_locale)
      ..minimumFractionDigits = fractionDigits
      ..maximumFractionDigits = fractionDigits;
    return '${f.format(value)} kvarh';
  }

  static String kw(num? value, {int fractionDigits = 1}) {
    if (value == null) return '—';
    final f = NumberFormat.decimalPattern(_locale)
      ..minimumFractionDigits = fractionDigits
      ..maximumFractionDigits = fractionDigits;
    return '${f.format(value)} kW';
  }

  static String tgPhi(num? value) {
    if (value == null) return '—';
    final f = NumberFormat.decimalPattern(_locale)
      ..minimumFractionDigits = 2
      ..maximumFractionDigits = 2;
    return f.format(value);
  }

  static String dateTime(DateTime? value) {
    if (value == null) return '—';
    return DateFormat('dd.MM.yyyy HH:mm', _locale).format(value);
  }

  static String date(DateTime? value) {
    if (value == null) return '—';
    return DateFormat('dd.MM.yyyy', _locale).format(value);
  }

  static String time(DateTime? value) {
    if (value == null) return '—';
    return DateFormat('HH:mm', _locale).format(value);
  }

  static String number(num? value, {int fractionDigits = 0}) {
    if (value == null) return '—';
    final f = NumberFormat.decimalPattern(_locale)
      ..minimumFractionDigits = fractionDigits
      ..maximumFractionDigits = fractionDigits;
    return f.format(value);
  }
}
