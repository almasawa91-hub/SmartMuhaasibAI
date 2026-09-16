import 'package:sqflite/sqflite.dart';

/// نظام الترحيل (Migrations) لقاعدة البيانات.
///
/// كل رقم إصدار جديد يُضاف كدالة منفصلة، ولا يتم تعديل الإصدارات
/// القديمة بعد نشرها حتى لا تتلف بيانات المستخدمين الحاليين.
class AppMigrations {
  /// أحدث إصدار لقاعدة البيانات. عند إضافة جدول/عمود جديد مستقبلاً
  /// يُرفع هذا الرقم وتُضاف دالة migrateVX جديدة.
  static const int currentVersion = 1;

  static Future<void> onCreate(Database db, int version) async {
    await db.transaction((txn) async {
      await _createV1(txn);
      await _seedDefaultSettings(txn);
      await _seedDefaultRolesAndPermissions(txn);
    });
  }

  static Future<void> onUpgrade(
      Database db, int oldVersion, int newVersion) async {
    // مستقبلاً: عند oldVersion < 2 نفّذ _migrateV2(db) وهكذا،
    // كل ترحيل يعمل ضمن Transaction ولا يحذف بيانات قديمة.
  }

  static Future<void> _createV1(DatabaseExecutor db) async {
    // ------------------------------------------------------------------
    // المستخدمون والصلاحيات
    // ------------------------------------------------------------------
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        username TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        full_name TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        last_login_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE roles (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        is_system_role INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE permissions (
        id TEXT PRIMARY KEY,
        code TEXT NOT NULL UNIQUE,
        description TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE role_permissions (
        role_id TEXT NOT NULL,
        permission_id TEXT NOT NULL,
        PRIMARY KEY (role_id, permission_id),
        FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
        FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE user_roles (
        user_id TEXT NOT NULL,
        role_id TEXT NOT NULL,
        PRIMARY KEY (user_id, role_id),
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE
      )
    ''');

    // ------------------------------------------------------------------
    // العملاء والموردون والحسابات
    // ------------------------------------------------------------------
    await db.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT,
        address TEXT,
        notes TEXT,
        default_currency TEXT NOT NULL DEFAULT 'YER',
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_customers_name ON customers(name)');
    await db.execute('CREATE INDEX idx_customers_phone ON customers(phone)');

    await db.execute('''
      CREATE TABLE suppliers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT,
        address TEXT,
        notes TEXT,
        default_currency TEXT NOT NULL DEFAULT 'YER',
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_suppliers_name ON suppliers(name)');
    await db.execute('CREATE INDEX idx_suppliers_phone ON suppliers(phone)');

    // حساب واحد لكل عميل/مورد. الرصيد الظاهر هنا هو Cache محسوب من
    // account_transactions ويُعاد حسابه دائمًا من الحركات، وليس مصدر الحقيقة.
    await db.execute('''
      CREATE TABLE accounts (
        id TEXT PRIMARY KEY,
        owner_type TEXT NOT NULL CHECK (owner_type IN ('customer','supplier')),
        owner_id TEXT NOT NULL,
        currency TEXT NOT NULL DEFAULT 'YER',
        cached_balance REAL NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        UNIQUE (owner_type, owner_id, currency)
      )
    ''');
    await db.execute('CREATE INDEX idx_accounts_owner ON accounts(owner_type, owner_id)');

    // كل حركة مالية على حساب عميل/مورد: فاتورة، دفعة، مصروف مرتبط، مرتجع، تسوية...
    // الرصيد = مجموع debit - credit لكل الحركات غير الملغاة.
    await db.execute('''
      CREATE TABLE account_transactions (
        id TEXT PRIMARY KEY,
        account_id TEXT NOT NULL,
        type TEXT NOT NULL CHECK (type IN (
          'sale_invoice','purchase_invoice','payment_in','payment_out',
          'sale_return','purchase_return','adjustment','opening_balance'
        )),
        reference_type TEXT,
        reference_id TEXT,
        debit REAL NOT NULL DEFAULT 0,
        credit REAL NOT NULL DEFAULT 0,
        currency TEXT NOT NULL,
        exchange_rate REAL,
        base_amount REAL,
        description TEXT,
        is_reversed INTEGER NOT NULL DEFAULT 0,
        reversed_by_transaction_id TEXT,
        created_by TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE RESTRICT
      )
    ''');
    await db.execute('CREATE INDEX idx_acct_txn_account ON account_transactions(account_id)');
    await db.execute('CREATE INDEX idx_acct_txn_ref ON account_transactions(reference_type, reference_id)');
    await db.execute('CREATE INDEX idx_acct_txn_created ON account_transactions(created_at)');

    // ------------------------------------------------------------------
    // المنتجات، التصنيفات، المستودعات، المخزون
    // ------------------------------------------------------------------
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE warehouses (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        is_main INTEGER NOT NULL DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        code TEXT UNIQUE,
        category_id TEXT,
        unit TEXT NOT NULL,
        sale_price REAL NOT NULL DEFAULT 0,
        purchase_price REAL NOT NULL DEFAULT 0,
        min_stock_level REAL NOT NULL DEFAULT 0,
        notes TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_products_name ON products(name)');
    await db.execute('CREATE INDEX idx_products_category ON products(category_id)');

    // الكمية الحالية لكل منتج في كل مستودع (Cache تُشتق من stock_transactions).
    await db.execute('''
      CREATE TABLE stock_balances (
        product_id TEXT NOT NULL,
        warehouse_id TEXT NOT NULL,
        quantity REAL NOT NULL DEFAULT 0,
        PRIMARY KEY (product_id, warehouse_id),
        FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
        FOREIGN KEY (warehouse_id) REFERENCES warehouses(id) ON DELETE CASCADE
      )
    ''');

    // مصدر الحقيقة الوحيد لكمية المخزون: كل حركة مسجلة ولا تُحذف.
    await db.execute('''
      CREATE TABLE stock_transactions (
        id TEXT PRIMARY KEY,
        product_id TEXT NOT NULL,
        warehouse_id TEXT NOT NULL,
        type TEXT NOT NULL CHECK (type IN (
          'purchase','sale','sale_return','purchase_return',
          'manual_in','manual_out','transfer_in','transfer_out','adjustment'
        )),
        quantity REAL NOT NULL,
        reference_type TEXT,
        reference_id TEXT,
        related_warehouse_id TEXT,
        notes TEXT,
        created_by TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT,
        FOREIGN KEY (warehouse_id) REFERENCES warehouses(id) ON DELETE RESTRICT
      )
    ''');
    await db.execute('CREATE INDEX idx_stock_txn_product ON stock_transactions(product_id, warehouse_id)');
    await db.execute('CREATE INDEX idx_stock_txn_ref ON stock_transactions(reference_type, reference_id)');

    // ------------------------------------------------------------------
    // المبيعات والمشتريات
    // ------------------------------------------------------------------
    await db.execute('''
      CREATE TABLE invoices (
        id TEXT PRIMARY KEY,
        invoice_number TEXT NOT NULL,
        invoice_type TEXT NOT NULL CHECK (invoice_type IN ('sale','purchase')),
        party_type TEXT NOT NULL CHECK (party_type IN ('customer','supplier')),
        party_id TEXT NOT NULL,
        invoice_date TEXT NOT NULL,
        due_date TEXT,
        currency TEXT NOT NULL DEFAULT 'YER',
        exchange_rate REAL,
        subtotal REAL NOT NULL DEFAULT 0,
        discount REAL NOT NULL DEFAULT 0,
        tax REAL NOT NULL DEFAULT 0,
        total REAL NOT NULL DEFAULT 0,
        paid_amount REAL NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'unpaid' CHECK (status IN ('unpaid','partial','paid','cancelled')),
        notes TEXT,
        created_by TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        UNIQUE (invoice_type, invoice_number)
      )
    ''');
    await db.execute('CREATE INDEX idx_invoices_party ON invoices(party_type, party_id)');
    await db.execute('CREATE INDEX idx_invoices_due ON invoices(due_date)');
    await db.execute('CREATE INDEX idx_invoices_status ON invoices(status)');

    await db.execute('''
      CREATE TABLE invoice_items (
        id TEXT PRIMARY KEY,
        invoice_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit_price REAL NOT NULL,
        discount REAL NOT NULL DEFAULT 0,
        total REAL NOT NULL,
        FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT
      )
    ''');
    await db.execute('CREATE INDEX idx_invoice_items_invoice ON invoice_items(invoice_id)');

    // مرتجعات مرتبطة دائمًا بفاتورة أصلية - لا تُحذف الفاتورة الأصلية أبدًا.
    await db.execute('''
      CREATE TABLE invoice_returns (
        id TEXT PRIMARY KEY,
        original_invoice_id TEXT NOT NULL,
        return_type TEXT NOT NULL CHECK (return_type IN ('sale_return','purchase_return')),
        return_date TEXT NOT NULL,
        total REAL NOT NULL,
        reason TEXT,
        created_by TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (original_invoice_id) REFERENCES invoices(id) ON DELETE RESTRICT
      )
    ''');

    await db.execute('''
      CREATE TABLE invoice_return_items (
        id TEXT PRIMARY KEY,
        return_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit_price REAL NOT NULL,
        total REAL NOT NULL,
        FOREIGN KEY (return_id) REFERENCES invoice_returns(id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT
      )
    ''');

    // ------------------------------------------------------------------
    // المدفوعات (يسمح بأكثر من دفعة لنفس الفاتورة)
    // ------------------------------------------------------------------
    await db.execute('''
      CREATE TABLE payments (
        id TEXT PRIMARY KEY,
        direction TEXT NOT NULL CHECK (direction IN ('in','out')),
        party_type TEXT NOT NULL CHECK (party_type IN ('customer','supplier')),
        party_id TEXT NOT NULL,
        invoice_id TEXT,
        amount REAL NOT NULL,
        currency TEXT NOT NULL DEFAULT 'YER',
        exchange_rate REAL,
        base_amount REAL,
        payment_date TEXT NOT NULL,
        method TEXT,
        notes TEXT,
        is_reversed INTEGER NOT NULL DEFAULT 0,
        created_by TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE SET NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_payments_party ON payments(party_type, party_id)');
    await db.execute('CREATE INDEX idx_payments_invoice ON payments(invoice_id)');

    // ------------------------------------------------------------------
    // المصروفات والإيرادات
    // ------------------------------------------------------------------
    await db.execute('''
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        currency TEXT NOT NULL DEFAULT 'YER',
        expense_date TEXT NOT NULL,
        description TEXT,
        notes TEXT,
        created_by TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_expenses_date ON expenses(expense_date)');

    await db.execute('''
      CREATE TABLE revenues (
        id TEXT PRIMARY KEY,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        currency TEXT NOT NULL DEFAULT 'YER',
        revenue_date TEXT NOT NULL,
        description TEXT,
        notes TEXT,
        created_by TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_revenues_date ON revenues(revenue_date)');

    // ------------------------------------------------------------------
    // المواعيد ووعود السداد (يسمح بأكثر من موعد لنفس العميل)
    // ------------------------------------------------------------------
    await db.execute('''
      CREATE TABLE appointments (
        id TEXT PRIMARY KEY,
        party_type TEXT NOT NULL CHECK (party_type IN ('customer','supplier')),
        party_id TEXT NOT NULL,
        amount REAL,
        currency TEXT DEFAULT 'YER',
        due_date TEXT NOT NULL,
        reason TEXT,
        notes TEXT,
        status TEXT NOT NULL DEFAULT 'upcoming' CHECK (status IN (
          'upcoming','today','due','overdue','paid','partial','postponed','cancelled'
        )),
        invoice_id TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE SET NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_appointments_party ON appointments(party_type, party_id)');
    await db.execute('CREATE INDEX idx_appointments_due ON appointments(due_date)');
    await db.execute('CREATE INDEX idx_appointments_status ON appointments(status)');

    // سجل تأجيل المواعيد - لا يُحذف التاريخ القديم أبدًا.
    await db.execute('''
      CREATE TABLE appointment_postponements (
        id TEXT PRIMARY KEY,
        appointment_id TEXT NOT NULL,
        old_due_date TEXT NOT NULL,
        new_due_date TEXT NOT NULL,
        reason TEXT,
        postponed_by TEXT,
        postponed_at TEXT NOT NULL,
        FOREIGN KEY (appointment_id) REFERENCES appointments(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE promises_to_pay (
        id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL,
        amount REAL NOT NULL,
        currency TEXT NOT NULL DEFAULT 'YER',
        promised_date TEXT NOT NULL,
        notes TEXT,
        status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','fulfilled','broken','postponed','cancelled')),
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX idx_promises_customer ON promises_to_pay(customer_id)');
    await db.execute('CREATE INDEX idx_promises_date ON promises_to_pay(promised_date)');

    // ------------------------------------------------------------------
    // نظام التذكيرات (Reminder Engine)
    // ------------------------------------------------------------------
    await db.execute('''
      CREATE TABLE reminder_templates (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        message_template TEXT NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // تعريف "متى" يُذكَّر المستخدم (قبل الاستحقاق بيوم، يوم الاستحقاق...)
    await db.execute('''
      CREATE TABLE reminders (
        id TEXT PRIMARY KEY,
        reference_type TEXT NOT NULL CHECK (reference_type IN ('appointment','promise_to_pay')),
        reference_id TEXT NOT NULL,
        rule_type TEXT NOT NULL CHECK (rule_type IN (
          'before_due_1_day','on_due_date','overdue_3_days','overdue_7_days','custom'
        )),
        is_enabled INTEGER NOT NULL DEFAULT 1,
        recurrence TEXT CHECK (recurrence IN ('none','daily','weekly','monthly','custom_date')),
        recurrence_end_date TEXT,
        reminder_time TEXT NOT NULL DEFAULT '09:00',
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_reminders_ref ON reminders(reference_type, reference_id)');

    // كل مرة فعلية للتذكير (occurrence) - مفتاح فريد يمنع التكرار
    // (Idempotency) بغض النظر عن عدد مرات إعادة تشغيل المحرك/الهاتف.
    await db.execute('''
      CREATE TABLE reminder_occurrences (
        id TEXT PRIMARY KEY,
        reminder_id TEXT NOT NULL,
        reference_type TEXT NOT NULL,
        reference_id TEXT NOT NULL,
        rule_type TEXT NOT NULL,
        occurrence_date TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','sent','failed','cancelled')),
        scheduled_notification_id INTEGER,
        created_at TEXT NOT NULL,
        sent_at TEXT,
        FOREIGN KEY (reminder_id) REFERENCES reminders(id) ON DELETE CASCADE,
        UNIQUE (reference_type, reference_id, rule_type, occurrence_date)
      )
    ''');
    await db.execute('CREATE INDEX idx_occurrence_status ON reminder_occurrences(status)');
    await db.execute('CREATE INDEX idx_occurrence_date ON reminder_occurrences(occurrence_date)');

    await db.execute('''
      CREATE TABLE reminder_notifications (
        id TEXT PRIMARY KEY,
        occurrence_id TEXT NOT NULL,
        channel TEXT NOT NULL CHECK (channel IN ('local_notification','whatsapp_manual','call')),
        result TEXT NOT NULL CHECK (result IN ('pending','success','failed')),
        error_message TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (occurrence_id) REFERENCES reminder_occurrences(id) ON DELETE CASCADE
      )
    ''');

    // سجل كامل وغير قابل للحذف لكل ما يحدث حول التذكيرات لكل عميل/مورد.
    await db.execute('''
      CREATE TABLE reminder_history (
        id TEXT PRIMARY KEY,
        party_type TEXT NOT NULL CHECK (party_type IN ('customer','supplier')),
        party_id TEXT NOT NULL,
        event_type TEXT NOT NULL,
        description TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_reminder_history_party ON reminder_history(party_type, party_id)');

    // ------------------------------------------------------------------
    // سجل العمليات (Audit Log)
    // ------------------------------------------------------------------
    await db.execute('''
      CREATE TABLE audit_logs (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        action TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        entity_id TEXT,
        details TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_audit_entity ON audit_logs(entity_type, entity_id)');
    await db.execute('CREATE INDEX idx_audit_created ON audit_logs(created_at)');

    // ------------------------------------------------------------------
    // الإعدادات، النسخ الاحتياطي، طابور المزامنة المستقبلي
    // ------------------------------------------------------------------
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE backup_metadata (
        id TEXT PRIMARY KEY,
        file_path TEXT NOT NULL,
        file_size_bytes INTEGER,
        checksum TEXT,
        db_version INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        restored_at TEXT
      )
    ''');

    // مُجهّزة لمزامنة سحابية مستقبلية - غير مستخدمة الآن.
    await db.execute('''
      CREATE TABLE sync_queue (
        id TEXT PRIMARY KEY,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        operation TEXT NOT NULL CHECK (operation IN ('insert','update','delete')),
        payload TEXT,
        status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','synced','failed')),
        created_at TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _seedDefaultSettings(DatabaseExecutor db) async {
    final defaults = <String, String>{
      'business_name': 'محلي',
      'business_phone': '',
      'business_address': '',
      'default_currency': 'YER',
      'reminder_before_due_enabled': '1',
      'reminder_on_due_enabled': '1',
      'reminder_overdue_3_enabled': '1',
      'reminder_overdue_7_enabled': '1',
      'reminder_default_time': '09:00',
      'db_schema_version': currentVersion.toString(),
    };
    for (final e in defaults.entries) {
      await db.insert('settings', {'key': e.key, 'value': e.value});
    }
  }

  static Future<void> _seedDefaultRolesAndPermissions(DatabaseExecutor db) async {
    // الصلاحيات الأساسية المذكورة في متطلبات النظام.
    const permissionCodes = <String, String>{
      'customers.view': 'عرض العملاء',
      'customers.edit': 'تعديل العملاء',
      'customers.delete': 'حذف العملاء',
      'accounts.view': 'عرض الحسابات',
      'payments.create': 'تسجيل دفعات',
      'sales.create': 'إنشاء مبيعات',
      'purchases.create': 'إنشاء مشتريات',
      'inventory.edit': 'تعديل المخزون',
      'reports.view': 'عرض التقارير',
      'users.manage': 'إدارة المستخدمين',
      'backup.manage': 'النسخ الاحتياطي',
    };

    for (final e in permissionCodes.entries) {
      await db.insert('permissions', {
        'id': 'perm_${e.key.replaceAll('.', '_')}',
        'code': e.key,
        'description': e.value,
      });
    }

    // دور المالك: كل الصلاحيات. دور الموظف: صلاحيات محدودة فقط
    // (لا يمنح كل المستخدمين صلاحيات كاملة كما ورد في المتطلبات).
    await db.insert('roles', {'id': 'role_owner', 'name': 'مالك', 'is_system_role': 1});
    await db.insert('roles', {'id': 'role_staff', 'name': 'موظف', 'is_system_role': 1});

    for (final code in permissionCodes.keys) {
      await db.insert('role_permissions', {
        'role_id': 'role_owner',
        'permission_id': 'perm_${code.replaceAll('.', '_')}',
      });
    }
    const staffPermissions = ['customers.view', 'accounts.view', 'payments.create', 'sales.create'];
    for (final code in staffPermissions) {
      await db.insert('role_permissions', {
        'role_id': 'role_staff',
        'permission_id': 'perm_${code.replaceAll('.', '_')}',
      });
    }

    await db.insert('warehouses', {
      'id': 'wh_main',
      'name': 'المستودع الرئيسي',
      'is_main': 1,
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
