import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';
import '../../../../../helpers/helpers.dart';

void main() {
  group('toggleSection', () {
    test('removes a section that is currently expanded', () {
      final result = toggleSection({
        SidebarSection.channels,
        SidebarSection.people,
      }, SidebarSection.channels);

      expect(result, {SidebarSection.people});
    });

    test('adds a section that is currently collapsed', () {
      final result = toggleSection({
        SidebarSection.people,
      }, SidebarSection.channels);

      expect(result, {SidebarSection.people, SidebarSection.channels});
    });

    test('does not mutate the set it was given', () {
      final input = {SidebarSection.channels};

      toggleSection(input, SidebarSection.channels);

      expect(input, {SidebarSection.channels});
    });

    test('toggling twice returns the original set', () {
      final input = {SidebarSection.channels, SidebarSection.people};

      final result = toggleSection(
        toggleSection(input, SidebarSection.people),
        SidebarSection.people,
      );

      expect(result, input);
    });
  });

  group('sectionArrowTurns', () {
    test('points down (no rotation) when expanded', () {
      expect(sectionArrowTurns(expanded: true), 0.0);
    });

    test('points right (quarter turn anticlockwise) when collapsed', () {
      expect(sectionArrowTurns(expanded: false), -0.25);
    });
  });

  group('SidebarSectionsNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
      addTearDown(container.dispose);
    });

    test('starts with every section expanded', () {
      expect(container.read(sidebarSectionsProvider), {
        SidebarSection.channels,
        SidebarSection.people,
      });
    });

    test('toggle flips only the requested section', () {
      container
          .read(sidebarSectionsProvider.notifier)
          .toggle(SidebarSection.channels);

      expect(container.read(sidebarSectionsProvider), {SidebarSection.people});
    });

    test('toggle twice restores the section', () {
      final notifier = container.read(sidebarSectionsProvider.notifier);

      notifier.toggle(SidebarSection.people);
      notifier.toggle(SidebarSection.people);

      expect(container.read(sidebarSectionsProvider), {
        SidebarSection.channels,
        SidebarSection.people,
      });
    });
  });
}
