import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

/// The three-dot menu in a channel's header. It holds one action for now,
/// "Edit channel", which opens [EditChannelModal] for the channel.
class ChannelOptionsMenu extends StatelessWidget {
  const ChannelOptionsMenu({super.key, required this.channel});

  /// The channel being viewed, or null while it has not loaded yet.
  final Channel? channel;

  @override
  Widget build(BuildContext context) {
    final channel = this.channel;

    return PopupMenuButton<String>(
      tooltip: 'Channel options',
      enabled: channel != null,
      icon: Icon(Icons.more_vert, color: context.colors.textHint),
      onSelected: (_) {
        if (channel == null) return;
        showDialog<void>(
          context: context,
          builder: (_) => EditChannelModal(channel: channel),
        );
      },
      itemBuilder: (_) => const [
        PopupMenuItem<String>(value: 'edit', child: Text('Edit channel')),
      ],
    );
  }
}
