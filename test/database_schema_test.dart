import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:shop_manager/core/database/migrations.dart';

/// اختبارات المرحلة الأولى: قاعدة البيانات فقط (بدون منطق محاسبي/مخزون
/// بعد، لأنه سيُبنى في المراحل التالية). تتحقق من:
/// - إنشاء كل الجداول المطلوبة بنجاح.
/// - القيود الأساسية (UNIQUE) تعمل فعليًا ولا تسمح بانتهاكها.
/// - البيانات الافتراضية (الأدوار، الصلاحيات، المستودع الرئيسي) تُزرع بشكل صحيح.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('تُنشأ كل الجداول المطلوبة بدون أخطاء', () async {
    final db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: AppMigrations.currentVersion,
        onConfigure: (d) => d.execute('PRAGMA foreign_keys = ON'),
        onCreate: AppMigrations.onCreate,
      ),
    );

    const expectedTables = [
      'users', 'roles', 'permissions', 'user_roles',
      'customers', 'suppliers', 'accounts', 'account_transactions',
      'categories', 'warehouses', 'products', 'stock_balances', 'stock_transactions',
      'invoices', 'invoice_items', 'invoice_returns', 'invoice_return_items',
      'payments', 'expenses', 'revenues',
      'appointments', 'appointment_postponements', 'promises_to_pay',
      'reminder_templates', 'reminders', 'reminder_occurrences',
      'reminder_notifications', 'reminder_history',
      'audit_logs', 'settings', 'backup_metadata', 'sync_queue',
    ];

    final rows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_%'",
    );
    final actualTables = rows.map((r) => r['name'] as String).toSet();

    for (final table in expectedTables) {
      expect(actualTables.contains(table), isTrue, reason: 'الجدول $table غير موجود');
    }

    await db.close();
  });

  test('المستودع الرئيسي يُزرع تلقائيًا عند الإنشاء', () async {
    final db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(version: AppMigrations.currentVersion, onCreate: AppMigrations.onCreate),
    );

    final warehouses = await db.query('warehouses', where: 'is_main = 1');
    expect(warehouses.length, 1);
    expect(warehouses.first['name'], 'المستودع الرئيسي');

    await db.close();
  });

  test('لا يمكن إنشاء حسابين مكررين لنفس العميل ونفس العملة (UNIQUE constraint)', () async {
    final db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: AppMigrations.currentVersion,
        onConfigure: (d) => d.execute('PRAGMA foreign_keys = ON'),
        onCreate: AppMigrations.onCreate,
      ),
    );

    await db.insert('customers', {
      'id': 'c1',
      'name': 'عميل تجريبي',
      'default_currency': 'YER',
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    await db.insert('accounts', {
      'id': 'a1',
      'owner_type': 'customer',
      'owner_id': 'c1',
      'currency': 'YER',
      'cached_balance': 0,
      'created_at': DateTime.now().toIso8601String(),
    });

    expect(
      () => db.insert('accounts', {
        'id': 'a2',
        'owner_type': 'customer',
        'owner_id': 'c1',
        'currency': 'YER',
        'cached_balance': 0,
        'created_at': DateTime.now().toIso8601String(),
      }),
      throwsA(isA<Exception>()),
    );

    await db.close();
  });

  test('منع تكرار تذكير لنفس الاستحقاق ونفس النوع ونفس التاريخ (Idempotency)', () async {
    final db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: AppMigrations.currentVersion,
        onConfigure: (d) => d.execute('PRAGMA foreign_keys = ON'),
        onCreate: AppMigrations.onCreate,
      ),
    );

    await db.insert('customers', {
      'id': 'c1',
      'name': 'عميل',
      'default_currency': 'YER',
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
    await db.insert('appointments', {
      'id': 'ap1',
      'party_type': 'customer',
      'party_id': 'c1',
      'due_date': '2026-10-01',
      'status': 'upcoming',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
    await db.insert('reminders', {
      'id': 'r1',
      'reference_type': 'appointment',
      'reference_id': 'ap1',
      'rule_type': 'on_due_date',
      'is_enabled': 1,
      'reminder_time': '09:00',
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.insert('reminder_occurrences', {
      'id': 'occ1',
      'reminder_id': 'r1',
      'reference_type': 'appointment',
      'reference_id': 'ap1',
      'rule_type': 'on_due_date',
      'occurrence_date': '2026-10-01',
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    });

    // محاولة إنشاء نفس التكرار (occurrence) مرة أخرى - يجب أن تُرفض
    // لأنها بالضبط الحالة التي يمنعها متطلب "منع التذكيرات المكررة".
    expect(
      () => db.insert('reminder_occurrences', {
        'id': 'occ2',
        'reminder_id': 'r1',
        'reference_type': 'appointment',
        'reference_id': 'ap1',
        'rule_type': 'on_due_date',
        'occurrence_date': '2026-10-01',
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      }),
      throwsA(isA<Exception>()),
    );

    await db.close();
  });
}
