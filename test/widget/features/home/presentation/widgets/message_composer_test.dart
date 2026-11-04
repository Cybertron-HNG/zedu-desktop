import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

class _FakeProfileNotifier extends UserProfileNotifier {
  _FakeProfileNotifier(this.initial);

  final UserProfileState initial;

  @override
  UserProfileState build() => initial;
}

TeamMember _member(String id, String name) => TeamMember(
  id: id,
  email: '$id@example.com',
  role: 'member',
  dateJoined: '2026-01-01',
  status: TeamMemberStatus.active,
  name: name,
);

void main() {
  testWidgets('mention suggestions show a whole first character or ?', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileNotifierProvider.overrideWith(
            () => _FakeProfileNotifier(
              UserProfileState(
                teamMembers: [
                  _member('rocket', '🚀 Rocket'),
                  _member('blank', '   '),
                  _member('ada', ' ada'),
                ],
              ),
            ),
          ),
        ],
        child: buildTestMaterialApp(
          Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: MessageComposer(
                activeChat: ActiveChatState.generalChannel,
                onSend: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '@');
    await tester.pump();

    final initials = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byType(CircleAvatar),
            matching: find.byType(Text),
          ),
        )
        .map((text) => text.data)
        .toList();
    expect(initials, ['🚀', '?', 'A']);
  });
}
