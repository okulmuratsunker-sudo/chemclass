import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../config/constants.dart';
import '../models/teacher_models.dart';
import '../providers/app_provider.dart';
import '../services/supabase_service.dart';

final _dashScheduleProvider = FutureProvider<List<ScheduleSlot>>((ref) async {
  return SupabaseService.loadSchedule();
});

class DashboardScreen extends ConsumerStatefulWidget {
  final void Function(int) onNavigate;
  const DashboardScreen({super.key, required this.onNavigate});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _greeting {
    final h = _now.hour;
    if (h < 6) return 'İyi geceler';
    if (h < 12) return 'Günaydın';
    if (h < 18) return 'İyi günler';
    return 'İyi akşamlar';
  }

  TextStyle get _sectionStyle =>
      TextStyle(color: kTextPrimary, fontSize: 15, fontWeight: FontWeight.w700);

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appDataProvider);
    final scheduleAsync = ref.watch(_dashScheduleProvider);
    final weekdayIndex = _now.weekday - 1; // 0=Pazartesi..4=Cuma, 5/6=hafta sonu

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_greeting, Öğretmenim 👋',
                style: TextStyle(color: kTextPrimary, fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              _ClockCard(now: _now),
              const SizedBox(height: 24),
              Text('Bugünün Dersleri', style: _sectionStyle),
              const SizedBox(height: 8),
              scheduleAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Text('Hata: $e', style: TextStyle(color: kRed)),
                data: (slots) => _TodayLessons(slots: slots, weekdayIndex: weekdayIndex),
              ),
              const SizedBox(height: 24),
              Text('Genel Bilgiler', style: _sectionStyle),
              const SizedBox(height: 8),
              _StatsRow(
                classCount: data.classes.length,
                studentCount: data.students.length,
                lessonCount: scheduleAsync.maybeWhen(
                  data: (slots) => slots.where((s) => s.dayIndex == weekdayIndex).length,
                  orElse: () => 0,
                ),
              ),
              const SizedBox(height: 24),
              Text('Hızlı Erişim', style: _sectionStyle),
              const SizedBox(height: 8),
              _QuickAccess(onNavigate: widget.onNavigate),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClockCard extends StatelessWidget {
  final DateTime now;
  const _ClockCard({required this.now});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kAccent.withOpacity(0.18), kSurface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kAccent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('HH:mm:ss').format(now),
            style: TextStyle(color: kTextPrimary, fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('EEEE, d MMMM yyyy', 'tr_TR').format(now),
            style: TextStyle(color: kAccent, fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _TodayLessons extends StatelessWidget {
  final List<ScheduleSlot> slots;
  final int weekdayIndex;
  const _TodayLessons({required this.slots, required this.weekdayIndex});

  static const _periods = ['1. Ders', '2. Ders', '3. Ders', '4. Ders', '5. Ders', '6. Ders', '7. Ders', '8. Ders'];

  @override
  Widget build(BuildContext context) {
    if (weekdayIndex < 0 || weekdayIndex > 4) {
      return _InfoBox(text: 'Bugün hafta sonu, ders yok 🎉');
    }
    final today = slots.where((s) => s.dayIndex == weekdayIndex).toList()
      ..sort((a, b) => a.periodIndex.compareTo(b.periodIndex));
    if (today.isEmpty) {
      return _InfoBox(text: 'Bugün için programa ders eklenmemiş.');
    }
    return Column(
      children: today.map((s) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: kAccent.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
              child: Text('${s.periodIndex + 1}', style: TextStyle(color: kAccent, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.periodIndex < _periods.length ? _periods[s.periodIndex] : '${s.periodIndex + 1}. Ders',
                    style: TextStyle(color: kTextSecondary, fontSize: 11),
                  ),
                  Text(s.content, style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String text;
  const _InfoBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: TextStyle(color: kTextSecondary)),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int classCount;
  final int studentCount;
  final int lessonCount;
  const _StatsRow({required this.classCount, required this.studentCount, required this.lessonCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(icon: Icons.class_, label: 'Sınıf', value: '$classCount')),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(icon: Icons.people, label: 'Öğrenci', value: '$studentCount')),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(icon: Icons.today, label: 'Bugünkü Ders', value: '$lessonCount')),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Icon(icon, color: kAccent, size: 22),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: kTextPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: kTextSecondary, fontSize: 11), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _QuickAccess extends StatelessWidget {
  final void Function(int) onNavigate;
  const _QuickAccess({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.how_to_reg, 'Yoklama', 2),
      (Icons.cast, 'Tahta', 8),
      (Icons.chat, 'Mesajlar', 5),
      (Icons.assignment, 'Ödevler', 4),
    ];
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.85,
      children: items.map((item) => GestureDetector(
        onTap: () => onNavigate(item.$3),
        child: Container(
          decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(12)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.$1, color: kAccent, size: 24),
              const SizedBox(height: 6),
              Text(item.$2, style: TextStyle(color: kTextSecondary, fontSize: 11), textAlign: TextAlign.center),
            ],
          ),
        ),
      )).toList(),
    );
  }
}
