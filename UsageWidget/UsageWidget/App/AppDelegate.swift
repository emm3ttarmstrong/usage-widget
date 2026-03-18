import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuItemValidation {
    private var panel: NSPanel!
    private var activity: NSObjectProtocol?
    private var eventMonitor: Any?
    private var contextMenu: NSMenu!

    private let windowPositionXKey = "windowPositionX"
    private let windowPositionYKey = "windowPositionY"

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        activity = ProcessInfo.processInfo.beginActivity(
            options: .userInitiated,
            reason: "Live stats refresh"
        )

        setupPanel()
        setupContextMenu()
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

    // MARK: - Context Menu

    private func setupContextMenu() {
        contextMenu = NSMenu()

        let launchItem = NSMenuItem(
            title: "Launch at Login",
            action: #selector(toggleLaunchAtLogin(_:)),
            keyEquivalent: ""
        )
        launchItem.target = self
        contextMenu.addItem(launchItem)

        contextMenu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        contextMenu.addItem(quitItem)

        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .rightMouseDown) { [weak self] event in
            guard let self, let panel = self.panel else { return event }
            if event.window == panel {
                NSMenu.popUpContextMenu(self.contextMenu, with: event, for: panel.contentView!)
                return nil
            }
            return event
        }
    }

    // MARK: - Launch at Login (LaunchAgent plist)

    private var launchAgentURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/com.emmett.UsageWidget.plist")
    }

    private var isLaunchAgentInstalled: Bool {
        FileManager.default.fileExists(atPath: launchAgentURL.path)
    }

    @objc private func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        if isLaunchAgentInstalled {
            try? FileManager.default.removeItem(at: launchAgentURL)
        } else {
            let plist: [String: Any] = [
                "Label": "com.emmett.UsageWidget",
                "ProgramArguments": ["/Applications/UsageWidget.app/Contents/MacOS/UsageWidget"],
                "RunAtLoad": true,
                "KeepAlive": ["SuccessfulExit": false],
            ]
            let data = try? PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
            FileManager.default.createFile(atPath: launchAgentURL.path, contents: data)
        }
    }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(toggleLaunchAtLogin(_:)) {
            menuItem.state = isLaunchAgentInstalled ? .on : .off
        }
        return true
    }

}
