struct TextDiffResult {
  let persistent: [(old: CharacterBlock, new: CharacterBlock)]
  let entering: [CharacterBlock]
  let exiting: [CharacterBlock]
}

enum TextDiff {

  static func diff(old: [CharacterBlock], new: [CharacterBlock]) -> TextDiffResult {
    let newIDs = Set(new.map(\.id))
    let oldLookup = Dictionary(uniqueKeysWithValues: old.map { ($0.id, $0) })

    var persistent: [(old: CharacterBlock, new: CharacterBlock)] = []
    var entering: [CharacterBlock] = []

    for block in new {
      if let oldBlock = oldLookup[block.id] {
        persistent.append((old: oldBlock, new: block))
      } else {
        entering.append(block)
      }
    }

    let exiting = old.filter { !newIDs.contains($0.id) }

    return TextDiffResult(
      persistent: persistent,
      entering: entering,
      exiting: exiting
    )
  }
}
