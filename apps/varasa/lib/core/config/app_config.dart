import 'package:firebase_core/firebase_core.dart';

abstract final class AppConfig {
  static const mode = String.fromEnvironment('APP_MODE', defaultValue: 'demo');
  static const useEmulators = bool.fromEnvironment('USE_FIREBASE_EMULATORS');
  static const emulatorHost = String.fromEnvironment(
    'FIREBASE_EMULATOR_HOST',
    defaultValue: 'localhost',
  );
  static const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const senderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const storageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
  );
  static const googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );
  static FirebaseOptions get firebaseOptions {
    if (useEmulators &&
        (!projectId.startsWith('demo-') || emulatorHost.trim().isEmpty)) {
      throw const FormatException(
        'Emulator mode requires a demo- project ID and an explicit host. See config.emulator.example.json.',
      );
    }
    if ([
      apiKey,
      appId,
      projectId,
      senderId,
      storageBucket,
    ].any((v) => v.isEmpty)) {
      throw const FormatException(
        'Firebase configuration is incomplete. Follow docs/SETUP.md, or use APP_MODE=demo.',
      );
    }
    return const FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      projectId: projectId,
      messagingSenderId: senderId,
      storageBucket: storageBucket,
      authDomain: String.fromEnvironment('FIREBASE_AUTH_DOMAIN'),
      iosBundleId: String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID'),
      iosClientId: String.fromEnvironment('FIREBASE_IOS_CLIENT_ID'),
    );
  }
}
