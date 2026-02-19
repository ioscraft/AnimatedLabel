enum Segmenter {

  static func segment(_ text: String) -> [CharacterBlock] {
    var blocks: [CharacterBlock] = []
    var seen: Set<String> = []

    for (index, character) in text.enumerated() {
      let key = String(character)
      let id: String

      if character == " " {
        id = "space-\(index)"
      } else if seen.contains(key) {
        id = "\(key)-\(index)"
      } else {
        id = key
        seen.insert(key)
      }

      blocks.append(CharacterBlock(id: id, character: character, index: index))
    }

    return blocks
  }

  static func segmentByPosition(_ text: String) -> [CharacterBlock] {
    text.enumerated().map { index, character in
      CharacterBlock(id: "p\(index)", character: character, index: index)
    }
  }
}
