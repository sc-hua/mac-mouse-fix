import Cocoa

@main enum ClickCycleTests {
    static var checks = 0

    static func check(_ condition: @autoclosure () -> Bool, _ message: String) {
        checks += 1
        guard condition() else { fatalError(message) }
    }

    static func main() {
        let remote = Device.strange()
        let unrelated = Device()

        for button in [4, 5, 6] {
            let cycle = ClickCycle()
            var phases: [ClickCycleTriggerPhase] = []
            var releases = 0
            let callback: ClickCycleTriggerCallback = { phase, _, _, _, onRelease in
                phases.append(phase)
                if phase == .press { onRelease.append { releases += 1 } }
            }
            func send(_ down: Bool, device: Device = remote) {
                cycle.handleClick(device: device, button: button, downNotUp: down,
                                  maxClickLevel: 1, triggerCallback: callback)
            }

            send(false)
            check(phases.isEmpty, "An unmatched release must not trigger an action")

            send(true)
            check(cycle.isActiveFor(device: remote, button: button as NSNumber),
                  "A forwarded press must own its click cycle")
            check(!cycle.isActiveFor(device: unrelated, button: button as NSNumber),
                  "Unrelated devices must not share the forwarded click cycle")
            send(false)
            check(phases == [.press, .release], "A forwarded click must have both edges")
            check(releases == 1, "Click actions must be released exactly once")
            cycle.kill()
            check(!cycle.isActiveFor(device: remote, button: button as NSNumber),
                  "Killing a click cycle must clear its device identity")

            phases = []
            send(true)
            let holdTimer = TestClock.timers[TestClock.timers.count - 2]
            holdTimer.fire()
            check(phases == [.press, .hold], "A forwarded hold must trigger: \(phases)")
            send(false)
            check(phases == [.press, .hold, .releaseFromHold],
                  "A forwarded hold must receive its release")
            check(!cycle.isActiveFor(device: remote, button: button as NSNumber),
                  "Releasing a hold must end the click cycle")

            phases = []
            send(true)
            let cancelledTimer = TestClock.timers[TestClock.timers.count - 2]
            cycle.kill()
            cancelledTimer.fire()
            check(phases == [.press], "A cancelled cycle must not fire a late hold")
            let previousReleases = releases
            send(false)
            check(releases == previousReleases + 1,
                  "An interrupted action must still receive its unconditional release")
            check(phases == [.press], "An interrupted release must not start another action")
        }
        print("Forwarded click/hold: \(checks) checks passed")
    }
}
