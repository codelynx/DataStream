// swift-tools-version:5.7

import PackageDescription

let package = Package(
	name: "DataStream",
	platforms: [
		.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6)
	],
	products: [
		.library(name: "DataStream", targets: ["DataStream"]),
	],
	targets: [
		.target(
			name: "DataStream",
			path: "DataStream"
		),
		.testTarget(
			name: "DataStreamTests",
			dependencies: ["DataStream"],
			path: "DataStreamTests_mac",
			exclude: ["Info.plist"]
		),
	]
)
