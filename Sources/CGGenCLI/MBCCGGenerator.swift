import CGGenIR
import Compression
import Foundation

private struct UnifiedBytecodeData {
  let compressedBytecode: [UInt8]
  let decompressedSize: Int
  let compressedSize: Int
  let imagePositions: [(Image, (start: Int, end: Int))]
  let pathPositions: [(PathRoutine, (start: Int, end: Int))]
}

func generateObjCImplementationFile(
  params: GenerationParams,
  headerImportPath: String?,
  outputs: [Output]
) throws -> String {
  let unifiedBytecodeData = try generateUnifiedBytecode(outputs: outputs)

  var sections = [String]()

  // Header comment
  sections.append(commonHeaderPrefix)

  // Imports and forward declarations
  if let headerImportPath {
    sections.append("#import \"\(headerImportPath)\"")
  }

  sections.append("""
  #import <dispatch/dispatch.h>

  const void *CGGenCreateBytecodeStorage(const uint8_t *bytes, intptr_t count, intptr_t decompressedSize);
  void CGGenDrawBytecode(CGContextRef context, const void *storage, intptr_t startIndex, intptr_t endIndex);
  void CGGenApplyPathBytecode(CGMutablePathRef path, const void *storage, intptr_t startIndex, intptr_t endIndex);

  static const uint8_t mergedBytecodes[\(unifiedBytecodeData.compressedSize)];

  static const void *bytecodeStorage(void) {
    static const void *storage;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
      storage = CGGenCreateBytecodeStorage(mergedBytecodes, \(
        unifiedBytecodeData
          .compressedSize
  ), \(unifiedBytecodeData.decompressedSize));
    });
    return storage;
  }
  """)

  // Image functions
  let imageFunctions = generateImageFunctions(
    params: params,
    unifiedBytecodeData: unifiedBytecodeData
  )
  sections.append(imageFunctions)

  // Path functions
  let pathFunctions = generatePathFunctions(
    params: params,
    unifiedBytecodeData: unifiedBytecodeData
  )
  if !pathFunctions.isEmpty {
    sections.append(pathFunctions)
  }

  // Bytecode array
  sections.append("""
  static const uint8_t mergedBytecodes[] = {
  \(formatBytecodeArray(unifiedBytecodeData.compressedBytecode))
  };
  """)

  return sections.joined(separator: "\n\n") + "\n"
}

private func generateUnifiedBytecode(outputs: [Output]) throws
  -> UnifiedBytecodeData {
  var mergedBytecodes: [UInt8] = []
  var imagePositions: [(Image, (start: Int, end: Int))] = []
  var pathPositions: [(PathRoutine, (start: Int, end: Int))] = []

  // Process images
  let images = outputs.map(\.image)
  for image in images {
    let bytecode = generateRouteBytecode(route: image.route)
    let position = (
      start: mergedBytecodes.count,
      end: mergedBytecodes.count + bytecode.count - 1
    )
    imagePositions.append((image, position))
    mergedBytecodes += bytecode
  }

  // Process paths
  let paths = outputs.flatMap(\.pathRoutines)
  for path in paths {
    let bytecode = generatePathBytecode(route: path)
    let position = (
      start: mergedBytecodes.count,
      end: mergedBytecodes.count + bytecode.count - 1
    )
    pathPositions.append((path, position))
    mergedBytecodes += bytecode
  }

  let decompressedSize = mergedBytecodes.count
  let compressedBytecode = try compressBytecode(mergedBytecodes)
  let compressedSize = compressedBytecode.count

  return UnifiedBytecodeData(
    compressedBytecode: compressedBytecode,
    decompressedSize: decompressedSize,
    compressedSize: compressedSize,
    imagePositions: imagePositions,
    pathPositions: pathPositions
  )
}

private func generateImageFunctions(
  params: GenerationParams,
  unifiedBytecodeData: UnifiedBytecodeData
) -> String {
  unifiedBytecodeData.imagePositions
    .map { image, position in
      generateImageFunction(
        params: params,
        image: image,
        position: position
      )
    }.joined(separator: "\n\n")
}

private func generateImageFunction(
  params: GenerationParams,
  image: Image,
  position: (start: Int, end: Int)
) -> String {
  """
  \(params.style.drawingHandlerPrefix)void \(params.prefix)Draw\(
    image.name.upperCamelCase
  )ImageInContext(CGContextRef context) {
    CGGenDrawBytecode(context, bytecodeStorage(), \(position.start), \(position
    .end));
  }
  """ + params.descriptorLines(for: image).joined(separator: "\n")
}

private func generatePathFunctions(
  params: GenerationParams,
  unifiedBytecodeData: UnifiedBytecodeData
) -> String {
  guard !unifiedBytecodeData.pathPositions.isEmpty else { return "" }

  return unifiedBytecodeData.pathPositions
    .map { path, position in
      let camel = path.id.upperCamelCase
      return """
      void \(params.prefix)\(camel)Path(CGMutablePathRef path) {
        CGGenApplyPathBytecode(path, bytecodeStorage(), \(position
        .start), \(position.end));
      }
      """
    }.joined(separator: "\n\n")
}

private func formatBytecodeArray(_ bytes: [UInt8]) -> String {
  // Format bytecode array with line breaks every 12 bytes for readability
  let bytesPerLine = 12
  var lines: [String] = []

  for i in stride(from: 0, to: bytes.count, by: bytesPerLine) {
    let end = min(i + bytesPerLine, bytes.count)
    let lineBytes = bytes[i..<end].map { String(format: "0x%02X", $0) }
      .joined(separator: ", ")
    let indent = "  " // Consistent 2 space indentation
    lines.append(indent + lineBytes)
  }

  return lines.joined(separator: ",\n")
}

func compressBytecode(_ bytecode: [UInt8]) throws -> [UInt8] {
  let pageSize = 128
  let sourceData = Data(bytecode)
  var compressedData = Data()

  let outputFilter = try OutputFilter(
    .compress,
    using: .lzfse,
    writingTo: { (data: Data?) in
      if let data {
        compressedData.append(data)
      }
    }
  )

  var index = 0
  let bufferSize = sourceData.count

  while true {
    let rangeLength = min(pageSize, bufferSize - index)

    let subdata = sourceData.subdata(in: index..<index + rangeLength)
    index += rangeLength

    try outputFilter.write(subdata)

    if rangeLength == 0 { break }
  }
  return [UInt8](compressedData)
}
