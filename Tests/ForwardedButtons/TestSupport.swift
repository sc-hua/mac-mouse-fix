import Cocoa

// The production ClickCycle runs on IOThread. These tests drive it synchronously
// and replace only its clock, logging and the unused multi-click math boundary.
@objc(IOThread) class IOThread: NSObject {
    @objc class func runLoop() -> CFRunLoop { CFRunLoopGetMain() }
}

func assertRunLoop(_ runLoop: CFRunLoop) {
    precondition(CFEqual(CFRunLoopGetCurrent(), runLoop))
}

func DDLogDebug(_ message: @autoclosure () -> String) {}

enum Math {
    static func intCycle(x: Int, lower: Int, upper: Int) -> Int {
        precondition(lower == upper, "These tests exercise single-click and hold mappings")
        return lower
    }
}

enum TestClock {
    static var timers: [Timer] = []
}

extension Timer {
    static func mf_scheduledTimer(withTimeInterval interval: TimeInterval,
                                  mode: RunLoop.Mode,
                                  block: @escaping (Timer) -> Void) -> Timer {
        let timer = Timer(timeInterval: interval, repeats: false, block: block)
        TestClock.timers.append(timer)
        return timer
    }
}
