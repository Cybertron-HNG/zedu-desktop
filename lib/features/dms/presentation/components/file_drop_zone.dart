import 'package:zedu/core/core.dart';

/// Lets files dragged from Finder or Explorer be dropped anywhere on [child],
/// with a "Drop files to attach" overlay while they are over it.
class FileDropZone extends StatefulWidget {
  const FileDropZone({super.key, required this.onDrop, required this.child});

  final ValueChanged<List<XFile>> onDrop;
  final Widget child;

  @override
  State<FileDropZone> createState() => _FileDropZoneState();
}

class _FileDropZoneState extends State<FileDropZone> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DropTarget(
      onDragDone: (detail) {
        setState(() => _isDragging = false);
        widget.onDrop(detail.files);
      },
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      child: Stack(
        children: [
          widget.child,
          if (_isDragging)
            Positioned.fill(
              child: Container(
                color: colors.primary.withValues(alpha: 0.2),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Drop files to attach',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
