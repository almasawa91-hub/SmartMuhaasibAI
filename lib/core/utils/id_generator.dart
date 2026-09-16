import 'package:uuid/uuid.dart';

/// مولّد معرفات فريدة (UUID v4) لكل السجلات في قاعدة البيانات،
/// ويُستخدم أيضًا لبناء مفاتيح idempotency لتكرارات التذكيرات.
class IdGenerator {
  static const Uuid _uuid = Uuid();

  static String newId() => _uuid.v4();
}
