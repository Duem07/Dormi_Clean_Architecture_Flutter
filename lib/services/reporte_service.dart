import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:gestion_dormitorios/core/config/api_config.dart'; 
import 'package:gestion_dormitorios/Estudiantes/models/reporte_model.dart' as estudiante_model; 
import 'package:gestion_dormitorios/Administrador/Monitor/models/reporte_monitor_model.dart' as monitor_model;

class ReporteService {
  final String _baseUrl = "${ApiConfig.baseUrl}/reportes";

  Future<List<estudiante_model.Reporte>> getReportesPorEstudiante(String matricula) async {
    final url = Uri.parse("$_baseUrl/estudiante/$matricula");
    print("[ReporteService] Llamando a GET $url (para Estudiante)");

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        if (body['success'] == true && body['data'] is List) {
          final List<dynamic> data = body['data'];
          print("[ReporteService] GET /estudiante/$matricula (Estudiante) - Éxito: ${data.length} reportes.");

          return data.map((json) => estudiante_model.Reporte.fromJson(json)).toList();
        } else {
          print("[ReporteService] GET /estudiante/$matricula (Estudiante) - Error lógico API: ${body['message']}");
          if (body['data'] is List && (body['data'] as List).isEmpty) return [];
          throw Exception(body['message'] ?? 'Respuesta inesperada al obtener reportes del estudiante');
        }
      } else {
        print("[ReporteService] GET /estudiante/$matricula (Estudiante) - Error HTTP: ${response.statusCode}");
        throw Exception('Error del servidor al obtener reportes [${response.statusCode}]');
      }
    } catch (e) {
      print("[ReporteService] GET /estudiante/$matricula (Estudiante) - Error en catch: $e");
      throw Exception('No se pudo obtener la lista de reportes: $e');
    }
  }

  Future<List<monitor_model.ReporteMonitor>> buscarReportesMonitor(String matricula) async {
    final url = Uri.parse("$_baseUrl/estudiante/$matricula");
     print("[ReporteService] Llamando a GET $url (para Monitor/Preceptor - Búsqueda)");

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        if (body['success'] == true && body['data'] is List) {
          final List<dynamic> data = body['data'];
           print("[ReporteService] GET /estudiante/$matricula (Monitor/Preceptor) - Éxito: ${data.length} reportes.");
          return data.map((json) => monitor_model.ReporteMonitor.fromJson(json)).toList();
        } else {
           print("[ReporteService] GET /estudiante/$matricula (Monitor/Preceptor) - Error lógico API: ${body['message']}");
           if (body['data'] is List && (body['data'] as List).isEmpty) return [];
          throw Exception(body['message'] ?? 'Respuesta inesperada al buscar reportes');
        }
      } else {
        print("[ReporteService] GET /estudiante/$matricula (Monitor/Preceptor) - Error HTTP: ${response.statusCode}");
        throw Exception('Error del servidor al buscar reportes [${response.statusCode}]');
      }
    } catch (e) {
       print("[ReporteService] GET /estudiante/$matricula (Monitor/Preceptor) - Error en catch: $e");
      throw Exception('No se pudo buscar la lista de reportes: $e');
    }
  }

  Future<Map<String, dynamic>> crearReporte({
    required String matriculaReportado,
    required String reportadoPor, 
    required String tipoUsuarioReportante,
    required String motivo,
    required int idTipoReporte, 
  }) async {
    final url = Uri.parse("$_baseUrl/crear");
    print("[ReporteService] Llamando a POST $url");

    final body = json.encode({
      'matriculaReportado': matriculaReportado,
      'reportadoPor': reportadoPor,
      'tipoUsuarioReportante': tipoUsuarioReportante,
      'motivo': motivo,
      'idTipoReporte' : idTipoReporte,
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 15));

      final Map<String, dynamic> responseBody = json.decode(response.body);
      print("[ReporteService] POST /crear - Status: ${response.statusCode}, Body: $responseBody");

    
      if (response.statusCode == 201 && responseBody['success'] == true) {
        return responseBody; 
      } else {
        throw Exception(responseBody['message'] ?? 'Error desconocido al crear el reporte');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<Map<String, dynamic>> getAllReportes({int page = 1, int limit = 20, String? search}) async {
    String queryString = '?page=$page&limit=$limit';
    if (search != null && search.isNotEmpty) {
      queryString += '&search=${Uri.encodeComponent(search)}'; 
    }
    final url = Uri.parse('$_baseUrl$queryString'); 
    print("[ReporteService] Llamando a GET $url (Todos los reportes)");

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 20)); // Mayor timeout

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        if (body['success'] == true && body['data'] is List) {
           print("[ReporteService] GET / (Todos) - Éxito: ${body['data'].length} reportes en pág $page.");

          final List<dynamic> data = body['data'];
          final List<monitor_model.ReporteMonitor> reportes = data
              .map((json) => monitor_model.ReporteMonitor.fromJson(json))
              .toList();
          
          return {
            'reportes': reportes,
            'total': body['total'] ?? 0,
            'page': body['page'] ?? 1,
            'limit': body['limit'] ?? 20,
          };

        } else {
           print("[ReporteService] GET / (Todos) - Error lógico API: ${body['message']}");
           if (body['data'] is List && (body['data'] as List).isEmpty) return {'reportes': [], 'total': 0, 'page': 1, 'limit': 20}; // Caso vacío
          throw Exception(body['message'] ?? 'Respuesta inesperada al obtener todos los reportes');
        }
      } else {
        print("[ReporteService] GET / (Todos) - Error HTTP: ${response.statusCode}");
        throw Exception('Error del servidor al obtener todos los reportes [${response.statusCode}]');
      }
    } catch (e) {
       print("[ReporteService] GET / (Todos) - Error en catch: $e");
      throw Exception('No se pudo obtener la lista completa de reportes: $e');
    }
  }


  Future<Map<String, dynamic>> aprobarReporte(int idReporte, String preceptorId) async {
    final url = Uri.parse("$_baseUrl/$idReporte/aprobar");
    print("[ReporteService] Llamando a PUT $url");

    final body = json.encode({
      'preceptorId': preceptorId, 
    });

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 15));

      final Map<String, dynamic> responseBody = json.decode(response.body);
      print("[ReporteService] PUT /aprobar - Status: ${response.statusCode}, Body: $responseBody");
      
      if (response.statusCode == 200 && responseBody['success'] == true) {
        return responseBody;
      } else {
        throw Exception(responseBody['message'] ?? 'Error al aprobar el reporte');
      }
    } catch (e) {
      print("[ReporteService] PUT /aprobar - Error en catch: $e");
      throw Exception('Error de red o al aprobar el reporte: $e');
    }
  }

  Future<Map<String, dynamic>> rechazarReporte(int idReporte) async {
    final url = Uri.parse("$_baseUrl/$idReporte/rechazar");
    print("[ReporteService] Llamando a PUT $url");

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      final Map<String, dynamic> responseBody = json.decode(response.body);
       print("[ReporteService] PUT /rechazar - Status: ${response.statusCode}, Body: $responseBody");

      if (response.statusCode == 200 && responseBody['success'] == true) {
        return responseBody;
      } else {
        throw Exception(responseBody['message'] ?? 'Error al rechazar el reporte');
      }
    } catch (e) {
       print("[ReporteService] PUT /rechazar - Error en catch: $e");
      throw Exception('Error de red o al rechazar el reporte: $e');
    }
  }
}