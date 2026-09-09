import 'package:flutter/material.dart';
import '../state.dart';
import '../theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.state});
  final AppState state;
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final email = TextEditingController();
  final user = TextEditingController();
  final name = TextEditingController();
  final pass = TextEditingController();
  bool register = false;
  bool busy = false;

  @override
  void dispose() {
    email.dispose();
    user.dispose();
    name.dispose();
    pass.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    setState(() => busy = true);
    final ok = register
        ? await widget.state.register(email: email.text, username: user.text, name: name.text, password: pass.text)
        : await widget.state.login(userOrEmail: email.text.isEmpty ? user.text : email.text, password: pass.text);
    if (mounted) {
      setState(() => busy = false);
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.state.lastError ?? 'No se pudo entrar')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SpaceColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          children: [
            const SizedBox(height: 48),
            Text('Space Social', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'GrandHotel', fontSize: 48, color: SpaceColors.text)),
            const SizedBox(height: 36),
            _field(email, register ? 'Correo' : 'Correo, usuario o teléfono'),
            if (register) _field(user, 'Nombre de usuario'),
            if (register) _field(name, 'Nombre'),
            _field(pass, 'Contraseña', hide: true),
            const SizedBox(height: 12),
            SizedBox(
              height: 44,
              child: FilledButton(
                onPressed: busy ? null : _go,
                style: FilledButton.styleFrom(backgroundColor: LumaColors.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: busy
                    ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: SpaceColors.text))
                    : Text(register ? 'Registrarte' : 'Entrar'),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => register = !register),
              child: Text(register ? '¿Tenés cuenta? Iniciá sesión' : '¿No tenés cuenta? Registrate', style: TextStyle(color: SpaceColors.textMuted)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String hint, {bool hide = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        obscureText: hide,
        style: TextStyle(color: SpaceColors.text),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: SpaceColors.textMuted),
          filled: true,
          fillColor: const Color(0xFF1C1C1C),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF8E8E8E))),
        ),
      ),
    );
  }
}
