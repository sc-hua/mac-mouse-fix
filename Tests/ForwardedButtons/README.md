# Forwarded button regression tests

Run on macOS with Xcode installed:

```sh
bash Tests/ForwardedButtons/run.sh
```

An optional first argument selects an existing Xcode derived-data directory.
The script builds the Helper without signing or installing it, links the actual
`Device` object file, and compiles the production `ClickCycle.swift` directly.
It does not post input events or change Accessibility permissions.

The checks cover virtual device identity, physical/virtual equality, click and
hold callbacks for buttons 4–6, unmatched releases, cancellation, and action
cleanup. The click-cycle tests replace the timer with a manually driven clock
and exercise single-click mappings only. They do not test concurrent input,
the SwitchMaster gates, or transport through Deskflow. Those require a signed
Helper and a live test with no mouse attached to the receiving Mac.

The button fix is adapted from upstream
[PR #2066](https://github.com/noah-nuebling/mac-mouse-fix/pull/2066).
The follow-up drag fix removes local-mouse eligibility checks from SwitchMaster;
drag activation and motion require a live test. Smooth scrolling is outside its scope.

To reproduce the startup regression, launch an isolated test Helper without
Accessibility permission, then run:

```sh
swift Tests/ForwardedButtons/HelperStartupProbe.swift com.sc-hua.mac-mouse-fix.deskflow.helper
```

The probe sends device queries which previously initialized input modules too
early and crashed the Helper. It also checks that version queries still work.
It does not grant permissions, change configuration, or post input events.
