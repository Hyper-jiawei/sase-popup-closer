import AppKit
import ApplicationServices
import Foundation

// Never match by executable name, partial window title, or window position.
let targetBundleID = "com.aliyun.security.sase"
let allowedTitles: Set<String> = ["SASE服务授权", "SASE Service Authorization"]

func matches(bundleID: String?, title: String) -> Bool {
    bundleID == targetBundleID && allowedTitles.contains(title)
}

func log(_ text: String) {
    print("\(ISO8601DateFormatter().string(from: Date())) \(text)")
    fflush(stdout)
}

func attribute(_ element: AXUIElement, _ name: CFString) -> CFTypeRef? {
    var result: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, name, &result) == .success else { return nil }
    return result
}

func inspect(close: Bool) {
    guard AXIsProcessTrusted() else { return }
    for app in NSRunningApplication.runningApplications(withBundleIdentifier: targetBundleID) {
        let axApp = AXUIElementCreateApplication(app.processIdentifier)
        AXUIElementSetMessagingTimeout(axApp, 0.5)
        guard let windows = attribute(axApp, kAXWindowsAttribute as CFString) as? [AXUIElement] else { continue }
        for window in windows {
            guard let title = attribute(window, kAXTitleAttribute as CFString) as? String,
                  matches(bundleID: app.bundleIdentifier, title: title) else { continue }
            if !close { log("Matching authorization window found"); continue }
            guard let value = attribute(window, kAXCloseButtonAttribute as CFString),
                  CFGetTypeID(value) == AXUIElementGetTypeID() else { continue }
            let button = value as! AXUIElement
            guard (attribute(button, kAXEnabledAttribute as CFString) as? Bool) == true else { continue }
            if AXUIElementPerformAction(button, kAXPressAction as CFString) == .success {
                log("Closed SASE authorization window")
            }
        }
    }
}

if CommandLine.arguments.contains("--self-test") {
    precondition(matches(bundleID: targetBundleID, title: "SASE服务授权"))
    precondition(matches(bundleID: targetBundleID, title: "SASE Service Authorization"))
    precondition(!matches(bundleID: "com.example.other", title: "SASE服务授权"))
    for title in ["SASE 客户端", "登录", "SASE服务授权 - 登录", "", "获取定位服务权限"] {
        precondition(!matches(bundleID: targetBundleID, title: title))
    }
    log("Exact bundle and title matching tests passed")
    exit(0)
}

let app = NSApplication.shared
app.setActivationPolicy(.prohibited)

if CommandLine.arguments.contains("--check") {
    log("Accessibility access: \(AXIsProcessTrusted())")
    log("SASE running: \(!NSRunningApplication.runningApplications(withBundleIdentifier: targetBundleID).isEmpty)")
    inspect(close: false)
    exit(0)
}

if CommandLine.arguments.contains("--once") {
    guard AXIsProcessTrusted() else { log("Accessibility access required"); exit(2) }
    inspect(close: true)
    exit(0)
}

var previousTrust: Bool?
func tick() {
    let trusted = AXIsProcessTrusted()
    if previousTrust != trusted {
        log(trusted ? "Watcher active; exact SASE authorization windows only" : "Waiting for Accessibility permission; no windows inspected")
        previousTrust = trusted
    }
    inspect(close: true)
}

tick()
let timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in tick() }
RunLoop.main.add(timer, forMode: .common)
app.run()
