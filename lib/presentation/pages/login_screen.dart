import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Importaciones de la nueva arquitectura
import '../../presentation/providers/auth_provider.dart';
import '../../providers/user_provider.dart';

// Importaciones de pantallas existentes (Ajusta la ruta si es necesario)
import 'package:gestion_dormitorios/Estudiantes/screens/home_screen.dart';
import 'package:gestion_dormitorios/Administrador/Preceptor/screens/dashboard_preceptor_screen.dart';
import 'package:gestion_dormitorios/Administrador/Monitor/screens/dashboard_monitor_screen.dart';
import 'package:gestion_dormitorios/Estudiantes/screens/registro_screen.dart';
import 'package:gestion_dormitorios/recuperar_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController matriculaController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  
  bool _obscurePassword = true;

  Future<void> _login() async {
    final usuarioID = matriculaController.text.trim();
    final password = passwordController.text.trim();

    if (usuarioID.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresa usuario y contraseña')),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    // Obtenemos los providers
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Ejecutamos el login a través de la arquitectura limpia
    final success = await authProvider.login(usuarioID, password);

    if (success && mounted) {
      final usuarioEntidad = authProvider.usuario!;

      // Mantenemos la compatibilidad con tu UserProvider antiguo
      userProvider.setUser({
        'UsuarioID': usuarioEntidad.usuarioID,
        'NombreCompleto': usuarioEntidad.nombreCompleto,
        'IdRol': usuarioEntidad.idRol,
        'Correo': usuarioEntidad.correo,
      });

      // Lógica de Firebase FCM (Detalle de Infraestructura)
      try {
        String? fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          debugPrint("FCM Token obtenido correctamente");
          // Aquí llamarías a un UseCase para guardar el token si lo deseas
        }
      } catch (fcmError) {
        debugPrint("Error obteniendo FCM Token: $fcmError");
      }

      if (!mounted) return;

      // Navegación basada en ROL (Lógica de Presentación)
      _navegarSegunRol(usuarioEntidad.idRol);

    } else if (mounted) {
      // Manejo de errores dinámico basado en lo que el Provider reportó
      String errorMsg = authProvider.error ?? 'Credenciales incorrectas';
      Color snackColor = Colors.orange;

      if (errorMsg.toLowerCase().contains('conexión') || 
          errorMsg.toLowerCase().contains('timeout')) {
        errorMsg = 'Sin conexión al servidor. Revisa tu internet.';
        snackColor = Colors.red;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: snackColor,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _navegarSegunRol(int rol) {
    if (rol == 1) { // Preceptor
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardPreceptorScreen()));
    } else if (rol == 2) { // Monitor
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardMonitorScreen()));
    } else if (rol == 3) { // Estudiante
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Escuchamos el estado de carga desde el nuevo Provider
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/logoulv.png', height: 100, color: isDark ? Colors.white : null),
                const SizedBox(height: 16),
                Text('DORMITORIOS ULV',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: theme.textTheme.bodyMedium?.color)),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4))
                      ]),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Iniciar sesión',
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
                      _buildTextField(
                          controller: matriculaController,
                          hint: 'Usuario (Matrícula/Clave)',
                          icon: Icons.person_outline,
                          isDark: isDark),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: passwordController,
                        hint: 'Contraseña',
                        icon: Icons.lock_outline,
                        isPassword: _obscurePassword,
                        isDark: isDark,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          onPressed: isLoading ? null : _login,
                          child: isLoading
                              ? SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                      color: theme.colorScheme.onPrimary,
                                      strokeWidth: 3))
                              : const Text('ACCEDER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const RecuperarPasswordScreen()));
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: Colors.grey[700],
                        ),
                        child: const Text(
                          '¿Olvidaste tu contraseña?',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '¿Eres nuevo? ',
                            style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const RegistroScreen()));
                            },
                            child: Text(
                              'Regístrate aquí',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    bool isPassword = false,
    Widget? suffixIcon,
  }) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      style: TextStyle(color: theme.textTheme.bodyMedium?.color),
      keyboardType: isPassword ? TextInputType.visiblePassword : TextInputType.text,
      textInputAction: isPassword ? TextInputAction.done : TextInputAction.next,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: theme.iconTheme.color?.withOpacity(0.7)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDark ? Colors.black.withOpacity(0.15) : Colors.grey.shade200,
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
      ),
    );
  }
}