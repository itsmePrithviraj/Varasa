import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:varasa/app/varasa_app.dart';
import 'package:varasa/data/demo_repository.dart';
import 'package:varasa/domain/models.dart';
import 'package:varasa/core/widgets/heritage_chrome.dart';

void main() {
  testWidgets(
    'phone demo can publish, discuss, accept a friend and find data export',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = DemoVarasaRepository();
      await tester.pumpWidget(VarasaApp(repository: repo));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 10),
      );
      expect(find.text('All Posts'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('nav-2')));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 10),
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Tell the story'),
        'A family festival memory',
      );
      await tester.scrollUntilVisible(
        find.text('Share with the community'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 10),
      );
      await tester.ensureVisible(find.text('Share with the community'));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 10),
      );
      await tester.tap(find.text('Share with the community'));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 10),
      );
      expect(
        (await repo.fetchPosts()).items.first.caption,
        'A family festival memory',
      );
      expect(find.text('A family festival memory'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('nav-4')));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 10),
      );
      await tester.scrollUntilVisible(
        find.text('Community & account'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Community & account'));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 10),
      );
      await tester.scrollUntilVisible(
        find.text('Friend requests'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 10),
      );
      await tester.tap(find.text('Friend requests'));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 10),
      );
      await tester.tap(find.text('Accept'));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 10),
      );
      final friends = await repo.fetchPeople('friends');
      expect(friends.items.map((p) => p.id), contains('demo-arjun'));
      await tester.pageBack();
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 10),
      );
      await tester.scrollUntilVisible(
        find.text('Your account & data'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 10),
      );
      await tester.tap(find.text('Your account & data'));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 10),
      );
      await tester.tap(find.text('Export my data'));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 10),
      );
      await tester.tap(find.text('Prepare export'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.text('Files'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 10),
      );
    },
  );
  testWidgets(
    'wide rail falls back on short windows and large text without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = DemoVarasaRepository();
      await repo.publish(const PostDraft(caption: 'A short story'));
      await tester.pumpWidget(VarasaApp(repository: repo));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 10),
      );
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(tester.takeException(), isNull);
      tester.view.physicalSize = const Size(1100, 450);
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 10),
      );
      expect(find.byType(HeritageNavigation), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 10),
      );
    },
  );
}
