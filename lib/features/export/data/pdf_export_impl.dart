import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:sundial/core/storage/app_database.dart';

class PdfExporter {
  Future<void> sharePdf(
    List<Session> sessions, {
    required int annualGoalHours,
  }) async {
    final doc = pw.Document();
    final totalSecs = sessions.fold<int>(0, (acc, s) => acc + s.durationSecs);
    final totalHours = totalSecs ~/ 3600;
    final today = DateFormat('MMMM d, yyyy').format(DateTime.now());

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('Sundial — Outdoor Time',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Text('Exported: $today'),
          pw.Text('Annual goal: ${annualGoalHours}h'),
          pw.Text('Total logged: ${totalHours}h'),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: ['Date', 'Duration', 'Notes'],
            data: sessions.map((s) {
              final h = s.durationSecs ~/ 3600;
              final m = (s.durationSecs % 3600) ~/ 60;
              final remainderSecs = s.durationSecs % 60;
              final dur = h > 0
                  ? (m > 0 ? '${h}h ${m}m' : '${h}h')
                  : (m > 0 ? '${m}m' : '${remainderSecs}s');
              return [s.dateDay, dur, s.notes ?? ''];
            }).toList(),
          ),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'sundial-${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf',
    );
  }
}
