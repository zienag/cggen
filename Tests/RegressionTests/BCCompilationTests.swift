import AppKit
import CGGenCLI
import CoreGraphics
import Darwin
import Foundation
import Testing

struct BCCompilationTests {
  @Test func generatedDrawingAndPathExecuteThroughCABI() throws {
    let fm = FileManager.default
    let temporary = try fm.url(
      for: .itemReplacementDirectory, in: .userDomainMask,
      appropriateFor: fm.homeDirectoryForCurrentUser, create: true
    )
    defer {
      do { try fm.removeItem(at: temporary) }
      catch { Issue.record(error) }
    }
    let sample = getCurrentFilePath()
      .appendingPathComponent("svg_samples/paths_and_images.svg")
    let header = temporary.appendingPathComponent("generated.h")
    let implementation = temporary.appendingPathComponent("generated.m")
    let library = temporary.appendingPathComponent("generated.dylib")
    try runCggen(with: .init(
      objcHeader: header.path, objcPrefix: "Tests",
      objcImpl: implementation.path,
      objcHeaderImportPath: header.path, generationStyle: .plain,
      cggenSupportHeaderPath: nil, module: nil, verbose: false,
      files: [sample.path], swiftOutput: nil
    ))
    let code = try String(contentsOf: implementation, encoding: .utf8)
    try (code + """

    void CGGenReleaseBytecodeStorage(const void *storage);
    void TestsReleaseStorage(void) {
      CGGenReleaseBytecodeStorage(bytecodeStorage());
    }
    """).write(to: implementation, atomically: true, encoding: .utf8)
    try clang(
      out: library, files: [implementation],
      frameworks: ["CoreGraphics", "Foundation"],
      additionalArguments: ["-dynamiclib", "-undefined", "dynamic_lookup"]
    )
    let handle = try #require(dlopen(library.path, RTLD_NOW))
    defer { dlclose(handle) }
    let draw = try unsafeBitCast(
      #require(dlsym(handle, "TestsDrawPathsAndImagesImageInContext")),
      to: (@convention(c) (CGContext) -> Void).self
    )
    let applyPath = try unsafeBitCast(
      #require(dlsym(handle, "TestsTrianglePath")),
      to: (@convention(c) (CGMutablePath) -> Void).self
    )
    let release = try unsafeBitCast(
      #require(dlsym(handle, "TestsReleaseStorage")),
      to: (@convention(c) () -> Void).self
    )
    defer { release() }
    let context = try #require(CGContext(
      data: nil, width: 50, height: 50, bitsPerComponent: 8, bytesPerRow: 0,
      space: CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ))
    context.setAllowsAntialiasing(false)
    draw(context)
    let result = try #require(context.makeImage())
    let (bytes, _) = try getImageBytecode(from: sample)
    let reference = try renderBytecode(
      bytes, width: 50, height: 50, scale: 1, antialiasing: false
    )
    let resultBytes = try #require(result.dataProvider?.data) as Data
    let referenceBytes = try #require(reference.dataProvider?.data) as Data
    #expect(resultBytes == referenceBytes)
    let path = CGMutablePath()
    applyPath(path)
    #expect(path.boundingBoxOfPath == CGRect(x: 5, y: 5, width: 40, height: 35))
  }

  @Test func compilation() throws {
    let variousFilenamesDir =
      getCurrentFilePath().appendingPathComponent("various_filenames")
    let files = [
      "Capital letter.svg",
      "dash-dash.svg",
      "under_score.svg",
      "white space.svg",
    ]

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

    let header = tmpdir.appendingPathComponent("gen.h").path
    let impl = tmpdir.appendingPathComponent("gen.m")

    try runCggen(
      with: .init(
        objcHeader: header,
        objcPrefix: "Tests",
        objcImpl: impl.path,
        objcHeaderImportPath: header,
        generationStyle: .plain,
        cggenSupportHeaderPath: nil,
        module: nil,
        verbose: false,
        files: files
          .map { variousFilenamesDir.appendingPathComponent($0).path },
        swiftOutput: nil
      )
    )

    try clang(
      out: nil,
      files: [impl],
      syntaxOnly: true,
      frameworks: []
    )
  }
}
