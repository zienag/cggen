import Foundation

import Base

protocol CoreGraphicsGenerator {
  func filePreamble() -> String
  func generateImageFunction(image: Image) -> String
  func generatePathFunction(path: PathRoutine) -> String
  func fileEnding() -> String
}

extension CoreGraphicsGenerator {
  func generateFile(images: [Outputs]) -> String {
    let functions = images.map(\.mainImage)
      .map(generateImageFunction).joined(separator: "\n\n")
    let pathFunctions = images.flatMap(\.path)
      .map(generatePathFunction).joined(separator: "\n\n")
    return
      """
      \(commonHeaderPrefix.renderText())

      \(filePreamble())
      \(functions)

      \(pathFunctions)

      \(fileEnding())

      """
  }
}
