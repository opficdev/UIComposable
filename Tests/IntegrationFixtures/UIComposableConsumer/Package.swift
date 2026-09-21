// swift-tools-version: 6.0

import PackageDescription

let package = Package(
	name: "UIComposableConsumer",
	platforms: [
		.iOS(.v17)
	],
	products: [
		.library(
			name: "UIComposableConsumer",
			targets: ["UIComposableConsumer"]
		)
	],
	dependencies: [
		.package(path: "../../..")
	],
	targets: [
		.target(
			name: "UIComposableConsumer",
			dependencies: [
				.product(name: "UIComposable", package: "UIComposable")
			]
		)
	]
)
