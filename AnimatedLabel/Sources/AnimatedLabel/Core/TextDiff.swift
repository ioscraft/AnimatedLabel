import CoreGraphics

struct TextDiffResult {
  let persistent: [(old: CharacterBlock, new: CharacterBlock)]
  let entering: [CharacterBlock]
  let exiting: [CharacterBlock]
  let changeRatio: CGFloat
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

    let maxCount = max(old.count, new.count)
    let changeRatio: CGFloat = maxCount > 0
      ? CGFloat(entering.count + exiting.count) / CGFloat(maxCount)
      : 0

    return TextDiffResult(
      persistent: persistent,
      entering: entering,
      exiting: exiting,
      changeRatio: min(changeRatio, 1)
    )
  }

  static func morphDiff(
    oldBlocks: [CharacterBlock],
    newText: String
  ) -> (newBlocks: [CharacterBlock], result: TextDiffResult) {
    let oldText = String(oldBlocks.map(\.character))
    let oldHasWords = oldText.contains(" ")
    let newHasWords = newText.contains(" ")

    if oldHasWords || newHasWords {
      return wordLevelDiff(oldBlocks: oldBlocks, oldText: oldText, newText: newText)
    } else {
      return characterLevelDiff(oldBlocks: oldBlocks, newText: newText)
    }
  }

  private static func characterLevelDiff(
    oldBlocks: [CharacterBlock],
    newText: String
  ) -> (newBlocks: [CharacterBlock], result: TextDiffResult) {
    let oldChars = oldBlocks.map(\.character)
    let newChars = Array(newText)
    let matches = computeLCS(oldChars, newChars)

    let matchedOldIndices = Set(matches.map(\.oldIndex))
    var newIndexToOldIndex: [Int: Int] = [:]
    for m in matches {
      newIndexToOldIndex[m.newIndex] = m.oldIndex
    }

    var inheritedIDs: Set<String> = []
    for m in matches {
      inheritedIDs.insert(oldBlocks[m.oldIndex].id)
    }

    var newBlocks: [CharacterBlock] = []
    var persistent: [(old: CharacterBlock, new: CharacterBlock)] = []
    var nextID = 0

    for i in 0..<newChars.count {
      if let oldIndex = newIndexToOldIndex[i] {
        let oldBlock = oldBlocks[oldIndex]
        let block = CharacterBlock(id: oldBlock.id, character: newChars[i], index: i)
        newBlocks.append(block)
        persistent.append((old: oldBlock, new: block))
      } else {
        while inheritedIDs.contains("n\(nextID)") {
          nextID += 1
        }
        newBlocks.append(CharacterBlock(id: "n\(nextID)", character: newChars[i], index: i))
        nextID += 1
      }
    }

    let entering = newBlocks.filter { newIndexToOldIndex[$0.index] == nil }
    let exiting = oldBlocks.filter { !matchedOldIndices.contains($0.index) }

    return buildResult(
      newBlocks: newBlocks,
      persistent: persistent,
      entering: entering,
      exiting: exiting,
      oldCount: oldBlocks.count
    )
  }

  private static func wordLevelDiff(
    oldBlocks: [CharacterBlock],
    oldText: String,
    newText: String
  ) -> (newBlocks: [CharacterBlock], result: TextDiffResult) {
    let oldWords = oldText.components(separatedBy: " ")
    let newWords = newText.components(separatedBy: " ")
    let newChars = Array(newText)

    let wordMatches = computeLCS(oldWords, newWords)

    func wordStarts(_ words: [String]) -> [Int] {
      var starts: [Int] = []
      var pos = 0
      for (i, word) in words.enumerated() {
        starts.append(pos)
        pos += word.count
        if i < words.count - 1 { pos += 1 }
      }
      return starts
    }

    let oldStarts = wordStarts(oldWords)
    let newStarts = wordStarts(newWords)

    var newIndexToOldBlock: [Int: CharacterBlock] = [:]
    var matchedOldCharIndices: Set<Int> = []

    var prevOldEnd = 0
    var prevNewEnd = 0

    for (oldWordIdx, newWordIdx) in wordMatches {
      let oldGapEnd = oldStarts[oldWordIdx]
      let newGapEnd = newStarts[newWordIdx]

      if prevOldEnd < oldGapEnd && prevNewEnd < newGapEnd {
        matchGap(
          oldBlocks: oldBlocks, newChars: newChars,
          oldRange: prevOldEnd..<oldGapEnd, newRange: prevNewEnd..<newGapEnd,
          into: &newIndexToOldBlock, matched: &matchedOldCharIndices
        )
      }

      let oldStart = oldStarts[oldWordIdx]
      let newStart = newStarts[newWordIdx]
      let wordLen = oldWords[oldWordIdx].count
      for offset in 0..<wordLen {
        newIndexToOldBlock[newStart + offset] = oldBlocks[oldStart + offset]
        matchedOldCharIndices.insert(oldStart + offset)
      }

      prevOldEnd = oldStart + wordLen
      prevNewEnd = newStart + wordLen
    }

    if prevOldEnd < oldBlocks.count && prevNewEnd < newChars.count {
      matchGap(
        oldBlocks: oldBlocks, newChars: newChars,
        oldRange: prevOldEnd..<oldBlocks.count, newRange: prevNewEnd..<newChars.count,
        into: &newIndexToOldBlock, matched: &matchedOldCharIndices
      )
    }

    let inheritedIDs = Set(newIndexToOldBlock.values.map(\.id))
    var newBlocks: [CharacterBlock] = []
    var persistent: [(old: CharacterBlock, new: CharacterBlock)] = []
    var nextID = 0

    for i in 0..<newChars.count {
      if let oldBlock = newIndexToOldBlock[i] {
        let block = CharacterBlock(id: oldBlock.id, character: newChars[i], index: i)
        newBlocks.append(block)
        persistent.append((old: oldBlock, new: block))
      } else {
        while inheritedIDs.contains("n\(nextID)") {
          nextID += 1
        }
        newBlocks.append(CharacterBlock(id: "n\(nextID)", character: newChars[i], index: i))
        nextID += 1
      }
    }

    let entering = newBlocks.filter { newIndexToOldBlock[$0.index] == nil }
    let exiting = oldBlocks.filter { !matchedOldCharIndices.contains($0.index) }

    return buildResult(
      newBlocks: newBlocks,
      persistent: persistent,
      entering: entering,
      exiting: exiting,
      oldCount: oldBlocks.count
    )
  }

  private static func matchGap(
    oldBlocks: [CharacterBlock],
    newChars: [Character],
    oldRange: Range<Int>,
    newRange: Range<Int>,
    into newIndexToOldBlock: inout [Int: CharacterBlock],
    matched matchedOldCharIndices: inout Set<Int>
  ) {
    let gapOldBlocks = Array(oldBlocks[oldRange])
    let gapNewIndices = Array(newRange)
    let charMatches = computeLCS(
      gapOldBlocks.map(\.character),
      gapNewIndices.map { newChars[$0] }
    )
    for (gapOldIdx, gapNewIdx) in charMatches {
      let oldBlock = gapOldBlocks[gapOldIdx]
      newIndexToOldBlock[gapNewIndices[gapNewIdx]] = oldBlock
      matchedOldCharIndices.insert(oldBlock.index)
    }
  }

  private static func buildResult(
    newBlocks: [CharacterBlock],
    persistent: [(old: CharacterBlock, new: CharacterBlock)],
    entering: [CharacterBlock],
    exiting: [CharacterBlock],
    oldCount: Int
  ) -> (newBlocks: [CharacterBlock], result: TextDiffResult) {
    let maxCount = max(oldCount, newBlocks.count)
    let changeRatio: CGFloat = maxCount > 0
      ? CGFloat(entering.count + exiting.count) / CGFloat(maxCount)
      : 0

    let result = TextDiffResult(
      persistent: persistent,
      entering: entering,
      exiting: exiting,
      changeRatio: min(changeRatio, 1)
    )

    return (newBlocks, result)
  }

  private static func computeLCS<T: Equatable>(
    _ old: [T],
    _ new: [T]
  ) -> [(oldIndex: Int, newIndex: Int)] {
    let m = old.count, n = new.count
    guard m > 0, n > 0 else { return [] }

    var dp = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)
    for i in 1...m {
      for j in 1...n {
        dp[i][j] = old[i - 1] == new[j - 1]
          ? dp[i - 1][j - 1] + 1
          : max(dp[i - 1][j], dp[i][j - 1])
      }
    }

    var matches: [(oldIndex: Int, newIndex: Int)] = []
    var i = m, j = n
    while i > 0 && j > 0 {
      if old[i - 1] == new[j - 1] {
        matches.append((i - 1, j - 1))
        i -= 1; j -= 1
      } else if dp[i - 1][j] > dp[i][j - 1] {
        i -= 1
      } else {
        j -= 1
      }
    }
    return matches.reversed()
  }
}
