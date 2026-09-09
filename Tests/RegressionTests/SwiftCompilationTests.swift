import CGGenCLI
import CoreGraphics
import Foundation
import Testing

struct SwiftCompilationTests {
  @Test func swiftCodeCompilation() throws {
    let svgSamplesPath = getCurrentFilePath()
      .appendingPathComponent("svg_samples")
    let files = [
      "shapes.svg",
      "lines.svg",
    ].map { svgSamplesPath.appendingPathComponent($0) }

    let fm = FileManager.default
    let tmpdir = try fm.url(
      for: .itemReplacementDirectory,
      in: .userDomainMask,
      appropriateFor: fm.homeDirectoryForCurrentUser,
      create: true
    )
    defer {
      do {
        try fm.removeItem(at: tmpdir)
      } catch {
        fatalError("Unable to clean up dir: \(tmpdir), error: \(error)")
      }
    }

    let swiftFile = tmpdir.appendingPathComponent("generated.swift")

    // Generate Swift code
    try runCggen(
      with: .init(
        objcHeader: nil,
        objcPrefix: "Test",
        objcImpl: nil,
        objcHeaderImportPath: nil,
        generationStyle: .plain,
        cggenSupportHeaderPath: nil,
        module: nil,
        verbose: false,
        files: files.map(\.path),
        swiftOutput: swiftFile.path
      )
    )

    let generatedCode = try String(contentsOf: swiftFile, encoding: .utf8)
    let testProgram = generatedCode + """

    public func testGeneratedCode() {
      let _: Set<Drawing> = [.shapes, .lines]
    }
    """
    let testFile = tmpdir.appendingPathComponent("test.swift")
    try testProgram.write(to: testFile, atomically: true, encoding: .utf8)

    let products = Bundle(for: RuntimeModuleLocator.self).bundleURL
      .deletingLastPathComponent()
    let moduleDirectory = try #require([
      products.appendingPathComponent("Modules"), products,
    ].first {
      fm
        .fileExists(atPath: $0
          .appendingPathComponent("CGGenRTSupport.swiftmodule").path)
    })
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/swiftc")
    process.arguments = [
      "-parse-as-library", "-typecheck", "-warnings-as-errors",
      "-I", moduleDirectory.path, testFile.path,
    ]

    let pipe = Pipe()
    process.standardError = pipe
    process.standardOutput = pipe

    try process.run()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    let output = String(data: data, encoding: .utf8) ?? ""

    if process.terminationStatus != 0 {
      let generatedCode = try String(contentsOf: swiftFile, encoding: .utf8)
      Issue.record("""
      Swift compilation failed with status \(process.terminationStatus)
      Output: \(output)

      Generated Swift file contents:
      \(generatedCode)
      """)
    }

    #expect(process.terminationStatus == 0)
  }
}

private final class RuntimeModuleLocator: NSObject {}
