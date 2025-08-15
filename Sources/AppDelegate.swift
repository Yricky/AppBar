import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Create the status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "app.badge", accessibilityDescription: nil)
            button.action = #selector(statusBarButtonClicked)
            button.target = self
        }
        
        // Populate the menu with applications
        populateMenu()
    }
    
    @objc func statusBarButtonClicked() {
        // Toggle menu visibility
        statusItem?.menu?.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
    }
    
    func populateMenu() {
        let menu = NSMenu()
        
        // Get list of applications
        let applications = getApplications()
        
        for app in applications {
            let menuItem = NSMenuItem(title: app, action: #selector(appMenuItemClicked), keyEquivalent: "")
            menuItem.target = self
            menu.addItem(menuItem)
        }
        
        // Add quit option
        menu.addItem(NSMenuItem.separator())
        let quitMenuItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitMenuItem.target = self
        menu.addItem(quitMenuItem)
        
        statusItem?.menu = menu
    }
    
    func getApplications() -> [String] {
        let applicationDirectory = FileManager.default.urls(for: .applicationDirectory, in: .localDomainMask).first!
        let contents = try? FileManager.default.contentsOfDirectory(at: applicationDirectory, includingPropertiesForKeys: nil)
        
        return contents?.compactMap { url in
            if url.pathExtension == "app" {
                return url.deletingPathExtension().lastPathComponent
            }
            return nil
        } ?? []
    }
    
    @objc func appMenuItemClicked(_ sender: NSMenuItem) {
        let appName = sender.title
        let applicationDirectory = FileManager.default.urls(for: .applicationDirectory, in: .localDomainMask).first!
        let appURL = applicationDirectory.appendingPathComponent("\(appName).app")
        
        NSWorkspace.shared.open(appURL)
    }
    
    @objc @MainActor func quitApp() {
        NSApplication.shared.terminate(self)
    }
}