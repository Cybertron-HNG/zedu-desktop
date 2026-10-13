import 'package:zedu/core/core.dart';

class EmojiPickerDialog extends StatelessWidget {
  const EmojiPickerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final emojis = [
      '😀',
      '😅',
      '😊',
      '😍',
      '😎',
      '🤔',
      '😴',
      '🥳',
      '😭',
      '😡',
      '👍',
      '🙏',
      '🔥',
      '✨',
      '🎉',
      '🚀',
      '👀',
      '💯',
      '❤️',
      '🙌',
      '👏',
      '🤝',
      '💼',
      '💻',
    ];

    return Dialog(
      backgroundColor: colors.background,
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Emoji',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              itemCount: emojis.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () {
                    Navigator.pop(context, emojis[index]);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Center(
                    child: Text(
                      emojis[index],
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
