# إدارة المحل (Shop Manager)

نظام إدارة ومحاسبة شامل للمحل: عملاء، موردون، حسابات، مبيعات، مشتريات،
مخزون، مستودعات، مواعيد، وعود سداد، وتذكيرات ذكية — يعمل **بدون إنترنت
(Offline-First)** بالكامل على هاتف Android، بواجهة عربية RTL.

> ⚠️ **حالة المشروع: قيد البناء على مراحل حقيقية.**
> هذا مشروع محاسبي كامل النطاق (70+ متطلبًا) ويُنفَّذ تدريجيًا حسب خطة
> مراحل واضحة (انظر أدناه)، بحيث لا تُطرح أي ميزة كمكتملة قبل أن تُبنى
> وتُختبر فعليًا. لا توجد بيانات وهمية ولا أزرار لا تعمل بدون توضيح.

## الحالة الحالية للمراحل

| المرحلة | المحتوى | الحالة |
|---|---|---|
| 1 | إعداد المشروع، قاعدة البيانات الكاملة، Architecture، Theme، RTL، Navigation | ✅ منجزة |
| 2 | العملاء، الموردون، الحسابات | ⏳ التالية |
| 3 | المنتجات، التصنيفات، المستودعات، المخزون | ⏳ |
| 4 | المبيعات، المشتريات، المدفوعات، المرتجعات | ⏳ |
| 5 | المواعيد، وعود السداد، Reminder Engine، الإشعارات، WhatsApp | ⏳ |
| 6 | المصروفات، الإيرادات، التقارير | ⏳ |
| 7 | المستخدمون، الصلاحيات، Audit Log، Backup/Restore | ⏳ |
| 8 | اختبارات شاملة، تحسين الأداء، إعداد Android نهائي، إصدار APK | ⏳ |

الأقسام غير المُنفَّذة بعد تظهر داخل التطبيق نفسه بعلامة واضحة
("قيد التنفيذ ضمن المرحلة كذا") بدل واجهات فارغة مضلِّلة.

## التقنيات المستخدمة

- **Flutter / Dart** — بنية Feature-based قابلة للتوسع (`lib/core` + `lib/features/<feature>/{data,domain,presentation}`).
- **sqflite + SQLite** — قاعدة بيانات محلية كاملة (31 جدولًا) مع Foreign Keys وIndexes وUnique Constraints ونظام Migrations.
- **intl, uuid, path, shared_preferences** — دعم عربي، معرفات فريدة، تخزين إعدادات.
- **flutter_local_notifications + timezone** — التذكيرات المحلية (المرحلة 5).
- **url_launcher** — فتح واتساب/الاتصال (المرحلة 5).
- **provider** — إدارة حالة بسيطة وواضحة.

## هيكل المشروع

```
lib/
  core/
    database/       # AppDatabase + Migrations (31 جدولًا، schema v1)
    theme/           # ألوان وTheme عربي RTL
    navigation/      # AppShell: BottomNavigation + Drawer
    widgets/         # عناصر مشتركة (EmptyState, StatCard, ComingSoonPage)
    utils/           # تنسيق أرقام/تواريخ/عملات، مولّد معرفات
  features/
    dashboard/       # لوحة تحكم حقيقية تُحسب من قاعدة البيانات مباشرة
    customers/ suppliers/ accounts/ sales/ purchases/ payments/
    products/ inventory/ warehouses/ appointments/ reminders/
    expenses/ revenues/ reports/ settings/ users/ backup/
    # كل مجلد به data/ domain/ presentation/ (تُملأ تباعًا حسب المراحل)
test/
  database_schema_test.dart   # اختبارات قاعدة البيانات والقيود (Idempotency, Unique...)
```

## قاعدة البيانات

مصممة بحيث **الرصيد المالي والمخزون ليسا رقمين يُعدَّلان يدويًا أبدًا**،
بل نتيجة حساب من الحركات المسجَّلة فعليًا:

- `account_transactions`: كل حركة مالية (فاتورة، دفعة، مرتجع...) → الرصيد = SUM(debit - credit).
- `stock_transactions`: كل حركة مخزون (شراء، بيع، تحويل، تسوية...) → الكمية = SUM الحركات.
- `reminder_occurrences`: بها `UNIQUE(reference_type, reference_id, rule_type, occurrence_date)`
  لمنع إرسال نفس التذكير مرتين (Idempotency) حتى لو أُعيد تشغيل المحرك أو الهاتف.

## طريقة التشغيل

### المتطلبات
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (قناة stable، إصدار 3.19 فأعلى).
- Android Studio أو VS Code مع أدوات Android SDK.
- جهاز Android أو محاكي (Emulator).

### الخطوات

```bash
# 1) تثبيت الاعتماديات
flutter pub get

# 2) إنشاء مجلد Android (مرة واحدة فقط، إن لم يكن موجودًا بعد)
flutter create . --platforms=android --org com.shopmanager --project-name shop_manager

# 3) تشغيل التطبيق على جهاز/محاكي متصل
flutter run

# 4) فحص الكود
flutter analyze

# 5) تشغيل الاختبارات
flutter test

# 6) بناء APK قابل للتثبيت
flutter build apk --release
# الملف الناتج: build/app/outputs/flutter-apk/app-release.apk
```

### عبر GitHub Actions (تلقائيًا)

عند رفع أي تعديل إلى فرع `main` (أو تشغيل الـ workflow يدويًا)، يقوم
`.github/workflows/build-apk.yml` تلقائيًا بـ:
1. تثبيت Flutter.
2. إنشاء مجلد `android/` تلقائيًا إن لم يكن موجودًا.
3. `flutter pub get`
4. `flutter analyze`
5. `flutter test`
6. `flutter build apk --release`
7. رفع الـ APK الناتج كـ **Artifact** يمكن تحميله من صفحة الـ Actions في GitHub.

## الأمان

- لا يوجد أي مفتاح سري أو كلمة مرور داخل الكود أو المستودع.
- كلمات مرور المستخدمين (عند تفعيل المرحلة 7) تُخزَّن بعد Hashing، وليست نصًا واضحًا.
- ملفات `keystore` و`key.properties` مستبعدة عبر `.gitignore` بشكل صريح.

## الترخيص

مشروع خاص لإدارة أعمال المحل — غير مخصص للنشر العام على `pub.dev`.
