import 'package:flutter/material.dart';

// ChemClass (ana uygulama)
const kSupabaseUrl = 'https://krqyzhmioqtfihwrblmb.supabase.co';
const kSupabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtycXl6aG1pb3F0Zmlod3JibG1iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAxNTQzOTQsImV4cCI6MjA5NTczMDM5NH0.qE5bmGq7DksTJ4WHklpS_cGPeghkQrk5ZwjR36dn0GI';

// Öğretmenim (not defteri & analiz)
const kOgretmenimUrl = 'https://yqyrhuednyhirgcghexe.supabase.co';

// Marka renkleri
const kAccent = Color(0xFF00D4AA);
const kAccentDim = Color(0x2900D4AA);
const kBg = Color(0xFF0A0E1A);
const kSurface = Color(0xFF141828);
const kSurface2 = Color(0xFF1C2235);
const kTextPrimary = Color(0xFFFFFFFF);
const kTextSecondary = Color(0xFF8892A4);
const kRed = Color(0xFFFF4444);
const kGold = Color(0xFFFFD700);
const kBlue = Color(0xFF4A90E2);

// Öğrenci avatar renkleri (8 adet, web app ile aynı sıra)
const kAvatarColors = [
  Color(0xFF00D4AA),
  Color(0xFFFF6B35),
  Color(0xFFFFD700),
  Color(0xFFA78BFA),
  Color(0xFFF472B6),
  Color(0xFF38BDF8),
  Color(0xFF34D399),
  Color(0xFFFB923C),
];

// MEB not seviyeleri
String gradeLevel(int? grade) {
  if (grade == null) return '—';
  if (grade >= 85) return 'Pekiyi';
  if (grade >= 70) return 'İyi';
  if (grade >= 55) return 'Orta';
  if (grade >= 50) return 'Geçer';
  return 'Başarısız';
}

Color gradeLevelColor(int? grade) {
  if (grade == null) return kTextSecondary;
  if (grade >= 70) return kAccent;
  if (grade >= 50) return kGold;
  return kRed;
}
