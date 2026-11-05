import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';
import '../../../../../helpers/helpers.dart';

// Suggests one registered person and records email invites.
class _PickableUsersNotifier extends UserProfileNotifier {
  final List<String> invited = [];

  @override
  UserProfileState build() => const UserProfileState();

  @override
  Future<List<Map<String, dynamic>>> fetchRegisteredUsers() async => [
    {'id': 'u-ada', 'email': 'ada@zedu.test', 'full_name': 'Ada Lovelace'},
  ];

  @override
  Future<void> inviteMember({
    required String email,
    required String role,
    String? userId,
  }) async {
    invited.add(email);
  }
}

class _FakeAddPeople extends AddPeopleToChannel {
  _FakeAddPeople(super.ref, this._result, this.calls);

  final AddEveryoneResult _result;
  final List<List<String>> calls;

  @override
  Future<AddEveryoneResult> call(List<String> userIds) async {
    calls.add(userIds);
    return _result;
  }
}

class _OpenChannel extends ActiveChatNotifier {
  @override
  ActiveChatState build() =>
      const ActiveChatState(type: ActiveChatType.channel, id: 'design');
}

void main() {
  late _PickableUsersNotifier profile;
  // Each test gets its own record of add calls.
  late List<List<String>> addCalls;

  Future<void> pumpModal(WidgetTester tester, AddEveryoneResult result) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    profile = _PickableUsersNotifier();
    addCalls = [];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileNotifierProvider.overrideWith(() => profile),
          activeChatProvider.overrideWith(_OpenChannel.new),
          addPeopleToChannelProvider.overrideWith(
            (ref) => _FakeAddPeople(ref, result, addCalls),
          ),
        ],
        child: buildTestMaterialApp(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (context) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: const TextScaler.linear(0.7)),
                    child: const InviteTeammatesModal(),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  Future<void> pickAda(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField), 'ada');
    await tester.pump();
    await tester.tap(find.text('Ada Lovelace'));
    await tester.pump();
  }

  Future<void> submit(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
    await tester.pumpAndSettle();
  }

  testWidgets('a picked person is added to the channel, not invited', (
    tester,
  ) async {
    await pumpModal(tester, const AddEveryoneAdded(1, 'design'));
    await pickAda(tester);
    await submit(tester);

    expect(addCalls, [
      ['u-ada'],
    ]);
    expect(profile.invited, isEmpty);
    expect(find.text('Added 1 person to #design.'), findsOneWidget);
    expect(find.byType(InviteTeammatesModal), findsNothing);
  });

  testWidgets('says so when everyone picked is already in the channel', (
    tester,
  ) async {
    await pumpModal(tester, const AddEveryoneNobodyToAdd('design'));
    await pickAda(tester);
    await submit(tester);

    expect(
      find.text('Everyone you picked is already in #design.'),
      findsOneWidget,
    );
    // The window stays open and usable, not stuck loading.
    expect(find.byType(InviteTeammatesModal), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('shows the error and stops loading when adding fails', (
    tester,
  ) async {
    await pumpModal(tester, const AddEveryoneFailed('Not allowed'));
    await pickAda(tester);
    await submit(tester);

    expect(find.text('Not allowed'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('an email that matches nobody is still invited by email', (
    tester,
  ) async {
    await pumpModal(tester, const AddEveryoneAdded(1, 'design'));
    await tester.enterText(find.byType(TextField), 'new@person.test');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await submit(tester);

    expect(addCalls, isEmpty);
    expect(profile.invited, ['new@person.test']);
    expect(find.text('Successfully invited 1 teammate.'), findsOneWidget);
  });
}
