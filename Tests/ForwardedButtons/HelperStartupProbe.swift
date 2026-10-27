import Foundation
import CoreFoundation

// Run against a test Helper which is waiting for Accessibility permission.
// This only queries its message port; it does not post input or change settings.
guard CommandLine.arguments.count == 2 else {
    print("Usage: swift HelperStartupProbe.swift <test-helper-bundle-id>")
    exit(2)
}
let name = CommandLine.arguments[1] as CFString
guard let port = CFMessagePortCreateRemote(nil, name) else {
    print("Test Helper message port is unavailable; run in its GUI login session")
    exit(2)
}

func request(_ message: String) -> NSNumber? {
    let data = try! NSKeyedArchiver.archivedData(
        withRootObject: ["message": message], requiringSecureCoding: false)
    var response: Unmanaged<CFData>?
    let status = CFMessagePortSendRequest(
        port, 0, data as CFData, 1, 1, CFRunLoopMode.defaultMode.rawValue, &response)
    precondition(status == kCFMessagePortSuccess, "Helper request failed: \(message), \(status)")
    guard let raw = response?.takeRetainedValue() else { return nil }
    let reply = raw as Data
    // Ignored messages are answered with empty data, not a NULL reply.
    guard !reply.isEmpty else { return nil }
    return try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSNumber.self, from: reply)
}

guard request("checkAccessibility")?.boolValue == false else {
    print("This probe requires an untrusted test Helper")
    exit(2)
}
for _ in 0..<20 {
    precondition(request("getActiveDeviceInfo") == nil)
    precondition(request("getBundleVersion")?.intValue ?? 0 > 0)
}
print("Untrusted Helper: 20 device queries safely ignored; 20 version queries answered")
