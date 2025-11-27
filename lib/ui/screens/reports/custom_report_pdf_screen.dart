import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../data/providers/client_provider.dart';
import '../../../data/providers/project_provider.dart';
import '../../../data/providers/audit_area_entry_provider.dart';
import '../../../data/providers/audit_area_provider.dart';
import '../../../data/providers/audit_issue_provider.dart';
import '../../../data/providers/responsible_person_provider.dart';

class CustomReportPdfScreen extends StatefulWidget {
  final String clientId;
  final String projectId;
  final String reportId;

  const CustomReportPdfScreen({
    super.key,
    required this.clientId,
    required this.projectId,
    required this.reportId,
  });

  @override
  State<CustomReportPdfScreen> createState() => _CustomReportPdfScreenState();
}

class _CustomReportPdfScreenState extends State<CustomReportPdfScreen> {
  Future<Uint8List>? _pdfFuture;
  String _errorMessage = '';

  // Data holders
  String _organizationName = 'SAMCO';
  String _reportDate = '';
  String _fssaiNo = '-';
  String _fboName = '';
  String _outletLocation = '';
  String _auditorName = 'Auditor';

  List<Map<String, dynamic>> _auditEntries = [];
  final Map<String, Uint8List?> _imageCache = {};

  // Modern Material Design color palette
  static final primaryPink = PdfColor.fromHex('#E91E63');
  static final primaryPinkLight = PdfColor.fromHex('#F8BBD0');
  static final accentTeal = PdfColor.fromHex('#00BCD4');
  static final successGreen = PdfColor.fromHex('#4CAF50');
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
      _loadReportData();
    });
  }

  Future<void> _loadReportData() async {
    try {
      // Get providers
      final clientProvider = context.read<ClientProvider>();
      final projectProvider = context.read<ProjectProvider>();
      final entryProvider = context.read<AuditAreaEntryProvider>();
      final auditAreaProvider = context.read<AuditAreaProvider>();
      final auditIssueProvider = context.read<AuditIssueProvider>();
      final responsiblePersonProvider = context.read<ResponsiblePersonProvider>();

      // Get client and project
      final clients = clientProvider.getAllClients();
      final clientIndex = clients.indexWhere((c) => c.id == widget.clientId);
      final client = clientIndex != -1 ? clients[clientIndex] : null;

      final projects = projectProvider.getAllProjects();
      final projectIndex = projects.indexWhere((p) => p.id == widget.projectId);
      final project = projectIndex != -1 ? projects[projectIndex] : null;

      // Set basic info
      _fboName = client?.name ?? 'Unknown Client';
      _outletLocation = project?.name ?? 'Unknown Project';
      _reportDate = DateFormat('dd.MM.yyyy').format(DateTime.now());

      // Get audit entries for this report
      // Set current report after frame to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          entryProvider.setCurrentReport(widget.reportId);
        }
      });

      // Get entries directly from repository without triggering provider state changes
      final entries = entryProvider.getAllEntries()
          .where((entry) => entry.reportId == widget.reportId)
          .toList();

      // Get all reference data
      final auditAreas = auditAreaProvider.getAllAuditAreas();
      final auditIssues = auditIssueProvider.getAllAuditIssues();
      final responsiblePersons = responsiblePersonProvider.getAllResponsiblePersons();

      // Transform entries into displayable format
      _auditEntries = entries.asMap().entries.map((entry) {
        final index = entry.key;
        final auditEntry = entry.value;

        // Get audit area name
        final auditAreaIndex = auditAreas.indexWhere((a) => a.id == auditEntry.auditAreaId);
        final auditAreaName = auditAreaIndex != -1
            ? auditAreas[auditAreaIndex].name
            : (auditAreas.isNotEmpty ? auditAreas.first.name : 'Unknown Area');

        // Get audit issue names (multiple)
        final issueNames = auditEntry.auditIssueIds
            .map((id) {
              final issueIndex = auditIssues.indexWhere((i) => i.id == id);
              return issueIndex != -1 ? auditIssues[issueIndex].name : null;
            })
            .where((name) => name != null)
            .join(', ');

        // Get responsible person name
        String responsiblePersonName = 'Store Incharge';
        final rpIndex = responsiblePersons.indexWhere((rp) => rp.id == auditEntry.responsiblePersonId);
        if (rpIndex != -1) {
          responsiblePersonName = responsiblePersons[rpIndex].name;
        }

        // Format deadline
        final deadlineStr = auditEntry.deadlineDate != null
            ? DateFormat('dd/MM/yyyy').format(auditEntry.deadlineDate!)
            : 'Not specified';

        return {
          'slNo': index + 1,
          'auditArea': auditAreaName,
          'auditIssue': issueNames.isNotEmpty ? issueNames : 'No issues',
          'observation': auditEntry.observation.isEmpty ? 'Not specified' : auditEntry.observation,
          'riskLevel': auditEntry.risk.toUpperCase(),
          'suggestion': auditEntry.recommendation.isEmpty ? 'Not specified' : auditEntry.recommendation,
          'responsiblePerson': responsiblePersonName,
          'deadline': deadlineStr,
          'imageUrls': auditEntry.imageUrls,
        };
      }).toList();

      setState(() {
        _pdfFuture = _generatePdf(PdfPageFormat.a4);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load report data: $e';
      });
    }
  }

  Future<void> _regeneratePDF() async {
    setState(() {
      _pdfFuture = _generatePdf(PdfPageFormat.a4);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Custom Report'),
          backgroundColor: const Color(0xFFE91E63),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading report',
                  style: TextStyle(
                    fontSize: Platform.isIOS ? 17 : 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: Platform.isIOS ? 13 : 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _regeneratePDF,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE91E63),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF222222),
        title: Text(
          'Custom Report PDF',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: Platform.isIOS ? 17 : 20,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: _pdfFuture == null
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFFE91E63)),
                  SizedBox(height: 16),
                  Text('Loading report data...'),
                ],
              ),
            )
          : FutureBuilder<Uint8List>(
              future: _pdfFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFFE91E63)),
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
                            onPressed: _regeneratePDF,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE91E63),
                              foregroundColor: Colors.white,
                            ),
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
                  pdfFileName: 'custom_report_${widget.reportId}.pdf',
                );
              },
            ),
    );
  }

  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    final pdf = pw.Document();

    // Load fonts
    final theme = pw.ThemeData.withFont(
      base: await PdfGoogleFonts.robotoRegular(),
      bold: await PdfGoogleFonts.robotoBold(),
    );

    // Preload images
    await _preloadImages();

    pdf.addPage(
      pw.MultiPage(
        maxPages: 100,
        pageFormat: format,
        theme: theme,
        margin: const pw.EdgeInsets.all(20),
        header: (context) => pw.Column(
          children: [
            _buildHeader(),
            pw.SizedBox(height: 16),
          ],
        ),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildReportTable(),
        ],
      ),
    );

    return pdf.save();
  }

  Future<void> _preloadImages() async {
    try {
      print('📥 Starting INSTANT image preload from local files for ${_auditEntries.length} entries');

      for (final entry in _auditEntries) {
        // Get image paths from entry
        // pendingImagePaths = new images not yet uploaded
        // imageUrls = local file paths (kept permanently after upload)
        final pendingPathsObj = entry['pendingImagePaths'];
        final imageUrlsObj = entry['imageUrls'];

        List<String> localImagePaths = [];

        // Collect pending images (new uploads)
        if (pendingPathsObj is List && (pendingPathsObj as List).isNotEmpty) {
          localImagePaths.addAll(pendingPathsObj.map((e) => e.toString()).toList());
        }

        // Collect permanent local images
        if (imageUrlsObj is List && (imageUrlsObj as List).isNotEmpty) {
          localImagePaths.addAll(imageUrlsObj.map((e) => e.toString()).toList());
        } else if (imageUrlsObj is String && imageUrlsObj.isNotEmpty) {
          localImagePaths.add(imageUrlsObj);
        }

        print('📁 Loading ${localImagePaths.length} images from local storage (INSTANT)');

        // Load all images from local file system (no network calls!)
        for (final imagePath in localImagePaths) {
          if (imagePath.isEmpty) continue;

          // Skip if already cached
          if (_imageCache.containsKey(imagePath)) {
            print('⏭️ Image already cached: ${imagePath.split('/').last}');
            continue;
          }

          try {
            // ONLY load from local files - NO Firebase downloads
            final file = File(imagePath);
            if (await file.exists()) {
              final bytes = await file.readAsBytes();
              _imageCache[imagePath] = bytes;
              print('✅ Loaded local image instantly: ${bytes.length} bytes');
            } else {
              _imageCache[imagePath] = null;
              print('⚠️ Local image not found (may have been deleted): ${imagePath.split('/').last}');
            }
          } catch (e) {
            _imageCache[imagePath] = null;
            print('❌ Failed to load local image: $e');
          }
        }
      }

      print('📥 ✨ INSTANT image preload complete! Cached ${_imageCache.length} images from local storage');
    } catch (e) {
      print('❌ Error in preloadImages: $e');
      // Continue anyway - we'll generate PDF without images
    }
  }

  pw.Widget _buildHeader() {
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
          // Modern title bar with gradient accent
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(16),
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
                  'FOOD SAFETY AUDIT REPORT',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: surfaceWhite,
                    letterSpacing: 0.5,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  _organizationName,
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: surfaceWhite.shade(0.9),
                  ),
                ),
              ],
            ),
          ),
          // Modern details grid
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Left column
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildDetailItem('Date', _reportDate, pw.IconData(0xe3a8)), // calendar_today
                      pw.SizedBox(height: 8),
                      _buildDetailItem('Organization', _organizationName, pw.IconData(0xe3af)), // business
                      pw.SizedBox(height: 8),
                      _buildDetailItem('Location', _outletLocation, pw.IconData(0xe3c8)), // location_on
                    ],
                  ),
                ),
                pw.SizedBox(width: 20),
                // Right column
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildDetailItem('FSSAI No', _fssaiNo, pw.IconData(0xe9ba)), // badge
                      pw.SizedBox(height: 8),
                      _buildDetailItem('FBO Name', _fboName, pw.IconData(0xe56c)), // restaurant
                      pw.SizedBox(height: 8),
                      _buildDetailItem('Auditor', _auditorName, pw.IconData(0xe7fd)), // person
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

  pw.Widget _buildDetailItem(String label, String value, pw.IconData icon) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 20,
          height: 20,
          padding: const pw.EdgeInsets.all(3),
          decoration: pw.BoxDecoration(
            color: primaryPinkLight,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Icon(
            icon,
            size: 10,
            color: primaryPink,
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                label,
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: textSecondary,
                  letterSpacing: 0.3,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                value,
                style: pw.TextStyle(
                  fontSize: 10,
                  color: textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildReportTable() {
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
            0: const pw.FixedColumnWidth(28),  // SL No
            1: const pw.FixedColumnWidth(68),  // Audit Area/Issue
            2: const pw.FixedColumnWidth(110), // Observation
            3: const pw.FixedColumnWidth(48),  // Risk Level
            4: const pw.FixedColumnWidth(98),  // Suggestion
            5: const pw.FixedColumnWidth(62),  // Responsible person
            6: const pw.FixedColumnWidth(48),  // Deadline
            7: const pw.FixedColumnWidth(80),  // Supporting Evidence
          },
          children: [
            // Modern header row
            pw.TableRow(
              decoration: pw.BoxDecoration(
                gradient: pw.LinearGradient(
                  colors: [primaryPink, PdfColor.fromHex('#C2185B')],
                  begin: pw.Alignment.topLeft,
                  end: pw.Alignment.bottomRight,
                ),
              ),
              children: [
                _buildTableHeader('SL\nNo'),
                _buildTableHeader('Audit Area/\nIssue'),
                _buildTableHeader('Observation'),
                _buildTableHeader('Risk\nLevel'),
                _buildTableHeader('Suggestion'),
                _buildTableHeader('Responsible\nPerson'),
                _buildTableHeader('Deadline'),
                _buildTableHeader('Evidence'),
              ],
            ),
            // Data rows
            ..._auditEntries.asMap().entries.map((entry) {
              final index = entry.key;
              final data = entry.value;
              return _buildDataRow(data, index);
            }),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildTableHeader(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: pw.Center(
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: surfaceWhite,
            letterSpacing: 0.3,
          ),
          textAlign: pw.TextAlign.center,
        ),
      ),
    );
  }

  pw.TableRow _buildDataRow(Map<String, dynamic> entry, int index) {
    // Subtle alternating row colors for better readability
    final bgColor = index.isEven ? surfaceWhite : surfaceGrey;

    return pw.TableRow(
      decoration: pw.BoxDecoration(color: bgColor),
      children: [
        _buildTableCell(entry['slNo'].toString(), isBold: true, align: pw.Alignment.center),
        _buildTableCell('${entry['auditArea']}\n${entry['auditIssue']}'),
        _buildTableCell(entry['observation']),
        _buildRiskCell(entry['riskLevel']),
        _buildTableCell(entry['suggestion']),
        _buildTableCell(entry['responsiblePerson']),
        _buildTableCell(entry['deadline'], align: pw.Alignment.center),
        _buildImagesCell(entry['imageUrls']),
      ],
    );
  }

  pw.Widget _buildTableCell(
    String text, {
    bool isBold = false,
    pw.Alignment align = pw.Alignment.topLeft,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      alignment: align,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: textPrimary,
        ),
        textAlign: align == pw.Alignment.center
            ? pw.TextAlign.center
            : pw.TextAlign.left,
      ),
    );
  }

  pw.Widget _buildRiskCell(String riskLevel) {
    PdfColor bgColor;
    PdfColor textColor;

    switch (riskLevel.toUpperCase()) {
      case 'HIGH':
        bgColor = PdfColor.fromHex('#FFEBEE');
        textColor = PdfColor.fromHex('#D32F2F');
        break;
      case 'MEDIUM':
        bgColor = PdfColor.fromHex('#FFF3E0');
        textColor = PdfColor.fromHex('#F57C00');
        break;
      case 'LOW':
        bgColor = PdfColor.fromHex('#E8F5E9');
        textColor = successGreen;
        break;
      default:
        bgColor = surfaceGrey;
        textColor = textSecondary;
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      alignment: pw.Alignment.center,
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: pw.BoxDecoration(
          color: bgColor,
          borderRadius: pw.BorderRadius.circular(12),
        ),
        child: pw.Text(
          riskLevel,
          style: pw.TextStyle(
            fontSize: 7,
            fontWeight: pw.FontWeight.bold,
            color: textColor,
          ),
          textAlign: pw.TextAlign.center,
        ),
      ),
    );
  }

  pw.Widget _buildImagesCell(List<String> imageUrls) {
    if (imageUrls.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(6),
        alignment: pw.Alignment.center,
        child: pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: surfaceGrey,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            'No images',
            style: pw.TextStyle(
              fontSize: 7,
              color: textSecondary,
              fontStyle: pw.FontStyle.italic,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ),
      );
    }

    // Build exactly 2 image slots (side-by-side)
    final imageWidgets = <pw.Widget>[];

    // Take up to 2 images
    final imagesToShow = imageUrls.take(2).toList();

    for (int i = 0; i < 2; i++) {
      if (i < imagesToShow.length) {
        // Show actual image
        final url = imagesToShow[i];
        final imageBytes = _imageCache[url];

        if (imageBytes != null && imageBytes.isNotEmpty) {
          imageWidgets.add(
            pw.Expanded(
              child: pw.Container(
                height: 80,
                margin: pw.EdgeInsets.only(
                  left: i == 0 ? 0 : 2,
                  right: i == 1 ? 0 : 2,
                ),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: dividerGrey, width: 0.5),
                  borderRadius: pw.BorderRadius.circular(6),
                  boxShadow: [
                    pw.BoxShadow(
                      color: PdfColor.fromHex('#00000010'),
                      blurRadius: 2,
                      offset: const PdfPoint(0, 1),
                    ),
                  ],
                ),
                child: pw.ClipRRect(
                  horizontalRadius: 6,
                  verticalRadius: 6,
                  child: pw.Image(
                    pw.MemoryImage(imageBytes),
                    fit: pw.BoxFit.cover,
                  ),
                ),
              ),
            ),
          );
        } else {
          // Image failed to load
          imageWidgets.add(
            pw.Expanded(
              child: pw.Container(
                height: 80,
                margin: pw.EdgeInsets.only(
                  left: i == 0 ? 0 : 2,
                  right: i == 1 ? 0 : 2,
                ),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: dividerGrey, width: 0.5),
                  borderRadius: pw.BorderRadius.circular(6),
                  color: surfaceGrey,
                ),
                alignment: pw.Alignment.center,
                child: pw.Icon(
                  pw.IconData(0xe3f4), // broken_image icon
                  size: 20,
                  color: textSecondary,
                ),
              ),
            ),
          );
        }
      } else {
        // Show blank space for missing image slot
        imageWidgets.add(
          pw.Expanded(
            child: pw.Container(
              height: 80,
              margin: pw.EdgeInsets.only(
                left: i == 0 ? 0 : 2,
                right: i == 1 ? 0 : 2,
              ),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: dividerGrey, width: 0.5, style: pw.BorderStyle.dashed),
                borderRadius: pw.BorderRadius.circular(6),
                color: surfaceGrey,
              ),
            ),
          ),
        );
      }
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Row(
        children: imageWidgets,
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: pw.BoxDecoration(
        color: surfaceGrey,
        border: pw.Border(top: pw.BorderSide(color: dividerGrey, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(
            children: [
              pw.Icon(
                pw.IconData(0xe192), // schedule icon
                size: 10,
                color: textSecondary,
              ),
              pw.SizedBox(width: 4),
              pw.Text(
                'Generated: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                style: pw.TextStyle(
                  fontSize: 8,
                  color: textSecondary,
                ),
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: pw.BoxDecoration(
              color: primaryPinkLight,
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: primaryPink,
              ),
            ),
          ),
        ],
      ),
    );
  }


  @override
  void dispose() {
    _imageCache.clear();
    super.dispose();
  }
}
