import PDFParse

struct Outputs {
  var mainImage: Image
  var path: [PathRoutine]
}

struct Image {
  let name: String
  let route: DrawRoutine
}
