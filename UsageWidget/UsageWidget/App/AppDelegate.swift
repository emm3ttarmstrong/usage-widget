import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panel: NSPanel!
    private var statusItem: NSStatusItem!

    private let windowPositionXKey = "windowPositionX"
    private let windowPositionYKey = "windowPositionY"

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        setupPanel()
        setupMenuBar()
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

        // Restore saved position or default to bottom-right
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

        // Auto-resize panel when content changes
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

        // Watch for window moves
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

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "chart.bar.fill", accessibilityDescription: "Usage Widget")
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Refresh", action: #selector(refreshData), keyEquivalent: "r"))
        menu.addItem(.separator())

        // 5h window limit submenu
        let limitMenu = NSMenu()
        for limit in [450, 900, 2250, 4500, 9000] {
            let item = NSMenuItem(title: "\(limit) / 5h", action: #selector(setRollingLimit(_:)), keyEquivalent: "")
            item.tag = limit
            item.target = self
            let current = UserDefaults.standard.integer(forKey: "rollingLimit")
            if current == limit {
                item.state = .on
            }
            limitMenu.addItem(item)
        }
        let limitItem = NSMenuItem(title: "5h Window Limit", action: nil, keyEquivalent: "")
        limitItem.submenu = limitMenu
        menu.addItem(limitItem)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    @objc private func refreshData() {
        NotificationCenter.default.post(name: .refreshStats, object: nil)
    }

    @objc private func setRollingLimit(_ sender: NSMenuItem) {
        UserDefaults.standard.set(sender.tag, forKey: "rollingLimit")
        if let menu = sender.menu {
            for item in menu.items {
                item.state = item.tag == sender.tag ? .on : .off
            }
        }
        NotificationCenter.default.post(name: .refreshStats, object: nil)
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}

extension Notification.Name {
    static let refreshStats = Notification.Name("refreshStats")
}
