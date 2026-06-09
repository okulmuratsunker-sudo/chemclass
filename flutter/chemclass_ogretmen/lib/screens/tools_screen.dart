import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/constants.dart';
import 'lesson_plans_screen.dart';
import 'item_analysis_screen.dart';
import 'teacher_portfolio_screen.dart';

class ToolsScreen extends ConsumerWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Öğretmen Araçları',
          style: TextStyle(color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        _ToolCard(
          icon: Icons.auto_stories,
          title: 'Ders Planları',
          subtitle: 'Günlük, ünite ve yıllık planlar oluşturun',
          color: const Color(0xFF3B82F6),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LessonPlansScreen())),
        ),
        const SizedBox(height: 12),
        _ToolCard(
          icon: Icons.analytics,
          title: 'Madde Analizi',
          subtitle: 'Sınav sorularının güçlük ve ayırt edicilik indeksleri',
          color: const Color(0xFF8B5CF6),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ItemAnalysisScreen())),
        ),
        const SizedBox(height: 12),
        _ToolCard(
          icon: Icons.school,
          title: 'Öğretmenim Portfolyosu',
          subtitle: 'Öğrenci listesi, notlar ve davranış kayıtları',
          color: const Color(0xFFF59E0B),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherPortfolioScreen())),
        ),
      ],
    );
  }
}

class _ToolCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _ToolCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: kTextSecondary, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: kTextSecondary, size: 16),
          ],
        ),
      ),
    );
  }
}
