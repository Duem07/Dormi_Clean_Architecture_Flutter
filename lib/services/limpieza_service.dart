import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:gestion_dormitorios/core/config/api_config.dart';
import 'package:gestion_dormitorios/Estudiantes/models/limpieza_model.dart'; 
import 'package:gestion_dormitorios/Administrador/Monitor/models/criterio_limpieza_model.dart'; 
import 'package:gestion_dormitorios/Administrador/Monitor/models/cuarto_para_evaluar_model.dart'; 

class LimpiezaService {
  final String _baseUrl = "${ApiConfig.baseUrl}/limpieza";

  Future<LimpiezaReporte?> obtenerUltimaLimpieza(int idCuarto) async {
    final url = Uri.parse("$_baseUrl/detalle/$idCuarto");
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        if (body['success'] == true && body['data'] != null) {
          return LimpiezaReporte.fromJson(body['data']);
        } else if (body['success'] == true && body['data'] == null) {
            return null; 
        } else {
          print("API error en obtenerUltimaLimpieza: ${body['message']}");
          return null; 
        }
      } else {
        print("HTTP Error en obtenerUltimaLimpieza: ${response.statusCode}");
        return null; 
      }
    } catch (e) {
      print("Exception en obtenerUltimaLimpieza: $e");
       return null; 
    }
  }

  Future<List<CriterioLimpieza>> obtenerCriterios() async {
    final url = Uri.parse("$_baseUrl/criterios");
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        if (body['success'] == true && body['data'] is List) {
          final List<dynamic> data = body['data'];
          // Aseguramos usar el fromJson del modelo importado de Monitor
          return data.map((json) => CriterioLimpieza.fromJson(json)).toList();
        } else {
          throw Exception(body['message'] ?? 'Respuesta inesperada al obtener criterios');
        }
      } else {
        throw Exception('Error del servidor [${response.statusCode}] al obtener criterios');
      }
    } catch (e) {
       print("Error en obtenerCriterios: $e");
      throw Exception('No se pudieron obtener los criterios: $e');
    }
  }

  Future<Map<String, dynamic>> registrarLimpieza({
    required int idCuarto,
    required String evaluadoPorMatricula,
    required List<CriterioLimpieza> criterios, 
    required int ordenGeneral,
    required int disciplina,
    String? observaciones, 
  }) async {
    final url = Uri.parse("$_baseUrl/registrar");
    final body = json.encode({
      'idCuarto': idCuarto,
      'evaluadoPor': evaluadoPorMatricula, 
      'detallesMatutinos': criterios.map((c) => {
        'idCriterio': c.idCriterio,
        'calificacion': c.calificacion 
      }).toList(),
      'ordenGeneral': ordenGeneral,
      'disciplina': disciplina,
      'observaciones': observaciones ?? '', 
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'}, 
        body: body,
      ).timeout(const Duration(seconds: 20)); 

      final Map<String, dynamic> responseBody = json.decode(response.body);

      if (response.statusCode == 201 && responseBody['success'] == true) {
        return responseBody; 
      } else {
        throw Exception(responseBody['message'] ?? 'Error desconocido al registrar la limpieza');
      }
    } catch (e) {
       print("Error en registrarLimpieza: $e");
      throw Exception('No se pudo registrar la limpieza: $e');
    }
  }

  Future<List<CuartoParaEvaluar>> obtenerCuartosConCalificacion() async {
    final url = Uri.parse("$_baseUrl/cuartos-con-calificacion");
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        if (body['success'] == true && body['data'] is List) {
          final List<dynamic> data = body['data'];
          return data.map((json) => CuartoParaEvaluar.fromJson(json)).toList();
        } else {
          throw Exception(body['message'] ?? 'Error al obtener lista de cuartos API');
        }
      } else {
        throw Exception('Error del servidor [${response.statusCode}] al obtener cuartos');
      }
    } catch (e) {
       print("Error en obtenerCuartosConCalificacion: $e");
      throw Exception('No se pudo obtener la lista de cuartos: $e');
    }
  }

  // Obtener el detalle completo de la última limpieza de un cuarto
Future<Map<String, dynamic>?> obtenerDetalleLimpieza(int idCuarto) async {
    final url = Uri.parse('$_baseUrl/detalle/$idCuarto');
    print("Consultando detalle: $url"); // Debug en consola

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      print("Respuesta Detalle (${response.statusCode}): ${response.body}"); // Debug respuesta

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        
        if (body['success'] == true) {
          if (body['data'] != null) {
            return body['data'];
          } else {
            // Si success es true pero data es null, es que no hay registros
            return null; 
          }
        } else {
          // Si el servidor dice success: false, lanzamos el error
          throw Exception(body['message'] ?? 'Error lógico en el servidor');
        }
      } else {
        // Si es 404, 500, etc.
        throw Exception('Error del servidor: Código ${response.statusCode}');
      }
    } catch (e) {
      print("Error en obtenerDetalleLimpieza: $e");
      // ¡IMPORTANTE! Lanzamos el error para que el Modal lo muestre en rojo
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }


// --- NUEVO: Obtener lista de semestres para el filtro ---
  Future<List<dynamic>> obtenerSemestres() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/semestres-lista'));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['data'] ?? [];
      }
      return [];
    } catch (e) {
      print("Error obteniendo semestres: $e");
      return [];
    }
  }
// --- MODIFICADO: Acepta idSemestre opcional ---
  Future<Map<String, dynamic>> obtenerEstadisticas({String? idSemestre}) async {
    // Construimos la URL. Si hay ID, lo agregamos como parámetro query (?idSemestre=1)
    String url = "$_baseUrl/estadisticas/generales";
    if (idSemestre != null) {
      url += "?idSemestre=$idSemestre";
    }

    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'success': false, 'message': 'Error http ${response.statusCode}'};
    } catch (e) {
      print("Error obteniendo estadísticas: $e");
      return {'success': false, 'message': e.toString()};
    }
  }
  
  // B. Realizar Corte Manual (Reiniciar gráfica del mes)
  Future<bool> realizarCorte(String matriculaPreceptor) async {
    final url = Uri.parse("$_baseUrl/realizar-corte");
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'realizadoPor': matriculaPreceptor}),
      );
      final body = json.decode(response.body);
      return response.statusCode == 200 && body['success'] == true;
    } catch (e) {
      print("Error realizando corte: $e");
      return false;
    }
  }
}
