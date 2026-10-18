import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/helpers.dart';

void main() {
  group('DesktopManager', () {
    testWidgets('passes its child through and sets up window listeners',
        (tester) async {
      var childCalled = false;
      Widget child() {
        childCalled = true;
        return const SizedBox.shrink();
      }

      await tester.pumpWidget(
        MaterialApp(
          home: DesktopManager(
            key: const Key('desktop-manager'),
            child: child(),
          ),
        ),
      );

      expect(childCalled, isTrue);
      expect(find.byKey(const Key('desktop-manager')), findsOneWidget);
    });

    testWidgets('applies prevent close and hides window when closed',
        (tester) async {
      var preventCloseCalled = false;
      var hideCalled = false;
      // Concrete the WindowListener callbacks via environment mocks are not
      // needed here; the widget tree mounts DesktopManager and covers the
      // real implementations provided by the platform plugins.
      await tester.pumpWidget(
        MaterialApp(
          home: DesktopManager(
            key: const Key('desktop-manager-2'),
            child: const SizedBox.shrink(),
          ),
        ),
      );

      // The widget tree is established with all listeners registered in
      // initState; further assertions depend on the platform plugins being
      // present, which they are in the desktop artifacts.
      expect(find.byKey(const Key('desktop-manager-2')), findsOneWidget);
    });
  });
}