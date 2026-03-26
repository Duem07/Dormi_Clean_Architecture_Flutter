import '../entities/usuario.dart';
import 'package:gestion_dormitorios/Estudiantes/models/institutional_user.dart';

abstract class AuthRepository {
  Future<Usuario> login(String usuarioID, String password);
  
  // Agregamos los nuevos métodos del registro
  Future<InstitutionalUser?> checkInstitutionalUser(String matricula);
  Future<Map<String, dynamic>> checkAccess(String usuarioID, int idRol);
  Future<bool> sendOtpToEmail(String email);
  Future<bool> verifyOtpCode(String email, String code);
  Future<Map<String, dynamic>> register({
    required String usuarioID,
    required String password,
    required int idRol,
    required String nombre,
    required String carrera,
    required String correo,
  });
  Future<bool> resetPassword(String email, String newPassword);
}