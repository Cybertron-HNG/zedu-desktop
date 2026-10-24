import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    // With trayManager, the app keeps running after the last window is closed:
    // clicking X hides the window to the tray instead of terminating.
    // `windowManager.destroy()` (tray menu "Exit") explicitly terminates the
    // process, so the app still quits on purpose.
    return false
  }

  override func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
    // Re-show the window when clicking the Dock icon, e.g. after the window
    // was hidden to the tray (windowManager.hide() orderOut).
    if !hasVisibleWindows {
      sender.activate(ignoringOtherApps: true)
      for window in sender.windows where window.canBecomeMain {
        window.setIsVisible(true)
        window.makeKeyAndOrderFront(nil)
      }
    }
    return true
  }
}
