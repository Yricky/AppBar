import SwiftUI
import AppKit

struct App : Hashable {
    var url: URL
    
    init(url: URL) {
        self.url = url
    }
    
    func name() -> String {
        return url.deletingPathExtension().lastPathComponent
    }
}

struct ContentView: View {
    @State private var searchText = ""
    @State private var applications: [App] = []
    
    var body: some View {
        VStack(spacing: 10) {
            // Search field
            TextField("Search apps...", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            // Applications list
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 5) {
                    ForEach(filteredApplications, id: \.self) { app in
                        Button(action: {
                            openApplication(app)
                        }) {
                            HStack {
                                Image(nsImage: getAppIcon(for: app))
                                    .resizable()
                                    .frame(width: 16, height: 16)
                                Text(app.name())
                                Spacer()
                            }
                            .padding(.horizontal)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            // Quit button
            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                Text("Quit")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .frame(width: 250, height: 500)
        .onAppear {
            loadApplications()
        }
    }
    
    private var filteredApplications: [App] {
        if searchText.isEmpty {
            return applications
        }
        return applications.filter { $0.name().localizedCaseInsensitiveContains(searchText) }
    }
    
    private func loadApplications() {
        let appPaths = [
            "/Applications",
            "/System/Applications",
            NSHomeDirectory() + "/Applications"
        ]
        
        var apps: [App] = []
        
        for path in appPaths {
            let url = URL(fileURLWithPath: path)
            if let contents = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil) {
                contents.forEach { fileURL in
                    if fileURL.pathExtension == "app" {
                        print("\(fileURL)")
                        apps.append(App(url: fileURL))
                    }
                }
                
                
            }
        }
        
        // Remove duplicates while preserving order
        var seen = Set<URL>()
        applications = apps.filter { seen.insert($0.url).inserted }
    }    

    private func openApplication(_ app: App) {
        NSWorkspace.shared.open(app.url)
    }
    
    private func getAppIcon(for app: App) -> NSImage {
        if FileManager.default.fileExists(atPath: app.url.path) {
            return NSWorkspace.shared.icon(forFile: app.url.path)
        }
        
        // Return a default icon if the app icon is not found
        return NSImage(systemSymbolName: "app.badge", accessibilityDescription: nil) ?? NSImage()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
