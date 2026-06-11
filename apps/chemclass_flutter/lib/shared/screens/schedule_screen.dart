import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/schedule_repository.dart';
import '../../state/auth_state.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthState>().profile;
    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }
    return ChangeNotifierProvider(
      create: (_) => ScheduleController(profile.id),
      child: const _ScheduleView(),
    );
  }
}

class _ScheduleView extends StatefulWidget {
  const _ScheduleView();

  @override
  State<_ScheduleView> createState() => _ScheduleViewState();
}

class _ScheduleViewState extends State<_ScheduleView> {
  late int _selectedDay;
  final Map<int, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = isoDayOfWeek(DateTime.now());
    for (final period in periods) {
      _controllers[period] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _syncControllers(ScheduleController controller) {
    final entryMap = <int, String>{};
    for (final entry in controller.items) {
      if (entry.dayOfWeek == _selectedDay) entryMap[entry.periodNumber] = entry.subjectName;
    }
    for (final period in periods) {
      final value = entryMap[period] ?? '';
      final c = _controllers[period]!;
      if (c.text != value && !c.value.composing.isValid) {
        c.text = value;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Programım')),
      body: Consumer<ScheduleController>(
        builder: (context, controller, _) {
          _syncControllers(controller);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: daysOfWeek.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final day = daysOfWeek[index];
                    final selected = day.value == _selectedDay;
                    return ChoiceChip(
                      label: Text(day.label),
                      selected: selected,
                      onSelected: (_) => setState(() => _selectedDay = day.value),
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: selected ? AppColors.primaryText : AppColors.text,
                        fontWeight: FontWeight.w500,
                      ),
                      backgroundColor: AppColors.surface,
                      side: const BorderSide(color: AppColors.border),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    for (final period in periods) ...[
                      if (period != periods.first) const SizedBox(height: 12),
                      Row(
                        children: [
                          SizedBox(
                            width: 64,
                            child: Text('$period. Ders', style: const TextStyle(fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _controllers[period],
                              decoration: const InputDecoration(hintText: 'Boş', isDense: true),
                              onSubmitted: (value) => controller.setEntry(_selectedDay, period, value),
                              onTapOutside: (_) {
                                FocusScope.of(context).unfocus();
                                controller.setEntry(_selectedDay, period, _controllers[period]!.text);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
