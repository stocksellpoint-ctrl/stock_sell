import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static final _currency = NumberFormat.currency(
    symbol: 'AED ',
    decimalDigits: 2,
    locale: 'en_AE',
  );
  static final _date = DateFormat('MMM dd, yyyy');
  static final _dateTime = DateFormat('MMM dd, yyyy • HH:mm');

  static String currency(num value) => _currency.format(value);
  static String date(DateTime d) => _date.format(d);
  static String dateTime(DateTime d) => _dateTime.format(d);
}