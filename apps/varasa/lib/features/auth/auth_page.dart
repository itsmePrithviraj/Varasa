import 'package:flutter/material.dart';
import '../../core/widgets/common.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(),
      _email = TextEditingController(),
      _password = TextEditingController();
  bool _signup = false, _busy = false, _hidden = true;
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() => _error = errorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final repo = RepositoryScope.of(context);
    await _run(
      () => _signup
          ? repo.signUp(_name.text, _email.text, _password.text)
          : repo.signIn(_email.text, _password.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFFFD49B),
      body: LayoutBuilder(
        builder: (context, size) {
          final panelWidth = size.maxWidth.clamp(0.0, 520.0),
              naturalHeight = (panelWidth * 915 / 412).clamp(700.0, 1150.0);
          return Center(
            child: SizedBox(
              width: panelWidth,
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: size.maxHeight),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.asset(
                          'assets/images/background.jpg',
                          fit: BoxFit.fill,
                          excludeFromSemantics: true,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          panelWidth * .15,
                          naturalHeight * .31,
                          panelWidth * .15,
                          90,
                        ),
                        child: AutofillGroup(
                          child: Form(
                            key: _form,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  _signup ? 'SIGN UP' : 'LOGIN',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                    color: Color(0xFFBC2828),
                                  ),
                                ),
                                const SizedBox(height: 28),
                                if (_signup) ...[
                                  TextFormField(
                                    controller: _name,
                                    enabled: !_busy,
                                    decoration: const InputDecoration(
                                      labelText: 'Name',
                                    ),
                                    autofillHints: const [AutofillHints.name],
                                    validator: (v) =>
                                        v == null || v.trim().isEmpty
                                        ? 'Enter your name.'
                                        : null,
                                  ),
                                  const SizedBox(height: 14),
                                ],
                                TextFormField(
                                  controller: _email,
                                  enabled: !_busy && !repo.isDemo,
                                  keyboardType: TextInputType.emailAddress,
                                  autofillHints: const [AutofillHints.email],
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    hintText: repo.isDemo
                                        ? 'Not needed for local demo'
                                        : null,
                                  ),
                                  validator: (v) => repo.isDemo
                                      ? null
                                      : v == null || !v.contains('@')
                                      ? 'Enter your email.'
                                      : null,
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _password,
                                  enabled: !_busy && !repo.isDemo,
                                  obscureText: _hidden,
                                  autofillHints: const [AutofillHints.password],
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    suffixIcon: IconButton(
                                      tooltip: _hidden
                                          ? 'Show password'
                                          : 'Hide password',
                                      onPressed: repo.isDemo
                                          ? null
                                          : () => setState(
                                              () => _hidden = !_hidden,
                                            ),
                                      icon: Icon(
                                        _hidden
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                    ),
                                  ),
                                  validator: (v) => repo.isDemo
                                      ? null
                                      : v == null ||
                                            v.length < (_signup ? 8 : 1)
                                      ? 'Enter ${_signup ? 'at least 8 characters' : 'your password'}.'
                                      : null,
                                ),
                                if (!repo.isDemo)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: _busy
                                          ? null
                                          : () async {
                                              if (!_email.text.contains('@')) {
                                                setState(
                                                  () => _error =
                                                      'Enter your email first.',
                                                );
                                                return;
                                              }
                                              await _run(() async {
                                                await repo.resetPassword(
                                                  _email.text,
                                                );
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Check your email for reset instructions.',
                                                      ),
                                                    ),
                                                  );
                                                }
                                              });
                                            },
                                      child: const Text('Forgot password?'),
                                    ),
                                  ),
                                const SizedBox(height: 24),
                                FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFFBD3032),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: _busy
                                      ? null
                                      : repo.isDemo
                                      ? () => _run(() => repo.signIn('', ''))
                                      : _submit,
                                  child: Text(
                                    _busy
                                        ? 'Please wait…'
                                        : repo.isDemo
                                        ? 'ENTER LOCAL DEMO'
                                        : _signup
                                        ? 'CREATE ACCOUNT'
                                        : 'SIGN IN',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (repo.isDemo)
                                  const Text(
                                    'Preview only · Sample community\nNo sign-in required. Changes reset on restart.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF622A0F),
                                    ),
                                  )
                                else ...[
                                  TextButton(
                                    onPressed: _busy
                                        ? null
                                        : () => setState(() {
                                            _signup = !_signup;
                                            _error = null;
                                          }),
                                    child: Text(
                                      _signup
                                          ? 'Already have an account? Sign in'
                                          : 'Create an account',
                                    ),
                                  ),
                                  const Row(
                                    children: [
                                      Expanded(child: Divider()),
                                      Padding(
                                        padding: EdgeInsets.all(12),
                                        child: Text('Or continue with'),
                                      ),
                                      Expanded(child: Divider()),
                                    ],
                                  ),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: _busy
                                        ? null
                                        : () => _run(repo.signInWithGoogle),
                                    icon: Image.asset(
                                      'assets/images/google_logo.png',
                                      width: 22,
                                      height: 22,
                                    ),
                                    label: const Text('Google'),
                                  ),
                                ],
                                if (_error != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 16),
                                    child: Semantics(
                                      liveRegion: true,
                                      child: Text(
                                        _error!,
                                        style: const TextStyle(
                                          color: Color(0xFF8B1515),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
