import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:gestion_dormitorios/core/config/api_config.dart';
import 'package:gestion_dormitorios/services/limpieza_service.dart';
import 'package:gestion_dormitorios/providers/user_provider.dart'; // Necesario para sacar la matrícula
import 'package:gestion_dormitorios/grafico_estadisticas.dart';

class EstadisticasPreceptorScreen extends StatefulWidget {
  const EstadisticasPreceptorScreen({super.key});

  @override
  State<EstadisticasPreceptorScreen> createState() => _EstadisticasPreceptorScreenState();
}

class _EstadisticasPreceptorScreenState extends State<EstadisticasPreceptorScreen> {
  final _limpiezaService = LimpiezaService();
  bool _isLoading = true;
  List<dynamic> _datosEnCurso = [];
  String _fechaUltimoCorte = "";

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    // El preceptor ve lo que está "En Curso" (Live)
    final resultado = await _limpiezaService.obtenerEstadisticas();
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (resultado['success'] == true) {
          _datosEnCurso = resultado['data']['enCurso'] ?? [];
          _fechaUltimoCorte = resultado['data']['ultimoCorte'] ?? "";
        }
      });
    }
  }

  // --- 1. ACCIÓN: CERRAR MES (Manual) ---
  Future<void> _hacerCorteMensual() async {
    final user = Provider.of<UserProvider>(context, listen: false);
    
    final confirma = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("✂️ Cerrar Periodo Mensual"),
        content: const Text(
          "Al hacer esto:\n\n"
          "1. Se publicarán las calificaciones actuales.\n"
          "2. La gráfica se reiniciará a CERO para el nuevo mes.\n\n"
          "¿Confirmar cierre de mes?"
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text("SÍ, REINICIAR MES"),
          ),
        ],
      ),
    );

    if (confirma == true) {
      setState(() => _isLoading = true);
      final exito = await _limpiezaService.realizarCorte(user.usuarioID);
      if (exito && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Mes cerrado! Nueva estadística iniciada.')));
        _cargarDatos(); 
      }
    }
  }

  // --- 2. ACCIÓN: CERRAR SEMESTRE (Fin de Ciclo) ---
  final _nombreSemestreCtrl = TextEditingController();

  void _cerrarSemestreCompleto() async {
    _nombreSemestreCtrl.clear();
    bool confirmar = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ FIN DE CICLO ESCOLAR'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Esta acción VACIARÁ TODOS LOS CUARTOS.', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text('Úsalo solo al final del semestre.'),
            const SizedBox(height: 15),
            TextField(
              controller: _nombreSemestreCtrl,
              decoration: const InputDecoration(labelText: 'Nombre Nuevo Semestre (Ej: 2026-B)', border: OutlineInputBorder()),
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
               if (_nombreSemestreCtrl.text.isEmpty) return;
               Navigator.pop(context, true);
            },
            child: const Text('BORRAR Y REINICIAR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirmar) return;

    // Llamada directa al endpoint de configuración
    try {
      setState(() => _isLoading = true);
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/configuracion/cerrar-semestre'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'nombreNuevoSemestre': _nombreSemestreCtrl.text.trim()}),
      );
      if (response.statusCode == 200 && mounted) {
         _cargarDatos();
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ciclo escolar reiniciado.')));
      }
    } catch (e) {
      print(e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Periodo')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Info del periodo actual
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                child: Text("Estadística actual iniciada el:\n${_fechaUltimoCorte.split('T')[0]}", 
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.blue[900])),
              ),
              const SizedBox(height: 20),

              // GRÁFICA (Se reinicia cada vez que cortas mes)
              GraficoPasillos(
                datos: _datosEnCurso,
                titulo: "Periodo En Curso",
                subTitulo: "Acumulado desde el último corte manual.",
                esVacio: _datosEnCurso.isEmpty,
              ),

              const SizedBox(height: 40),
              const Divider(),
              const Text("Acciones de Gestión", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),

              // BOTÓN 1: CERRAR MES (Rutina)
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.cut),
                  label: const Text("CERRAR MES (REINICIAR GRÁFICA)"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                  onPressed: _hacerCorteMensual,
                ),
              ),
              
              const SizedBox(height: 15),

              // BOTÓN 2: CERRAR SEMESTRE (Peligro)
              SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.warning_amber_rounded, color: Colors.red),
                  label: const Text("FIN DE CICLO (VACIAR CUARTOS)", style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                  onPressed: _cerrarSemestreCompleto,
                ),
              ),
            ],
          ),
    );
  }
}