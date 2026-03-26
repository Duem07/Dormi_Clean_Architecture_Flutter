import '../../domain/entities/usuario.dart';

class UsuarioModel extends Usuario {
  UsuarioModel({
    required super.usuarioID,
    required super.nombreCompleto,
    required super.idRol,
    required super.correo,
  });

  // Esta pieza es clave: Convierte el JSON de tu API a la Entidad
  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
      usuarioID: json['UsuarioID'] ?? json['usuarioID'],
      nombreCompleto: json['NombreCompleto'] ?? '',
      idRol: json['IdRol'] ?? 0,
      correo: json['Correo'] ?? '',
    );
  }
}