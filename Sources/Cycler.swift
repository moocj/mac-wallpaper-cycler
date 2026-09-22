import AppKit
import Combine

// Everything the app remembers, for now just the wallpaper folder.

final class Cycler: ObservableObject {
    static let shared = Cycler()

    // wallpaper folders
    @Published private(set) var sources: [URL] = []
    // wallpapers
    @Published private(set) var library: [URL] = []
    // current wallpaper
    @Published private(set) var currentImage: URL? = nil

    private static let imageExtensions: Set<String> = [
        "jpg", "jpeg", "png", "heic", "heif", "tif", "tiff", "bmp", "gif", "webp"
    ]

    private enum Key {
        static let sources = "sources"
        static let lastImage = "lastImage"
    }

    private init() {
        let saved = UserDefaults.standard.stringArray(forKey: Key.sources) ?? []
        sources = saved.map {URL(fileURLWithPath: $0) }
        if let path = UserDefaults.standard.string(forKey: Key.lastImage),
            FileManager.default.fileExists(atPath: path) {
                currentImage = URL(fileURLWithPath: path)
            }

        rescan()
        showSomething()
    }

    // ask for folder(s) and add any that aren't in list
    func addSources() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.prompt = "Add"
        panel.message = "Pick the folder that contains your wallpapers."

        // try to put this infront of any other apps to prevent it being hidden since its not a dock app
        if #available(macOS 14.0, *) {
            NSApp.activate()
        } else {
            NSApp.activate(ignoringOtherApps: true)
        }

        guard panel.runModal() == .OK else { return }

        var paths = sources.map(\.path)
        for url in panel.urls where !paths.contains(url.path) {
            paths.append(url.path)
        }
        save(paths)
    }

    func removeSource(_ url: URL) {
        save(sources.map(\.path).filter{ $0 != url.path })
    }

    // get images inside source folders
    func rescan() {
        var found: [URL] = []
        let fm = FileManager.default

        for source in sources {
            guard let walker = fm.enumerator(
                at: source,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else { continue }

            for case let url as URL in walker {
                if Self.imageExtensions.contains(url.pathExtension.lowercased()) {
                    found.append(url)
                }
            }
        }

        // stop duplicate wallpapers
        var seen = Set<String>()
        library = found.filter { seen.insert($0.path).inserted }

    }

    func apply(_ url: URL) {
        for screen in NSScreen.screens {
            try? NSWorkspace.shared.setDesktopImageURL(url, for: screen, options: [:])
        }
        currentImage = url
        UserDefaults.standard.set(url.path, forKey: Key.lastImage)
    }

    // either puts the last wallpaper back or shows the first found to avoid empty wallpaper
    func showSomething() {
        guard let url = currentImage ?? library.first else { return }
        apply(url)
    }

    private func save(_ paths: [String]) {
        UserDefaults.standard.set(paths, forKey: Key.sources)
        sources = paths.map { URL(fileURLWithPath: $0) }
        rescan()
        showSomething()
    }
}