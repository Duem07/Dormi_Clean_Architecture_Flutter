import 'dart:convert';
import 'package:http/http.dart' as http;
// Asegúrate de que esta ruta sea la correcta según tu proyecto:
import '../../core/config/api_config.dart'; 
import '../models/usuario_model.dart';
import 'package:gestion_dormitorios/Estudiantes/models/institutional_user.dart';

class AuthRemoteDataSource {
  
  // --- MÉTODOS DE LOGIN ---
  Future<UsuarioModel> login(String usuarioID, String password) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/auth/login"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'usuarioID': usuarioID, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return UsuarioModel.fromJson(data['user']);
    } else {
      throw Exception('Credenciales incorrectas');
    }
  }

  // --- MÉTODOS PARA REGISTRO ---

  Future<InstitutionalUser?> checkInstitutionalUser(String matricula) async {
    // Nota: Aquí usas la URL de la API escolar externa
    final response = await http.get(
      Uri.parse("https://api.ulv.edu.mx/api/escolar/usuario/$matricula"), 
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return InstitutionalUser.fromJson(data);
    }
    return null;
  }

  Future<Map<String, dynamic>> checkAccess(String usuarioID, int idRol) async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/auth/check-access/$usuarioID/$idRol"),
    );
    return jsonDecode(response.body);
  }

  Future<bool> sendOtpToEmail(String email) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/auth/send-otp"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    return response.statusCode == 200;
  }

  Future<bool> verifyOtpCode(String email, String code) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/auth/verify-otp"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'code': code}),
    );
    return response.statusCode == 200;
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/auth/register"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  Future<bool> resetPassword(String email, String newPassword) async {
  final response = await http.post(
    Uri.parse("${ApiConfig.baseUrl}/auth/reset-password"),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email, 'newPassword': newPassword}),
  );
  return response.statusCode == 200;
}
}