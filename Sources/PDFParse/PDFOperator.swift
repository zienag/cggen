// Copyright (c) 2017 Yandex LLC. All rights reserved.
// Author: Alfred Zien <zienag@yandex-team.ru>

import CoreGraphics
import Foundation

enum PDFOperator {
  // b
  case closeFillStrokePathWinding
  // B
  case fillStrokePathWinding
  // b*
  case closeFillStrokePathEvenOdd
  // B*
  case fillStrokePathEvenOdd
  // BDC
  case markedContentSequenceWithPListBegin
  // BI
  case inlineImageBegin
  // BMC
  case markedContentSequenceBegin
  // BT
  case textObjectBegin
  // BX
  case compatabilitySectionBegin
  // c
  case curveTo(CGPoint, CGPoint, CGPoint)
  // cm
  case concatCTM(CGAffineTransform)
  // CS
  case colorSpaceStroke(String)
  // cs
  case colorSpaceNonstroke(String)
  // d
  case dash(CGFloat, [CGFloat])
  // d0
  case glyphWidthInType3Font
  // d1
  case glyphWidthAndBoundingBoxInType3Font
  // Do
  case invokeXObject(String)
  // DP
  case markedContentPointWithPListDefine
  // EI
  case inlineImageEnd
  // EMC
  case markedContentSequenceEnd
  // ET
  case textObjectEnd
  // EX
  case compatabilitySectionEnd
  // f
  case fillWinding
  // F
  case fillWindingObsolete
  // f*
  case fillEvenOdd
  // G
  case grayLevelStroke
  // g
  case grayLevelNonstroke
  // gs
  case applyGState(String)
  // h
  case closeSubpath
  // i
  case setFlatnessTolerance(CGFloat)
  // ID
  case inlineImageDataBegin
  // j
  case lineJoinStyle(Int)
  // J
  case lineCapStyle(Int)
  // K
  case cmykColorStroke
  // k
  case cmykColorNonstroke
  // l
  case lineTo(CGPoint)
  // m
  case moveTo(CGPoint)
  // M
  case miterLimit
  // MP
  case markedContentPointDefine
  // n
  case endPath
  // q
  case saveGState
  // Q
  case restoreGState
  // re
  case appendRectangle(CGRect)
  // RG
  case rgbColorStroke(RGBColor)
  // rg
  case rgbColorNonstroke(RGBColor)
  // ri
  case colorRenderingIntent
  // s
  case closeAndStrokePath
  // S
  case strokePath
  // SC
  case colorStroke(RGBColor)
  // sc
  case colorNonstroke(RGBColor)
  // SCN
  case iccOrSpecialColorStroke
  // scn
  case iccOrSpecialColorNonstroke
  // sh
  case shadingFill(String)
  // T*
  case startNextTextLine
  // Tc
  case characterSpacing
  // Td
  case moveTextPosition
  // TD
  case moveTextPositionAnsSetLeading
  // Tf
  case textFontAndSize
  // Tj
  case showText
  // TJ
  case showTextAllowingIndividualGlyphPositioning
  // TL
  case textLeading
  // Tm
  case textAndTextLineMatrix
  // Tr
  case textRenderingMode
  // Ts
  case textRise
  // Tw
  case wordSpacing
  // Tz
  case horizontalTextScaling
  // v
  case curveToWithInitailPointReplicated
  // w
  case lineWidth(CGFloat)
  // W
  case clipWinding
  // W*
  case clipEvenOdd
  // y
  case curveToWithFinalPointReplicated
  // '
  case moveToNextLineAndShowText
  // "
  case wordAndCharacterSpacingMoveToNextLineAndShowText
}
