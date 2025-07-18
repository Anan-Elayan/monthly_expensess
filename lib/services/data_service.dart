import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/record.dart';

class DataService {
  static Future<File> get _localFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/finance_data.json');
  }

  static Future<Map<String, List<Record>>> loadData() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        final jsonStr = await file.readAsString();
        final jo = json.decode(jsonStr);
        return {
          'incomes': (jo['incomes'] as List? ?? [])
              .map((e) => Record.fromJson(e))
              .toList(),
          'expenses': (jo['expenses'] as List? ?? [])
              .map((e) => Record.fromJson(e))
              .toList(),
        };
      }
    } catch (e) {
      print('Load data error: $e');
    }
    return {
      'incomes': <Record>[],
      'expenses': <Record>[],
    };
  }

  static Future<bool> saveData(Map<String, List<Record>> data) async {
    try {
      final file = await _localFile;
      final jo = {
        'incomes': data['incomes']!.map((r) => r.toJson()).toList(),
        'expenses': data['expenses']!.map((r) => r.toJson()).toList(),
        'lastModified': DateTime.now().toIso8601String(),
      };
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(jo),
        flush: true,
      );
      return true;
    } catch (e) {
      print('Save data error: $e');
      return false;
    }
  }

  static Future<bool> clearAllData() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        await file.delete();
      }
      return true;
    } catch (e) {
      print('Clear data error: $e');
      return false;
    }
  }
}
