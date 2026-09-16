import 'package:flutter/material.dart';

/// تُستخدم فقط للأقسام التي لم تُبنَ بعد ضمن المرحلة الحالية من التنفيذ.
/// هذه ليست "ميزة منتهية بواجهة فارغة" - هي إعلان صريح بأن هذا القسم
/// سيُنفَّذ في مرحلة لاحقة من خطة التنفيذ المرحلية، تمشّيًا مع قاعدة
/// عدم ادّعاء اكتمال ميزة غير منفذة فعليًا.
class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({super.key, required this.title, required this.phaseLabel});

  final String title;
  final String phaseLabel;

  /// يُستخدم عندما تحتاج الصفحة إلى Scaffold مستقل (مثل التنقل من الـ Drawer
  /// عبر MaterialPageRoute)، بعكس صفحات التبويب الأساسية التي تُعرض داخل
  /// Scaffold واحد يملكه AppShell.
  Widget asStandalonePage() {
    return Scaffold(appBar: AppBar(title: Text(title)), body: this);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.construction, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'هذا القسم قيد التنفيذ ضمن $phaseLabel من خطة بناء النظام،\nولم يُفعَّل بعد.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
