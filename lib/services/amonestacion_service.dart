import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:gestion_dormitorios/core/config/api_config.dart';

import 'package:gestion_dormitorios/Estudiantes/models/amonestacion_model.dart' as estudiante_model; 
import 'package:gestion_dormitorios/Administrador/Preceptor/models/amonestacion_preceptor_model.dart'; 
import 'package:gestion_dormitorios/Administrador/Preceptor/models/nivel_amonestacion_model.dart'; 


class AmonestacionService {
  final String _baseUrl = "${ApiConfig.baseUrl}/amonestaciones";


  Future<Map<String, dynamic>> getAmonestacionesPorEstudiante(String matricula) async {
    final url = Uri.parse("$_baseUrl/estudiante/$matricula");
    print("[AmonestacionService] GET $url (Estudiante)");
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        print("[AmonestacionService] GET /estudiante/$matricula - Éxito");
        return body; // Devuelve { success: true, data: [...] } o { success: false, ... }
      } else {
         print("[AmonestacionService] GET /estudiante/$matricula - Error HTTP: ${response.statusCode}");
        return {'success': false, 'message': 'Error del servidor (${response.statusCode})'};
      }
    } catch (e) {
       print("[AmonestacionService] GET /estudiante/$matricula - Error catch: $e");
      return {'success': false, 'message': 'No se pudo conectar con el servidor.'};
    }
  }


  Future<List<AmonestacionPreceptor>> getAllAmonestaciones() async {
    final url = Uri.parse(_baseUrl); // Llama a la ruta raíz
    print("[AmonestacionService] GET $url (Preceptor - Todas)");
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        if (body['success'] == true && body['data'] is List) {
          final List<dynamic> data = body['data'];
          print("[AmonestacionService] GET / - Éxito: ${data.length} amonestaciones.");
          // Usa el modelo AmonestacionPreceptor
          return data.map((json) => AmonestacionPreceptor.fromJson(json)).toList();
        } else {
           print("[AmonestacionService] GET / - Error lógico API: ${body['message']}");
           if (body['data'] is List && (body['data'] as List).isEmpty) return []; // Lista vacía es éxito
          throw Exception(body['message'] ?? 'Respuesta inesperada al obtener amonestaciones');
        }
      } else {
        print("[AmonestacionService] GET / - Error HTTP: ${response.statusCode}");
        throw Exception('Error del servidor al obtener amonestaciones [${response.statusCode}]');
      }
    } catch (e) {
       print("[AmonestacionService] GET / - Error catch: $e");
      throw Exception('No se pudo obtener la lista de amonestaciones: $e');
    }
  }


  Future<List<NivelAmonestacion>> getNivelesAmonestacion() async {
    final url = Uri.parse("$_baseUrl/niveles");
    print("[AmonestacionService] GET $url (Preceptor - Niveles)");
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        if (body['success'] == true && body['data'] is List) {
          final List<dynamic> data = body['data'];
          print("[AmonestacionService] GET /niveles - Éxito: ${data.length} niveles.");
          return data.map((json) => NivelAmonestacion.fromJson(json)).toList();
        } else {
          print("[AmonestacionService] GET /niveles - Error lógico API: ${body['message']}");
          throw Exception(body['message'] ?? 'Respuesta inesperada al obtener niveles');
        }
      } else {
         print("[AmonestacionService] GET /niveles - Error HTTP: ${response.statusCode}");
        throw Exception('Error del servidor al obtener niveles [${response.statusCode}]');
      }
    } catch (e) {
      print("[AmonestacionService] GET /niveles - Error catch: $e");
      throw Exception('No se pudo obtener la lista de niveles: $e');
    }
  }


  Future<Map<String, dynamic>> registrarAmonestacion({
    required String matriculaEstudiante,
    required String clavePreceptor,
    required int idNivel,
    required String motivo,
  }) async {
    final url = Uri.parse("$_baseUrl/registrar");
    print("[AmonestacionService] POST $url");

    final body = json.encode({
      'matriculaEstudiante': matriculaEstudiante,
      'clavePreceptor': clavePreceptor,
      'idNivel': idNivel,
      'motivo': motivo,
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 15));

      final Map<String, dynamic> responseBody = json.decode(response.body);
      print("[AmonestacionService] POST /registrar - Status: ${response.statusCode}, Body: $responseBody");

      if (response.statusCode == 200 && responseBody['success'] == true) {
        return responseBody;
      } else {
        throw Exception(responseBody['message'] ?? 'Error desconocido al registrar amonestación');
      }
    } catch (e) {
      print("[AmonestacionService] POST /registrar - Error catch: $e");
      throw Exception('Error de red o al registrar la amonestación: $e');
    }
  }

} 
