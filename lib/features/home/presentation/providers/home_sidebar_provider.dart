import 'package:zedu/core/core.dart';

enum HomeSidebarType { home, dms, people, files, buzz }

class HomeSidebarNotifier extends Notifier<HomeSidebarType> {
  @override
  HomeSidebarType build() => HomeSidebarType.home;

  void setType(HomeSidebarType type) {
    state = type;
  }
}

final homeSidebarProvider =
    NotifierProvider<HomeSidebarNotifier, HomeSidebarType>(
      HomeSidebarNotifier.new,
    );

/// Collapsible groups in the main (Home) sidebar.
enum SidebarSection { channels, people }

/// Pure: returns a new set with [section] removed if it is expanded, or added
/// if it is collapsed. The input set is never mutated.
Set<SidebarSection> toggleSection(
  Set<SidebarSection> expanded,
  SidebarSection section,
) {
  final next = {...expanded};
  if (!next.remove(section)) next.add(section);
  return next;
}

/// Pure: rotation (in turns) for a section's arrow. The base icon points down,
/// so a collapsed section turns a quarter anticlockwise to point right.
double sectionArrowTurns({required bool expanded}) => expanded ? 0.0 : -0.25;

/// Holds the set of *expanded* sections. Lives in a provider (not widget
/// state) so it survives switching rail tabs, which disposes the sidebar.
class SidebarSectionsNotifier extends Notifier<Set<SidebarSection>> {
  @override
  Set<SidebarSection> build() => {...SidebarSection.values};

  void toggle(SidebarSection section) {
    state = toggleSection(state, section);
  }
}

final sidebarSectionsProvider =
    NotifierProvider<SidebarSectionsNotifier, Set<SidebarSection>>(
      SidebarSectionsNotifier.new,
    );
