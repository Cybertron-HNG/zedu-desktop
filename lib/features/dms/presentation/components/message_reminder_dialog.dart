import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

const _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// When a reminder fires, in the clock format the message bubbles use:
/// "today at 6:00 PM", "tomorrow at 9:00 AM", "Nov 7 at 9:00 AM".
String reminderWhenLabel(DateTime when, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(when.year, when.month, when.day);
  final daysApart = day.difference(today).inDays;

  final hour = when.hour > 12
      ? when.hour - 12
      : (when.hour == 0 ? 12 : when.hour);
  final minute = when.minute.toString().padLeft(2, '0');
  final period = when.hour >= 12 ? 'PM' : 'AM';
  final time = '$hour:$minute $period';

  if (daysApart == 0) return 'today at $time';
  if (daysApart == 1) return 'tomorrow at $time';
  if (daysApart == -1) return 'yesterday at $time';
  return '${_monthNames[when.month - 1]} ${when.day} at $time';
}

/// Picks when to be reminded about a message. Pops the chosen
/// [ReminderPreset], or null when cancelled.
class MessageReminderDialog extends StatelessWidget {
  const MessageReminderDialog({super.key, this.now});

  /// Fixed clock for tests; the wall clock otherwise.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final resolvedNow = now ?? DateTime.now();
    return AlertDialog(
      title: const Text('Remind me'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final preset in ReminderPreset.values)
            ListTile(
              leading: const Icon(Icons.schedule),
              title: Text(preset.label),
              subtitle: Text(
                reminderWhenLabel(preset.resolve(resolvedNow), resolvedNow),
              ),
              onTap: () => Navigator.pop(context, preset),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

/// Every reminder still waiting, soonest first, with the conversation it came
/// from and a way to cancel it.
class UpcomingRemindersDialog extends ConsumerWidget {
  const UpcomingRemindersDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final store = ref.watch(messageRemindersStoreProvider);
    final items = store.items;
    final now = DateTime.now();

    return AlertDialog(
      title: const Text('Reminders'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!store.isLoaded)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else if (items.isEmpty)
              const Text(
                'No reminders yet. Hover over a message and choose Remind me.',
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, _) =>
                      Divider(height: 1, color: colors.divider),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      isThreeLine: true,
                      leading: Icon(Icons.alarm, color: colors.primary),
                      title: Text(
                        item.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${item.conversationName} · ${reminderWhenLabel(item.remindAt, now)}',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: colors.textHint,
                        ),
                      ),
                      trailing: Tooltip(
                        message: 'Cancel reminder',
                        child: IconButton(
                          icon: const Icon(Icons.alarm_off_outlined),
                          iconSize: 20,
                          onPressed: () => store.cancel(item.id),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
