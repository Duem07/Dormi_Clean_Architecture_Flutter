import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:gestion_dormitorios/core/config/api_config.dart';
import 'package:gestion_dormitorios/Administrador/Monitor/models/asistencia_model.dart'; 

class AsistenciaService {
  
  final String _baseUrl = "${ApiConfig.baseUrl}/asistencia";

  Future<List<Asistencia>> getAsistenciasCulto({
    required int idTipoCulto,
    DateTime? fecha,
  }) async {
    String url = '$_baseUrl/culto?idTipoCulto=$idTipoCulto';
    if (fecha != null) {
      url += '&fecha=${fecha.toIso8601String().substring(0, 10)}';
    }

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        if (body['success'] == true) {
          final List<dynamic> data = body['data'];
          return data.map((json) => Asistencia.fromJson(json)).toList();
        } else {
          throw Exception(body['message'] ?? 'Error al obtener datos del servidor');
        }
      } else {
        throw Exception('Fallo la conexión con el servidor: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión o al procesar la respuesta: $e');
    }
  }
 
  Future<Map<String, dynamic>> registrarAsistencia({
    required String matriculaEstudiante,
    required int idTipoCulto,
    required String registradoPor,
  }) async {
    final url = Uri.parse('$_baseUrl/registrar');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'matriculaEstudiante': matriculaEstudiante,
          'idTipoCulto': idTipoCulto,
          'registradoPor': registradoPor,
          // 'fecha': DateTime.now().toIso8601String(), // Opcional, el backend ya pone la fecha si no se envía
        }),
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': body['message']};
      } else {
        return {'success': false, 'message': body['message'] ?? 'Error al registrar'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Obtener lista de FALTANTES
  Future<List<Asistencia>> getFaltantesCulto({required int idTipoCulto, DateTime? fecha}) async {
    String url = '$_baseUrl/faltantes?idTipoCulto=$idTipoCulto';
    if (fecha != null) url += '&fecha=${fecha.toIso8601String().substring(0, 10)}';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['success'] == true) {
          return (body['data'] as List).map((json) => Asistencia.fromJson(json)).toList();
        }
      }
    } catch (e) {
      print("Error obteniendo faltantes: $e");
    }
    return [];
  }

  // Generar reportes masivos
  Future<bool> generarReportesMasivos({
    required List<String> matriculas, 
    required int idTipoCulto, 
    required DateTime fecha,
    required String reportadoPor, // Matrícula del monitor
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/reportar-faltantes'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'listaMatriculas': matriculas,
          'idTipoCulto': idTipoCulto,
          'fecha': fecha.toIso8601String().substring(0, 10),
          'reportadoPor': reportadoPor
        }),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print("Error generando reportes: $e");
      return false;
    }
  }
}
