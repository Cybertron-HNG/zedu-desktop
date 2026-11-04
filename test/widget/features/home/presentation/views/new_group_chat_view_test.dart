import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

class _FakeUserProfileNotifier extends UserProfileNotifier {
  final List<TeamMember> _members;
  _FakeUserProfileNotifier(this._members);

  @override
  UserProfileState build() {
    return UserProfileState(isLoading: false, teamMembers: _members);
  }
}

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this._user);
  final User _user;

  @override
  AuthState build() =>
      AuthState(status: AuthStatus.authenticated, user: _user);
}

User _user({required String id, required String name, required String email}) =>
    User(
      id: id,
      firstName: name.split(' ').first,
      lastName: name.split(' ').length > 1 ? name.split(' ').last : '',
      email: email,
      phone: '0800000000',
      username: email.split('@').first,
      isVerified: true,
      isOnboarded: true,
      createdAt: DateTime(2026),
      currentOrg: 'org-1',
      currentOrganisationSlug: 'team-neo',
      avatarUrl: '',
      defaultAvatarUrl: '',
    );

void main() {
  final testMembers = [
    const TeamMember(
      id: 'member-1',
      name: '',
      email: 'emptyname@zedu.test',
      role: 'Member',
      dateJoined: 'Jan 1, 2026',
      status: TeamMemberStatus.active,
    ),
    const TeamMember(
      id: 'member-2',
      name: '   ',
      email: 'whitespace@zedu.test',
      role: 'Member',
      dateJoined: 'Jan 1, 2026',
      status: TeamMemberStatus.active,
    ),
    const TeamMember(
      id: 'member-3',
      name: null,
      email: 'nullname@zedu.test',
      role: 'Member',
      dateJoined: 'Jan 1, 2026',
      status: TeamMemberStatus.active,
    ),
    const TeamMember(
      id: 'member-4',
      name: 'Alice Cooper',
      email: 'alice@zedu.test',
      role: 'Admin',
      dateJoined: 'Jan 1, 2026',
      status: TeamMemberStatus.active,
    ),
  ];

  Widget buildWidget({List<TeamMember>? members, User? currentUser}) {
    return ProviderScope(
      overrides: [
        userProfileNotifierProvider.overrideWith(
          () => _FakeUserProfileNotifier(members ?? testMembers),
        ),
        authNotifierProvider.overrideWith(
          () => _FakeAuthNotifier(
            currentUser ??
                _user(id: 'default-me', name: 'Default Me', email: 'me@zedu.test'),
          ),
        ),
      ],
      child: buildTestMaterialApp(
        const Scaffold(
          body: SizedBox(width: 1200, height: 900, child: NewGroupChatView()),
        ),
      ),
    );
  }

  Finder findSearchField() {
    return find.byWidgetPredicate(
      (w) =>
          w is TextField &&
          w.decoration?.hintText?.contains('#a-channel') == true,
    );
  }

  testWidgets(
    'renders contact list without crashing when members have empty or whitespace names',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      final searchField = findSearchField();
      expect(searchField, findsOneWidget);

      await tester.tap(searchField);
      await tester.pumpAndSettle();

      // Contact tiles should be displayed without throwing RangeError
      expect(find.text('emptyname'), findsOneWidget);
      expect(find.text('whitespace'), findsOneWidget);
      expect(find.text('nullname'), findsOneWidget);
      expect(find.text('Alice Cooper'), findsOneWidget);
    },
  );

  testWidgets(
    'renders selected member chip with safe initials and fallback label for empty name',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      await tester.tap(findSearchField());
      await tester.pumpAndSettle();

      // Tap on member with empty name ('emptyname@zedu.test')
      await tester.tap(find.text('emptyname'));
      await tester.pumpAndSettle();

      // Verify selected member chip renders with label and without error
      expect(find.byType(Chip), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(Chip),
          matching: find.text('emptyname'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: find.byType(Chip), matching: find.text('EM')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'NewGroupChatView does not suggest the signed-in user in dropdown',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final currentUser = _user(
        id: 'user-self',
        name: 'Eniola Adegbiyan',
        email: 'self@example.com',
      );

      const selfMember = TeamMember(
        id: 'user-self',
        email: 'self@example.com',
        name: 'Eniola Adegbiyan',
        role: 'owner',
        dateJoined: '2026-01-01',
        status: TeamMemberStatus.active,
      );

      const teammate1 = TeamMember(
        id: 'user-alice',
        email: 'alice@example.com',
        name: 'Alice Wonder',
        role: 'member',
        dateJoined: '2026-01-01',
        status: TeamMemberStatus.active,
      );

      await tester.pumpWidget(
        buildWidget(
          members: [selfMember, teammate1],
          currentUser: currentUser,
        ),
      );
      await tester.pumpAndSettle();

      final searchField = findSearchField();
      expect(searchField, findsOneWidget);
      await tester.tap(searchField);
      await tester.pumpAndSettle();

      // Teammate should be suggested
      expect(find.text('Alice Wonder'), findsOneWidget);

      // Current signed-in user should NEVER be suggested
      expect(find.text('Eniola Adegbiyan'), findsNothing);
    },
  );

  testWidgets(
    'NewGroupChatView search excludes signed-in user even if query matches their name',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final currentUser = _user(
        id: 'user-self',
        name: 'Eniola Adegbiyan',
        email: 'self@example.com',
      );

      const selfMember = TeamMember(
        id: 'user-self',
        email: 'self@example.com',
        name: 'Eniola Adegbiyan',
        role: 'owner',
        dateJoined: '2026-01-01',
        status: TeamMemberStatus.active,
      );

      const teammate1 = TeamMember(
        id: 'user-alice',
        email: 'alice@example.com',
        name: 'Alice Wonder',
        role: 'member',
        dateJoined: '2026-01-01',
        status: TeamMemberStatus.active,
      );

      await tester.pumpWidget(
        buildWidget(
          members: [selfMember, teammate1],
          currentUser: currentUser,
        ),
      );
      await tester.pumpAndSettle();

      final searchField = findSearchField();
      await tester.enterText(searchField, 'Eniola');
      await tester.pumpAndSettle();

      // Current user should not be suggested
      expect(find.text('Eniola Adegbiyan'), findsNothing);
    },
  );
}
