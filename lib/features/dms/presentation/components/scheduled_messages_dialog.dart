import 'package:flutter/material.dart';
import 'package:zedu/features/features.dart';

/// What the schedule dialog returns: the message and when to send it.
class ScheduleDraft {
  const ScheduleDraft({required this.content, required this.sendAt});

  final String content;
  final DateTime sendAt;
}

/// Pickers are injected so widget tests do not drive the platform dialogs.
typedef ScheduleDatePicker =
    Future<DateTime?> Function(BuildContext context, DateTime initial);
typedef ScheduleTimePicker =
    Future<TimeOfDay?> Function(BuildContext context, TimeOfDay initial);

const _months = [
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

String _twoDigits(int value) => value.toString().padLeft(2, '0');

/// `5 Nov 2026`
String scheduleDateLabel(DateTime time) {
  final local = time.toLocal();
  return '${local.day} ${_months[local.month - 1]} ${local.year}';
}

/// `3:05 PM`
String scheduleTimeLabel(DateTime time) {
  final local = time.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = _twoDigits(local.minute);
  final period = local.hour < 12 ? 'AM' : 'PM';
  return '$hour:$minute $period';
}

/// `today at 3:05 PM`, `tomorrow at 9:00 AM`, or `5 Nov 2026 at 3:05 PM`.
String scheduledWhenLabel(DateTime sendAt, DateTime now) {
  final send = sendAt.toLocal();
  final today = now.toLocal();
  final days = DateTime(
    send.year,
    send.month,
    send.day,
  ).difference(DateTime(today.year, today.month, today.day)).inDays;
  final time = scheduleTimeLabel(send);
  return switch (days) {
    0 => 'today at $time',
    1 => 'tomorrow at $time',
    -1 => 'yesterday at $time',
    _ => '${scheduleDateLabel(send)} at $time',
  };
}

/// Compose-ahead dialog: takes the text and a date and time, and returns a
/// [ScheduleDraft] for the caller to store.
class ScheduleMessageDialog extends StatefulWidget {
  const ScheduleMessageDialog({
    super.key,
    required this.conversationName,
    this.initialText = '',
    this.initialSendAt,
    this.now,
    this.pickDate,
    this.pickTime,
  });

  final String conversationName;
  final String initialText;
  final DateTime? initialSendAt;

  /// Fixed clock for tests; defaults to [DateTime.now].
  final DateTime Function()? now;
  final ScheduleDatePicker? pickDate;
  final ScheduleTimePicker? pickTime;

  @override
  State<ScheduleMessageDialog> createState() => _ScheduleMessageDialogState();
}

class _ScheduleMessageDialogState extends State<ScheduleMessageDialog> {
  late final TextEditingController _controller;
  late DateTime _sendAt;
  String? _error;

  DateTime get _now => widget.now?.call() ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _sendAt = widget.initialSendAt ?? _defaultSendAt();
  }

  DateTime _defaultSendAt() {
    final now = _now;
    final inAnHour = now.add(const Duration(hours: 1));
    return DateTime(
      inAnHour.year,
      inAnHour.month,
      inAnHour.day,
      inAnHour.hour,
      inAnHour.minute,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _chooseDate() async {
    final picked = await (widget.pickDate ?? _showDatePicker)(context, _sendAt);
    if (picked == null || !mounted) return;
    setState(() {
      _sendAt = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _sendAt.hour,
        _sendAt.minute,
      );
      _error = null;
    });
  }

  Future<void> _chooseTime() async {
    final picked = await (widget.pickTime ?? _showTimePicker)(
      context,
      TimeOfDay.fromDateTime(_sendAt),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _sendAt = DateTime(
        _sendAt.year,
        _sendAt.month,
        _sendAt.day,
        picked.hour,
        picked.minute,
      );
      _error = null;
    });
  }

  Future<DateTime?> _showDatePicker(BuildContext context, DateTime initial) {
    final now = _now;
    return showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Send on',
    );
  }

  Future<TimeOfDay?> _showTimePicker(BuildContext context, TimeOfDay initial) =>
      showTimePicker(context: context, initialTime: initial);

  bool get _isEditing => widget.initialSendAt != null;

  void _submit() {
    final content = _controller.text.trim();
    if (content.isEmpty) {
      setState(() => _error = 'Write a message to schedule.');
      return;
    }
    if (!_sendAt.isAfter(_now)) {
      setState(() => _error = 'Pick a time in the future.');
      return;
    }
    Navigator.of(
      context,
    ).pop(ScheduleDraft(content: _controller.text.trim(), sendAt: _sendAt));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(_isEditing ? 'Edit scheduled message' : 'Schedule message'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Sends to ${widget.conversationName}.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
              maxLines: 4,
              minLines: 2,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _chooseDate,
                    icon: const Icon(Icons.event_outlined, size: 18),
                    label: Text(scheduleDateLabel(_sendAt)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _chooseTime,
                    icon: const Icon(Icons.schedule, size: 18),
                    label: Text(scheduleTimeLabel(_sendAt)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Sends ${scheduledWhenLabel(_sendAt, _now)}.',
              style: theme.textTheme.bodySmall,
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(_isEditing ? 'Save' : 'Schedule'),
        ),
      ],
    );
  }
}

/// The pending queue, soonest first, with edit and cancel for each message.
class ScheduledMessagesDialog extends StatefulWidget {
  const ScheduledMessagesDialog({super.key, required this.store, this.now});

  final ScheduledMessagesStore store;
  final DateTime Function()? now;

  @override
  State<ScheduledMessagesDialog> createState() =>
      _ScheduledMessagesDialogState();
}

class _ScheduledMessagesDialogState extends State<ScheduledMessagesDialog> {
  @override
  void initState() {
    super.initState();
    widget.store.addListener(_onStore);
  }

  @override
  void dispose() {
    widget.store.removeListener(_onStore);
    super.dispose();
  }

  void _onStore() {
    if (mounted) setState(() {});
  }

  DateTime get _now => widget.now?.call() ?? DateTime.now();

  Future<void> _edit(ScheduledMessage message) async {
    final draft = await showDialog<ScheduleDraft>(
      context: context,
      builder: (context) => ScheduleMessageDialog(
        conversationName: message.conversationName,
        initialText: message.content,
        initialSendAt: message.sendAt,
        now: widget.now,
      ),
    );
    if (draft == null) return;
    await widget.store.update(
      message.id,
      content: draft.content,
      sendAt: draft.sendAt,
    );
  }

  Future<void> _cancel(ScheduledMessage message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel scheduled message?'),
        content: const Text('This message will not be sent.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancel message'),
          ),
        ],
      ),
    );
    if (confirmed == true) await widget.store.cancel(message.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final messages = widget.store.items;
    final now = _now;

    return AlertDialog(
      title: const Text('Scheduled messages'),
      content: SizedBox(
        width: 460,
        child: messages.isEmpty
            ? const Text('No scheduled messages yet.')
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: messages.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final when = scheduledWhenLabel(message.sendAt, now);
                        final failed = message.lastError != null;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.schedule_send_outlined),
                          title: Text(
                            message.content,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            failed
                                ? '${message.conversationName} · '
                                      "couldn't send, retrying"
                                : '${message.conversationName} · sends $when',
                            style: failed
                                ? theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.error,
                                  )
                                : theme.textTheme.bodySmall,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Edit scheduled message',
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                onPressed: () => _edit(message),
                              ),
                              IconButton(
                                tooltip: 'Cancel scheduled message',
                                icon: const Icon(Icons.close_rounded, size: 18),
                                onPressed: () => _cancel(message),
                              ),
                            ],
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
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
