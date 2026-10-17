import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

Channel _channel(String name) => Channel(
  id: 'channel-$name',
  name: name,
  description: '',
  organisationId: 'org-1',
  ownerId: 'user-1',
);

class _FakeChannelNotifier extends ChannelNotifier {
  @override
  Future<List<Channel>> build() async => [
    _channel('general'),
    _channel('random'),
  ];
}

class _FakeWorkspaceNotifier extends WorkspaceNotifier {
  @override
  WorkspaceState build() => const WorkspaceState(
    selectedWorkspace: Workspace(id: 'org-1', name: 'Workspace A', avatar: ''),
  );
}

void main() {
  group('HomeChatArea', () {
    Future<void> pumpSidebarAndChat(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            channelProvider.overrideWith(_FakeChannelNotifier.new),
            workspaceProvider.overrideWith(_FakeWorkspaceNotifier.new),
          ],
          child: buildTestMaterialApp(
            const Scaffold(
              body: Row(
                children: [
                  SizedBox(width: 320, child: SidebarChannelList()),
                  Expanded(child: HomeChatArea()),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows #general until another channel is picked', (
      tester,
    ) async {
      await pumpSidebarAndChat(tester);

      expect(find.text('# general'), findsOneWidget);
      expect(find.text('Welcome to #general'), findsOneWidget);
    });

    testWidgets('clicking a sidebar channel opens it in the chat area', (
      tester,
    ) async {
      await pumpSidebarAndChat(tester);

      await tester.tap(find.text('random'));
      await tester.pumpAndSettle();

      expect(find.text('# random'), findsOneWidget);
      expect(find.text('Welcome to #random'), findsOneWidget);
      expect(find.text('# general'), findsNothing);
    });
  });
}
