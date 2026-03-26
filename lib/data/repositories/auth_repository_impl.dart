import '../../domain/entities/usuario.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import 'package:gestion_dormitorios/Estudiantes/models/institutional_user.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<Usuario> login(String usuarioID, String password) async {
    return await remoteDataSource.login(usuarioID, password);
  }

  @override
  Future<InstitutionalUser?> checkInstitutionalUser(String matricula) async {
    return await remoteDataSource.checkInstitutionalUser(matricula);
  }

  @override
  Future<Map<String, dynamic>> checkAccess(String usuarioID, int idRol) async {
    return await remoteDataSource.checkAccess(usuarioID, idRol);
  }

  @override
  Future<bool> sendOtpToEmail(String email) async {
    return await remoteDataSource.sendOtpToEmail(email);
  }

  @override
  Future<bool> verifyOtpCode(String email, String code) async {
    return await remoteDataSource.verifyOtpCode(email, code);
  }

  @override
  Future<Map<String, dynamic>> register({
    required String usuarioID,
    required String password,
    required int idRol,
    required String nombre,
    required String carrera,
    required String correo,
  }) async {
    // Creamos el mapa de datos para enviarlo al DataSource
    final data = {
      'usuarioID': usuarioID,
      'password': password,
      'idRol': idRol,
      'nombre': nombre,
      'carrera': carrera,
      'correo': correo,
    };
    return await remoteDataSource.register(data);
  }

  @override
  Future<bool> resetPassword(String email, String newPassword) async {
    return await remoteDataSource.resetPassword(email, newPassword);
  }
}