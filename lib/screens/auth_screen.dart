import 'package:flutter/material.dart';
import '../state.dart';
import '../theme.dart';
import '../space_theme.dart';

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
  bool hidePass = true;

  @override
  void dispose() {
    email.dispose();
    user.dispose();
    name.dispose();
    pass.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    final mail = email.text.trim();
    final pwd = pass.text;
    if (register) {
      if (!mail.contains('@')) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usa un email válido.')));
        return;
      }
      if (user.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Elegí un nombre de usuario.')));
        return;
      }
      if (pwd.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La contraseña debe tener al menos 6 caracteres.')));
        return;
      }
    } else if (mail.isEmpty && user.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Escribe tu email o usuario.')));
      return;
    } else if (pwd.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Escribe tu contraseña.')));
      return;
    }
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
            const SizedBox(height: 24),
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: SpaceColors.text, width: 1.2)),
                child: Icon(Icons.auto_awesome, color: SpaceColors.text, size: 34),
              ),
            ),
            const SizedBox(height: 16),
            Text('Space Social', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'GrandHotel', fontSize: 52, color: SpaceColors.text, height: 1)),
            const SizedBox(height: 6),
            Text('Comparte lo que te hace brillar.', textAlign: TextAlign.center, style: TextStyle(color: SpaceColors.textMuted, fontSize: 13)),
            const SizedBox(height: 32),
            _field(email, register ? 'Correo' : 'Correo, usuario o teléfono'),
            if (register) _field(user, 'Nombre de usuario'),
            if (register) _field(name, 'Nombre'),
            _field(pass, 'Contraseña', hide: hidePass, onToggle: () => setState(() => hidePass = !hidePass)),
            const SizedBox(height: 12),
            SizedBox(
              height: 44,
              child: FilledButton(
                onPressed: busy ? null : _go,
                style: FilledButton.styleFrom(backgroundColor: LumaColors.blue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: busy
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(register ? 'Registrarte' : 'Entrar'),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: busy
                    ? null
                    : () async {
                        final ok = await widget.state.sendReset(email.text.isEmpty ? user.text : email.text);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(ok ? 'Te enviamos un mail para cambiar la clave' : (widget.state.lastError ?? 'No se pudo enviar')),
                        ));
                      },
                child: Text('¿Olvidaste tu contraseña?', style: TextStyle(color: SpaceColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(child: Divider(color: SpaceColors.hairline)),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('O', style: TextStyle(color: SpaceColors.textMuted, fontWeight: FontWeight.w700, fontSize: 12))),
              Expanded(child: Divider(color: SpaceColors.hairline)),
            ]),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => setState(() => register = !register),
              child: Text(register ? '¿Tenés una cuenta? Iniciá sesión' : '¿No tenés una cuenta? Registrate', style: const TextStyle(color: Color(0xFF0095F6), fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String hint, {bool hide = false, VoidCallback? onToggle}) {
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
          fillColor: SpaceColors.chip,
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: SpaceColors.hairline)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: SpaceColors.textMuted)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: SpaceColors.hairline)),
          suffixIcon: onToggle == null
              ? null
              : IconButton(
                  icon: Icon(hide ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: SpaceColors.textMuted, size: 20),
                  onPressed: onToggle,
                ),
        ),
      ),
    );
  }
}
