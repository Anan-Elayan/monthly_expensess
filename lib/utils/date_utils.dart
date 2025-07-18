import 'package:intl/intl.dart';

class DateUtils {
  static List<String> generateMonths() {
    return List.generate(18, (i) {
      final d = DateTime.now().subtract(Duration(days: 30 * i));
      return DateFormat('yyyy-MM').format(d);
    });
  }

  static String getCurrentMonth() {
    return DateFormat('yyyy-MM').format(DateTime.now());
  }

  static String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
}
