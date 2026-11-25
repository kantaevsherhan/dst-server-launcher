import 'package:dst_server_launcher/app/theme.dart';
import 'package:dst_server_launcher/features/woodland_atmosphere.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Pointer and keyboard keep the button action and motion preference',
    (tester) async {
      var taps = 0;
      var reduced = false;
      final focus = FocusNode();
      addTearDown(focus.dispose);
      Future<void> show() => tester.pumpWidget(
        MaterialApp(
          theme: launcherTheme(),
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduced),
            child: Scaffold(
              body: Center(
                child: FilledButton(
                  focusNode: focus,
                  onPressed: () => taps++,
                  child: const Text('Create'),
                ),
              ),
            ),
          ),
        ),
      );
      await show();
      final button = find.byType(FilledButton);
      double scale() => tester
          .widget<AnimatedScale>(
            find.descendant(of: button, matching: find.byType(AnimatedScale)),
          )
          .scale;
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer();
      await mouse.moveTo(tester.getCenter(button));
      await tester.pumpAndSettle();
      expect(scale(), greaterThan(1));
      await mouse.down(tester.getCenter(button));
      await tester.pump();
      expect(scale(), lessThan(1));
      await mouse.up();
      await tester.pumpAndSettle();
      expect(taps, 1);
      focus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(taps, 2);
      reduced = true;
      await show();
      await tester.pumpAndSettle();
      expect(scale(), 1);
      await mouse.removePointer();
    },
  );

  testWidgets(
    'Forest breeze settles, replays on hover and respects reduced motion',
    (tester) async {
      Future<void> show(bool reduced) => tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: const Center(
            child: SizedBox(
              width: 300,
              height: 100,
              child: WoodlandAtmosphere(),
            ),
          ),
        ),
      );
      await show(false);
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pump(const Duration(seconds: 5));
      expect(tester.hasRunningAnimations, isFalse);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer();
      await mouse.moveTo(tester.getCenter(find.byType(WoodlandAtmosphere)));
      await tester.pump();
      expect(tester.hasRunningAnimations, isTrue);
      await show(true);
      expect(tester.hasRunningAnimations, isFalse);
      await mouse.removePointer();
    },
  );
}
