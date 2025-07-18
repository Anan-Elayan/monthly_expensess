import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../models/record.dart';

class BackupService {
  static Future<String?> exportBackup(Map<String, List<Record>> data) async {
    try {
      // Request storage permission first
      bool hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        print('Storage permission denied');
        return await _fallbackExport(data);
      }

      // Prepare backup data
      final backupData = {
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'data': {
          'incomes': data['incomes']!.map((r) => r.toJson()).toList(),
          'expenses': data['expenses']!.map((r) => r.toJson()).toList(),
        }
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);

      // Create backup file with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'finance_backup_$timestamp.json';

      // Get Downloads directory path using the reliable method
      String? savePath = await _getDownloadsFilePath(fileName);
      if (savePath == null) {
        print('Could not get Downloads path');
        return await _fallbackExport(data);
      }

      // Write file to Downloads folder
      final file = File(savePath);
      await file.writeAsString(jsonString);

      print('Backup saved to: $savePath');
      return savePath;
    } catch (e) {
      print('Export error: $e');
      return await _fallbackExport(data);
    }
  }

  // Reliable method to get Downloads folder path (similar to your example)
  static Future<String?> _getDownloadsFilePath(String fileName) async {
    try {
      String path = '';

      if (Platform.isAndroid) {
        // Try to get the actual Downloads directory
        List<String> possibleDownloadsPaths = [
          '/storage/emulated/0/Download',
          '/storage/emulated/0/Downloads',
        ];

        for (String downloadsPath in possibleDownloadsPaths) {
          final dir = Directory(downloadsPath);
          if (await dir.exists()) {
            // Test write permission
            try {
              final testFile = File('$downloadsPath/.test_write');
              await testFile.writeAsString('test');
              await testFile.delete();

              path = '$downloadsPath/$fileName';
              return path;
            } catch (e) {
              print('No write permission for $downloadsPath');
              continue;
            }
          }
        }

        // Fallback: Use external storage directory approach
        try {
          Directory? externalDir = await getExternalStorageDirectory();
          if (externalDir != null) {
            // Navigate to the Downloads folder from external storage
            String externalPath = externalDir.path;
            // Remove the app-specific part to get to root storage
            List<String> pathParts = externalPath.split('/');

            // Reconstruct path to Downloads
            String rootPath =
                '/${pathParts[1]}/${pathParts[2]}/${pathParts[3]}';
            String downloadsPath = '$rootPath/Download';

            final downloadsDir = Directory(downloadsPath);
            if (await downloadsDir.exists()) {
              try {
                final testFile = File('$downloadsPath/.test_write');
                await testFile.writeAsString('test');
                await testFile.delete();

                path = '$downloadsPath/$fileName';
                return path;
              } catch (e) {
                // Try Downloads with 's'
                downloadsPath = '$rootPath/Downloads';
                final downloadsDir2 = Directory(downloadsPath);
                if (await downloadsDir2.exists()) {
                  try {
                    final testFile = File('$downloadsPath/.test_write');
                    await testFile.writeAsString('test');
                    await testFile.delete();

                    path = '$downloadsPath/$fileName';
                    return path;
                  } catch (e) {
                    print('No write permission for Downloads folder');
                  }
                }
              }
            }
          }
        } catch (e) {
          print('External storage method failed: $e');
        }
      }

      return null;
    } catch (e) {
      print('Get Downloads path error: $e');
      return null;
    }
  }

  static Future<bool> _requestStoragePermission() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _getAndroidVersion();

        if (androidInfo >= 30) {
          // Android 11+ (API 30+) - Request MANAGE_EXTERNAL_STORAGE
          var status = await Permission.manageExternalStorage.status;
          if (!status.isGranted) {
            status = await Permission.manageExternalStorage.request();

            // If still not granted, try to open settings
            if (!status.isGranted) {
              print('Opening app settings for storage permission');
              await openAppSettings();
              // Wait a bit and check again
              await Future.delayed(const Duration(seconds: 1));
              status = await Permission.manageExternalStorage.status;
            }
          }
          return status.isGranted;
        } else {
          // Android 10 and below - Request WRITE_EXTERNAL_STORAGE
          var status = await Permission.storage.status;
          if (!status.isGranted) {
            status = await Permission.storage.request();
          }
          return status.isGranted;
        }
      }
      return true; // For iOS or other platforms
    } catch (e) {
      print('Permission request error: $e');
      return false;
    }
  }

  static Future<int> _getAndroidVersion() async {
    try {
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.version.sdkInt;
      }
      return 30; // Default to modern Android
    } catch (e) {
      print('Android version detection error: $e');
      return 30;
    }
  }

  static Future<String?> _fallbackExport(Map<String, List<Record>> data) async {
    try {
      print('Using fallback export method');

      // Fallback 1: Try app external files directory (more accessible)
      try {
        Directory? externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final fileName = 'finance_backup_$timestamp.json';
          final file = File('${externalDir.path}/$fileName');

          final backupData = {
            'version': '1.0',
            'exportDate': DateTime.now().toIso8601String(),
            'data': {
              'incomes': data['incomes']!.map((r) => r.toJson()).toList(),
              'expenses': data['expenses']!.map((r) => r.toJson()).toList(),
            }
          };

          final jsonString =
              const JsonEncoder.withIndent('  ').convert(backupData);
          await file.writeAsString(jsonString);
          print('Fallback: Saved to external storage: ${file.path}');
          return file.path;
        }
      } catch (e) {
        print('External storage fallback failed: $e');
      }

      // Fallback 2: App documents directory
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'finance_backup_$timestamp.json';
      final file = File('${directory.path}/$fileName');

      final backupData = {
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'data': {
          'incomes': data['incomes']!.map((r) => r.toJson()).toList(),
          'expenses': data['expenses']!.map((r) => r.toJson()).toList(),
        }
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);
      await file.writeAsString(jsonString);
      print('Fallback: Saved to documents: ${file.path}');
      return file.path;
    } catch (e) {
      print('All fallback methods failed: $e');

      // Final fallback: Use FilePicker
      try {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'finance_backup_$timestamp.json';

        String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'حفظ النسخة الاحتياطية',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['json'],
        );

        if (outputFile != null) {
          final backupData = {
            'version': '1.0',
            'exportDate': DateTime.now().toIso8601String(),
            'data': {
              'incomes': data['incomes']!.map((r) => r.toJson()).toList(),
              'expenses': data['expenses']!.map((r) => r.toJson()).toList(),
            }
          };

          final jsonString =
              const JsonEncoder.withIndent('  ').convert(backupData);
          final file = File(outputFile);
          await file.writeAsString(jsonString);
          print('FilePicker fallback: ${outputFile}');
          return outputFile;
        }
      } catch (pickerError) {
        print('FilePicker fallback error: $pickerError');
      }

      return null;
    }
  }

  // NEW: Import backup with target month option
  static Future<Map<String, List<Record>>?> importBackup(
      {String? targetMonth}) async {
    try {
      // Pick backup file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'اختر ملف النسخة الاحتياطية',
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        final jsonData = json.decode(jsonString);

        // Validate backup format
        if (jsonData['data'] == null) {
          throw Exception('Invalid backup format');
        }

        final data = jsonData['data'];

        // Convert records and update dates if targetMonth is provided
        List<Record> incomes = (data['incomes'] as List? ?? [])
            .map((e) => Record.fromJson(e))
            .toList();

        List<Record> expenses = (data['expenses'] as List? ?? [])
            .map((e) => Record.fromJson(e))
            .toList();

        // If targetMonth is specified, update all dates to that month
        if (targetMonth != null) {
          incomes = _updateRecordDates(incomes, targetMonth);
          expenses = _updateRecordDates(expenses, targetMonth);
        }

        return {
          'incomes': incomes,
          'expenses': expenses,
        };
      }
      return null;
    } catch (e) {
      print('Import error: $e');
      return null;
    }
  }

  // Helper method to update record dates to target month
  static List<Record> _updateRecordDates(
      List<Record> records, String targetMonth) {
    return records.map((record) {
      // Parse the original date
      DateTime originalDate = DateTime.parse(record.date);

      // Parse target month (format: YYYY-MM)
      List<String> monthParts = targetMonth.split('-');
      int targetYear = int.parse(monthParts[0]);
      int targetMonthNum = int.parse(monthParts[1]);

      // Create new date with target month/year but keep original day
      // If original day doesn't exist in target month, use last day of target month
      int targetDay = originalDate.day;
      int daysInTargetMonth = DateTime(targetYear, targetMonthNum + 1, 0).day;
      if (targetDay > daysInTargetMonth) {
        targetDay = daysInTargetMonth;
      }

      DateTime newDate = DateTime(targetYear, targetMonthNum, targetDay);

      // Create new record with updated date
      return Record(
        // id: record.id,

        desc: record.desc,
        amount: record.amount,
        date: newDate.toIso8601String().split('T')[0], // YYYY-MM-DD format
      );
    }).toList();
  }

  // Get backup preview without importing
  static Future<Map<String, dynamic>?> getBackupPreview() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'اختر ملف النسخة الاحتياطية للمعاينة',
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        final jsonData = json.decode(jsonString);

        if (jsonData['data'] == null) {
          throw Exception('Invalid backup format');
        }

        final data = jsonData['data'];
        final incomes = (data['incomes'] as List? ?? [])
            .map((e) => Record.fromJson(e))
            .toList();
        final expenses = (data['expenses'] as List? ?? [])
            .map((e) => Record.fromJson(e))
            .toList();

        // Get date range from backup
        Set<String> months = {};
        for (var record in [...incomes, ...expenses]) {
          months.add(record.date.substring(0, 7)); // YYYY-MM
        }

        return {
          'incomes': incomes,
          'expenses': expenses,
          'months': months.toList()..sort(),
          'exportDate': jsonData['exportDate'],
          'filePath': result.files.single.path,
        };
      }
      return null;
    } catch (e) {
      print('Preview error: $e');
      return null;
    }
  }

  static Future<String> getBackupInfo(Map<String, List<Record>> data) async {
    final totalIncomes = data['incomes']!.length;
    final totalExpenses = data['expenses']!.length;
    final totalRecords = totalIncomes + totalExpenses;

    final totalIncomeAmount =
        data['incomes']!.fold(0.0, (sum, record) => sum + record.amount);
    final totalExpenseAmount =
        data['expenses']!.fold(0.0, (sum, record) => sum + record.amount);

    return '''
إجمالي العمليات: $totalRecords
المقبوضات: $totalIncomes عملية (${totalIncomeAmount.toStringAsFixed(0)} ₪)
المصروفات: $totalExpenses عملية (${totalExpenseAmount.toStringAsFixed(0)} ₪)
    ''';
  }

  // Method to check if Downloads folder is accessible
  static Future<bool> isDownloadsFolderAccessible() async {
    try {
      String? path = await _getDownloadsFilePath('test.txt');
      return path != null;
    } catch (e) {
      return false;
    }
  }

  // Method to get Downloads folder path for display
  static Future<String> getDownloadsFolderPath() async {
    try {
      String? path = await _getDownloadsFilePath('test.txt');
      if (path != null) {
        return path.substring(0, path.lastIndexOf('/'));
      }
      return 'غير متاح';
    } catch (e) {
      return 'غير متاح';
    }
  }

  // Method to test Downloads folder access
  static Future<String> testDownloadsAccess() async {
    try {
      bool hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        return 'لا توجد صلاحيات للوصول للتخزين';
      }

      String? path = await _getDownloadsFilePath('test_file.txt');
      if (path != null) {
        // Try to write a test file
        final testFile = File(path);
        await testFile.writeAsString('test');
        await testFile.delete();
        return 'يمكن الوصول لمجلد التحميلات: ${path.substring(0, path.lastIndexOf('/'))}';
      } else {
        return 'لا يمكن الوصول لمجلد التحميلات';
      }
    } catch (e) {
      return 'خطأ في اختبار الوصول: $e';
    }
  }
}
