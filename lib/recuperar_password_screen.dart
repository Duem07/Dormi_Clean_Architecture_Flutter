import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './presentation/providers/auth_provider.dart';

class RecuperarPasswordScreen extends StatefulWidget {
  final String? correoInicial;
  const RecuperarPasswordScreen({super.key, this.correoInicial});

  @override
  State<RecuperarPasswordScreen> createState() => _RecuperarPasswordScreenState();
}

class _RecuperarPasswordScreenState extends State<RecuperarPasswordScreen> {
  final emailCtrl = TextEditingController();
  final codeCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmPassCtrl = TextEditingController();

  int _step = 0; // 0:Correo, 1:Código, 2:Nueva Pass
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    if (widget.correoInicial != null) {
      emailCtrl.text = widget.correoInicial!;
    }
  }

  void _sendCode() async {
    if (emailCtrl.text.isEmpty) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final enviado = await authProvider.sendOtpToEmail(emailCtrl.text.trim());
    
    if (enviado) {
      setState(() => _step = 1);
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Código enviado a tu correo')));
    } else {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al enviar código. Verifica el correo.')));
    }
  }

  void _verifyCode() async {
    if (codeCtrl.text.isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final valido = await authProvider.verifyOtpCode(emailCtrl.text.trim(), codeCtrl.text.trim());

    if (valido) {
      setState(() => _step = 2);
    } else {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Código incorrecto')));
    }
  }

  void _changePassword() async {
    if (passCtrl.text.isEmpty || passCtrl.text != confirmPassCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Las contraseñas no coinciden o están vacías')));
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // Este método lo agregaremos al provider a continuación
    final exito = await authProvider.resetPassword(emailCtrl.text.trim(), passCtrl.text.trim());

    if (exito) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Contraseña actualizada!')));
        Navigator.pop(context);
      }
    } else {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al actualizar contraseña')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usamos el estado de carga del Provider
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar Contraseña')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : _buildCurrentStep(),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 0: 
        return Column(
          children: [
            const Text('Ingresa tu correo institucional para recibir un código.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            TextField(
              controller: emailCtrl, 
              decoration: const InputDecoration(
                labelText: 'Correo', 
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email_outlined)
              )
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(onPressed: _sendCode, child: const Text('Enviar Código'))
            )
          ],
        );

      case 1: 
        return Column(
          children: [
            Text('Código enviado a ${emailCtrl.text}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: codeCtrl, 
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Código OTP', 
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_clock_outlined)
              )
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(onPressed: _verifyCode, child: const Text('Verificar'))
            )
          ],
        );

      case 2: 
        return Column(
          children: [
            const Text('Crea tu nueva contraseña', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: passCtrl, 
              obscureText: _obscurePass,
              decoration: InputDecoration(
                labelText: 'Nueva Contraseña', 
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscurePass = !_obscurePass),
                ),
              )
            ),
            const SizedBox(height: 15),
            TextField(
              controller: confirmPassCtrl, 
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                labelText: 'Confirmar', 
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              )
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(onPressed: _changePassword, child: const Text('Actualizar Contraseña'))
            )
          ],
        );
      default: return Container();
    }
  }
}