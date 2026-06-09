import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/constants.dart';
import '../models/teacher_models.dart';
import '../services/supabase_service.dart';

final _scheduleProvider = FutureProvider<List<ScheduleSlot>>((ref) async {
  return SupabaseService.loadSchedule();
});

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  bool _editMode = false;

  final _days = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma'];
  final _periods = ['1. Ders', '2. Ders', '3. Ders', '4. Ders', '5. Ders', '6. Ders', '7. Ders', '8. Ders'];

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_scheduleProvider);

    return Scaffold(
      backgroundColor: kBg,
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e', style: TextStyle(color: kRed))),
        data: (slots) {
          // Map [day][period] -> slot
          final map = <int, Map<int, ScheduleSlot>>{};
          for (final s in slots) {
            map[s.dayIndex] ??= {};
            map[s.dayIndex]![s.periodIndex] = s;
          }
          return Column(
            children: [
              // Edit toggle
              Container(
                color: kSurface,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text('Ders Programı', style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    TextButton.icon(
                      icon: Icon(_editMode ? Icons.check : Icons.edit, size: 16),
                      label: Text(_editMode ? 'Bitti' : 'Düzenle'),
                      style: TextButton.styleFrom(foregroundColor: kAccent),
                      onPressed: () => setState(() => _editMode = !_editMode),
                    ),
                  ],
                ),
              ),
              // Grid
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Table(
                      border: TableBorder.all(
                        color: kSurface2,
                        width: 1,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      defaultColumnWidth: const FixedColumnWidth(120),
                      children: [
                        // Header row
                        TableRow(
                          decoration: BoxDecoration(color: kSurface),
                          children: [
                            _HeaderCell(''),
                            ..._days.map((d) => _HeaderCell(d)),
                          ],
                        ),
                        // Period rows
                        ..._periods.asMap().entries.map((pe) => TableRow(
                          children: [
                            _HeaderCell(_periods[pe.key], small: true),
                            ..._days.asMap().entries.map((de) {
                              final slot = map[de.key]?[pe.key];
                              return _SlotCell(
                                slot: slot,
                                editMode: _editMode,
                                onTap: () => _editSlot(de.key, pe.key, slot),
                              );
                            }),
                          ],
                        )),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _editSlot(int day, int period, ScheduleSlot? existing) {
    final ctrl = TextEditingController(text: existing?.content ?? '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kSurface,
        title: Text(
          '${_days[day]} — ${_periods[period]}',
          style: TextStyle(color: kTextPrimary, fontSize: 14),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: TextStyle(color: kTextPrimary),
          decoration: InputDecoration(
            hintText: 'Ders / Sınıf (örn: Kimya — 10A)',
            hintStyle: TextStyle(color: kTextSecondary),
            filled: true, fillColor: kSurface2,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          if (existing != null)
            TextButton(
              onPressed: () async {
                await SupabaseService.deleteScheduleSlot(existing.id);
                ref.invalidate(_scheduleProvider);
                if (mounted) Navigator.pop(context);
              },
              child: Text('Sil', style: TextStyle(color: kRed)),
            ),
          TextButton(onPressed: () => Navigator.pop(context), child: Text('İptal', style: TextStyle(color: kTextSecondary))),
          TextButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              await SupabaseService.upsertScheduleSlot(
                id: existing?.id,
                day: day,
                period: period,
                content: ctrl.text.trim(),
              );
              ref.invalidate(_scheduleProvider);
              if (mounted) Navigator.pop(context);
            },
            child: Text('Kaydet', style: TextStyle(color: kAccent)),
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final bool small;
  const _HeaderCell(this.text, {this.small = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: small ? kTextSecondary : kAccent,
          fontWeight: FontWeight.w600,
          fontSize: small ? 11 : 12,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _SlotCell extends StatelessWidget {
  final ScheduleSlot? slot;
  final bool editMode;
  final VoidCallback onTap;
  const _SlotCell({this.slot, required this.editMode, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: editMode ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(minHeight: 52),
        decoration: BoxDecoration(
          color: slot != null ? kAccent.withOpacity(0.08) : Colors.transparent,
        ),
        alignment: Alignment.center,
        child: slot != null
            ? Text(
                slot!.content,
                style: TextStyle(color: kTextPrimary, fontSize: 11),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            : editMode
                ? Icon(Icons.add, color: kTextSecondary.withOpacity(0.3), size: 18)
                : null,
      ),
    );
  }
}
