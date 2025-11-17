import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class HttpClient {
  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final url = Uri.parse(ApiConfig.buildUrl(endpoint));
      print('🌐 GET: $url');

      final response = await http
          .get(url, headers: ApiConfig.headers)
          .timeout(const Duration(seconds: 30));

      print('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ HTTP GET Error: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getList(String endpoint) async {
    try {
      final url = Uri.parse(ApiConfig.buildUrl(endpoint));
      print('🌐 GET List: $url');

      final response = await http
          .get(url, headers: ApiConfig.headers)
          .timeout(const Duration(seconds: 30));

      print('📥 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        print('🔍 Decoded type: ${decoded.runtimeType}');

        // Si la respuesta es un objeto con una propiedad 'data' que contiene el array
        if (decoded is Map && decoded.containsKey('data')) {
          print('✅ Found data property with ${decoded['data'].length} items');
          return decoded['data'] as List<dynamic>;
        }
        // Si la respuesta es directamente un array
        if (decoded is List) {
          print('✅ Direct array with ${decoded.length} items');
          return decoded;
        }
        print('⚠️ Unexpected response format');
        return [];
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ HTTP GET List Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> post(
      String endpoint, Map<String, dynamic> body) async {
    try {
      final url = Uri.parse(ApiConfig.buildUrl(endpoint));
      print('🌐 POST: $url');
      print('📤 Body: $body');

      final response = await http
          .post(
            url,
            headers: ApiConfig.headers,
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 30));

      print('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ HTTP POST Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> put(
      String endpoint, Map<String, dynamic> body) async {
    try {
      final url = Uri.parse(ApiConfig.buildUrl(endpoint));
      print('🌐 PUT: $url');

      final response = await http
          .put(
            url,
            headers: ApiConfig.headers,
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 30));

      print('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ HTTP PUT Error: $e');
      rethrow;
    }
  }

  Future<void> delete(String endpoint) async {
    try {
      final url = Uri.parse(ApiConfig.buildUrl(endpoint));
      print('🌐 DELETE: $url');

      final response = await http
          .delete(url, headers: ApiConfig.headers)
          .timeout(const Duration(seconds: 15));

      print('📥 Response status: ${response.statusCode}');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ HTTP DELETE Error: $e');
      rethrow;
    }
  }
}
