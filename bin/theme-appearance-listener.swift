import Foundation

let watcher = NSHomeDirectory() + "/.local/bin/theme-appearance-watch"

func runWatcher() {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/bin/bash")
    p.arguments = [watcher]
    try? p.run()
}

runWatcher()

DistributedNotificationCenter.default().addObserver(
    forName: NSNotification.Name("AppleInterfaceThemeChangedNotification"),
    object: nil, queue: nil
) { _ in runWatcher() }

DistributedNotificationCenter.default().addObserver(
    forName: NSNotification.Name("com.apple.screenIsUnlocked"),
    object: nil, queue: nil
) { _ in runWatcher() }

RunLoop.main.run()
