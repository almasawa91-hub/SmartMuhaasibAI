import 'package:intl/intl.dart';

/// أدوات تنسيق موحّدة للأرقام والعملات والتواريخ بالعربية،
/// حتى لا تتكرر منطق التنسيق داخل كل شاشة على حدة.
class AppFormatters {
  static final NumberFormat _numberFormat = NumberFormat.decimalPattern('ar');
  static final DateFormat _dateFormat = DateFormat('yyyy/MM/dd', 'ar');
  static final DateFormat _dateTimeFormat = DateFormat('yyyy/MM/dd - hh:mm a', 'ar');
  static final DateFormat _timeFormat = DateFormat('hh:mm a', 'ar');

  /// يعرض المبلغ مع رمز/كود العملة، بدون جمع عملات مختلفة أبدًا في نفس القيمة.
  static String currency(double amount, String currencyCode) {
    return '${_numberFormat.format(amount)} $currencyCode';
  }

  static String number(num value) => _numberFormat.format(value);

  static String date(DateTime date) => _dateFormat.format(date);

  static String dateTime(DateTime date) => _dateTimeFormat.format(date);

  static String time(DateTime date) => _timeFormat.format(date);

  /// عدد الأيام بين تاريخ الاستحقاق واليوم (موجب = متأخر، سالب = قادم).
  static int daysOverdue(DateTime dueDate) {
    final today = DateTime.now();
    final d1 = DateTime(today.year, today.month, today.day);
    final d2 = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return d1.difference(d2).inDays;
  }
}
