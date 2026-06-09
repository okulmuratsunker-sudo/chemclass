import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../config/constants.dart';
import '../providers/session_provider.dart';
import '../services/supabase_service.dart';
import '../models/assignment.dart';

class AssignmentsScreen extends ConsumerStatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  ConsumerState<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends ConsumerState<AssignmentsScreen> {
  List<Assignment>? _items;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = ref.read(sessionProvider)!;
      final items = await SupabaseService.loadAssignments(session);
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) setState(() => _error = 'Ödevler yüklenemedi.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: kAccent));
    }
    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.wifi_off_rounded, color: kTextSecondary, size: 48),
          const SizedBox(height: 12),
          Text(_error!,
              style: GoogleFonts.inter(color: kTextSecondary)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _load,
            style: ElevatedButton.styleFrom(
                backgroundColor: kAccent, foregroundColor: kBg),
            child: Text('Tekrar Dene',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ]),
      );
    }

    final items = _items!;

    return RefreshIndicator(
      color: kAccent,
      backgroundColor: kSurface,
      onRefresh: _load,
      child: items.isEmpty
          ? ListView(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.assignment_outlined,
                            color: kTextSecondary, size: 52),
                        const SizedBox(height: 12),
                        Text(
                          'Henüz ödev veya duyuru yok.',
                          style: GoogleFonts.inter(color: kTextSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _AssignmentCard(item: items[i]),
            ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final Assignment item;

  const _AssignmentCard({required this.item});

  Color get _typeColor {
    switch (item.type) {
      case 'odev':
        return const Color(0xFF4A90E2);
      case 'duyuru':
        return kAccent;
      case 'gorev':
        return const Color(0xFF7ED321);
      default:
        return kTextSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('d MMMM y', 'tr_TR');

    return Container(
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kSurface2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _typeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.typeLabel,
                    style: GoogleFonts.inter(
                        color: _typeColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const Spacer(),
                Text(
                  dateFmt.format(item.createdAt),
                  style: GoogleFonts.inter(
                      color: kTextSecondary, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              item.title,
              style: GoogleFonts.inter(
                color: kTextPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (item.description != null &&
                item.description!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                item.description!,
                style: GoogleFonts.inter(
                    color: kTextSecondary, fontSize: 13, height: 1.5),
              ),
            ],
            if (item.dueDate != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      color: kRed, size: 13),
                  const SizedBox(width: 4),
                  Text(
                    'Son tarih: ${dateFmt.format(item.dueDate!)}',
                    style: GoogleFonts.inter(
                        color: kRed,
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
