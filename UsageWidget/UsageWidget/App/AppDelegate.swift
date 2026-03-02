import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panel: NSPanel!
    private var activity: NSObjectProtocol?

    private let windowPositionXKey = "windowPositionX"
    private let windowPositionYKey = "windowPositionY"

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        activity = ProcessInfo.processInfo.beginActivity(
            options: .userInitiated,
            reason: "Live stats refresh"
        )

        setupPanel()
    }

    private func setupPanel() {
        let viewModel = StatsViewModel()
        let contentView = ContentView(viewModel: viewModel)
            .fixedSize()

        let hostingView = NSHostingView(rootView: contentView)
        let fittingSize = hostingView.fittingSize
        hostingView.frame = NSRect(origin: .zero, size: fittingSize)

        panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: fittingSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.contentView = hostingView
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = NSWindow.Level(Int(CGWindowLevelForKey(.desktopIconWindow)) + 1)
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false

        if let x = UserDefaults.standard.object(forKey: windowPositionXKey) as? CGFloat,
           let y = UserDefaults.standard.object(forKey: windowPositionYKey) as? CGFloat {
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        } else if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.maxX - panel.frame.width - 20
            let y = screenFrame.minY + 20
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        panel.orderFront(nil)

        NotificationCenter.default.addObserver(
            forName: NSView.frameDidChangeNotification,
            object: hostingView,
            queue: .main
        ) { [weak self] _ in
            guard let self, let panel = self.panel else { return }
            let newSize = hostingView.fittingSize
            let origin = panel.frame.origin
            panel.setFrame(NSRect(origin: origin, size: newSize), display: true)
        }

        NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification,
            object: panel,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.saveWindowPosition(self.panel.frame.origin)
        }
    }

    private func saveWindowPosition(_ origin: NSPoint) {
        UserDefaults.standard.set(origin.x, forKey: windowPositionXKey)
        UserDefaults.standard.set(origin.y, forKey: windowPositionYKey)
    }

}
