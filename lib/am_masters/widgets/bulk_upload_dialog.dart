import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:file_picker/file_picker.dart';
// dart:html replaced with cross-platform stub

import '../services/bulk_upload_service.dart';
import '../services/operational_log_service.dart';

// Brand & Premium Colors
const _kP = Color(0xFF3D6EBE);
const _kPL = Color(0xFFEFF6FF);
const _kBorder = Color(0xFFE2E8F0);
const _kText = Color(0xFF0F172A);
const _kMuted = Color(0xFF475569);
const _kBg = Color(0xFFF8FAFC);
const _kR = Color(0xFFC83737);
const _kRL = Color(0xFFFEF2F2);
const _kG = Color(0xFF059669);
const _kGL = Color(0xFFD1FAE5);

class BulkUploadDialog extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback? onCancel;
  final String title;
  final String entityName;
  final String validateEndpoint;
  final String uploadEndpoint;
  final String templateAssetPath;
  final String templateFileName;
  final String templateSheetName;
  final String? programName;
  final String? orgCode;

  const BulkUploadDialog({
    super.key, 
    required this.onComplete, 
    this.onCancel,
    required this.validateEndpoint,
    required this.uploadEndpoint,
    this.title = 'Bulk Upload', 
    this.entityName = 'Records',
    this.templateAssetPath = 'assets/Template.xlsx',
    this.templateFileName = 'Template.xlsx',
    this.templateSheetName = 'Bulk Upload',
    this.programName,
    this.orgCode,
  });

  static void show(
    BuildContext context, {
    required VoidCallback onComplete, 
    VoidCallback? onCancel,
    required String validateEndpoint,
    required String uploadEndpoint,
    String title = 'Bulk Upload', 
    String entityName = 'Records',
    String templateAssetPath = 'assets/Template.xlsx',
    String templateFileName = 'Template.xlsx',
    String templateSheetName = 'Bulk Upload',
    String? programName,
    String? orgCode,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: BulkUploadDialog(
          onComplete: () {
            onComplete();
            Navigator.of(context).pop();
          }, 
          onCancel: () {
            if (onCancel != null) onCancel();
            Navigator.of(context).pop();
          },
          title: title, 
          entityName: entityName,
          validateEndpoint: validateEndpoint,
          uploadEndpoint: uploadEndpoint,
          templateAssetPath: templateAssetPath,
          templateFileName: templateFileName,
          templateSheetName: templateSheetName,
        ),
      ),
    );
  }

  @override
  State<BulkUploadDialog> createState() => _BulkUploadDialogState();
}

