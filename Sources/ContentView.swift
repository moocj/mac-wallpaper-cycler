import SwiftUI

// All the stuff inside the popover
struct ContentView: View {
    @ObservedObject private var cycler = Cycler.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Wallpaper folders")
                .font(.system(size: 12, weight: .semibold, design: .rounded))

            if cycler.sources.isEmpty {
                Text("No folders yet. Pick one that has your wallpapers in.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal:false, vertical: true)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(cycler.sources, id: \.self) {url in
                        HStack {
                            Text(url.lastPathComponent)
                                .font(.system(size:11))
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .help(url.path)
                            Spacer()
                            Button {
                                cycler.removeSource(url)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size:11))
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .help("Remove this folder")
                        }
                    }
                }
                Text("\(cycler.library.count) wallpapers found")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            HStack {
                Button("Choose folder...") {
                    cycler.addSources()
                }
                Spacer()
                Button("Quit"){
                    NSApp.terminate(nil)
                }
                .keyboardShortcut("q")
            }
        }
        .frame(width: 300, alignment: .leading)
        .padding(16)
    }
}
