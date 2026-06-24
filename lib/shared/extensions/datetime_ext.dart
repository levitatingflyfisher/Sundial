import 'package:intl/intl.dart';

extension DateTimeExt on DateTime {
  static final _dayFmt = DateFormat('yyyy-MM-dd');
  static final _monthFmt = DateFormat('yyyy-MM');
  static final _yearFmt = DateFormat('yyyy');

  String toDateDay() => _dayFmt.format(this);
  String toYearMonth() => _monthFmt.format(this);
  String toYear() => _yearFmt.format(this);
}
