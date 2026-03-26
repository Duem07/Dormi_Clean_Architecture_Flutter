import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:gestion_dormitorios/core/config/api_config.dart';
import 'package:gestion_dormitorios/Administrador/Monitor/models/tipo_culto_model.dart';

class CultoService {
   
  Future<List<TipoCulto>> getTiposCulto() async {
    final url = Uri.parse("${ApiConfig.baseUrl}/cultos/tipos");

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          final List<dynamic> data = jsonResponse['data'];
          return data.map((json) => TipoCulto.fromJson(json)).toList();
        } else {
          throw Exception(jsonResponse['message'] ?? 'Error al obtener tipos de culto');
        }
      } else {
        throw Exception('Error del servidor (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error de red al obtener tipos de culto: $e');
    }
  }
}