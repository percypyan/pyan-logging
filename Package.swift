// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PyanLogging",
	platforms: [
		.iOS(.v18),
		.macOS(.v15),
		.tvOS(.v18),
		.watchOS(.v11),
		.visionOS(.v2)
	],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "PyanLogging",
            targets: ["PyanLogging"]
        ),
    ],
	dependencies: [
		.package(url: "https://github.com/apple/swift-log", from: "1.10.1")
	],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "PyanLogging",
			dependencies: [
				.product(name: "Logging", package: "swift-log")
			]
        ),
        .testTarget(
            name: "PyanLoggingTests",
            dependencies: ["PyanLogging"]
        ),
    ]
)
