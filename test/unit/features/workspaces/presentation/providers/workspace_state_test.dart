import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/features/features.dart';

void main() {
  group('WorkspaceState.copyWith', () {
    test('can clear the selected workspace and error message', () {
      const workspace = Workspace(
        id: 'org-1',
        name: 'Riverside Academy',
        avatar: '',
      );
      const state = WorkspaceState(
        workspaces: [workspace],
        selectedWorkspace: workspace,
        errorMessage: 'network down',
      );

      final cleared = state.copyWith(
        clearSelectedWorkspace: true,
        clearError: true,
      );

      expect(cleared.selectedWorkspace, isNull);
      expect(cleared.errorMessage, isNull);
      expect(cleared.workspaces, [workspace]);
    });

    test('keeps the selected workspace when the clear flag is not set', () {
      const workspace = Workspace(
        id: 'org-1',
        name: 'Riverside Academy',
        avatar: '',
      );
      const state = WorkspaceState(selectedWorkspace: workspace);

      expect(state.copyWith(isLoading: true).selectedWorkspace, workspace);
    });
  });
}
