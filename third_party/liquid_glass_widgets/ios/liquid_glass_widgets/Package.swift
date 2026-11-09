// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "liquid_glass_widgets",
    platforms: [
        // 上游为 15.0；下调以继续支持 iOS 13/14，原生 API 均有可用性检查。
        .iOS("13.0")
    ],
    products: [
        .library(name: "liquid-glass-widgets", targets: ["liquid_glass_widgets"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "liquid_glass_widgets",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
