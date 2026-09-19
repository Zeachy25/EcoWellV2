import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/utils/stress_scoring.dart';
import '../../models/app_user.dart';
import '../../models/visit.dart';

class PdfExportService {
  static const _green = PdfColor.fromInt(0xFF2E7D32);

  Future<void> exportVisitSummary({
    required AppUser user,
    required List<Visit> visits,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: _green, width: 2),
            ),
          ),
          child: pw.Text(
            'EcoWell',
            style: pw.TextStyle(color: _green, fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey),
          ),
        ),
        build: (context) => [
          pw.SizedBox(height: 8),
          pw.Text(
            'Visit & Wellness Summary',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          pw.Text('Name: ${user.name}', style: _body),
          pw.Text('Email: ${user.email}', style: _body),
          pw.Text('Age: ${user.age}', style: _body),
          pw.Text(
            'Generated: ${DateFormat('MMM d, yyyy h:mm a').format(DateTime.now())}',
            style: _body,
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Overview',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ['Metric', 'Value'],
            data: [
              ['Total Visits', '${visits.length}'],
              [
                'Average Stress Reduction',
                visits.isEmpty ? '—' : (_avgReduction(visits).toStringAsFixed(1)),
              ],
              [
                'Average Quiet Score',
                visits.isEmpty ? '—' : '${(_avgQuiet(visits).toStringAsFixed(1))} / 5',
              ],
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: _green),
            cellStyle: _body,
            cellAlignments: {0: pw.Alignment.centerLeft, 1: pw.Alignment.centerLeft},
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Visit History',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          if (visits.isEmpty)
            pw.Text('No visits recorded.', style: _body)
          else
            pw.TableHelper.fromTextArray(
              headers: ['Date', 'Green Space', 'Pre', 'Post', 'Reduction', 'Interpretation', 'Quiet'],
              data: [
                for (final visit in visits)
                  [
                    DateFormat('MMM d, yyyy').format(visit.startTime),
                    visit.greenSpaceName,
                    '${visit.preScore}',
                    '${visit.postScore}',
                    '${visit.stressReduction >= 0 ? '+' : ''}${visit.stressReduction}',
                    interpretStressReduction(visit.stressReduction),
                    '${visit.quietRating}/5',
                  ],
              ],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
              headerDecoration: const pw.BoxDecoration(color: _green),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.center,
                3: pw.Alignment.center,
                4: pw.Alignment.center,
                5: pw.Alignment.centerLeft,
                6: pw.Alignment.center,
              },
            ),
          pw.SizedBox(height: 24),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 8),
          pw.Text(
            'The Stress Reduction Score is the difference between pre-visit and post-visit PSS-4 scores. '
            'This summary is for personal wellness use only and is not a medical assessment.',
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey),
          ),
        ],
      ),
    );

    final bytes = await doc.save();
    final now = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'EcoWell_Visit_Summary_$now.pdf',
    );
  }

  double _avgReduction(List<Visit> visits) =>
      visits.fold<int>(0, (sum, v) => sum + v.stressReduction) / visits.length;

  double _avgQuiet(List<Visit> visits) =>
      visits.fold<int>(0, (sum, v) => sum + v.quietRating) / visits.length;

  static const _body = pw.TextStyle(fontSize: 11);
}