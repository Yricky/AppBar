import SwiftUI
import AppKit

struct App : Hashable, Identifiable {
    let id = UUID()
    var url: URL
    
    init(url: URL) {
        self.url = url
    }
    
    func name() -> String {
        guard let bundle = Bundle(url: url) else {
            return url.deletingPathExtension().lastPathComponent
        }

        // Try to get the localized name from the app bundle
        if let displayName = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String, !displayName.isEmpty {
            return displayName
        }
        
        if let name = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String, !name.isEmpty {
            return name
        }
        
        // Fallback to the file name without extension
        return url.deletingPathExtension().lastPathComponent
    }
    
    @MainActor
    func loadIcon() async -> NSImage {
        // Move the icon loading logic here
        if FileManager.default.fileExists(atPath: self.url.path) {
            return NSWorkspace.shared.icon(forFile: self.url.path)
        }
        
        // Return a default icon if the app icon is not found
        return NSImage(systemSymbolName: "app.badge", accessibilityDescription: nil) ?? NSImage()
    }
}

struct ContentView: View {
    @State private var searchText = ""
    @FocusState private var isSearchFieldFocused: Bool
    @State private var applications: [App] = []
    
    var body: some View {
        VStack() {
            // Search field with icon
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .padding(.leading, 8)
                TextField("Search apps...", text: $searchText)
                    .focused($isSearchFieldFocused)
                    .onSubmit {
                        if !filteredApplications.isEmpty {
                            openApplication(filteredApplications[0])
                        }
                    }
                // Clear button when there's text
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }.padding(.trailing, 8)
            
            // Applications list
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 5) {
                    ForEach(filteredApplications) { app in
                        Button(action: {
                            openApplication(app)
                        }) {
                            AppIconView(app: app)
                            Text(app.name())
                            Spacer()
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
            }.padding(.horizontal)
        }
        .frame(width: 250, height: 500)
        .onAppear {
            loadApplications()
        }
    }
    
    struct AppIconView: View {
        let app: App
        @State private var image: NSImage = NSImage(systemSymbolName: "app.badge", accessibilityDescription: nil) ?? NSImage()
        
        var body: some View {
            Image(nsImage: image)
                .resizable()
                .frame(width: 16, height: 16)
                .padding(.leading)
                .onAppear {
                    Task { @MainActor in
                        image = await app.loadIcon()
                    }
                }
        }
    }
    
    private var filteredApplications: [App] {
        if searchText.isEmpty {
            return applications
        }
        return applications.filter { 
            $0.name().localizedCaseInsensitiveContains(searchText) || 
            $0.url.lastPathComponent.localizedCaseInsensitiveContains(searchText)
        }
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
            recursivelyFindApps(at: url, apps: &apps)
        }
        
        // Remove duplicates while preserving order
        var seen = Set<URL>()
        applications = apps.filter { seen.insert($0.url).inserted }
    }
    
    private func recursivelyFindApps(at url: URL, apps: inout [App]) {
        guard let contents = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil) else { return }
        
        for fileURL in contents {
            if fileURL.pathExtension == "app" {
                print("\(fileURL)")
                apps.append(App(url: fileURL))
            } else if fileURL.hasDirectoryPath {
                // Recursively search in directories that don't have .app extension
                recursivelyFindApps(at: fileURL, apps: &apps)
            }
        }
    }
    

    private func openApplication(_ app: App) {
        NSWorkspace.shared.open(app.url)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
