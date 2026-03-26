import 'package:flutter/material.dart';
import '../../domain/entities/usuario.dart';
import '../../domain/repositories/auth_repository.dart';
import 'package:gestion_dormitorios/Estudiantes/models/institutional_user.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository repository;

  Usuario? _usuario;
  bool _isLoading = false;
  String? _error;

  AuthProvider(this.repository);

  // Getters para la UI
  Usuario? get usuario => _usuario;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // --- MÉTODO DE LOGIN ---
  Future<bool> login(String id, String pass) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _usuario = await repository.login(id, pass);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // --- MÉTODOS PARA EL REGISTRO ---

  Future<InstitutionalUser?> checkInstitutionalUser(String matricula) async {
    _isLoading = true;
    notifyListeners();
    try {
      final user = await repository.checkInstitutionalUser(matricula);
      _isLoading = false;
      notifyListeners();
      return user;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<Map<String, dynamic>> checkAccess(String id, int rol) async {
    try {
      return await repository.checkAccess(id, rol);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<bool> sendOtpToEmail(String email) async {
    try {
      return await repository.sendOtpToEmail(email);
    } catch (e) {
      return false;
    }
  }

  Future<bool> verifyOtpCode(String email, String code) async {
    try {
      return await repository.verifyOtpCode(email, code);
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> register({
    required String usuarioID,
    required String password,
    required int idRol,
    required String nombre,
    required String carrera,
    required String correo,
  }) async {
    try {
      return await repository.register(
        usuarioID: usuarioID,
        password: password,
        idRol: idRol,
        nombre: nombre,
        carrera: carrera,
        correo: correo,
      );
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
  
  Future<bool> resetPassword(String email, String newPassword) async {
  _isLoading = true;
  notifyListeners();
  try {
    final success = await repository.resetPassword(email, newPassword);
    _isLoading = false;
    notifyListeners();
    return success;
  } catch (e) {
    _isLoading = false;
    _error = e.toString();
    notifyListeners();
    return false;
  }
}
}