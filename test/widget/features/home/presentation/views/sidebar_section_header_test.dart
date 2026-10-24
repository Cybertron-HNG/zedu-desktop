import 'package:flutter/rendering.dart';
import 'package:zedu/features/features.dart';
import '../../../../../helpers/helpers.dart';

Widget _build({required bool expanded, required VoidCallback onToggle}) {
  return buildTestMaterialApp(
    Scaffold(
      body: SidebarSectionHeader(
        label: 'Channels',
        expanded: expanded,
        onToggle: onToggle,
      ),
    ),
  );
}

double _turns(WidgetTester tester) =>
    tester.widget<AnimatedRotation>(find.byType(AnimatedRotation)).turns;

void main() {
  testWidgets('shows the section label', (tester) async {
    await tester.pumpWidget(_build(expanded: true, onToggle: () {}));

    expect(find.text('Channels'), findsOneWidget);
  });

  testWidgets('calls onToggle once per tap on the label', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_build(expanded: true, onToggle: () => taps++));

    await tester.tap(find.text('Channels'));

    expect(taps, 1);
  });

  testWidgets('calls onToggle when the arrow itself is tapped', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_build(expanded: true, onToggle: () => taps++));

    await tester.tap(find.byIcon(Icons.arrow_drop_down));

    expect(taps, 1);
  });

  testWidgets('arrow points down when expanded', (tester) async {
    await tester.pumpWidget(_build(expanded: true, onToggle: () {}));

    expect(_turns(tester), 0.0);
  });

  testWidgets('arrow points right when collapsed', (tester) async {
    await tester.pumpWidget(_build(expanded: false, onToggle: () {}));

    expect(_turns(tester), -0.25);
  });

  testWidgets('arrow animates to the new state when expanded changes', (
    tester,
  ) async {
    await tester.pumpWidget(_build(expanded: true, onToggle: () {}));
    await tester.pumpWidget(_build(expanded: false, onToggle: () {}));
    await tester.pumpAndSettle();

    expect(_turns(tester), -0.25);
  });

  testWidgets('uses the same arrow icon whatever the state', (tester) async {
    await tester.pumpWidget(_build(expanded: false, onToggle: () {}));

    expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
    expect(find.byIcon(Icons.arrow_right), findsNothing);
  });

  testWidgets('exposes button semantics with the expanded state', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_build(expanded: true, onToggle: () {}));

    expect(
      tester.getSemantics(find.byType(SidebarSectionHeader)),
      matchesSemantics(
        label: 'Channels',
        isButton: true,
        isExpanded: true,
        hasExpandedState: true,
        hasTapAction: true,
        hasFocusAction: true,
        isFocusable: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('shows a click cursor on hover', (tester) async {
    await tester.pumpWidget(_build(expanded: true, onToggle: () {}));

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.text('Channels')));
    await tester.pump();

    expect(
      // TestGesture's default pointer id is 1.
      RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
      SystemMouseCursors.click,
    );
  });
}
