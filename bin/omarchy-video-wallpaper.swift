// omarchy-video-wallpaper — plays a video behind the windows on every screen,
// muted, with AVPlayer (Omarchy 4.5: video backgrounds and theme intros).
//   omarchy-video-wallpaper <video>          loop it until killed (a video background)
//   omarchy-video-wallpaper --once <video>   play it one time, then exit (a theme intro)
// bin/omarchy-bg-set starts and stops it. install.sh builds it:
//   swiftc -O omarchy-video-wallpaper.swift -o ~/.local/bin/omarchy-video-wallpaper
import AppKit
import AVFoundation

var args = Array(CommandLine.arguments.dropFirst())
let once = args.first == "--once"
if once { args.removeFirst() }
guard let path = args.first, FileManager.default.fileExists(atPath: path) else {
    FileHandle.standardError.write("usage: omarchy-video-wallpaper [--once] <video>\n".data(using: .utf8)!)
    exit(1)
}

let item = AVPlayerItem(url: URL(fileURLWithPath: path))
let player = AVQueuePlayer()
player.isMuted = true
var looper: AVPlayerLooper?
if once {
    player.insert(item, after: nil)
    for name in [AVPlayerItem.didPlayToEndTimeNotification, AVPlayerItem.failedToPlayToEndTimeNotification] {
        NotificationCenter.default.addObserver(forName: name, object: item, queue: .main) { _ in exit(0) }
    }
    // An intro that cannot load posts nothing; never leave a window over the desktop.
    DispatchQueue.main.asyncAfter(deadline: .now() + 60) { exit(0) }
} else {
    looper = AVPlayerLooper(player: player, templateItem: item)
}

// The desktop picture's level: behind every window and the desktop icons. An
// intro sits one above, so it covers a video background while it plays.
let level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)) + (once ? 1 : 0))
var windows: [NSWindow] = []

func cover() {
    windows.forEach { $0.orderOut(nil) }
    windows = NSScreen.screens.map { (screen: NSScreen) -> NSWindow in
        let w = NSWindow(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
        w.level = level
        w.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        w.ignoresMouseEvents = true
        w.isReleasedWhenClosed = false
        w.backgroundColor = .black
        let view = NSView(frame: NSRect(origin: .zero, size: screen.frame.size))
        view.wantsLayer = true
        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspectFill
        layer.frame = view.bounds
        layer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        view.layer?.addSublayer(layer)
        w.contentView = view
        w.setFrame(screen.frame, display: true) // global coordinates, so each screen gets its own
        w.orderFront(nil)
        return w
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory) // no Dock icon, never takes focus
NotificationCenter.default.addObserver(
    forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main
) { _ in cover() }
cover()
player.play()
app.run()
