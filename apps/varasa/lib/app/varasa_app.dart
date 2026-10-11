import '../domain/models.dart';
import '../features/account/account_page.dart';
import 'package:flutter/material.dart';
import '../core/theme/varasa_theme.dart';
import '../core/widgets/common.dart';
import '../domain/varasa_repository.dart';
import '../features/auth/auth_page.dart';
import 'varasa_shell.dart';

class VarasaApp extends StatefulWidget {
  const VarasaApp({super.key, required this.repository});
  final VarasaRepository repository;
  @override
  State<VarasaApp> createState() => _VarasaAppState();
}

class _VarasaAppState extends State<VarasaApp> {
  late final _session = widget.repository.watchSession();
  @override
  void dispose() {
    widget.repository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepositoryScope(
    repository: widget.repository,
    child: StreamBuilder<String?>(
      stream: _session,
      builder: (context, snapshot) {
        // Replacing the navigator on session changes clears private routes after sign-out.
        return MaterialApp(
          key: ValueKey(snapshot.data),
          title: 'Varasa',
          debugShowCheckedModeBanner: false,
          theme: VarasaTheme.light,
          home: snapshot.hasError
              ? Scaffold(
                  body: EmptyState(
                    title: 'Sign-in is unavailable',
                    message: errorMessage(snapshot.error!),
                  ),
                )
              : snapshot.connectionState == ConnectionState.waiting
              ? const Scaffold(body: Center(child: CircularProgressIndicator()))
              : snapshot.data == null
              ? const AuthPage()
              : _ProfileGate(repository: widget.repository),
        );
      },
    ),
  );
}

class _ProfileGate extends StatefulWidget {
  const _ProfileGate({required this.repository});
  final VarasaRepository repository;
  @override
  State<_ProfileGate> createState() => _ProfileGateState();
}

class _ProfileGateState extends State<_ProfileGate> {
  late Future<void> _ready = widget.repository.ensureProfile();
  Stream<Profile>? _profile;
  Widget _restricted(String title, String message) => Scaffold(
    appBar: AppBar(title: const Text('Your Varasa account')),
    body: SafeArea(
      child: SingleChildScrollView(
        child: EmptyState(
          title: title,
          message: message,
          action: Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: () => setState(() {
                  _ready = widget.repository.ensureProfile();
                  _profile = null;
                }),
                child: const Text('Retry'),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const AccountPage()),
                ),
                child: const Text('Your account & data'),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    await widget.repository.signOut();
                  } catch (e) {
                    if (mounted) showError(context, e);
                  }
                },
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: _ready,
    builder: (context, ready) {
      if (ready.hasError) {
        return _restricted(
          'Your profile is unavailable',
          errorMessage(ready.error!),
        );
      }
      if (ready.connectionState != ConnectionState.done) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      _profile ??= widget.repository.watchProfile(
        widget.repository.currentUserId!,
      );
      return StreamBuilder<Profile>(
        stream: _profile,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _restricted(
              'Your profile is unavailable',
              errorMessage(snapshot.error!),
            );
          }
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.data!.suspended) {
            return _restricted(
              'Your profile is suspended',
              'Community actions are unavailable. You can still export your data, delete your account or sign out.',
            );
          }
          return const VarasaShell();
        },
      );
    },
  );
}
