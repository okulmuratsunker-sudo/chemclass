import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../models/lesson_session.dart';
import '../models/student.dart';
import '../providers/app_state.dart';
import '../utils/formatters.dart';

const _receiptGreen = Color(0xFF00B88C);
const _receiptInk = Color(0xFF111111);
const _receiptGrey = Color(0xFF888888);
const _receiptPaidGreen = Color(0xFF00A882);
const _receiptUnpaidRed = Color(0xFFD42F3F);
const _receiptBg = Color(0xFFF8F8F8);
const _receiptFootGrey = Color(0xFFAAAAAA);

const _pdfGreen = PdfColor.fromInt(0xFF00B88C);
const _pdfInk = PdfColor.fromInt(0xFF111111);
const _pdfGrey = PdfColor.fromInt(0xFF888888);
const _pdfPaidGreen = PdfColor.fromInt(0xFF00A882);
const _pdfUnpaidRed = PdfColor.fromInt(0xFFD42F3F);
const _pdfBg = PdfColor.fromInt(0xFFF8F8F8);
const _pdfFootGrey = PdfColor.fromInt(0xFFAAAAAA);

/// Veliye gönderilecek ders raporu, mirroring `ders-takip.html`'s
/// `showReceipt()` / `doExportPng()` / `doExportPdf()`.
class ReceiptScreen extends StatefulWidget {
  final Student student;
  final List<LessonSession> sessions;
  const ReceiptScreen({super.key, required this.student, required this.sessions});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  final _screenshotController = ScreenshotController();
  bool _exporting = false;

