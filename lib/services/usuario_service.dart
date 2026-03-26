import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:gestion_dormitorios/core/config/api_config.dart'; 
import 'package:gestion_dormitorios/Administrador/Preceptor/models/monitor_info_model.dart';

class UsuarioService {
  final String _baseUrl = "${ApiConfig.baseUrl}/usuarios"; 

  Future<List<MonitorInfo>> getMonitores() async {
    final url = Uri.parse("$_baseUrl/monitores");
    print("[UsuarioService] Llamando a GET $url"); // Log para depuración

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15)); 

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body); 
        if (body['success'] == true && body['data'] is List) {
          final List<dynamic> data = body['data'];
          print("[UsuarioService] GET /monitores - Éxito. Datos recibidos: ${data.length} monitores."); // Log de éxito
          return data.map((json) => MonitorInfo.fromJson(json)).toList();
        } else {
           print("[UsuarioService] GET /monitores - Error lógico de API: ${body['message']}"); // Log de error API
          throw Exception(body['message'] ?? 'Respuesta inesperada del servidor al obtener monitores');
        }
      } else {
         print("[UsuarioService] GET /monitores - Error HTTP: ${response.statusCode}"); // Log de error HTTP
        throw Exception('Error del servidor al obtener monitores [${response.statusCode}]');
      }
    } catch (e) {
       print("[UsuarioService] GET /monitores - Error en catch: $e"); // Log general de error
      throw Exception('No se pudo obtener la lista de monitores: $e');
    }
  }

  Future<Map<String, dynamic>> asignarMonitor(String usuarioID) async {
    final url = Uri.parse("$_baseUrl/$usuarioID/rol"); 
    print("[UsuarioService] Llamando a PUT $url con rol 2 (Monitor)"); // Log

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'}, 
        body: json.encode({'nuevoRol': 2}), 
      ).timeout(const Duration(seconds: 15)); 

      final Map<String, dynamic> responseBody = json.decode(response.body);
      print("[UsuarioService] PUT /$usuarioID/rol (Asignar) - Status: ${response.statusCode}, Body: $responseBody"); // Log de respuesta

      if (response.statusCode == 200 && responseBody['success'] == true) {
        return responseBody;
      } else {
        throw Exception(responseBody['message'] ?? 'Error desconocido al asignar rol de monitor');
      }
    } catch (e) {

      print("[UsuarioService] PUT /$usuarioID/rol (Asignar) - Error en catch: $e"); // Log de error
      throw Exception('Error de red o al asignar el rol de monitor: $e');
    }
  }

  Future<Map<String, dynamic>> quitarMonitor(String usuarioID) async {
    final url = Uri.parse("$_baseUrl/$usuarioID/rol");
    print("[UsuarioService] Llamando a PUT $url con rol 3 (Estudiante)"); // Log

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'nuevoRol': 3}), 
      ).timeout(const Duration(seconds: 15));

      final Map<String, dynamic> responseBody = json.decode(response.body);
       print("[UsuarioService] PUT /$usuarioID/rol (Quitar) - Status: ${response.statusCode}, Body: $responseBody"); // Log de respuesta

      if (response.statusCode == 200 && responseBody['success'] == true) {
        return responseBody; 
      } else {
        throw Exception(responseBody['message'] ?? 'Error desconocido al quitar rol de monitor');
      }
    } catch (e) {
      print("[UsuarioService] PUT /$usuarioID/rol (Quitar) - Error en catch: $e"); 
      throw Exception('Error de red o al quitar el rol de monitor: $e');
    }
  }

}

