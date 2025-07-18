import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/backup_service.dart';
import '../models/record.dart';

class BackupSection extends StatefulWidget {
  final Map<String, List<Record>> data;
  final Function(Map<String, List<Record>>) onDataImported;
  final bool isTablet;
  final String selectedMonth; // Add selected month parameter

  const BackupSection({
    super.key,
    required this.data,
    required this.onDataImported,
    required this.isTablet,
    required this.selectedMonth, // Add this parameter
  });

  @override
  State<BackupSection> createState() => _BackupSectionState();
}

class _BackupSectionState extends State<BackupSection> {
  bool _isExporting = false;
  bool _isImporting = false;

  Future<void> _exportBackup() async {
    setState(() => _isExporting = true);
    try {
      final filePath = await BackupService.exportBackup(widget.data);
      if (filePath != null) {
        _showSuccessDialog(
          'تم التصدير بنجاح',
          'تم حفظ النسخة الاحتياطية في:\n$filePath',
          Icons.download_done,
          Colors.green,
          showCopyPath: true,
          filePath: filePath,
        );
      } else {
        _showErrorDialog('فشل في تصدير النسخة الاحتياطية');
      }
    } catch (e) {
      _showErrorDialog('حدث خطأ أثناء التصدير: $e');
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _importBackup() async {
    setState(() => _isImporting = true);
    try {
      // First, get backup preview
      final backupPreview = await BackupService.getBackupPreview();
      if (backupPreview != null) {
        setState(() => _isImporting = false);
        _showImportOptionsDialog(backupPreview);
      } else {
        setState(() => _isImporting = false);
        _showErrorDialog('فشل في قراءة ملف النسخة الاحتياطية');
      }
    } catch (e) {
      setState(() => _isImporting = false);
      _showErrorDialog('حدث خطأ أثناء الاستيراد: $e');
    }
  }

  void _showImportOptionsDialog(Map<String, dynamic> backupPreview) {
    final incomes = backupPreview['incomes'] as List<Record>;
    final expenses = backupPreview['expenses'] as List<Record>;
    final months = backupPreview['months'] as List<String>;
    final exportDate = backupPreview['exportDate'] as String;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue[600]),
            const SizedBox(width: 8),
            const Text('خيارات الاستيراد'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Backup info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'معلومات النسخة الاحتياطية:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('المقبوضات: ${incomes.length} عملية'),
                    Text('المصروفات: ${expenses.length} عملية'),
                    Text('تاريخ التصدير: ${_formatDate(exportDate)}'),
                    if (months.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('الأشهر المتوفرة: ${months.join(', ')}'),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Import options
              Text(
                'اختر طريقة الاستيراد:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),

              // Option 1: Keep original dates
              Card(
                child: ListTile(
                  leading:
                      Icon(Icons.calendar_today, color: Colors.orange[600]),
                  title: const Text('الاحتفاظ بالتواريخ الأصلية'),
                  subtitle:
                      const Text('سيتم استيراد البيانات بتواريخها الأصلية'),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmImport(null); // null means keep original dates
                  },
                ),
              ),

              // Option 2: Import to selected month
              Card(
                child: ListTile(
                  leading: Icon(Icons.event, color: Colors.green[600]),
                  title: Text('استيراد للشهر المحدد (${widget.selectedMonth})'),
                  subtitle: const Text(
                      'سيتم تحديث جميع التواريخ للشهر المحدد حالياً'),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmImport(widget.selectedMonth);
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  void _confirmImport(String? targetMonth) async {
    setState(() => _isImporting = true);

    try {
      final importedData =
          await BackupService.importBackup(targetMonth: targetMonth);
      if (importedData != null) {
        final backupInfo = await BackupService.getBackupInfo(importedData);
        _showImportConfirmationDialog(importedData, backupInfo, targetMonth);
      } else {
        _showErrorDialog('فشل في استيراد النسخة الاحتياطية');
      }
    } catch (e) {
      _showErrorDialog('حدث خطأ أثناء الاستيراد: $e');
    } finally {
      setState(() => _isImporting = false);
    }
  }

  void _showImportConfirmationDialog(Map<String, List<Record>> importedData,
      String backupInfo, String? targetMonth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange[600]),
            const SizedBox(width: 8),
            const Text('تأكيد الاستيراد'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'سيتم استبدال جميع البيانات الحالية بالبيانات المستوردة:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Text(backupInfo, style: const TextStyle(fontSize: 14)),
            ),
            if (targetMonth != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.green[600], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'سيتم تحديث جميع التواريخ إلى الشهر: $targetMonth',
                        style: TextStyle(
                          color: Colors.green[800],
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Text(
              'هل أنت متأكد من المتابعة؟',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _finalizeImport(importedData, targetMonth);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('تأكيد الاستيراد'),
          ),
        ],
      ),
    );
  }

  void _finalizeImport(
      Map<String, List<Record>> importedData, String? targetMonth) {
    widget.onDataImported(importedData);

    String message = 'تم الاستيراد بنجاح';
    if (targetMonth != null) {
      message += ' وتم تحديث التواريخ للشهر $targetMonth';
    }

    _showMessage(message, isError: false);
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return isoDate;
    }
  }

  void _showSuccessDialog(
    String title,
    String message,
    IconData icon,
    Color color, {
    bool showCopyPath = false,
    String? filePath,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (showCopyPath && filePath != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: filePath));
                        _showMessage('تم نسخ المسار', isError: false);
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('نسخ المسار'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
            ),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[600]),
            const SizedBox(width: 8),
            const Text('خطأ'),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 3),
        backgroundColor: isError ? Colors.red[600] : const Color(0xFF4F46E5),
        behavior: SnackBarBehavior.fixed,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.backup,
                    color: Color(0xFF7C3AED), size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'النسخ الاحتياطي',
                style: TextStyle(
                  fontSize: widget.isTablet ? 24 : 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'احتفظ بنسخة آمنة من بياناتك المالية',
            style: TextStyle(
              fontSize: widget.isTablet ? 16 : 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Export Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isExporting ? null : _exportBackup,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  vertical: widget.isTablet ? 20 : 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              icon: _isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.download),
              label: Text(
                _isExporting ? 'جاري التصدير...' : 'تصدير نسخة احتياطية',
                style: TextStyle(
                  fontSize: widget.isTablet ? 18 : 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Import Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isImporting ? null : _importBackup,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  vertical: widget.isTablet ? 20 : 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              icon: _isImporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.upload),
              label: Text(
                _isImporting ? 'جاري الاستيراد...' : 'استيراد نسخة احتياطية',
                style: TextStyle(
                  fontSize: widget.isTablet ? 18 : 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
