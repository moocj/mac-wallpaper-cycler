import AppKit
import Combine

// Everything the app remembers, for now just the wallpaper folder.

final class Cycler: ObservableObject {
    static let shared = Cycler()

    // wallpaper folders
    @Published private(set) var sources: [URL] = []
    // wallpapers
    @Published private(set) var library: [URL] = []
    // the wallpaper up next for previewing
    @Published private(set) var upNext: [URL] = []
    // wallpapers that have just been shown
    @Published private(set) var recent: [URL] = []
    // flag is there are previous wallpapers we can go back to
    @Published private(set) var canGoBack = false
    // current wallpaper
    @Published private(set) var currentImage: URL? = nil
    // prevent wallpaper changing when paused
    @Published var isPaused = false {
        didSet {
            UserDefaults.standard.set(isPaused, forKey : Key.paused)
            startTimer()
        }
    }

    @Published var shuffle = false {
        didSet {
            UserDefaults.standard.set(shuffle, forKey: Key.shuffle)
            rebuildQueue()
        }
    }

    @Published var snapToClock = false {
        didSet {
            UserDefaults.standard.set(snapToClock, forKey: Key.snapToClock)
            startTimer()
        }
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
    private var queue: [URL] = []
    private var history: [URL] = []

    private enum Key {
        static let sources = "sources"
        static let lastImage = "lastImage"
        static let paused = "paused"
        static let intervalValue = "intervalValue"
        static let intervalUnit = "intervalUnit"
        static let shuffle = "shuffle"
        static let snapToClock = "snapToClock"
    }

    private init() {
        let saved = UserDefaults.standard.stringArray(forKey: Key.sources) ?? []
        sources = saved.map {URL(fileURLWithPath: $0) }
        if let path = UserDefaults.standard.string(forKey: Key.lastImage),
            FileManager.default.fileExists(atPath: path) {
                currentImage = URL(fileURLWithPath: path)
            }

        isPaused = UserDefaults.standard.bool(forKey: Key.paused)
        shuffle = UserDefaults.standard.bool(forKey: Key.shuffle)
        let savedInterval = UserDefaults.standard.double(forKey: Key.intervalValue)
        intervalValue = savedInterval > 0 ? savedInterval : 15
        intervalUnit = IntervalUnit(rawValue: UserDefaults.standard.string(forKey: Key.intervalUnit) ?? "") ?? .minutes
        snapToClock = UserDefaults.standard.bool(forKey: Key.snapToClock)
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

        // try to put this in front of any other apps to prevent it being hidden since its not a dock app
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

        rebuildQueue()
    }

    private func rebuildQueue() {
        queue = library
        if shuffle { queue.shuffle() }

        // dont give back the same wallpaper
        if let current = currentImage, queue.first == current, queue.count > 1 {
            queue.append(queue.removeFirst())
        }
        refreshUpNext()
    }

    private func refreshUpNext() {
        upNext = Array(queue.prefix(4))
    }

    private func pushHistory(_ url: URL) {
        history.append(url)
        // cap of 50 wallpapers
        if history.count > 50 {history.removeFirst() }
        updateRecent()
    }

    private func updateRecent() {
        recent = Array(history.reversed().prefix(8))
        canGoBack = !history.isEmpty
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
        timer = nil

        guard !isPaused else { return }

        let delay = max(1, snapToClock ? secondsUntilNextClockBoundary() : intervalSeconds)

        let once = Timer(timeInterval: delay, repeats: false) {
            [weak self] _ in
                self?.next()
                self?.startTimer()
        }
        RunLoop.main.add(once, forMode: .common)
        timer = once
    }

    private func secondsUntilNextClockBoundary() -> Double {
        let now = Date()
        // time since midnight so we can snap boundaries to :00, :15, :30 etc
        let elapsed = now.timeIntervalSince(Calendar.current.startOfDay(for: now))
        let next = (floor(elapsed / intervalSeconds) + 1) * intervalSeconds
        return next - elapsed
    }

    // move to next wallpaper and wrap at end
    func next() {
        guard !library.isEmpty else { return }

        if queue.isEmpty { rebuildQueue() }
        guard !queue.isEmpty else { return }

        if let current = currentImage { pushHistory(current) }
        apply(queue.removeFirst())
        refreshUpNext()
    }

    // move to previous wallpaper and wrap at start (now using history)
    func previous() {
        guard let earlier = history.popLast() else { return }

        // current wallpaper goes to front of queue so
        // stepping back and then forward moves back to same wallpaper
        if let current = currentImage { queue.insert(current, at: 0)}

        apply(earlier)
        updateRecent()
        refreshUpNext()
    }

    private func save(_ paths: [String]) {
        UserDefaults.standard.set(paths, forKey: Key.sources)
        sources = paths.map { URL(fileURLWithPath: $0) }
        rescan()
        showSomething()
    }
}