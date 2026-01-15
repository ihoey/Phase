import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var statusMenu: NSMenu?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        setupWindowBehavior()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "network", accessibilityDescription: "Phase")
            button.action = #selector(toggleMenu)
            button.target = self
        }
        
        statusMenu = NSMenu()
        statusMenu?.addItem(NSMenuItem(title: "显示主窗口", action: #selector(showMainWindow), keyEquivalent: ""))
        statusMenu?.addItem(NSMenuItem.separator())
        statusMenu?.addItem(NSMenuItem(title: "退出 Phase", action: #selector(quitApp), keyEquivalent: "q"))
    }
    
    private func setupWindowBehavior() {
        NSWindow.allowsAutomaticWindowTabbing = false
    }
    
    @objc private func toggleMenu() {
        if let menu = statusMenu, let button = statusItem?.button {
            statusItem?.menu = menu
            button.performClick(nil)
            statusItem?.menu = nil
        }
    }
    
    @objc private func showMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first {
            window.makeKeyAndOrderFront(nil)
        }
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
