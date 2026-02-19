import UIKit

enum LayoutEngine {

  struct CharacterFrame {
    let id: String
    let character: Character
    let frame: CGRect
  }

  static func measure(
    blocks: [CharacterBlock],
    font: UIFont,
    letterSpacing: CGFloat = 0
  ) -> (frames: [CharacterFrame], totalSize: CGSize) {
    guard !blocks.isEmpty else { return ([], .zero) }

    var frames: [CharacterFrame] = []
    var x: CGFloat = 0
    let height = ceil(font.lineHeight)
    let attrs: [NSAttributedString.Key: Any] = [.font: font]

    for (i, block) in blocks.enumerated() {
      let charWidth = (String(block.character) as NSString).size(
        withAttributes: attrs
      ).width
      let w = ceil(charWidth)
      frames.append(
        CharacterFrame(
          id: block.id,
          character: block.character,
          frame: CGRect(x: x, y: 0, width: w, height: height)
        )
      )
      x += w
      if i < blocks.count - 1 {
        x += letterSpacing
      }
    }

    return (frames, CGSize(width: x, height: height))
  }
}
