import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:varasa/app/varasa_app.dart';
import 'package:varasa/data/demo_repository.dart';

void main() {
  const capture = bool.fromEnvironment('CAPTURE_UI');
  testWidgets(
    'heritage screens retain navigation at phone and large text sizes',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      if (capture) {
        await tester.runAsync(() async {
          for (final entry in {
            'Itim': 'Itim-Regular.ttf',
            'CormorantGaramond': 'CormorantGaramond.ttf',
            'CinzelDecorative': 'CinzelDecorative-Regular.ttf',
          }.entries) {
            await (FontLoader(
              entry.key,
            )..addFont(rootBundle.load('assets/fonts/${entry.value}'))).load();
          }
          final sdk = Platform.environment['FLUTTER_ROOT'];
          if (sdk == null) {
            throw StateError('FLUTTER_ROOT is required for real-font captures');
          }
          final bytes = await File(
            '$sdk/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',
          ).readAsBytes();
          final icons = await File(
            '$sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
          ).readAsBytes();
          await (FontLoader(
            'MaterialIcons',
          )..addFont(Future.value(ByteData.sublistView(icons)))).load();
          await (FontLoader(
            'Roboto',
          )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
        });
      }
      final boundary = GlobalKey();
      final repo = DemoVarasaRepository();
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundary,
          child: VarasaApp(repository: repo),
        ),
      );
      await tester.pumpAndSettle();
      Future<void> snap(String name) async {
        expect(tester.takeException(), isNull);
        if (!capture) return;
        await tester.runAsync(() async {
          final context = tester.element(find.byType(MaterialApp));
          final images = tester.widgetList<Image>(find.byType(Image)).toList();
          await Future.wait(
            images.map((image) => precacheImage(image.image, context)),
          );
        });
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          final render =
              boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await render.toImage(pixelRatio: 1);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('../../.impeccable/review/$name.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }

      await snap('phone-home');
      for (final entry in {1: 'games', 3: 'heritage', 4: 'profile'}.entries) {
        await tester.tap(find.byKey(ValueKey('nav-${entry.key}')));
        await tester.pumpAndSettle();
        if (entry.key == 3) {
          await tester.tap(find.text('PAINTINGS'));
          await tester.pumpAndSettle();
          expect(find.text('Madhubani Painting'), findsOneWidget);
        }
        await snap('phone-${entry.value}');
      }
      tester.view.physicalSize = const Size(320, 640);
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      for (final i in [0, 1, 2, 3, 4]) {
        await tester.tap(find.byKey(ValueKey('nav-$i')));
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: 'Small phone, large text, tab $i',
        );
      }
      tester.platformDispatcher.textScaleFactorTestValue = 1;
      tester.view.physicalSize = const Size(1200, 900);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Community'));
      await tester.pumpAndSettle();
      await snap('desktop-home');
      tester.view.physicalSize = const Size(390, 844);
      await repo.signOut();
      await tester.pumpAndSettle();
      await snap('phone-login');
      expect(find.text('LOGIN'), findsOneWidget);
      tester.view.physicalSize = const Size(320, 500);
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('ENTER LOCAL DEMO'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
}