  Future<void> _exportPng() async {
    final app = context.read<AppState>();
    app.toast('PNG oluşturuluyor...');
    try {
      final bytes = await _screenshotController.capture(pixelRatio: 2);
      if (bytes == null) throw Exception('capture failed');
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/ders-raporu.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)]);
      app.toast('PNG indirildi');
    } catch (_) {
      app.toast('PNG oluşturulamadı');
    }
  }

  Future<void> _exportPdf() async {
    final app = context.read<AppState>();
    setState(() => _exporting = true);
    app.toast('PDF hazırlanıyor...');
    try {
      final doc = await _buildPdf();
      await Printing.layoutPdf(onLayout: (_) async => doc.save());
    } catch (_) {
      app.toast('PDF oluşturulamadı');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<pw.Document> _buildPdf() async {
    final st = widget.student;
    final sData = widget.sessions;
    final totalAmt = sData.fold<double>(0, (a, s) => a + s.amount);
    final paidAmt = sData.where((s) => s.paid).fold<double>(0, (a, s) => a + s.amount);
    final unpaidAmt = totalAmt - paidAmt;
    final totalDur = sData.fold<double>(0, (a, s) => a + s.duration);
    final today = todayLong();

    final regular = await PdfGoogleFonts.notoSansRegular();
    final bold = await PdfGoogleFonts.notoSansBold();

    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: regular, bold: bold),
        build: (ctx) => pw.Padding(
          padding: const pw.EdgeInsets.all(28),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.only(bottom: 14),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(color: _pdfGreen, width: 2)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('DersTakip', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: _pdfGreen)),
                    pw.SizedBox(height: 8),
                    pw.Text(st.name, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: _pdfInk)),
                    pw.SizedBox(height: 2),
                    pw.Text('Ders Raporu · $today', style: pw.TextStyle(fontSize: 12, color: _pdfGrey)),
                    pw.Text(
                      'Saatlik Ücret: ${fmt(st.hourlyRate)} · Toplam: ${fmtDur(totalDur)} · ${sData.length} ders',
                      style: pw.TextStyle(fontSize: 12, color: _pdfGrey),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                headers: ['Tarih', 'Süre', 'Tutar', 'Durum', 'Not'],
                data: sData
                    .map((s) => [
                          fmtDate(s.date),
                          fmtDur(s.duration),
                          fmt(s.amount),
                          s.paid ? '✓ Ödendi' : '✕ Bekliyor',
                          s.notes ?? '',
                        ])
                    .toList(),
                border: null,
                headerDecoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(color: PdfColor.fromInt(0xFFE0E0E0))),
                ),
                cellDecoration: (index, data, rowNum) => const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(color: PdfColor.fromInt(0xFFF0F0F0))),
                ),
                headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _pdfGrey),
                cellStyle: pw.TextStyle(fontSize: 10, color: _pdfInk),
                cellAlignments: {1: pw.Alignment.center, 2: pw.Alignment.centerRight, 3: pw.Alignment.center},
                headerAlignments: {1: pw.Alignment.center, 2: pw.Alignment.centerRight, 3: pw.Alignment.center},
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              ),
              pw.SizedBox(height: 20),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(color: _pdfBg, borderRadius: pw.BorderRadius.circular(10)),
                child: pw.Column(
                  children: [
                    _pdfTotalRow('Toplam Tutar', fmt(totalAmt), _pdfInk, bold: false),
                    _pdfTotalRow('Ödenen', fmt(paidAmt), _pdfPaidGreen, bold: false),
                    if (unpaidAmt > 0) _pdfTotalRow('Kalan Borç', fmt(unpaidAmt), _pdfUnpaidRed, bold: false),
                    pw.Container(
                      padding: const pw.EdgeInsets.only(top: 8),
                      margin: const pw.EdgeInsets.only(top: 6),
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(top: pw.BorderSide(color: PdfColor.fromInt(0xFFDDDDDD))),
                      ),
                      child: _pdfTotalRow('NET TOPLAM', fmt(totalAmt), _pdfInk, bold: true, fontSize: 15),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.only(top: 12),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(top: pw.BorderSide(color: PdfColor.fromInt(0xFFF0F0F0))),
                ),
                child: pw.Text(
                  'Bu rapor DersTakip uygulaması tarafından oluşturulmuştur.',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontSize: 11, color: _pdfFootGrey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return doc;
  }

  static pw.Widget _pdfTotalRow(String label, String value, PdfColor color, {required bool bold, double fontSize = 13}) {
    final style = pw.TextStyle(fontSize: fontSize, color: color, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal);
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [pw.Text(label, style: style), pw.Text(value, style: style)],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final st = widget.student;
    final sData = widget.sessions;
    final totalAmt = sData.fold<double>(0, (a, s) => a + s.amount);
    final paidAmt = sData.where((s) => s.paid).fold<double>(0, (a, s) => a + s.amount);
    final unpaidAmt = totalAmt - paidAmt;
    final totalDur = sData.fold<double>(0, (a, s) => a + s.duration);
    final today = todayLong();

    return Scaffold(
      appBar: AppBar(title: Text('📤 Veliye Gönder — ${st.name}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Screenshot(
          controller: _screenshotController,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(bottom: 16),
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _receiptGreen, width: 2))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('DersTakip', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _receiptGreen)),
                      const SizedBox(height: 8),
                      Text(st.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _receiptInk)),
                      const SizedBox(height: 2),
                      Text('Ders Raporu · $today', style: const TextStyle(fontSize: 12, color: _receiptGrey)),
                      Text(
                        'Saatlik Ücret: ${fmt(st.hourlyRate)} · Toplam: ${fmtDur(totalDur)} · ${sData.length} ders',
                        style: const TextStyle(fontSize: 12, color: _receiptGrey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _ReceiptTable(sessions: sData),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: _receiptBg, borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    children: [
                      _TotalRow(label: 'Toplam Tutar', value: fmt(totalAmt), color: _receiptInk),
                      _TotalRow(label: 'Ödenen', value: fmt(paidAmt), color: _receiptPaidGreen),
                      if (unpaidAmt > 0) _TotalRow(label: 'Kalan Borç', value: fmt(unpaidAmt), color: _receiptUnpaidRed),
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.only(top: 8),
                        decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFDDDDDD)))),
                        child: _TotalRow(label: 'NET TOPLAM', value: fmt(totalAmt), color: _receiptInk, bold: true),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 12),
                  decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFF0F0F0)))),
                  child: const Text(
                    'Bu rapor DersTakip uygulaması tarafından oluşturulmuştur.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: _receiptFootGrey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Kapat'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _exporting ? null : _exportPng,
                  child: const Text('🖼 PNG İndir'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _exporting ? null : _exportPdf,
                  child: _exporting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('📄 PDF / Yazdır'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptTable extends StatelessWidget {
  final List<LessonSession> sessions;
  const _ReceiptTable({required this.sessions});

  @override
  Widget build(BuildContext context) {
    const headerStyle = TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _receiptGrey, letterSpacing: 1);
    const cellStyle = TextStyle(fontSize: 13, color: Color(0xFF333333));
    const noteStyle = TextStyle(fontSize: 11, color: _receiptGrey);

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1.6),
        1: FlexColumnWidth(1.2),
        2: FlexColumnWidth(1.3),
        3: FlexColumnWidth(1.4),
        4: FlexColumnWidth(2),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0)))),
          children: [
            _cell('TARİH', headerStyle),
            _cell('SÜRE', headerStyle, align: TextAlign.center),
            _cell('TUTAR', headerStyle, align: TextAlign.right),
            _cell('DURUM', headerStyle, align: TextAlign.center),
            _cell('NOT', headerStyle),
          ],
        ),
        for (final s in sessions)
          TableRow(
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0)))),
            children: [
              _cell(fmtDate(s.date), cellStyle),
              _cell(fmtDur(s.duration), cellStyle, align: TextAlign.center),
              _cell(fmt(s.amount), const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _receiptInk), align: TextAlign.right),
              _cell(s.paid ? '✓ Ödendi' : '✕ Bekliyor', TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: s.paid ? _receiptPaidGreen : _receiptUnpaidRed), align: TextAlign.center),
              _cell(s.notes ?? '', noteStyle),
            ],
          ),
      ],
    );
  }

  Widget _cell(String text, TextStyle style, {TextAlign align = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(text, style: style, textAlign: align),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool bold;
  const _TotalRow({required this.label, required this.value, required this.color, this.bold = false});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: bold ? 15 : 13,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      color: color,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(value, style: style)],
      ),
    );
  }
}
