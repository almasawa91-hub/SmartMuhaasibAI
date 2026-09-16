import 'package:flutter/material.dart';

/// ألوان دلالية موحّدة، تُستخدم للحالات المهمة فقط (بدون مبالغة في الألوان).
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF0F6E5C); // أخضر محاسبي هادئ
  static const Color primaryDark = Color(0xFF0A4C3F);
  static const Color secondary = Color(0xFF1E5B8C);

  static const Color success = Color(0xFF2E7D32); // مدفوع بالكامل
  static const Color warning = Color(0xFFE0A800); // مستحق اليوم / قريب
  static const Color danger = Color(0xFFC62828); // متأخر
  static const Color info = Color(0xFF1565C0);
  static const Color neutral = Color(0xFF6B7280);

  static const Color background = Color(0xFFF5F7F8);
  static const Color surface = Color(0xFFFFFFFF);
}
