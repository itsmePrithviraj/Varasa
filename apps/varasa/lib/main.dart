import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'app/varasa_app.dart';
import 'core/config/app_config.dart';
import 'core/theme/varasa_theme.dart';
import 'core/widgets/common.dart';
import 'data/demo_repository.dart';
import 'data/firebase_repository.dart';
import 'domain/varasa_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final VarasaRepository repository;
    switch (AppConfig.mode) {
      case 'demo':
        repository = DemoVarasaRepository();
      case 'firebase':
        await Firebase.initializeApp(options: AppConfig.firebaseOptions);
        final functions = FirebaseFunctions.instanceFor(
          region: const String.fromEnvironment(
            'FIREBASE_FUNCTIONS_REGION',
            defaultValue: 'us-central1',
          ),
        );
        if (AppConfig.useEmulators) {
          functions.useFunctionsEmulator(AppConfig.emulatorHost, 5001);
          await FirebaseAuth.instance.useAuthEmulator(
            AppConfig.emulatorHost,
            9099,
          );
          FirebaseFirestore.instance.settings = const Settings(
            persistenceEnabled: false,
          );
          FirebaseFirestore.instance.useFirestoreEmulator(
            AppConfig.emulatorHost,
            8080,
          );
          await FirebaseStorage.instance.useStorageEmulator(
            AppConfig.emulatorHost,
            9199,
          );
        }
        if (!AppConfig.useEmulators) {
          const siteKey = String.fromEnvironment('APP_CHECK_WEB_SITE_KEY');
          if (kIsWeb && siteKey.isEmpty) {
            throw const FormatException(
              'Set APP_CHECK_WEB_SITE_KEY for connected web mode. Local development can use the emulator configuration.',
            );
          }
          const debug = bool.fromEnvironment('APP_CHECK_DEBUG');
          await FirebaseAppCheck.instance.activate(
            webProvider: kIsWeb ? ReCaptchaV3Provider(siteKey) : null,
            androidProvider: debug
                ? AndroidProvider.debug
                : AndroidProvider.playIntegrity,
            appleProvider: debug
                ? AppleProvider.debug
                : AppleProvider.appAttestWithDeviceCheckFallback,
          );
        }
        repository = FirebaseVarasaRepository(
          functions: functions,
          auth: FirebaseAuth.instance,
          database: FirebaseFirestore.instance,
          storage: FirebaseStorage.instance,
        );
      default:
        throw const FormatException('APP_MODE must be demo or firebase.');
    }
    runApp(VarasaApp(repository: repository));
  } catch (error) {
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: VarasaTheme.light,
        home: Scaffold(
          body: SafeArea(
            child: ContentWidth(
              child: EmptyState(
                title: 'Let’s finish setting up Varasa',
                message:
                    '${errorMessage(error)}\n\nOpen docs/SETUP.md in the project for configuration steps.',
                action: FilledButton(
                  onPressed: () =>
                      runApp(VarasaApp(repository: DemoVarasaRepository())),
                  child: const Text('Explore the local demo'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
