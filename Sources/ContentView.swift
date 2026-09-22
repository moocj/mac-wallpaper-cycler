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
                        Text(url.lastPathComponent)
                            .font(.system(size:11))
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .help(url.path)
                    }
                }
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
