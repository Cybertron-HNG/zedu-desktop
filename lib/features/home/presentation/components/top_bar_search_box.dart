import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

/// The 'Search messages...' box in the top bar. Clicking it opens the quick
/// switcher, the same one Ctrl+K / Cmd+K opens.
class TopBarSearchBox extends StatelessWidget {
  const TopBarSearchBox({super.key, this.maxWidth = 400});

  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = colors.onPrimary.withValues(alpha: 0.7);
    final shortcut = defaultTargetPlatform == TargetPlatform.macOS
        ? 'Cmd+K'
        : 'Ctrl+K';

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Tooltip(
        message: 'Search ($shortcut)',
        child: Semantics(
          button: true,
          label: 'Search messages',
          excludeSemantics: true,
          child: Material(
            color: colors.onPrimary.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(6),
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              mouseCursor: SystemMouseCursors.click,
              onTap: () => QuickSwitcherShortcut.open(context),
              child: SizedBox(
                height: 28,
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    Icon(Icons.search, color: foreground, size: 18),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Search messages...',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: foreground, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
