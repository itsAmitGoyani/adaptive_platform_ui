import 'package:adaptive_platform_ui/src/widgets/ios26/route_settled_offstage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const Key _first = ValueKey<String>('first');
const Key _second = ValueKey<String>('second');

Widget _page(Key gateKey) => Scaffold(
  body: Center(
    child: RouteSettledOffstage(
      key: gateKey,
      child: const SizedBox(width: 100, height: 40),
    ),
  ),
);

/// Whether the gate with [gateKey] leaves its child out of the frame.
bool _hidden(WidgetTester tester, Key gateKey) {
  final Finder offstage = find.descendant(
    of: find.byKey(gateKey, skipOffstage: false),
    matching: find.byType(Offstage, skipOffstage: false),
  );
  return tester.widget<Offstage>(offstage.first).offstage;
}

Future<void> _pumpFirstPage(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(platform: TargetPlatform.iOS),
      home: _page(_first),
    ),
  );
}

NavigatorState _navigator(WidgetTester tester) =>
    tester.state<NavigatorState>(find.byType(Navigator));

void main() {
  group('RouteSettledOffstage', () {
    testWidgets('shows the child on a route that stands still', (
      WidgetTester tester,
    ) async {
      await _pumpFirstPage(tester);

      expect(_hidden(tester, _first), isFalse);
    });

    testWidgets('a push hides both pages\' children until it ends', (
      WidgetTester tester,
    ) async {
      await _pumpFirstPage(tester);

      _navigator(
        tester,
      ).push(CupertinoPageRoute<void>(builder: (_) => _page(_second)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(_hidden(tester, _first), isTrue);
      expect(_hidden(tester, _second), isTrue);

      await tester.pumpAndSettle();

      expect(_hidden(tester, _second), isFalse);
    });

    testWidgets('a pop hides both children, then the page below shows it', (
      WidgetTester tester,
    ) async {
      await _pumpFirstPage(tester);
      _navigator(
        tester,
      ).push(CupertinoPageRoute<void>(builder: (_) => _page(_second)));
      await tester.pumpAndSettle();

      _navigator(tester).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(_hidden(tester, _first), isTrue);
      expect(_hidden(tester, _second), isTrue);

      await tester.pumpAndSettle();

      expect(_hidden(tester, _first), isFalse);
    });

    testWidgets('a back swipe hides both children while the finger moves', (
      WidgetTester tester,
    ) async {
      await _pumpFirstPage(tester);
      _navigator(
        tester,
      ).push(CupertinoPageRoute<void>(builder: (_) => _page(_second)));
      await tester.pumpAndSettle();

      final TestGesture gesture = await tester.startGesture(
        const Offset(5, 300),
      );
      await gesture.moveBy(const Offset(120, 0));
      await tester.pump();

      expect(_hidden(tester, _first), isTrue);
      expect(_hidden(tester, _second), isTrue);

      // A short swipe springs back: the top page stands still again.
      await gesture.up();
      await tester.pumpAndSettle();

      expect(_hidden(tester, _second), isFalse);
    });

    testWidgets('a dialog above the page keeps the child', (
      WidgetTester tester,
    ) async {
      await _pumpFirstPage(tester);

      showDialog<void>(
        context: tester.element(find.byKey(_first)),
        builder: (_) => const AlertDialog(content: Text('Leave?')),
      );
      await tester.pumpAndSettle();

      expect(_hidden(tester, _first), isFalse);
    });
  });
}
