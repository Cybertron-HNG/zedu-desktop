import 'package:zedu/core/core.dart';

enum HomeSidebarType { home, dms, people, files, buzz }

class HomeSidebarNotifier extends Notifier<HomeSidebarType> {
  @override
  HomeSidebarType build() => HomeSidebarType.home;

  void setType(HomeSidebarType type) {
    state = type;
  }
}

final homeSidebarProvider =
    NotifierProvider<HomeSidebarNotifier, HomeSidebarType>(
      HomeSidebarNotifier.new,
    );
