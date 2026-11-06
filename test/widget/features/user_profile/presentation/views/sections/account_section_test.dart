import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../../helpers/helpers.dart';

Future<void> _pump(WidgetTester tester, ProfileAccount account) async {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      child: buildTestMaterialApp(
        Scaffold(
          body: SingleChildScrollView(
            child: AccountSection(
              account: account,
              isSaving: false,
              onSave: (_) {},
              onDelete: () async {},
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  const account = ProfileAccount(
    name: 'Ada Lovelace',
    email: 'ada@zedu.test',
    timezone: 'Africa/Lagos',
  );

  testWidgets('shows the initials when there is no avatar', (tester) async {
    await _pump(tester, account);

    expect(find.text('AL'), findsOneWidget);
    expect(find.byIcon(Icons.person), findsNothing);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('shows the avatar when there is one', (tester) async {
    await _pump(
      tester,
      account.copyWith(avatarUrl: 'https://cdn.zedu.test/ada.png'),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as NetworkImage).url, 'https://cdn.zedu.test/ada.png');
    expect(find.text('AL'), findsNothing);
  });

  testWidgets('shows the initials when the avatar fails to load', (
    tester,
  ) async {
    await _pump(
      tester,
      account.copyWith(avatarUrl: 'https://cdn.zedu.test/broken.png'),
    );

    final image = tester.widget<Image>(find.byType(Image));
    final fallback = image.errorBuilder!(
      tester.element(find.byType(Image)),
      Exception('404'),
      null,
    );
    await tester.pumpWidget(buildTestMaterialApp(Scaffold(body: fallback)));

    expect(find.text('AL'), findsOneWidget);
  });

  testWidgets('treats a blank avatar link as no avatar', (tester) async {
    await _pump(tester, account.copyWith(avatarUrl: '   '));

    expect(find.text('AL'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('shows the saved username as the handle', (tester) async {
    await _pump(tester, account.copyWith(username: 'CountessAda'));

    expect(find.text('@CountessAda'), findsOneWidget);
    expect(find.text('@adalovelace'), findsNothing);
  });

  testWidgets('trims the saved username', (tester) async {
    await _pump(tester, account.copyWith(username: '  ada_l '));

    expect(find.text('@ada_l'), findsOneWidget);
  });

  testWidgets('falls back to the name when there is no username', (
    tester,
  ) async {
    await _pump(tester, account);

    expect(find.text('@adalovelace'), findsOneWidget);
  });

  testWidgets('falls back to the name for a blank username', (tester) async {
    await _pump(tester, account.copyWith(username: '   '));

    expect(find.text('@adalovelace'), findsOneWidget);
  });

  testWidgets('the Reduce motion switch turns it on', (tester) async {
    await _pump(tester, account);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(AccountSection)),
    );
    expect(container.read(reduceMotionProvider), isFalse);

    await tester.ensureVisible(find.text('Reduce motion'));
    await tester.tap(find.byType(Switch));
    await tester.pump();

    expect(container.read(reduceMotionProvider), isTrue);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
  });

  testWidgets('keeps a long email on one line with its tooltip (#2921)', (
    tester,
  ) async {
    const email = 'henryuks129.longer.address@gmail.com';
    await _pump(tester, account.copyWith(email: email));
    // Narrow enough that the address can't fit in its card.
    tester.view.physicalSize = const Size(700, 1000);
    await tester.pumpAndSettle();

    final text = tester.widget<Text>(find.text(email));
    expect(text.maxLines, 1);
    expect(text.softWrap, isFalse);
    expect(text.overflow, TextOverflow.ellipsis);
    expect(tester.getSize(find.text(email)).height, lessThan(30));
    expect(
      find.ancestor(of: find.text(email), matching: find.byType(Tooltip)),
      findsOneWidget,
    );
    expect(
      tester
          .widget<Tooltip>(
            find.ancestor(of: find.text(email), matching: find.byType(Tooltip)),
          )
          .message,
      email,
    );
  });
}
