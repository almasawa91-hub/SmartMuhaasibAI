import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/database/app_database.dart';
import 'core/navigation/app_shell.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // فتح قاعدة البيانات وتنفيذ الترحيلات (migrations) قبل عرض أي واجهة،
  // تطبيقًا للبند 57: "تشغيل النظام عند بدء التطبيق".
  await AppDatabase.instance.database;

  runApp(const ShopManagerApp());
}

class ShopManagerApp extends StatelessWidget {
  const ShopManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'إدارة المحل',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        // فرض اتجاه RTL بالكامل بغض النظر عن لغة النظام على الجهاز،
        // تطبيقًا للبند 4: "يجب أن يكون التطبيق RTL بالكامل".
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const AppShell(),
    );
  }
}
