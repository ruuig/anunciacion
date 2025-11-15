import 'http_client.dart';

class HttpPaymentClient {
  final HttpClient _httpClient;

  HttpPaymentClient(this._httpClient);

  // Crear un nuevo pago
  Future<Map<String, dynamic>> createPayment({
    required int estudianteId,
    required double monto,
    required String mes,
    String? fechaPago,
    String? metodoPago,
    String? referencia,
    String? comprobanteUrl,
    String? notas,
  }) async {
    return await _httpClient.post('/api/pagos', {
      'estudiante_id': estudianteId,
      'monto': monto,
      'mes': mes,
      if (fechaPago != null) 'fecha_pago': fechaPago,
      if (metodoPago != null) 'metodo_pago': metodoPago,
      if (referencia != null) 'referencia': referencia,
      if (comprobanteUrl != null) 'comprobante_url': comprobanteUrl,
      if (notas != null) 'notas': notas,
    });
  }

  // Obtener todos los pagos con filtros opcionales
  Future<List<dynamic>> getPayments({
    int? estudianteId,
    int? gradoId,
    String? mes,
    String? estado,
  }) async {
    String endpoint = '/api/pagos?';
    final params = <String>[];
    
    if (estudianteId != null) params.add('estudiante_id=$estudianteId');
    if (gradoId != null) params.add('grado_id=$gradoId');
    if (mes != null) params.add('mes=$mes');
    if (estado != null) params.add('estado=$estado');
    
    endpoint += params.join('&');
    
    return await _httpClient.getList(endpoint);
  }

  // Obtener un pago por ID
  Future<Map<String, dynamic>> getPaymentById(int id) async {
    return await _httpClient.get('/api/pagos/$id');
  }

  // Actualizar un pago
  Future<Map<String, dynamic>> updatePayment({
    required int id,
    double? monto,
    String? mes,
    String? fechaPago,
    String? metodoPago,
    String? referencia,
    String? comprobanteUrl,
    String? notas,
  }) async {
    return await _httpClient.put('/api/pagos/$id', {
      if (monto != null) 'monto': monto,
      if (mes != null) 'mes': mes,
      if (fechaPago != null) 'fecha_pago': fechaPago,
      if (metodoPago != null) 'metodo_pago': metodoPago,
      if (referencia != null) 'referencia': referencia,
      if (comprobanteUrl != null) 'comprobante_url': comprobanteUrl,
      if (notas != null) 'notas': notas,
    });
  }

  // Eliminar un pago (soft delete)
  Future<void> deletePayment(int id) async {
    await _httpClient.delete('/api/pagos/$id');
  }

  // Obtener estadísticas de pagos
  Future<Map<String, dynamic>> getPaymentStats({int? gradoId}) async {
    String endpoint = '/api/pagos/stats';
    if (gradoId != null) {
      endpoint += '?grado_id=$gradoId';
    }
    return await _httpClient.get(endpoint);
  }

  // Obtener historial de pagos de un estudiante
  Future<List<dynamic>> getStudentPaymentHistory(int estudianteId) async {
    return await _httpClient.getList('/api/pagos/student/$estudianteId');
  }
}
