import 'package:zedu/features/features.dart';

class WorkspaceState {
  final List<Workspace> workspaces;
  final Workspace? selectedWorkspace;
  final bool isLoading;

  const WorkspaceState({
    this.workspaces = const [],
    this.selectedWorkspace,
    this.isLoading = false,
  });

  WorkspaceState copyWith({
    List<Workspace>? workspaces,
    Workspace? selectedWorkspace,
    bool? isLoading,
  }) {
    return WorkspaceState(
      workspaces: workspaces ?? this.workspaces,
      selectedWorkspace: selectedWorkspace ?? this.selectedWorkspace,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
