import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:surakshith/data/constants/fssai_audit_points.dart';
import 'package:surakshith/data/providers/fssai_report_provider.dart';

class FssaiPdfScreen extends StatefulWidget {
  final String reportId;

  const FssaiPdfScreen({
    super.key,
    required this.reportId,
  });

  @override
  State<FssaiPdfScreen> createState() => _FssaiPdfScreenState();
}

class _FssaiPdfScreenState extends State<FssaiPdfScreen> {
  Future<Uint8List>? _pdfFuture;

  // Modern Material Design color palette
  static final primaryPink = PdfColor.fromHex('#E91E63');
  static final primaryPinkLight = PdfColor.fromHex('#F8BBD0');
  static final accentOrange = PdfColor.fromHex('#FF9800');
  static final successGreen = PdfColor.fromHex('#4CAF50');
  static final errorRed = PdfColor.fromHex('#F44336');
  static final textPrimary = PdfColor.fromHex('#212121');
  static final textSecondary = PdfColor.fromHex('#757575');
  static final surfaceWhite = PdfColor.fromHex('#FFFFFF');
  static final surfaceGrey = PdfColor.fromHex('#FAFAFA');
  static final dividerGrey = PdfColor.fromHex('#E0E0E0');
  static final shadowGrey = PdfColor.fromHex('#00000029');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generatePDF();
    });
  }

  Future<void> _generatePDF() async {
    setState(() {
      _pdfFuture = _createPDF();
    });
  }

  Future<Uint8List> _createPDF() async {
    final provider = context.read<FssaiReportProvider>();
    await provider.loadReport(widget.reportId);

    final pdf = pw.Document();
    final report = provider.currentReport;

    if (report == null) {
      throw Exception('Report not found');
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          _buildHeader(report),
          pw.SizedBox(height: 16),
          _buildDetailsSection(report),
          pw.SizedBox(height: 16),
          _buildScoreBanner(provider),
          pw.SizedBox(height: 16),
          _buildAuditTable(provider),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(report) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: surfaceWhite,
        borderRadius: pw.BorderRadius.circular(8),
        boxShadow: [
          pw.BoxShadow(
            color: shadowGrey,
            blurRadius: 8,
            offset: const PdfPoint(0, 2),
          ),
        ],
      ),
      child: pw.Column(
        children: [
          // Modern title bar with gradient
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [primaryPink, PdfColor.fromHex('#C2185B')],
                begin: pw.Alignment.topLeft,
                end: pw.Alignment.bottomRight,
              ),
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(8),
                topRight: pw.Radius.circular(8),
              ),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'FSSAI AUDIT CHECKLIST',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: surfaceWhite,
                    letterSpacing: 0.5,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'Food Safety and Standards Authority of India',
                  style: pw.TextStyle(
                    fontSize: 11,
                    color: surfaceWhite.shade(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildDetailsSection(report) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: surfaceWhite,
        borderRadius: pw.BorderRadius.circular(8),
        boxShadow: [
          pw.BoxShadow(
            color: shadowGrey,
            blurRadius: 8,
            offset: const PdfPoint(0, 2),
          ),
        ],
      ),
      child: pw.Column(
        children: [
          // Details header
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: pw.BoxDecoration(
              color: surfaceGrey,
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(8),
                topRight: pw.Radius.circular(8),
              ),
            ),
            child: pw.Text(
              'Report Details',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: textPrimary,
                letterSpacing: 0.3,
              ),
            ),
          ),
          // Details content
          pw.Padding(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: _buildDetailItem(
                        'Organization Name',
                        report.organizationName ?? 'N/A',
                      ),
                    ),
                    pw.SizedBox(width: 20),
                    pw.Expanded(
                      child: _buildDetailItem(
                        'FBO Name',
                        report.fboName ?? 'N/A',
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: _buildDetailItem(
                        'Location',
                        report.location ?? 'N/A',
                      ),
                    ),
                    pw.SizedBox(width: 20),
                    pw.Expanded(
                      child: _buildDetailItem(
                        'Auditor Name',
                        report.auditorName ?? 'N/A',
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: _buildDetailItem(
                        'Date',
                        report.date ?? 'N/A',
                      ),
                    ),
                    pw.SizedBox(width: 20),
                    pw.Expanded(
                      child: _buildDetailItem(
                        'FSSAI Number',
                        report.fssaiNumber ?? 'N/A',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildDetailItem(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 9,
            color: textSecondary,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 11,
            color: textPrimary,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildScoreBanner(FssaiReportProvider provider) {
    final percentage = (provider.totalScore / provider.totalMaxScore * 100).toStringAsFixed(1);
    final percentageNum = double.parse(percentage);

    // Determine color based on percentage
    PdfColor bannerColor;
    if (percentageNum >= 80) {
      bannerColor = successGreen;
    } else if (percentageNum >= 60) {
      bannerColor = accentOrange;
    } else {
      bannerColor = errorRed;
    }

    return pw.Container(
      decoration: pw.BoxDecoration(
        color: surfaceWhite,
        borderRadius: pw.BorderRadius.circular(8),
        boxShadow: [
          pw.BoxShadow(
            color: shadowGrey,
            blurRadius: 8,
            offset: const PdfPoint(0, 2),
          ),
        ],
      ),
      child: pw.Column(
        children: [
          // Score header
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [bannerColor, bannerColor.shade(0.7)],
                begin: pw.Alignment.topLeft,
                end: pw.Alignment.bottomRight,
              ),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'TOTAL SCORE',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: surfaceWhite,
                        letterSpacing: 0.5,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      '${provider.totalScore} / ${provider.totalMaxScore}',
                      style: pw.TextStyle(
                        fontSize: 32,
                        fontWeight: pw.FontWeight.bold,
                        color: surfaceWhite,
                      ),
                    ),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: surfaceWhite,
                    shape: pw.BoxShape.circle,
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        '$percentage%',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: bannerColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildAuditTable(FssaiReportProvider provider) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: surfaceWhite,
        borderRadius: pw.BorderRadius.circular(8),
        boxShadow: [
          pw.BoxShadow(
            color: shadowGrey,
            blurRadius: 8,
            offset: const PdfPoint(0, 2),
          ),
        ],
      ),
      child: pw.ClipRRect(
        horizontalRadius: 8,
        verticalRadius: 8,
        child: pw.Table(
          border: pw.TableBorder.symmetric(
            inside: pw.BorderSide(color: dividerGrey, width: 0.5),
          ),
          columnWidths: {
            0: const pw.FixedColumnWidth(40),
            1: const pw.FlexColumnWidth(6),
            2: const pw.FixedColumnWidth(50),
            3: const pw.FixedColumnWidth(50),
          },
          children: [
            // Modern Header Row
            pw.TableRow(
              decoration: pw.BoxDecoration(
                gradient: pw.LinearGradient(
                  colors: [primaryPink, PdfColor.fromHex('#C2185B')],
                  begin: pw.Alignment.topLeft,
                  end: pw.Alignment.bottomRight,
                ),
              ),
              children: [
                _buildTableHeaderCell('S.No'),
                _buildTableHeaderCell('Audit Point'),
                _buildTableHeaderCell('Max'),
                _buildTableHeaderCell('Score'),
              ],
            ),

            // Data Rows
            ...FssaiAuditPoints.allPoints.map((point) {
              final score = provider.getScore(point.serialNo);
              final isEvenRow = point.serialNo % 2 == 0;

              return pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: isEvenRow ? surfaceGrey : surfaceWhite,
                ),
                children: [
                  _buildTableCell(
                    '${point.serialNo}',
                    alignment: pw.Alignment.center,
                    bold: true,
                  ),
                  _buildTableCell(point.description, fontSize: 9),
                  _buildTableCell(
                    '${point.maxScore}',
                    alignment: pw.Alignment.center,
                  ),
                  _buildScoreCell(score, point.maxScore),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildTableHeaderCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
          color: surfaceWhite,
          letterSpacing: 0.3,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _buildTableCell(
    String text, {
    pw.Alignment alignment = pw.Alignment.centerLeft,
    bool bold = false,
    double fontSize = 10,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      alignment: alignment,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: textPrimary,
        ),
        textAlign: alignment == pw.Alignment.center
            ? pw.TextAlign.center
            : pw.TextAlign.left,
      ),
    );
  }

  pw.Widget _buildScoreCell(int score, int maxScore) {
    final isFullScore = score == maxScore;
    final bgColor = isFullScore
        ? PdfColor.fromHex('#E8F5E9')
        : PdfColor.fromHex('#FFEBEE');
    final textColor = isFullScore ? successGreen : errorRed;

    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      alignment: pw.Alignment.center,
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: pw.BoxDecoration(
          color: bgColor,
          borderRadius: pw.BorderRadius.circular(12),
        ),
        child: pw.Text(
          '$score',
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: textColor,
          ),
          textAlign: pw.TextAlign.center,
        ),
      ),
    );
  }

  Future<void> _sharePDF(Uint8List pdfBytes) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/fssai_report_${widget.reportId}.pdf');
    await file.writeAsBytes(pdfBytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'FSSAI Audit Report',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF222222),
        title: Text(
          'FSSAI Report PDF',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: Platform.isIOS ? 17 : 20,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          if (_pdfFuture != null)
            FutureBuilder<Uint8List>(
              future: _pdfFuture,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return IconButton(
                    onPressed: () => _sharePDF(snapshot.data!),
                    icon: const Icon(Icons.share),
                    tooltip: 'Share PDF',
                  );
                }
                return const SizedBox();
              },
            ),
        ],
      ),
      body: _pdfFuture == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<Uint8List>(
              future: _pdfFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Generating PDF...'),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error generating PDF',
                            style: TextStyle(
                              fontSize: Platform.isIOS ? 17 : 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            snapshot.error.toString(),
                            style: TextStyle(
                              fontSize: Platform.isIOS ? 13 : 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _generatePDF,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: Text('No data'));
                }

                return PdfPreview(
                  build: (format) => snapshot.data!,
                  canChangePageFormat: false,
                  canChangeOrientation: false,
                  canDebug: false,
                  pdfFileName: 'fssai_report_${widget.reportId}.pdf',
                );
              },
            ),
    );
  }
}
