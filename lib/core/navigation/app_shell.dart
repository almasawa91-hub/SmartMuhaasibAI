import 'package:flutter/material.dart';

import '../widgets/coming_soon_page.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';

/// الهيكل الرئيسي للتنقل: Bottom Navigation للأقسام الأساسية الخمسة،
/// وDrawer لبقية الأقسام الثانوية (تقارير، إعدادات، مستخدمون...).
///
/// الأقسام التي لم تُبنَ بعد تُعرض بوضوح كـ "قيد التنفيذ ضمن مرحلة لاحقة"
/// (انظر ComingSoonPage) - لا توجد أزرار وهمية بدون توضيح.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _titles = ['لوحة التحكم', 'العملاء', 'المبيعات', 'المخزون', 'التذكيرات'];

  static const _primaryPages = <Widget>[
    DashboardPage(),
    ComingSoonPage(title: 'العملاء', phaseLabel: 'المرحلة الثانية'),
    ComingSoonPage(title: 'المبيعات', phaseLabel: 'المرحلة الرابعة'),
    ComingSoonPage(title: 'المخزون', phaseLabel: 'المرحلة الثالثة'),
    ComingSoonPage(title: 'التذكيرات', phaseLabel: 'المرحلة الخامسة'),
  ];

  static const _drawerSections = <_DrawerItem>[
    _DrawerItem('الموردون', Icons.local_shipping_outlined, 'المرحلة الثانية'),
    _DrawerItem('الحسابات', Icons.account_balance_wallet_outlined, 'المرحلة الثانية'),
    _DrawerItem('المشتريات', Icons.shopping_bag_outlined, 'المرحلة الرابعة'),
    _DrawerItem('المدفوعات', Icons.payments_outlined, 'المرحلة الرابعة'),
    _DrawerItem('المستودعات', Icons.warehouse_outlined, 'المرحلة الثالثة'),
    _DrawerItem('المواعيد', Icons.event_outlined, 'المرحلة الخامسة'),
    _DrawerItem('وعود السداد', Icons.handshake_outlined, 'المرحلة الخامسة'),
    _DrawerItem('المصروفات', Icons.money_off_outlined, 'المرحلة السادسة'),
    _DrawerItem('الإيرادات', Icons.trending_up_outlined, 'المرحلة السادسة'),
    _DrawerItem('التقارير', Icons.bar_chart_outlined, 'المرحلة السادسة'),
    _DrawerItem('المستخدمون والصلاحيات', Icons.admin_panel_settings_outlined, 'المرحلة السابعة'),
    _DrawerItem('النسخ الاحتياطي', Icons.backup_outlined, 'المرحلة السابعة'),
    _DrawerItem('الإعدادات', Icons.settings_outlined, 'المرحلة السابعة'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
      drawer: _buildDrawer(context),
      body: IndexedStack(index: _index, children: _primaryPages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'الرئيسية'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'العملاء'),
          NavigationDestination(icon: Icon(Icons.point_of_sale_outlined), selectedIcon: Icon(Icons.point_of_sale), label: 'المبيعات'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'المخزون'),
          NavigationDestination(icon: Icon(Icons.notifications_outlined), selectedIcon: Icon(Icons.notifications), label: 'التذكيرات'),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF0F6E5C)),
              child: Align(
                alignment: AlignmentDirectional.bottomStart,
                child: Text(
                  'إدارة المحل',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            for (final item in _drawerSections)
              ListTile(
                leading: Icon(item.icon),
                title: Text(item.label),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ComingSoonPage(title: item.label, phaseLabel: item.phase).asStandalonePage(),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem {
  const _DrawerItem(this.label, this.icon, this.phase);
  final String label;
  final IconData icon;
  final String phase;
}
