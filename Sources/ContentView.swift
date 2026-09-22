import SwiftUI

// All the stuff inside the popover
struct ContentView: View {
    @ObservedObject private var cycler = Cycler.shared

    private struct Preset: Identifiable {
        let label: String
        let value: Double
        let unit: IntervalUnit
        var id: String { label }
        var seconds: Double { value * unit.seconds }
    }

    private let presets: [Preset] = [
        Preset(label: "30s", value: 30, unit: .seconds),
        Preset(label: "1m",  value: 1,  unit: .minutes),
        Preset(label: "5m",  value: 5,  unit: .minutes),
        Preset(label: "15m", value: 15, unit: .minutes),
        Preset(label: "30m", value: 30, unit: .minutes),
        Preset(label: "1h",  value: 1,  unit: .hours),
        Preset(label: "3h",  value: 3,  unit: .hours),
        Preset(label: "6h",  value: 6,  unit: .hours),
        Preset(label: "1d",  value: 24, unit: .hours)
    ]

    private func isSelected(_ preset: Preset) -> Bool {
        abs(cycler.intervalSeconds - preset.seconds) < 0.5
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(cycler.currentImage?.lastPathComponent ?? "No wallpaper showing")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .truncationMode(.middle)
                .help(cycler.currentImage?.path ?? "")

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
            VStack(alignment: .leading, spacing: 8) {
                Text("Change every")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 5), spacing: 6) {
                    ForEach(presets) { preset in
                        Button {
                            cycler.intervalValue = preset.value
                            cycler.intervalUnit = preset.unit
                        } label: {
                            Text(preset.label)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule().fill(isSelected(preset)
                                        ? Color.accentColor.opacity(0.85)
                                        : Color.secondary.opacity(0.15))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }

                HStack(spacing: 8) {
                    TextField("15", value: $cycler.intervalValue, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.center)
                        .frame(width: 60)

                    Picker("", selection: $cycler.intervalUnit) {
                        ForEach(IntervalUnit.allCases) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                    .labelsHidden()

                    Spacer()
                }

                Text("Smallest interval is 5 seconds.")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            HStack{
                Button("Previous") { cycler.previous() }
                    .disabled(cycler.library.isEmpty)
                Button("Next") { cycler.next() }
                    .disabled(cycler.library.isEmpty)
                Spacer()
                Button(cycler.isPaused ? "Resume" : "Pause") {
                    cycler.isPaused.toggle()
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
