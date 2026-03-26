import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:gestion_dormitorios/core/config/api_config.dart';

class DormitorioService {
  final String _baseUrl = ApiConfig.baseUrl;

// Obtener estudiantes para el dropdown
  Future<List<dynamic>> getEstudiantesParaAsignacion() async {
    try {
      // OJO: La ruta debe coincidir con la del backend ('/para-asignacion')
      final response = await http.get(Uri.parse('$_baseUrl/estudiantes/para-asignacion'));
      
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['data'] ?? []; 
      }
    } catch (e) {
      print("Error: $e");
    }
    return [];
  }


Future<List<dynamic>> getDormitorios() async {
    try {
      // Apunta a la raíz de dormitorios (donde pusimos el GET /)
      final response = await http.get(Uri.parse('$_baseUrl/dormitorios'));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['data'] ?? [];
      }
    } catch (e) {
      print("Error obteniendo dormitorios: $e");
    }
    return [];
  }


  // 2. Obtener Pasillos
  Future<List<dynamic>> getPasillos() async {
    try {
      // Asegúrate que esta ruta coincida con tu backend ('api/dormitorios/pasillos')
      final response = await http.get(Uri.parse('$_baseUrl/dormitorios/pasillos')); 
      
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        // SOLUCIÓN AQUÍ:
        return body['data'] ?? []; 
      }
    } catch (e) {
      print("Error obteniendo pasillos: $e");
    }
    return [];
  }

  // 3. Obtener Cuartos por Pasillo
  Future<List<dynamic>> getCuartosPorPasillo(int idPasillo) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/dormitorios/cuartos?idPasillo=$idPasillo'));
      
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['data'] ?? [];
      }
    } catch (e) {
      print("Error obteniendo cuartos: $e");
    }
    return [];
  }

  // 4. Guardar Asignación
  Future<bool> asignarCuarto(String matricula,int Dormitorio, int idPasillo, int idCuarto) async {
    try {
      // OJO: Aquí tenías un error en tu código anterior, apuntabas a 'estudiantes/sin-cuarto' (GET)
      // Debe ser 'estudiantes/asignar-cuarto' (PUT)
     final response = await http.put(
        Uri.parse('$_baseUrl/estudiantes/asignar-cuarto'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'matricula': matricula,
          'idDormitorio': Dormitorio, // <--- Enviamos el dato nuevo
          'idPasillo': idPasillo,
          'idCuarto': idCuarto,
        }),
      );
      
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['success'] == true;
      }
    } catch (e) {
      print("Error asignando cuarto: $e");
    }
    return false;
  }

  // 5. Obtener datos de Ocupación
  Future<List<dynamic>> getOcupacion() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/dormitorios/ocupacion'));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['data'] ?? [];
      }
    } catch (e) {
      print("Error obteniendo ocupación: $e");
    }
    return [];
  }
}