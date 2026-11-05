import 'package:zedu/core/core.dart';

/// A thin bar and percentage for an attached file that is still uploading.
class UploadProgressBar extends StatelessWidget {
  const UploadProgressBar({super.key, required this.progress});

  /// From 0 to 1.
  final double progress;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final percent = (progress.clamp(0.0, 1.0) * 100).round();
    return Semantics(
      label: 'Uploading, $percent%',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 3,
                backgroundColor: colors.divider,
                color: colors.primary,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$percent%',
            style: TextStyle(fontSize: 10, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
