import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_state.dart';
import '../widgets/glass.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _signup = false;
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    return Scaffold(
      backgroundColor: C.bg1,
      body: AuroraBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: GlassCard(
                padding: const EdgeInsets.all(22),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('🏋️', style: TextStyle(fontSize: 42)),
                  const SizedBox(height: 10),
                  Text('DesiFit', style: t(30, w: FontWeight.w800)),
                  Text(_signup ? 'Create your account' : 'Welcome back', style: t(14, color: C.textDim)),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(22)),
                    child: Row(children: [
                      Expanded(child: _modeChip('Sign in', !_signup, () => setState(() => _signup = false))),
                      Expanded(child: _modeChip('Sign up', _signup, () => setState(() => _signup = true))),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  if (_signup) ...[
                    GlassField(controller: _name, hint: 'Your name', icon: Icons.person_outline_rounded),
                    const SizedBox(height: 10),
                  ],
                  GlassField(controller: _email, hint: 'Email address', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 10),
                  GlassField(controller: _password, hint: 'Password (min. 8 characters)', icon: Icons.lock_outline_rounded, obscureText: true),
                  if (auth.error != null) ...[
                    const SizedBox(height: 12),
                    Text(auth.error!, textAlign: TextAlign.center, style: t(13, color: C.flame)),
                  ],
                  const SizedBox(height: 18),
                  LiquidButton(
                    label: auth.busy ? 'Please wait...' : (_signup ? 'Create account' : 'Sign in'),
                    icon: Icons.arrow_forward_rounded,
                    onTap: auth.busy ? null : _submit,
                  ),
                  const SizedBox(height: 14),
                  Row(children: [Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.2))), Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text('OR', style: t(11, color: C.textFaint))), Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.2)))]),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: auth.busy ? null : auth.signInWithGoogle,
                      icon: const Text('G', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                      label: const Text('Continue with Google'),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(auth.backendOnline ? Icons.cloud_done_rounded : Icons.cloud_off_rounded, size: 16, color: auth.backendOnline ? C.mint : C.flame),
                    const SizedBox(width: 6),
                    Text(auth.backendOnline ? 'Backend connected' : 'Backend offline', style: t(12, color: auth.backendOnline ? C.mint : C.flame)),
                  ]),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _modeChip(String label, bool selected, VoidCallback onTap) => Pressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(gradient: selected ? C.heroGradient : null, borderRadius: BorderRadius.circular(18)),
          child: Text(label, textAlign: TextAlign.center, style: t(13, w: FontWeight.w700, color: selected ? Colors.white : C.textDim)),
        ),
      );

  Future<void> _submit() async {
    final auth = context.read<AuthState>();
    if (_signup) {
      await auth.register(name: _name.text.trim(), email: _email.text.trim(), password: _password.text);
    } else {
      await auth.login(email: _email.text.trim(), password: _password.text);
    }
  }
}
