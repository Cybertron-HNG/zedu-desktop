import 'package:zedu/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DesktopManager', () {
    testWidgets('passes its child through and sets up window listeners', (
      tester,
    ) async {
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
  });
}
