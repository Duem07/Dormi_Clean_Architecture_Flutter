import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http; // <--- NECESARIO PARA CONSULTAR DATOS

// Imports de tu proyecto
import 'package:gestion_dormitorios/core/config/api_config.dart'; // <--- IMPORTANTE
import 'package:gestion_dormitorios/providers/user_provider.dart';
import 'package:gestion_dormitorios/providers/theme_provider.dart';
import 'package:gestion_dormitorios/services/asistencia_service.dart';

class AsistenciaScreen extends StatefulWidget {
  const AsistenciaScreen({super.key});

  @override
  State<AsistenciaScreen> createState() => _AsistenciaScreenState();
}

class _AsistenciaScreenState extends State<AsistenciaScreen> {
  // Estado
  bool mostrandoQR = false;
  bool _yaNotifiqueEsteCodigo = false;
  String actividadSeleccionada = '';
  
  // Controladores y Servicios
  final MobileScannerController _scannerController = MobileScannerController();
  final AsistenciaService _asistenciaService = AsistenciaService();

  // Fechas
  late final String fechaActual;
  late final String diaSemana;

  // DATOS DEL USUARIO (Ya no son final ni fijos)
  String nombreUsuario = 'Cargando...';
  String carrera = '';

  @override
  void initState() {
    super.initState();
    final hoy = DateTime.now();
    fechaActual = DateFormat('dd/MM/yyyy').format(hoy);
    diaSemana = toTitle(DateFormat('EEEE', 'es').format(hoy));

    // Cargamos los datos reales apenas inicia la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarDatosUsuario();
    });
  }

  // FUNCIÓN NUEVA: Obtener nombre y carrera reales
  Future<void> _cargarDatosUsuario() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final matricula = userProvider.matricula;

    // Si no hay matrícula, no hacemos nada
    if (matricula.isEmpty) return;

    try {
      // Usamos tu endpoint existente de estudiantes
      final url = Uri.parse('${ApiConfig.baseUrl}/estudiantes/$matricula');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          setState(() {
            // Asignamos los datos reales de la BD
            nombreUsuario = body['data']['NombreCompleto'] ?? 'Sin Nombre';
            carrera = body['data']['Carrera'] ?? 'Sin Carrera';
          });
        }
      }
    } catch (e) {
      print("Error cargando datos de usuario: $e");
      setState(() {
        nombreUsuario = "Error al cargar";
      });
    }
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Asistencia'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildUserCard(context),
          const SizedBox(height: 20),
          
          if (actividadSeleccionada.isNotEmpty)
            _buildConfirmacion(Theme.of(context).textTheme.bodyMedium?.color)
          else
            _buildActionCard(context),
        ],
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildUserCard(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildUserHeader(context),
            const Divider(height: 24, thickness: 1),
            _buildInfoRow(Icons.calendar_today_outlined, 'Fecha actual', fechaActual),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.event_note_outlined, 'Día', diaSemana),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            nombreUsuario.isNotEmpty && nombreUsuario != 'Cargando...' ? nombreUsuario[0] : '?',
            style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(nombreUsuario, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              if (carrera.isNotEmpty)
                Text(carrera, style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodySmall?.color)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Text('$label:', style: Theme.of(context).textTheme.bodyMedium),
        const Spacer(),
        Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            if (!mostrandoQR) ...[
              Text(
                'Registro de Asistencia',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Presiona el botón para escanear el código QR y registrar tu asistencia.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildBotonQR(context),
            ] else
              _buildQRScanner(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBotonQR(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => setState(() => mostrandoQR = true),
      icon: const Icon(Icons.qr_code_scanner),
      label: const Text('Escanear código QR'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildQRScanner(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Column(
      children: [
        Container(
          height: 320,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: primary.withOpacity(0.3)),
          ),
          child: Stack(
            children: [
              MobileScanner(
                controller: _scannerController,
                onDetect: (capture) async {
                  final barcode = capture.barcodes.isNotEmpty ? capture.barcodes.first : null;
                  final valor = barcode?.rawValue;

                  if (valor == null || _yaNotifiqueEsteCodigo) return;

                  _yaNotifiqueEsteCodigo = true; 
                  _scannerController.stop(); 

                  try {
                    final Map<String, dynamic> dataQR = jsonDecode(valor);
                    final int idTipoCulto = dataQR['idTipoCulto'];
                    final String registradoPor = dataQR['registradoPor'];

                    if (!mounted) return;
                    final userProvider = Provider.of<UserProvider>(context, listen: false);
                    final matriculaEstudiante = userProvider.matricula;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Procesando asistencia...'), duration: Duration(seconds: 1)),
                    );

                    final resultado = await _asistenciaService.registrarAsistencia(
                      matriculaEstudiante: matriculaEstudiante,
                      idTipoCulto: idTipoCulto,
                      registradoPor: registradoPor,
                    );

                    if (!mounted) return;

                    if (resultado['success'] == true) { 
                      setState(() {
                        actividadSeleccionada = "Culto (ID: $idTipoCulto)"; 
                        mostrandoQR = false;
                      });
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(resultado['message']), backgroundColor: Colors.green),
                      );
                    } else {
                      _yaNotifiqueEsteCodigo = false;
                      _scannerController.start(); 
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(resultado['message']), backgroundColor: Colors.red),
                      );
                    }

                  } catch (e) {
                    print("Error al leer QR: $e");
                    _yaNotifiqueEsteCodigo = false;
                    _scannerController.start();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Código QR no válido o error de red'), backgroundColor: Colors.orange),
                      );
                    }
                  }
                },
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _roundBtn(icon: Icons.flashlight_on_outlined, onTap: () => _scannerController.toggleTorch()),
                    _roundBtn(icon: Icons.cameraswitch_outlined, onTap: () => _scannerController.switchCamera()),
                    _roundBtn(icon: Icons.close, onTap: () {
                      _scannerController.stop();
                      setState(() => mostrandoQR = false);
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Apunta al código QR para registrar tu asistencia',
          style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildConfirmacion(Color? textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.5))
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 48),
          const SizedBox(height: 12),
          Text(
            '¡Asistencia Registrada!',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.green.shade800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Actividad: $actividadSeleccionada',
            style: TextStyle(color: textColor, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () {
              setState(() {
                actividadSeleccionada = '';
                _yaNotifiqueEsteCodigo = false;
              });
            }, 
            child: const Text("Registrar otra asistencia")
          )
        ],
      ),
    );
  }

  Widget _roundBtn({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          borderRadius: BorderRadius.circular(21),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  String toTitle(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}