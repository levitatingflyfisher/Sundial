import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:sundial/core/storage/app_database.dart';
import 'package:sundial/shared/extensions/duration_ext.dart';

class PdfExporter {
  @visibleForTesting
  static String totalLoggedLine(List<Session> sessions) {
    final totalSecs = sessions.fold<int>(0, (acc, s) => acc + s.durationSecs);
    return 'Total logged: ${Duration(seconds: totalSecs).toHoursLabel()}';
  }

  @visibleForTesting
  static String durationCell(Session s) =>
      Duration(seconds: s.durationSecs).toHoursLabel();

  Future<void> sharePdf(
    List<Session> sessions, {
    required int annualGoalHours,
  }) async {
    final doc = pw.Document();
    final today = DateFormat('MMMM d, yyyy').format(DateTime.now());

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('Sundial: Outdoor Time',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Text('Exported: $today'),
          pw.Text('Annual goal: ${annualGoalHours}h'),
          pw.Text(totalLoggedLine(sessions)),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: ['Date', 'Duration', 'Notes'],
            data: [
              for (final s in sessions)
                [s.dateDay, durationCell(s), s.notes ?? ''],
            ],
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
