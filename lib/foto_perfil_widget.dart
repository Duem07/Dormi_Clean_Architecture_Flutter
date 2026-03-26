import 'package:flutter/material.dart';
import 'package:gestion_dormitorios/core/config/api_config.dart'; // Asegúrate de importar tu config

class FotoPerfilWidget extends StatelessWidget {
  final String matricula;
  final double size;

  const FotoPerfilWidget({
    super.key, 
    required this.matricula, 
    this.size = 50.0 // Tamaño por defecto (radio)
  });

  @override
  Widget build(BuildContext context) {
    // Si la matrícula viene vacía (ej. un admin global sin matrícula), mostramos default
    if (matricula.isEmpty) {
      return _imagenPorDefecto();
    }

    // Construimos la URL: http://tu-ip:5000/api/estudiantes/222100/foto
    final String urlFoto = '${ApiConfig.baseUrl}/estudiantes/$matricula/foto';

    return CircleAvatar(
      radius: size,
      backgroundColor: Colors.grey[200],
      child: ClipOval( // Recorta la imagen en círculo perfecto
        child: Image.network(
          urlFoto,
          width: size * 2,
          height: size * 2,
          fit: BoxFit.cover, // Para que la foto llene el círculo sin deformarse
          
          // AQUÍ ESTÁ LA MAGIA DEL DEFAULT 👇
          errorBuilder: (context, error, stackTrace) {
            // Si el backend da 404 o error, mostramos esto:
            return _imagenPorDefecto();
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          },
        ),
      ),
    );
  }

  Widget _imagenPorDefecto() {
    return Image.asset(
      'assets/images/profile_placeholder.png', // <--- ASEGURATE DE TENER ESTA IMAGEN
      width: size * 2,
      height: size * 2,
      fit: BoxFit.cover,
    );
  }
}