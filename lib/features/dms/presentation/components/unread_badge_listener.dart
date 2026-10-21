import 'dart:async';

import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

/// Keeps the app icon badge in step with the unread total.
class UnreadBadgeListener extends ConsumerStatefulWidget {
  const UnreadBadgeListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<UnreadBadgeListener> createState() =>
      _UnreadBadgeListenerState();
}

class _UnreadBadgeListenerState extends ConsumerState<UnreadBadgeListener> {
  @override
  void initState() {
    super.initState();
    // Fires once at start so a badge left over from the last session clears.
    ref.listenManual<int>(unreadTotalProvider, (previous, next) {
      unawaited(ref.read(unreadBadgeServiceProvider).update(next));
    }, fireImmediately: true);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
