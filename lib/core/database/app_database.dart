import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'migrations.dart';

/// نقطة الوصول الوحيدة لقاعدة البيانات المحلية (SQLite عبر sqflite).
///
/// كل الـ Repositories تمر عبر [AppDatabase.instance.database] ولا تفتح
/// اتصالاً خاصًا بها، حتى تبقى العمليات المترابطة (فاتورة + مخزون + حساب)
/// قابلة للتنفيذ ضمن Transaction واحدة متسقة.
class AppDatabase {
  AppDatabase._internal();

  static final AppDatabase instance = AppDatabase._internal();

  Database? _database;

  /// اسم ملف قاعدة البيانات على الجهاز.
  static const String _dbFileName = 'shop_manager.db';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _open();
    return _database!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbFileName);

    return openDatabase(
      path,
      version: AppMigrations.currentVersion,
      onConfigure: (db) async {
        // تفعيل قيود المفاتيح الأجنبية إجباريًا - بدونها SQLite يتجاهلها.
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: AppMigrations.onCreate,
      onUpgrade: AppMigrations.onUpgrade,
    );
  }

  /// تنفيذ مجموعة عمليات ضمن Transaction واحدة: إمّا تنجح كلها معًا
  /// أو يتم التراجع عنها بالكامل (مطلوب لكل عملية بيع/شراء/دفع مترابطة).
  Future<T> runInTransaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    return db.transaction<T>(action);
  }

  /// يُستخدم فقط في الاختبارات لإغلاق الاتصال بين الحالات.
  Future<void> closeForTests() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
