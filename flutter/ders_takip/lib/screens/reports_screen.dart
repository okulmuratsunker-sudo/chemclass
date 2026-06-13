import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// Rapor page, mirroring `ders-takip.html`'s `renderReports()` /
/// `renderBarChart()`: a 6-month income bar chart plus a per-student summary
/// table.
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final dt = Theme.of(context).dt;
    final monthly = app.monthlyIncome();

    return RefreshIndicator(
      onRefresh: () => app.loadAll(),
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _ChartCard(
            title: 'Aylık Gelir (Son 6 Ay)',
            child: _BarChart(monthly: monthly),
          ),
          const SizedBox(height: 12),
          _ChartCard(
            title: 'Öğrenci Bazında Özet',
            child: app.students.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: Text('Öğrenci yok', style: TextStyle(color: dt.text3, fontSize: 13))),
                  )
                : const _StudentSummaryTable(),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _ChartCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final dt = Theme.of(context).dt;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: dt.text1)),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  final Map<String, double> monthly;
  const _BarChart({required this.monthly});

  @override
  Widget build(BuildContext context) {
    final dt = Theme.of(context).dt;
    final max = monthly.values.fold<double>(1, (a, b) => b > a ? b : a);
    return SizedBox(
      height: 170,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: monthly.entries.map((e) {
          final value = e.value;
          final barHeight = value > 0 ? (value / max * 120).clamp(4.0, 120.0) : 0.0;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    height: 16,
                    child: Text(
                      value > 0 ? fmtS(value) : '',
                      style: TextStyle(fontSize: 9, color: dt.text2, fontFamily: 'monospace'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: barHeight,
                    decoration: BoxDecoration(
                      color: dt.green,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(monthLabel(e.key), style: TextStyle(fontSize: 10, color: dt.text3)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StudentSummaryTable extends StatelessWidget {
  const _StudentSummaryTable();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final dt = Theme.of(context).dt;
    final headerStyle = TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: dt.text3, letterSpacing: 1);

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1.3),
        3: FlexColumnWidth(1.3),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: dt.border))),
          children: [
            _cell('ÖĞRENCİ', headerStyle),
            _cell('DERS', headerStyle, align: TextAlign.right),
            _cell('TOPLAM', headerStyle, align: TextAlign.right),
            _cell('ÖDENMEDİ', headerStyle, align: TextAlign.right),
          ],
        ),
        for (final st in app.students)
          TableRow(
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: dt.border))),
            children: [
              _cell(st.name, TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: dt.text1)),
              _cell('${app.sessionsFor(st.id).length}', TextStyle(fontFamily: 'monospace', fontSize: 12, color: dt.text2), align: TextAlign.right),
              _cell(
                fmt(app.sessionsFor(st.id).fold<double>(0, (a, s) => a + s.amount)),
                TextStyle(fontFamily: 'monospace', fontSize: 12, color: dt.green),
                align: TextAlign.right,
              ),
              _cell(
                fmt(app.unpaidFor(st.id)),
                TextStyle(fontFamily: 'monospace', fontSize: 12, color: app.unpaidFor(st.id) > 0 ? dt.red : dt.text3),
                align: TextAlign.right,
              ),
            ],
          ),
      ],
    );
  }

  Widget _cell(String text, TextStyle style, {TextAlign align = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(text, style: style, textAlign: align, overflow: TextOverflow.ellipsis),
    );
  }
}
