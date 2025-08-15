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
        let menu = NSMenu()
        
        // Create a hosting controller for the SwiftUI view
        let contentView = ContentView()
        let hostingController = NSHostingController(rootView: contentView)
        hostingController.view.frame = NSRect(x: 0, y: 0, width: 250, height: 500)
        hostingController.view.wantsLayer = true
        hostingController.view.layer?.isOpaque = false
        
        // Create a menu item to hold the SwiftUI view
        let menuItem = NSMenuItem()
        menuItem.view = hostingController.view
        
        menu.addItem(menuItem)
        statusItem?.menu = menu
    }
    
    @objc func statusBarButtonClicked() {
        // Toggle menu visibility
        statusItem?.menu?.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
    }
}
