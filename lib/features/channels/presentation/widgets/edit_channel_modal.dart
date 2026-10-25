import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class EditChannelModal extends ConsumerStatefulWidget {
  final Channel channel;

  const EditChannelModal({super.key, required this.channel});

  @override
  ConsumerState<EditChannelModal> createState() => _EditChannelModalState();
}

class _EditChannelModalState extends ConsumerState<EditChannelModal> {
  late TextEditingController _descController;
  late TextEditingController _topicController;
  // Kept in the dialog, not in the channel list state, so an old error never
  // shows when the dialog is opened again.
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _descController = TextEditingController(text: widget.channel.description);
    _topicController = TextEditingController(text: widget.channel.topic);
  }

  @override
  void dispose() {
    _descController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_isSaving) return;
    final topic = _topicController.text.trim();
    final description = _descController.text.trim();
    // The backend ignores empty fields and rejects a request with none.
    if (topic.isEmpty && description.isEmpty) {
      setState(() => _errorMessage = 'Add a topic or a description to save.');
      return;
    }
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final result = await ref
        .read(channelProvider.notifier)
        .updateChannelTopicOrDescription(
          channelId: widget.channel.id,
          topic: topic.isEmpty ? null : topic,
          description: description.isEmpty ? null : description,
        );
    if (!mounted) return;
    switch (result) {
      case Success<void>():
        Navigator.of(context).pop();
      case Failure<void>(:final error):
        // Keep the dialog and the typed text so the user can try again.
        setState(() {
          _isSaving = false;
          _errorMessage = error.message;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.textTheme;
    final isLoading = _isSaving;
    final errorMessage = _errorMessage;

    return Dialog(
      backgroundColor: colors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit #${widget.channel.name}',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Topic',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _topicController,
              decoration: InputDecoration(
                hintText: 'Add a topic',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              style: textTheme.bodyMedium?.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: 16),
            Text(
              'Description',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'What is this channel about?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              style: textTheme.bodyMedium?.copyWith(color: colors.textPrimary),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                errorMessage,
                style: textTheme.bodySmall?.copyWith(color: colors.error),
              ),
            ],
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: isLoading ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Save changes',
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
