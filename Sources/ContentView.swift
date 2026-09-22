import SwiftUI

// All the stuff inside the popover
struct ContentView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "photo.on.rectangle.angled")
                .font (.system(size:30, weight: .light))
                .foregroundStyle(.secondary)
            Text("Wallpaper Cycler")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
        }
        .frame(width: 260)
        .padding(24)
    }
}
