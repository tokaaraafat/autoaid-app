import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models.dart';
import '../../core/utils.dart';
import '../../services/app_state.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  UserRole _role = UserRole.customer;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final navigator = Navigator.of(context);
    try {
      await context.read<AppState>().register(
            name: _name.text,
            phone: _phone.text,
            email: _email.text,
            password: _password.text,
            role: _role,
          );
      // AuthGate switches screens automatically; close this one.
      navigator.popUntil((route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      if (mounted) showMessage(context, e.message ?? e.code);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                SegmentedButton<UserRole>(
                  segments: const [
                    ButtonSegment(
                        value: UserRole.customer,
                        icon: Icon(Icons.directions_car),
                        label: Text('I need help')),
                    ButtonSegment(
                        value: UserRole.provider,
                        icon: Icon(Icons.build),
                        label: Text('I am a provider')),
                  ],
                  selected: {_role},
                  onSelectionChanged: (s) => setState(() => _role = s.first),
                ),
                if (_role == UserRole.provider)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      'Provider accounts must be verified by an administrator '
                      'before they can accept requests.',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                      labelText: 'Full name', border: OutlineInputBorder()),
                  validator: requiredField,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                      labelText: 'Phone number', border: OutlineInputBorder()),
                  validator: requiredField,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                      labelText: 'Email', border: OutlineInputBorder()),
                  validator: requiredField,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: 'Password (min 6 characters)',
                      border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.length < 6)
                      ? 'At least 6 characters'
                      : null,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Sign up'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
