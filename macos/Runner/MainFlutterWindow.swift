import Cocoa
import FlutterMacOS
import ServiceManagement

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // "Launch Zedu at login": the channel the launch_at_startup package talks
    // to, backed by the macOS login item (macOS 13 and later).
    FlutterMethodChannel(
      name: "launch_at_startup", binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    .setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      guard #available(macOS 13.0, *) else {
        // No login item API before macOS 13: never report a write as done.
        if call.method == "launchAtStartupIsEnabled" {
          result(false)
        } else {
          result(
            FlutterError(
              code: "UNSUPPORTED", message: "Launch at login needs macOS 13 or later",
              details: nil))
        }
        return
      }
      switch call.method {
      case "launchAtStartupIsEnabled":
        result(SMAppService.mainApp.status == .enabled)
      case "launchAtStartupSetEnabled":
        if let arguments = call.arguments as? [String: Any],
          let enabled = arguments["setEnabledValue"] as? Bool
        {
          do {
            if enabled {
              try SMAppService.mainApp.register()
            } else {
              try SMAppService.mainApp.unregister()
            }
            result(nil)
          } catch {
            result(FlutterError(code: "LOGIN_ITEM", message: error.localizedDescription, details: nil))
          }
        } else {
          result(nil)
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
