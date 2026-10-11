import 'package:cloud_functions/cloud_functions.dart';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/varasa_repository.dart';
import '../theme/varasa_theme.dart';
import '../config/app_config.dart';

class RepositoryScope extends InheritedWidget {
  const RepositoryScope({
    super.key,
    required this.repository,
    required super.child,
  });
  final VarasaRepository repository;
  static VarasaRepository of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RepositoryScope>()!.repository;
  @override
  bool updateShouldNotify(RepositoryScope oldWidget) =>
      oldWidget.repository != repository;
}

String errorMessage(Object error) {
  if (error is FirebaseFunctionsException &&
      [
        'invalid-argument',
        'already-exists',
        'failed-precondition',
        'not-found',
        'resource-exhausted',
        'permission-denied',
      ].contains(error.code)) {
    return error.message ?? 'This action is unavailable. Please try again.';
  }
  if (error is FirebaseException) {
    return switch (error.code) {
      'invalid-credential' || 'wrong-password' || 'user-not-found' =>
        'The email or password didn’t match. Please try again.',
      'email-already-in-use' =>
        'This email already has an account. Sign in or reset your password.',
      'weak-password' =>
        'Choose a stronger password with at least 8 characters.',
      'invalid-email' => 'Enter a valid email address.',
      'network-request-failed' || 'unavailable' =>
        'We couldn’t connect. Check your connection and try again.',
      'permission-denied' || 'unauthorized' =>
        'This action isn’t allowed. Check your sign-in and the Firebase setup guide.',
      'failed-precondition' =>
        'The backend needs configuration. Check the indexes in docs/SETUP.md.',
      'too-many-requests' =>
        'Too many attempts. Please wait a little and try again.',
      'popup-closed-by-user' ||
      'cancelled-popup-request' => 'Sign-in was cancelled. You can try again.',
      _ => 'Something went wrong (${error.code}). Please try again.',
    };
  }
  if (error is FormatException) return error.message;
  if (error is StateError) return error.message.toString();
  return 'Something went wrong. Please try again.';
}

void showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(errorMessage(error))));
}

class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child, this.maxWidth = 760});
  final Widget child;
  final double maxWidth;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.auto_stories_outlined,
    this.action,
  });
  final String title, message;
  final IconData icon;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          if (action != null) ...[const SizedBox(height: 20), action!],
        ],
      ),
    ),
  );
}

class AsyncState<T> extends StatelessWidget {
  const AsyncState({super.key, required this.snapshot, required this.builder});
  final AsyncSnapshot<T> snapshot;
  final Widget Function(T) builder;
  @override
  Widget build(BuildContext context) {
    if (snapshot.hasError) {
      return EmptyState(
        title: 'Couldn’t load this yet',
        message: errorMessage(snapshot.error!),
        icon: Icons.wifi_off_outlined,
      );
    }
    if (!snapshot.hasData) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }
    return builder(snapshot.data as T);
  }
}

class HeritageImage extends StatelessWidget {
  const HeritageImage(
    this.source, {
    super.key,
    this.height,
    this.fit = BoxFit.cover,
  });
  final String source;
  final double? height;
  final BoxFit fit;
  @override
  Widget build(BuildContext context) {
    Widget fallback() => Container(
      height: height ?? 180,
      color: VarasaTheme.parchment,
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_not_supported_outlined,
        semanticLabel: 'Image unavailable',
      ),
    );
    if (source.isEmpty) return fallback();
    if (source.startsWith('assets/')) {
      return Image.asset(
        source,
        height: height,
        width: double.infinity,
        fit: fit,
        errorBuilder: (_, __, ___) => fallback(),
      );
    }
    if (source.startsWith('data:image/')) {
      try {
        return Image.memory(
          base64Decode(source.split(',').last),
          height: height,
          width: double.infinity,
          fit: fit,
          errorBuilder: (_, __, ___) => fallback(),
        );
      } catch (_) {
        return fallback();
      }
    }
    final uri = Uri.tryParse(source);
    if (uri == null || !isAllowedMediaUri(uri)) return fallback();
    return Image.network(
      source,
      height: height,
      width: double.infinity,
      fit: fit,
      errorBuilder: (_, __, ___) => fallback(),
      loadingBuilder: (_, child, progress) => progress == null
          ? child
          : SizedBox(
              height: height ?? 180,
              child: const Center(child: CircularProgressIndicator()),
            ),
    );
  }
}

Future<void> openExternal(BuildContext context, String value) async {
  final uri = Uri.tryParse(value);
  if (uri == null || !isAllowedMediaUri(uri) || uri.host.isEmpty) {
    showError(
      context,
      StateError(
        'This attachment is available only in this demo session. Publish in connected mode to get a shareable file.',
      ),
    );
    return;
  }
  try {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        context.mounted) {
      showError(context, StateError('Couldn’t open this link on your device.'));
    }
  } catch (e) {
    if (context.mounted) showError(context, e);
  }
}

/// HTTP is allowed only for the explicitly configured local Storage emulator.
bool isAllowedMediaUri(Uri uri) =>
    uri.scheme == 'https' ||
    (AppConfig.useEmulators &&
        uri.scheme == 'http' &&
        uri.port == 9199 &&
        (uri.host == AppConfig.emulatorHost ||
            AppConfig.emulatorHost == 'localhost' && uri.host == '127.0.0.1'));

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, required this.source, this.radius = 20});
  final String source;
  final double radius;
  @override
  Widget build(BuildContext context) => source.isEmpty
      ? CircleAvatar(
          radius: radius,
          child: Icon(Icons.person_outline, size: radius),
        )
      : ClipOval(
          child: SizedBox.square(
            dimension: radius * 2,
            child: HeritageImage(source),
          ),
        );
}
