// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to
// build this package.

import PackageDescription

let package = Package(
  name: "cggen",
  platforms: [
    .macOS(.v14), .iOS(.v13),
  ],
  products: [
    .executable(name: "cggen", targets: ["cggen"]),
    .library(name: "cggen-runtime-support", targets: ["CGGenRuntimeSupport"]),
    .plugin(name: "cggen-spm-plugin", targets: ["plugin"]),
  ],
  dependencies: [
    .package(
      url: "https://github.com/apple/swift-argument-parser",
      .upToNextMajor(from: "1.5.1")
    ),
    .package(
      url: "https://github.com/pointfreeco/swift-parsing",
      .upToNextMajor(from: "0.14.1")
    ),
  ],
  targets: [
    .target(
      name: "BCCommon"
    ),
    .target(
      name: "CGGenRuntimeSupport",
      dependencies: ["BCCommon"]
    ),
    .executableTarget(
      name: "cggen",
      dependencies: [
        "libcggen",
        "Base",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ]
    ),
    .target(
      name: "libcggen",
      dependencies: ["Base", "SVGParse", "PDFParse", "BCCommon"]
    ),
    .target(
      name: "Base",
      dependencies: [
        .product(name: "Parsing", package: "swift-parsing"),
      ]
    ),
    .target(
      name: "SVGParse",
      dependencies: [
        "Base",
        .product(name: "Parsing", package: "swift-parsing"),
      ]
    ),
    .target(
      name: "PDFParse",
      dependencies: ["Base"]
    ),
    .testTarget(
      name: "UnitTests",
      dependencies: ["Base", "SVGParse", "libcggen"],
      resources: [
        .copy("UnitTests.xctestplan"),
      ]
    ),
    .testTarget(
      name: "RegressionTests",
      dependencies: ["libcggen", "CGGenRuntimeSupport"],
      exclude: ["__Snapshots__"],
      resources: [
        .copy("pdf_samples"),
        .copy("svg_samples"),
        .copy("various_filenames"),
        .copy("tests.sketch"),
        .copy("RegressionSuite.xctestplan"),
      ]
    ),
    .executableTarget(
      name: "plugin-demo",
      dependencies: ["CGGenRuntimeSupport"],
      plugins: ["plugin"]
    ),
    .plugin(
      name: "plugin",
      capability: .buildTool(),
      dependencies: ["cggen"]
    ),
  ]
)
