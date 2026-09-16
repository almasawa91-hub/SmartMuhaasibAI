import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../domain/dashboard_summary.dart';

/// كل الأرقام هنا تُحسب مباشرة من قاعدة البيانات الفعلية (وليست ثابتة)،
/// طبقًا للبند رقم 5 من متطلبات النظام.
class DashboardRepository {
  Future<DashboardSummary> loadSummary() async {
    final db = await AppDatabase.instance.database;
    final today = DateTime.now();
    final todayStr = _dateOnly(today);

    final totalCustomers = await _count(db, 'customers', where: 'is_active = 1');
    final totalSuppliers = await _count(db, 'suppliers', where: 'is_active = 1');

    final receivable = await _sumAccountBalance(db, ownerType: 'customer');
    final payable = await _sumAccountBalance(db, ownerType: 'supplier');

    final paymentsInToday = await _sumPayments(db, direction: 'in', date: todayStr);
    final paymentsOutToday = await _sumPayments(db, direction: 'out', date: todayStr);

    final expensesToday = await _sumTable(db, 'expenses', dateColumn: 'expense_date', date: todayStr);
    final revenuesToday = await _sumTable(db, 'revenues', dateColumn: 'revenue_date', date: todayStr);

    final inventoryValue = await _inventoryValue(db);
    final lowStockCount = await _lowStockCount(db);
    final outOfStockCount = await _outOfStockCount(db);

    final appointmentsToday = await _count(
      db,
      'appointments',
      where: "date(due_date) = date(?) AND status NOT IN ('paid','cancelled')",
      whereArgs: [todayStr],
    );
    final dueToday = appointmentsToday;
    final overdueCount = await _count(
      db,
      'appointments',
      where: "date(due_date) < date(?) AND status NOT IN ('paid','cancelled')",
      whereArgs: [todayStr],
    );

    final upcomingReminders = await _count(
      db,
      'reminder_occurrences',
      where: "status = 'pending' AND date(occurrence_date) >= date(?)",
      whereArgs: [todayStr],
    );

    final promisesDueSoon = await _count(
      db,
      'promises_to_pay',
      where: "status = 'pending' AND date(promised_date) BETWEEN date(?) AND date(?, '+3 day')",
      whereArgs: [todayStr, todayStr],
    );
    final promisesOverdue = await _count(
      db,
      'promises_to_pay',
      where: "status = 'pending' AND date(promised_date) < date(?)",
      whereArgs: [todayStr],
    );

    return DashboardSummary(
      totalCustomers: totalCustomers,
      totalSuppliers: totalSuppliers,
      totalReceivable: receivable,
      totalPayable: payable,
      paymentsInToday: paymentsInToday,
      paymentsOutToday: paymentsOutToday,
      expensesToday: expensesToday,
      revenuesToday: revenuesToday,
      inventoryValue: inventoryValue,
      lowStockCount: lowStockCount,
      outOfStockCount: outOfStockCount,
      appointmentsToday: appointmentsToday,
      dueToday: dueToday,
      overdueCount: overdueCount,
      upcomingReminders: upcomingReminders,
      promisesDueSoon: promisesDueSoon,
      promisesOverdue: promisesOverdue,
    );
  }

  String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<int> _count(Database db, String table, {String? where, List<Object?>? whereArgs}) async {
    final rows = await db.query(
      table,
      columns: ['COUNT(*) as c'],
      where: where,
      whereArgs: whereArgs,
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  /// الرصيد = SUM(debit) - SUM(credit) للحركات غير الملغاة، لكل نوع طرف.
  /// هذا هو مصدر الحقيقة الوحيد للرصيد (وليس رقمًا يُعدَّل يدويًا).
  Future<double> _sumAccountBalance(Database db, {required String ownerType}) async {
    final rows = await db.rawQuery('''
      SELECT COALESCE(SUM(t.debit - t.credit), 0) as balance
      FROM account_transactions t
      INNER JOIN accounts a ON a.id = t.account_id
      WHERE a.owner_type = ? AND t.is_reversed = 0
    ''', [ownerType]);
    return (rows.first['balance'] as num?)?.toDouble() ?? 0;
  }

  Future<double> _sumPayments(Database db, {required String direction, required String date}) async {
    final rows = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) as total
      FROM payments
      WHERE direction = ? AND date(payment_date) = date(?) AND is_reversed = 0
    ''', [direction, date]);
    return (rows.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<double> _sumTable(Database db, String table, {required String dateColumn, required String date}) async {
    final rows = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) as total FROM $table WHERE date($dateColumn) = date(?)
    ''', [date]);
    return (rows.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<double> _inventoryValue(Database db) async {
    final rows = await db.rawQuery('''
      SELECT COALESCE(SUM(sb.quantity * p.purchase_price), 0) as value
      FROM stock_balances sb
      INNER JOIN products p ON p.id = sb.product_id
    ''');
    return (rows.first['value'] as num?)?.toDouble() ?? 0;
  }

  Future<int> _lowStockCount(Database db) async {
    final rows = await db.rawQuery('''
      SELECT COUNT(*) as c FROM (
        SELECT p.id, p.min_stock_level, COALESCE(SUM(sb.quantity), 0) as qty
        FROM products p
        LEFT JOIN stock_balances sb ON sb.product_id = p.id
        WHERE p.is_active = 1
        GROUP BY p.id
        HAVING qty > 0 AND qty <= p.min_stock_level
      )
    ''');
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  Future<int> _outOfStockCount(Database db) async {
    final rows = await db.rawQuery('''
      SELECT COUNT(*) as c FROM (
        SELECT p.id, COALESCE(SUM(sb.quantity), 0) as qty
        FROM products p
        LEFT JOIN stock_balances sb ON sb.product_id = p.id
        WHERE p.is_active = 1
        GROUP BY p.id
        HAVING qty <= 0
      )
    ''');
    return Sqflite.firstIntValue(rows) ?? 0;
  }
}
