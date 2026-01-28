import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'api_service.dart';

class ExportService {
  /// Export data and share as CSV file
  static Future<void> exportAndShare({
    required String endpoint,
    required String filename,
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      // Download CSV data from API
      final csvData = await ApiService.downloadCSV(endpoint, queryParams);

      // Get temporary directory
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');

      // Write CSV to file
      await file.writeAsString(csvData);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Export from SmartExit',
      );
    } catch (e) {
      throw Exception('Export failed: $e');
    }
  }

  /// Export sales report
  static Future<void> exportSalesReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    await exportAndShare(
      endpoint: '/admin/export/sales',
      filename: 'sales_report_${_formatDate(startDate)}_to_${_formatDate(endDate)}.csv',
      queryParams: {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      },
    );
  }

  /// Export product performance report
  static Future<void> exportProductReport({
    String metric = 'revenue',
    int limit = 50,
  }) async {
    await exportAndShare(
      endpoint: '/admin/export/products',
      filename: 'product_performance_${_formatDate(DateTime.now())}.csv',
      queryParams: {
        'metric': metric,
        'limit': limit.toString(),
      },
    );
  }

  /// Export customer analytics report
  static Future<void> exportCustomerReport() async {
    await exportAndShare(
      endpoint: '/admin/export/customers',
      filename: 'customer_analytics_${_formatDate(DateTime.now())}.csv',
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  }
}
