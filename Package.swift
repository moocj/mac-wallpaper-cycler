// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "WallpaperCycler",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "WallpaperCycler",
            path: "Sources"
        )
    ]
)