import SwiftUI

struct ContentView: View {
    @State private var searchText = ""
    @State private var applications: [String] = []
    
    var body: some View {
        VStack(spacing: 10) {
            // Search field
            TextField("Search apps...", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
                .onChange(of: searchText) { newValue in
                    // Filtering is handled by computed property filteredApplications
                }
            
            // Applications list
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 5) {
                    ForEach(filteredApplications, id: \.self) { app in
                        Button(action: {
                            openApplication(app)
                        }) {
                            HStack {
                                Image(systemName: "app.badge")
                                    .foregroundColor(.blue)
                                Text(app)
                                Spacer()
                            }
                            .padding(.horizontal)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.vertical)
            }
            
            // Quit button
            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                Text("Quit")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
            .padding(.bottom, 5)
        }
        .frame(width: 250, height: 500)
        .onAppear {
            loadApplications()
        }
    }
    
    private var filteredApplications: [String] {
        if searchText.isEmpty {
            return applications
        }
        return applications.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }
    
    private func loadApplications() {
        let appPaths = [
            "/Applications",
            NSHomeDirectory() + "/Applications"
        ]
        
        var apps: [String] = []
        
        for path in appPaths {
            let url = URL(fileURLWithPath: path)
            if let contents = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil) {
                let appNames = contents.compactMap { fileURL -> String? in
                    if fileURL.pathExtension == "app" {
                        return fileURL.deletingPathExtension().lastPathComponent
                    }
                    return nil
                }
                apps.append(contentsOf: appNames)
            }
        }
        
        // Remove duplicates while preserving order
        var seen = Set<String>()
        applications = apps.filter { seen.insert($0).inserted }
    }
    
    private func filterApplications() {
        // Filtering is handled by computed property filteredApplications
        // This method is kept for compatibility with the onChange modifier
    }
    
    private func openApplication(_ appName: String) {
        let appPaths = [
            "/Applications/\(appName).app",
            NSHomeDirectory() + "/Applications/\(appName).app"
        ]
        
        for path in appPaths {
            let url = URL(fileURLWithPath: path)
            if FileManager.default.fileExists(atPath: url.path) {
                NSWorkspace.shared.open(url)
                break
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}