import 'package:zedu/features/features.dart';

class WorkspaceState {
  final List<Workspace> workspaces;
  final Workspace? selectedWorkspace;
  final bool isLoading;
  final String? errorMessage;

  const WorkspaceState({
    this.workspaces = const [],
    this.selectedWorkspace,
    this.isLoading = false,
    this.errorMessage,
  });

  WorkspaceState copyWith({
    List<Workspace>? workspaces,
    Workspace? selectedWorkspace,
    bool? isLoading,
    String? errorMessage,
    bool clearSelectedWorkspace = false,
    bool clearError = false,
  }) {
    return WorkspaceState(
      workspaces: workspaces ?? this.workspaces,
      selectedWorkspace: clearSelectedWorkspace
          ? null
          : (selectedWorkspace ?? this.selectedWorkspace),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
