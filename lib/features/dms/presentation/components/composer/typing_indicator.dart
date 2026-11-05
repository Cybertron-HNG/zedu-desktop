import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class TypingIndicator extends ConsumerWidget {
  final String channelId;

  const TypingIndicator({super.key, required this.channelId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (channelId.isEmpty) return const SizedBox.shrink();
    final typingNotifier = ref.watch(typingProvider(channelId));
    if (typingNotifier.isEmpty) return const SizedBox.shrink();

    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            typingNotifier.label,
            style: TextStyle(
              fontSize: 12,
              color: colors.textHint,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
