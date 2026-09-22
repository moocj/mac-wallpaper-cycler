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
    // prevent wallpaper changing when paused
    @Published var isPaused = false {
        didSet { UserDefaults.standard.set(isPaused, forKey : Key.paused) }
    }

    private static let imageExtensions: Set<String> = [
        "jpg", "jpeg", "png", "heic", "heif", "tif", "tiff", "bmp", "gif", "webp"
    ]

    @Published var intervalValue: Double = 15 {
        didSet{
            UserDefaults.standard.set(intervalValue, forKey: Key.intervalValue)
            startTimer()
        }
    }

    @Published var intervalUnit: IntervalUnit = .minutes {
        didSet {
            UserDefaults.standard.set(intervalUnit.rawValue, forKey: Key.intervalUnit)
            startTimer()
        }
    }

    var intervalSeconds: Double { max(5, intervalValue * intervalUnit.seconds)}

    private var timer: Timer?

    private enum Key {
        static let sources = "sources"
        static let lastImage = "lastImage"
        static let paused = "paused"
        static let intervalValue = "intervalValue"
        static let intervalUnit = "intervalUnit"
    }

    private init() {
        let saved = UserDefaults.standard.stringArray(forKey: Key.sources) ?? []
        sources = saved.map {URL(fileURLWithPath: $0) }
        if let path = UserDefaults.standard.string(forKey: Key.lastImage),
            FileManager.default.fileExists(atPath: path) {
                currentImage = URL(fileURLWithPath: path)
            }

        isPaused = UserDefaults.standard.bool(forKey: Key.paused)
        let savedInterval = UserDefaults.standard.double(forKey: Key.intervalValue)
        intervalValue = savedInterval > 0 ? savedInterval : 15
        intervalUnit = IntervalUnit(rawValue: UserDefaults.standard.string(forKey: Key.intervalUnit) ?? "") ?? .minutes
        rescan()
        showSomething()
        startTimer()
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

        // if the wallpaper was from that folder then switch
        if let showing = currentImage, !library.contains(showing), let first = library.first {
            apply(first)
        }
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

    private func startTimer() {
        timer?.invalidate()
        let repeating = Timer(timeInterval: intervalSeconds, repeats: true) {
            [weak self] _ in
                guard let self, !self.isPaused else { return }
                self.next()
        }
        // .common means it will still work if another menu is open
        RunLoop.main.add(repeating, forMode: .common)
        timer = repeating
    }
    // stores where current wallpaper is
    private var currentIndex: Int? {
        guard let current = currentImage else { return nil }
        return library.firstIndex(of: current)
    }

    // move to next wallpaper and wrap at end
    func next() {
        guard !library.isEmpty else { return }
        let index = currentIndex.map { ($0 + 1) % library.count} ?? 0
        apply(library[index])
    }

    // move to previous wallpaper and wrap at start
    func previous() {
        guard !library.isEmpty else { return }
        let index = currentIndex.map { ($0 - 1 + library.count) % library.count} ?? library.count - 1
        apply(library[index])
    }

    private func save(_ paths: [String]) {
        UserDefaults.standard.set(paths, forKey: Key.sources)
        sources = paths.map { URL(fileURLWithPath: $0) }
        rescan()
        showSomething()
    }
}