class _BulkUploadDialogState extends State<BulkUploadDialog> with SingleTickerProviderStateMixin {
  int _currentPage = 0; // 0: Upload & Template, 1: Loader & Results
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
      lowerBound: 0.4,
      upperBound: 1.0,
    )..repeat(reverse: true);
  }

  bool _isDownloading = false;
  bool _isProcessing = false;
  bool _isValidated = false;
  PlatformFile? _selectedFile;
  String _statusText = 'Awaiting spreadsheet file';
  String? _errorMessage;
  double _progressValue = 0.0;
  Timer? _smoothTimer;
  bool _isCommitting = false;

  // Statistics
  int? _batchId;
  int _successCount = 0;
  int _failedCount = 0;
  bool _isFinished = false;
  String? _fileChecksum;

  String _calculateChecksum(List<int> bytes) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(10, (index) => chars[random.nextInt(chars.length)]).join();
  }

  @override
  void dispose() {
    _smoothTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String _parseErrorMessage(String error) {
    String msg = error;
    try {
      if (error.contains('{') && error.contains('}')) {
        final jsonStr = error.substring(error.indexOf('{'), error.lastIndexOf('}') + 1);
        final data = json.decode(jsonStr);
        if (data['message'] != null) {
          msg = data['message'].toString();
        }
      }
    } catch (_) {}
    
    msg = msg.replaceAll('Exception: ', '');
    msg = msg.replaceAll(RegExp(r'\s*\(expected at least \d+ columns\)\.?'), '');
    msg = msg.trim();
    if (msg.contains('Invalid file template')) {
      if (!msg.endsWith('.')) msg += '.';
      msg += ' Please upload a file that matches the template.';
    }
    return msg;
  }

  void _goBack() {
    setState(() {
      _currentPage = 0;
      _selectedFile = null;
      _fileChecksum = null;
      _isFinished = false;
      _isProcessing = false;
      _isValidated = false;
      _progressValue = 0.0;
      _errorMessage = null;
      _isCommitting = false;
      _statusText = 'Awaiting spreadsheet file';
    });
  }

  Future<void> _downloadTemplate() async {
    setState(() => _isDownloading = true);
    try {
      final bytes = await rootBundle.load(widget.templateAssetPath);
      final list = bytes.buffer.asUint8List();
      
      if (kIsWeb) {
        // File download not supported on this platform
            // TODO: Implement platform-specific file download
        
        final progId = widget.entityName.toUpperCase().contains('USER') ? 'USER UPLOAD' : 'PRODUCT UPLOAD';
        OperationalLogService().logAction(programId: progId, action: 'Z');
      }
    } catch (e) {
      debugPrint('Failed to download template: $e');
    } finally {
      setState(() => _isDownloading = false);
    }
  }

  Future<void> _pickExcelFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.first;
          _fileChecksum = null;
          _isFinished = false;
          _isValidated = false;
          _successCount = 0;
          _failedCount = 0;
          _progressValue = 0.0;
          _isCommitting = false;
          _statusText = 'Spreadsheet ready to upload';
        });
      }
    } catch (e) {
      debugPrint('Failed to pick file: $e');
    }
  }

  void _startSmoothProgress(double start, double end, Duration duration) {
    _smoothTimer?.cancel();
    final steps = 50;
    final increment = (end - start) / steps;
    final stepDuration = duration.inMilliseconds ~/ steps;
    int currentStep = 0;

    _smoothTimer = Timer.periodic(Duration(milliseconds: stepDuration), (timer) {
      if (currentStep >= steps) {
        timer.cancel();
      } else {
        currentStep++;
        if (mounted) {
          setState(() {
            _progressValue = start + (increment * currentStep);
          });
        }
      }
    });
  }

  Future<void> _validateRecords() async {
    if (_selectedFile == null || _selectedFile!.bytes == null) {
      return;
    }

    setState(() {
      _currentPage = 1;
      _isProcessing = true;
      _isFinished = false;
      _isValidated = false;
      _successCount = 0;
      _failedCount = 0;
      _progressValue = 0.10;
      _errorMessage = null;
      _isCommitting = false;
      _statusText = 'Extracting and Validating...';
    });

    try {
      _startSmoothProgress(0.10, 0.95, const Duration(seconds: 30));
      
      if (_fileChecksum == null && _selectedFile?.bytes != null) {
        _fileChecksum = _calculateChecksum(_selectedFile!.bytes!);
      }

      final result = await BulkUploadService().uploadExcelFile(
        widget.validateEndpoint, 
        _selectedFile!.bytes!,
        _selectedFile!.name,
        checksum: _fileChecksum,
      );
      final progId = widget.entityName.toUpperCase().contains('USER') ? 'USER UPLOAD' : 'PRODUCT UPLOAD';
      OperationalLogService().logAction(programId: progId, action: 'I');
      
      _smoothTimer?.cancel();

      _batchId = result['batchId'] as int?;
      _successCount = result['successCount'] as int? ?? 0;
      _failedCount = result['failedCount'] as int? ?? 0;

      // Animate smoothly to 100% to finish off the loader
      _startSmoothProgress(_progressValue, 1.0, const Duration(milliseconds: 300));
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Wait 3 seconds after reaching 100% before moving to the next screen
      await Future.delayed(const Duration(seconds: 3));

      setState(() {
        _progressValue = 0.50; 
        _isProcessing = false;
        
        _isValidated = true;
        _statusText = 'Validation complete. Ready to import.';
      });
    } catch (e) {
      _smoothTimer?.cancel();
      setState(() {
        _isProcessing = false;
        _isValidated = false;
        _progressValue = 0.0;
        _statusText = 'Validation Failed';
        _errorMessage = _parseErrorMessage(e.toString());
      });
    }
  }

  void _confirmProceed() {
    if (_failedCount > 0) {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 750,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.help_outline_rounded, color: _kP, size: 28),
                    const SizedBox(width: 12),
                    const Text('Confirm Batch Upload', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Shall I proceed with $_successCount success records and delete $_failedCount failed records?',
                  style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.5),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _kRL,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _kR.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: _kR, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '$_failedCount failed record(s) will be permanently removed. Remember to download the failure report before proceeding.',
                          style: const TextStyle(color: _kR, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _proceedToUpload();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kP,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Yes, Proceed'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      _proceedToUpload();
    }
  }

  Future<void> _proceedToUpload() async {
    if (_batchId == null) return;

    setState(() {
      _isProcessing = true;
      _isValidated = false;
      _errorMessage = null;
      _isCommitting = true;
      _statusText = 'Syncing and Mapping users...';
    });

    try {
      _startSmoothProgress(0.50, 0.95, const Duration(seconds: 15));

      if (_fileChecksum == null && _selectedFile?.bytes != null) {
        _fileChecksum = _calculateChecksum(_selectedFile!.bytes!);
      }

      final result = await BulkUploadService().processBatch(
        widget.uploadEndpoint, 
        _batchId!,
        checksum: _fileChecksum,
      );
      final progId = widget.entityName.toUpperCase().contains('USER') ? 'USER UPLOAD' : 'PRODUCT UPLOAD';
      OperationalLogService().logAction(programId: progId, action: 'I');
      
      _smoothTimer?.cancel();

      setState(() {
        _successCount = result['successCount'] as int? ?? _successCount;
        _failedCount = result['failedCount'] as int? ?? _failedCount;
      });
      
      // Animate smoothly to 100% to finish off the loader
      _startSmoothProgress(_progressValue, 1.0, const Duration(milliseconds: 300));
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Wait 3 seconds after reaching 100% before moving to the next screen
      await Future.delayed(const Duration(seconds: 3));

      setState(() {
        _statusText = 'Imported Successfully';
        _isFinished = true;
      });
    } catch (e) {
      _smoothTimer?.cancel();
      setState(() {
        _isFinished = true;
        _progressValue = 0.0;
        _statusText = 'Import Failed';
        _errorMessage = _parseErrorMessage(e.toString());
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _downloadReport(String type) async {
    if (_batchId == null) return;
    try {
      final bytes = await BulkUploadService().downloadReport(widget.uploadEndpoint, _batchId!, type);
      
      final pName = (widget.programName != null && widget.programName!.isNotEmpty) ? widget.programName! : 'Report';
      OperationalLogService().logAction(
        programId: pName,
        action: 'Z',
      );

      if (kIsWeb) {
        // File download not supported on this platform
            // TODO: Implement platform-specific file download
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to download report: $e'), backgroundColor: _kR));
    }
  }

  Widget _buildAnimatedPhases() {
    final double val = _progressValue;
    int currentStep = 0;
    if (_isFinished) {
      currentStep = 4;
    } else if (val >= 0.85) {
      currentStep = 3; 
    } else if (val > 0.40) {
      currentStep = 2; 
    } else if (_isValidated && !_isProcessing) {
      currentStep = 2; 
    } else if (val >= 0.10) {
      currentStep = 1; 
    } else {
      currentStep = 0; 
    }

    final steps = [
      {'label': 'Extracting', 'icon': Icons.unarchive_rounded},
      {'label': 'Validating', 'icon': Icons.rule_rounded},
      {'label': 'Syncing', 'icon': Icons.cloud_sync_rounded},
      {'label': 'Mapping', 'icon': Icons.swap_horiz_rounded},
      {'label': 'Complete', 'icon': Icons.check_circle_rounded},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(steps.length, (index) {
          final isCompleted = index < currentStep;
          final isActive = index == currentStep;

          Color color;
          Color bg;
          BorderSide border;

          if (isCompleted) {
            color = _kG;
            bg = _kGL;
            border = BorderSide(color: _kG.withOpacity(0.3), width: 1);
          } else if (isActive) {
            color = _kP;
            bg = _kPL;
            border = const BorderSide(color: _kP, width: 1.5);
          } else {
            color = const Color(0xFF94A3B8);
            bg = Colors.transparent;
            border = const BorderSide(color: Colors.transparent);
          }

          Widget stepContent = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.fromBorderSide(border),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCompleted ? Icons.check_circle_rounded : steps[index]['icon'] as IconData,
                      size: 14,
                      color: color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      steps[index]['label'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
                        color: isActive ? color : color.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              if (index < steps.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFFCBD5E1)),
                ),
            ],
          );

          if (isActive && !_isFinished) {
            return FadeTransition(opacity: _pulseController, child: stepContent);
          }
          return stepContent;
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kBg,
      width: double.infinity,
      height: double.infinity,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _kPL,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.cloud_upload_outlined, color: _kP, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentPage == 0 ? widget.title : 'Importing ${widget.entityName}...',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: _kText,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _currentPage == 0
                            ? 'Upload a spreadsheet to import multiple ${widget.entityName.toLowerCase()} at once.'
                            : 'Please wait while records are validated and imported.',
                        style: const TextStyle(fontSize: 12, color: _kMuted, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                if (_currentPage == 1 && !_isProcessing)
                  ElevatedButton.icon(
                    onPressed: _goBack,
                    icon: const Icon(Icons.arrow_back_rounded, size: 16),
                    label: const Text('Back'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kP,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  )
                else if (_currentPage == 0)
                  ElevatedButton.icon(
                    onPressed: () {
                      if (widget.onCancel != null) {
                        widget.onCancel!();
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                    icon: const Icon(Icons.arrow_back_rounded, size: 16),
                    label: const Text('Back'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kP,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: _kBorder),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      switchInCurve: Curves.easeOutQuart,
                      switchOutCurve: Curves.easeInQuart,
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.0, 0.05),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: _currentPage == 0 
                          ? KeyedSubtree(key: const ValueKey('page1'), child: _buildPage1()) 
                          : KeyedSubtree(key: const ValueKey('page2'), child: _buildPage2()),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kBorder, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(color: _kPL, shape: BoxShape.circle),
                child: const Icon(Icons.table_view_rounded, color: _kP, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Download Sample Format', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _kText)),
                    const SizedBox(height: 2),
                    Text('Get the template format file to set up ${widget.entityName.toLowerCase()} data.', style: const TextStyle(fontSize: 13, color: _kMuted)),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: (_isDownloading || _isProcessing) ? null : _downloadTemplate,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kP,
                  side: const BorderSide(color: _kP, width: 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: _isDownloading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _kP))
                    : const Icon(Icons.download_rounded, size: 18),
                label: Text(_isDownloading ? 'Downloading' : 'Download', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 48),

        const Text('Upload Excel Document', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _kText)),
        const SizedBox(height: 24),

        MouseRegion(
          cursor: _isProcessing ? SystemMouseCursors.basic : SystemMouseCursors.click,
          child: GestureDetector(
            onTap: _isProcessing ? null : _pickExcelFile,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              decoration: BoxDecoration(
                color: _selectedFile != null ? _kBg : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedFile != null ? _kP : const Color(0xFFCBD5E1),
                  width: _selectedFile != null ? 2 : 1.5,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _selectedFile != null ? Icons.file_present_rounded : Icons.cloud_upload_outlined,
                    color: _selectedFile != null ? _kP : _kMuted,
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _selectedFile != null ? _selectedFile!.name : 'Select or drop an Excel file here',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _selectedFile != null ? _kText : const Color(0xFF334155)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedFile != null
                        ? '${(_selectedFile!.size / 1024).toStringAsFixed(1)} KB'
                        : 'Supported formats: .xlsx, .xls (Max size: 15MB)',
                    style: const TextStyle(fontSize: 13, color: _kMuted, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedFile != null && !_isProcessing ? _validateRecords : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kP,
                  disabledBackgroundColor: _kP.withOpacity(0.5),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white.withOpacity(0.8),
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                child: const Text('Validate Records'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMeaningfulAnimation(Color statusColor, IconData statusIcon) {
    return Container(
      height: 380,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: SizedBox(
              width: 240, height: 240,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                   double val = (_pulseController.value - 0.4) / 0.6;
                   
                   return Stack(
                     alignment: Alignment.center,
                     children: [
                       Container(
                         width: 140, height: 140,
                         decoration: BoxDecoration(
                           color: statusColor,
                           shape: BoxShape.circle,
                           boxShadow: [
                             BoxShadow(
                               color: statusColor.withOpacity(0.3),
                               blurRadius: 30 + (10 * val),
                               spreadRadius: 10 + (5 * val),
                             )
                           ]
                         ),
                         child: Icon(statusIcon == Icons.cloud_done_rounded ? Icons.group_add_rounded : statusIcon, size: 60, color: Colors.white),
                       ),
                       Transform.translate(
                         offset: Offset(-60 + (6 * val), -65 + (6 * val)),
                         child: _buildOrbiter(icon: Icons.person_rounded, color: statusColor, bgColor: Colors.white),
                       ),
                       Transform.translate(
                         offset: Offset(65 - (6 * val), -45 - (6 * val)),
                         child: _buildOrbiter(
                           icon: statusIcon == Icons.cloud_done_rounded ? Icons.check_rounded : Icons.close_rounded, 
                           color: Colors.white, 
                           bgColor: statusColor == _kP ? const Color(0xFF10B981) : _kR, 
                           size: 45
                         ),
                       ),
                       Transform.translate(
                         offset: Offset(60 + (6 * val), 65 + (6 * val)),
                         child: _buildOrbiter(icon: Icons.person_add_rounded, color: statusColor, bgColor: Colors.white),
                       ),
                       Transform.translate(
                         offset: Offset(-65 - (6 * val), 55 - (6 * val)),
                         child: _buildOrbiter(icon: Icons.cloud_done_rounded, color: statusColor, bgColor: Colors.white),
                       ),
                     ]
                   );
                }
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isFinished ? 'IMPORTED SUCCESSFULLY' : 'VALIDATION COMPLETE',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: statusColor,
              letterSpacing: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildOrbiter({required IconData icon, required Color color, required Color bgColor, double size = 45}) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, spreadRadius: 2)
        ]
      ),
      child: Icon(icon, color: color, size: size * 0.55),
    );
  }

  Widget _buildPage2() {
    if (_isProcessing) {
      int totalItems = 4;
      int processingCount = (_progressValue * totalItems).toInt();
      if (processingCount > totalItems) processingCount = totalItems;
      if (processingCount < 0) processingCount = 0;
      
      final List<Map<String, dynamic>> genericItems = _isCommitting 
      ? [
          {'icon': Icons.storage_rounded, 'color': const Color(0xFFEAB308), 'name': 'Preparing DB'},
          {'icon': Icons.sync_rounded, 'color': _kP, 'name': 'Syncing Records'},
          {'icon': Icons.people_alt_rounded, 'color': Colors.purple, 'name': 'Mapping Users'},
          {'icon': Icons.save_rounded, 'color': _kG, 'name': 'Committing Data'},
        ]
      : [
          {'icon': Icons.file_present_rounded, 'color': _kP, 'name': 'Extracting File'},
          {'icon': Icons.schema_rounded, 'color': const Color(0xFFEAB308), 'name': 'Parsing Content'},
          {'icon': Icons.rule_rounded, 'color': _kR, 'name': 'Validating Rules'},
          {'icon': Icons.fact_check_rounded, 'color': _kG, 'name': 'Finalizing Checks'},
        ];
      
      return Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left Panel: Select Multiple Files style
            Expanded(
              flex: 3,
              child: Container(
                height: 380,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kBorder),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text('PROCESSING QUEUE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: _kMuted)),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: totalItems,
                        itemBuilder: (context, index) {
                          bool isDone = index < processingCount;
                          bool isCurrent = index == processingCount;
                          var item = genericItems[index];
                          
                          double fillValue = isDone ? 1.0 : (isCurrent ? (_progressValue * totalItems) % 1.0 : 0.0);
                          
                          Widget gridItem = Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isCurrent ? _kP : _kBorder, width: isCurrent ? 2 : 1),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ShaderMask(
                                  blendMode: BlendMode.srcATop,
                                  shaderCallback: (bounds) => LinearGradient(
                                    stops: [fillValue, fillValue],
                                    colors: [item['color'], _kBorder],
                                  ).createShader(bounds),
                                  child: Icon(item['icon'], size: 36, color: Colors.white),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  item['name'],
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isDone ? _kMuted : _kText),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                ),
                                const SizedBox(height: 4),
                                Icon(
                                  isDone ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded, 
                                  color: isDone ? _kP : _kBorder, 
                                  size: 14
                                ),
                              ],
                            ),
                          );
                          
                          if (isCurrent) {
                            return AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: 0.5 + (_pulseController.value * 0.5),
                                  child: child,
                                );
                              },
                              child: gridItem,
                            );
                          }
                          return gridItem;
                        }
                      )
                    )
                  ]
                )
              )
            ),
            
            const SizedBox(width: 32),
            
            // Center Panel
            Expanded(
              flex: 4,
              child: Container(
                height: 380,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _kBorder, width: 2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isCommitting ? 'COMMITTING' : 'VALIDATING', 
                      style: const TextStyle(
                        fontSize: 22, 
                        fontWeight: FontWeight.w900, 
                        letterSpacing: 2.0,
                        color: _kP,
                      )
                    ),
                    const SizedBox(height: 20),
                    BulkUploadFlowAnimation(isCommitting: _isCommitting),
                    const SizedBox(height: 20),
                    
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: _progressValue,
                        minHeight: 12,
                        backgroundColor: _kBorder,
                        valueColor: const AlwaysStoppedAnimation<Color>(_kP),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('${(_progressValue * 100).toInt()}%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: _kP)),
                  ],
                ),
              ),
            ),
            
            const SizedBox(width: 32),
            
            // Right Panel
            Expanded(
              flex: 3,
              child: Container(
                height: 380,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kBorder),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]
                ),
                child: Column(
                  children: [
                    const Center(
                      child: Text('UPLOAD PROGRESS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: _kMuted)),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(totalItems, (index) {
                          var item = genericItems[index];
                          bool isFullyDone = index < processingCount;
                          bool isCurrent = index == processingCount;
                          double rowFill = isFullyDone ? 1.0 : (isCurrent ? (_progressValue * totalItems) % 1.0 : 0.0);
                          
                          return Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: item['color'].withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(item['icon'], color: item['color'], size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 10),
                                    LinearProgressIndicator(
                                      value: rowFill, 
                                      minHeight: 4, 
                                      backgroundColor: _kBorder, 
                                      valueColor: AlwaysStoppedAnimation<Color>(isFullyDone ? _kG : _kP)
                                    )
                                  ]
                                )
                              ),
                            ]
                          );
                        })
                      )
                    )
                  ]
                )
              )
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null && !_isValidated && !_isFinished) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kBorder),
            ),
            child: Column(
              children: [
                const Icon(Icons.error_rounded, color: _kR, size: 40),
                const SizedBox(height: 12),
                Text(
                  _statusText,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _kR),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                _buildAnimatedPhases(),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _kRL,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kR.withOpacity(0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline_rounded, color: _kR, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_errorMessage!, style: const TextStyle(color: _kR, fontSize: 13, height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 64),
          ElevatedButton(
            onPressed: _goBack,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kP, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ],
      );
    }

    Color statusColor = _kP;
    IconData statusIcon = Icons.cloud_done_rounded;

    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: _buildMeaningfulAnimation(statusColor, statusIcon),
          ),
          const SizedBox(width: 48),
          Expanded(
            flex: 6,
            child: SizedBox(
              height: 380,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: (_successCount > 0 && _failedCount > 0)
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  if (_successCount > 0 && _failedCount > 0)
                    const SizedBox(height: 12),
                  // 1. Success Card
                  if (_successCount > 0) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: _kGL.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _kG.withOpacity(0.3), width: 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: _kG, size: 28),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'Success : ',
                                      style: TextStyle(
                                        color: _kG,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    TweenAnimationBuilder<int>(
                                      tween: IntTween(begin: 0, end: _successCount),
                                      duration: const Duration(milliseconds: 1500),
                                      curve: Curves.easeOutCubic,
                                      builder: (context, value, child) => Text(
                                        '$value',
                                        style: const TextStyle(
                                          color: _kG,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _isFinished 
                                      ? (widget.entityName.toLowerCase() == 'users'
                                          ? 'Users Imported Successfully'
                                          : 'User product mapping imported successfully')
                                      : 'Total valid records ready to import.',
                                  style: const TextStyle(
                                    color: Color(0xFF475569),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _downloadReport('success'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kG,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(230, 50),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.download_rounded, size: 18),
                            label: const Text(
                              'Download Success Report',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 2. Failure Card
                  if (_failedCount > 0) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: _kRL,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _kR.withOpacity(0.3), width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.cancel_rounded, color: _kR, size: 28),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Failure : ',
                                      style: TextStyle(
                                        color: _kR,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    TweenAnimationBuilder<int>(
                                      tween: IntTween(begin: 0, end: _failedCount),
                                      duration: const Duration(milliseconds: 1500),
                                      curve: Curves.easeOutCubic,
                                      builder: (context, value, child) => Text(
                                        '$value',
                                        style: TextStyle(
                                          color: _kR,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _isFinished
                                      ? (widget.entityName.toLowerCase() == 'users'
                                          ? 'User Failed to Import'
                                          : 'User product mapping failed to import')
                                      : 'Total invalid records found.',
                                  style: const TextStyle(
                                    color: Color(0xFF475569),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _downloadReport('failure'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kR,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(230, 50),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.download_rounded, size: 18),
                            label: const Text(
                              'Download Failure Report',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 3. Warning Card (Message)
                  if (_failedCount > 0 && _successCount > 0) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: _kPL,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _kP.withOpacity(0.3), width: 1),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(Icons.warning_rounded, color: _kP, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TweenAnimationBuilder<int>(
                                  tween: IntTween(begin: 0, end: _failedCount),
                                  duration: const Duration(milliseconds: 1500),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, value, child) => Text(
                                    '$value record(s) contain validation errors.',
                                    style: const TextStyle(
                                      color: _kP,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'If you want to proceed with successful users, download the failure report and click Proceed to Process.',
                                  style: TextStyle(
                                    color: Color(0xFF475569),
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else if (_failedCount > 0 && _successCount == 0) ...[
                    // If all failed, show a red error warning card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: _kRL,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _kR.withOpacity(0.3), width: 1),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Icon(Icons.error_outline_rounded, color: _kR, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TweenAnimationBuilder<int>(
                                  tween: IntTween(begin: 0, end: _failedCount),
                                  duration: const Duration(milliseconds: 1500),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, value, child) => Text(
                                    '$value record(s) failed validation.',
                                    style: TextStyle(
                                      color: _kR,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'All records failed validation. Please download the failure report, correct the issues, and upload again.',
                                  style: TextStyle(
                                    color: Color(0xFF475569),
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  const SizedBox(height: 16),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isFinished) ...[
                        ElevatedButton(
                          onPressed: widget.onComplete,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kP, foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ] else ...[
                        ElevatedButton.icon(
                          onPressed: _goBack,
                          icon: const Icon(Icons.arrow_back_rounded, size: 16),
                          label: const Text('Back', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: _kP,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            side: const BorderSide(color: _kP),
                          ),
                        ),
                        if (_successCount > 0) ...[
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: _confirmProceed,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kP, foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Proceed to Process', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                        ],
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BulkUploadFlowAnimation extends StatelessWidget {
  final bool isCommitting;
  const BulkUploadFlowAnimation({super.key, required this.isCommitting});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 240,
      height: 150,
      child: Center(
        child: Icon(
          Icons.cloud_upload_rounded,
          size: 120.0,
          color: _kP,
        ),
      ),
    );
  }
}
