import Cocoa
import SwiftUI
import AppKit

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
        
        // Populate the menu with applications and ensure search box is displayed
        populateMenu()
    }
    
    @objc func statusBarButtonClicked() {
        // Toggle menu visibility
        statusItem?.menu?.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
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
    
    func getApplicationURL(for appName: String) -> URL? {
        let applicationDirectory = FileManager.default.urls(for: .applicationDirectory, in: .localDomainMask).first!
        let appURL = applicationDirectory.appendingPathComponent("\(appName).app")
        return FileManager.default.fileExists(atPath: appURL.path) ? appURL : NSWorkspace.shared.urlForApplication(withBundleIdentifier: appName)
    }
    
    @objc func appMenuItemClicked(_ sender: NSMenuItem) {
        let appName = sender.title
        let applicationDirectory = FileManager.default.urls(for: .applicationDirectory, in: .localDomainMask).first!
        let appURL = applicationDirectory.appendingPathComponent("\(appName).app")
        
        NSWorkspace.shared.open(appURL)
    }
    
    @objc @MainActor func searchFieldChanged(_ sender: NSSearchField) {
        // Implement search filtering logic here
        let searchText = sender.stringValue.lowercased()
        populateMenu(withFilter: searchText)
    }
    
    @MainActor func populateMenu() {
        populateMenu(withFilter: "")
    }
    
    @MainActor func populateMenu(withFilter filter: String = "") {
        let menu = NSMenu()
        
        // Add search field
        let searchItem = NSMenuItem()
        let searchField = NSSearchField()
        searchField.placeholderString = "Search apps..."
        searchField.target = self
        searchField.action = #selector(searchFieldChanged)
        searchItem.view = searchField
        menu.addItem(searchItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Get list of applications
        let applications = getApplications().filter { app in
            filter.isEmpty || app.lowercased().contains(filter)
        }
        
        for app in applications {
            let menuItem = NSMenuItem(title: app, action: #selector(appMenuItemClicked), keyEquivalent: "")
            menuItem.target = self
            
            // Add app icon
            if let appURL = getApplicationURL(for: app) {
                let icon = NSWorkspace.shared.icon(forFile: appURL.path)
                icon.size = NSSize(width: 16, height: 16)
                menuItem.image = icon
            } else if let icon = NSImage(named: app) {
                icon.size = NSSize(width: 16, height: 16)
                menuItem.image = icon
            }
            
            menu.addItem(menuItem)
        }
        
        // Add quit option
        menu.addItem(NSMenuItem.separator())
        let quitMenuItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitMenuItem.target = self
        menu.addItem(quitMenuItem)
        
        statusItem?.menu = menu
    }
    
    @objc @MainActor func quitApp() {
        NSApplication.shared.terminate(self)
    }
}