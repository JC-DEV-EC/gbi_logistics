import '../models/api_response.dart';

/// Resultado de procesamiento por lote
class BatchResult<T> {
  final List<String> processedItems;
  final Map<String, String> failedItems;
  final ApiResponse<T>? response;

  const BatchResult({
    required this.processedItems,
    required this.failedItems,
    this.response,
  });

  bool get hasErrors => failedItems.isNotEmpty;
  bool get hasSuccess => processedItems.isNotEmpty;
  String get successCount => '${processedItems.length}';
  String get errorCount => '${failedItems.length}';
}

/// Procesa una lista de items en lotes
class BatchProcessor {
  static const int defaultBatchSize = 0;  // 0 significa procesar todo en un solo lote

  /// Procesa una lista de items en lotes y maneja errores individualmente
  static Future<BatchResult<T>> process<T>({
    required List<String> items,
    required Future<ApiResponse<T>> Function(List<String> batch) processBatch,
    int batchSize = defaultBatchSize,
    bool stopOnError = false,
  }) async {
    final processedItems = <String>[];
    final failedItems = <String, String>{};
    ApiResponse<T>? lastResponse;

    // Si batchSize es 0 o mayor que el total de items, procesar todo junto
    if (batchSize <= 0 || batchSize >= items.length) {
      try {
        final response = await processBatch(items);
        lastResponse = response;

        if (response.isSuccessful) {
          processedItems.addAll(items);
        } else {
          // Si falla el lote completo
          for (final item in items) {
            failedItems[item] = response.messageDetail ?? response.message ?? 'Error desconocido';
          }
        }
      } catch (e) {
        // Error general del lote
        for (final item in items) {
          failedItems[item] = e.toString();
        }
      }
      return BatchResult(
        processedItems: processedItems,
        failedItems: failedItems,
        response: lastResponse,
      );
    }

    // Si se especifica un tamaño de lote, dividir y procesar en lotes
    for (var i = 0; i < items.length; i += batchSize) {
      final end = (i + batchSize < items.length) ? i + batchSize : items.length;
      final batch = items.sublist(i, end);

      try {
        final response = await processBatch(batch);
        lastResponse = response;

        if (response.isSuccessful) {
          processedItems.addAll(batch);
        } else {
          // Si falla el lote completo
          for (final item in batch) {
            failedItems[item] = response.messageDetail ?? response.message ?? 'Error desconocido';
          }
          if (stopOnError) break;
        }
      } catch (e) {
        // Error general del lote
        for (final item in batch) {
          failedItems[item] = e.toString();
        }
        if (stopOnError) break;
      }
    }

    return BatchResult(
      processedItems: processedItems,
      failedItems: failedItems,
      response: lastResponse,
    );
  }

  /// Procesa items individuales y agrupa resultados
  static Future<BatchResult<T>> processIndividually<T>({
    required List<String> items,
    required Future<ApiResponse<T>> Function(String item) processItem,
    bool stopOnError = false,
  }) async {
    final processedItems = <String>[];
    final failedItems = <String, String>{};
    ApiResponse<T>? lastResponse;

    for (final item in items) {
      try {
        final response = await processItem(item);
        lastResponse = response;

        if (response.isSuccessful) {
          processedItems.add(item);
        } else {
          failedItems[item] = response.messageDetail ?? response.message ?? 'Error desconocido';
          if (stopOnError) break;
        }
      } catch (e) {
        failedItems[item] = e.toString();
        if (stopOnError) break;
      }
    }

    return BatchResult(
      processedItems: processedItems,
      failedItems: failedItems,
      response: lastResponse,
    );
  }
}