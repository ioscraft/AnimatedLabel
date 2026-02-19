import UIKit

public final class AnimatedLabel: UIView {

  public var font: UIFont = .systemFont(ofSize: 17) {
    didSet {
      updateExistingViews()
      remeasureAndResize()
    }
  }

  public var textColor: UIColor = .label {
    didSet { updateExistingViews() }
  }

  public var style: AnimationStyle = .snappy

  public var mode: AnimationMode = .morph

  public var transition: TransitionType = .scale

  public var letterSpacing: CGFloat = 0 {
    didSet { remeasureAndResize() }
  }

  public var drift: CGFloat = 10

  private var currentText: String = ""
  private var currentBlocks: [CharacterBlock] = []
  private var characterViews: [String: CharacterView] = [:]
  private let animator = Animator()
  private var sizeAnimator: UIViewPropertyAnimator?

  private lazy var widthConstraint: NSLayoutConstraint = {
    let c = widthAnchor.constraint(equalToConstant: 0)
    c.priority = .defaultHigh
    return c
  }()

  private lazy var heightConstraint: NSLayoutConstraint = {
    let c = heightAnchor.constraint(equalToConstant: 0)
    c.priority = .defaultHigh
    return c
  }()

  override init(frame: CGRect) {
    super.init(frame: frame)
    clipsToBounds = false
    widthConstraint.isActive = true
    heightConstraint.isActive = true
  }

  @available(*, unavailable)
  public required init?(coder: NSCoder) { fatalError() }

  public func setText(_ text: String, alongside: (() -> Void)? = nil) {
    guard text != currentText else { return }

    let oldText = currentText
    let oldBlocks = currentBlocks
    let newBlocks = mode == .replace
      ? Segmenter.segmentByPosition(text)
      : Segmenter.segment(text)
    let isFirstText = currentText.isEmpty && oldBlocks.isEmpty

    currentText = text
    currentBlocks = newBlocks

    let (newFrames, newSize) = LayoutEngine.measure(
      blocks: newBlocks,
      font: font,
      letterSpacing: letterSpacing
    )

    if isFirstText {
      widthConstraint.constant = newSize.width
      heightConstraint.constant = newSize.height
      invalidateIntrinsicContentSize()
      initialLayout(blocks: newBlocks, frames: newFrames)
    } else {
      let direction: CGFloat = transition == .rolling
        ? Self.detectDirection(old: oldText, new: text)
        : 1
      performTransition(
        oldBlocks: oldBlocks,
        newBlocks: newBlocks,
        newFrames: newFrames,
        newSize: newSize,
        direction: direction,
        alongside: alongside
      )
    }
  }

  public override var intrinsicContentSize: CGSize {
    CGSize(width: widthConstraint.constant, height: heightConstraint.constant)
  }

  public override func sizeThatFits(_ size: CGSize) -> CGSize {
    CGSize(width: widthConstraint.constant, height: heightConstraint.constant)
  }

  private func initialLayout(
    blocks: [CharacterBlock],
    frames: [LayoutEngine.CharacterFrame]
  ) {
    for charFrame in frames {
      let view = makeCharacterView(
        id: charFrame.id,
        character: charFrame.character
      )
      view.contextualFrame = charFrame.frame
      view.alpha = 1
    }
  }

  private func performTransition(
    oldBlocks: [CharacterBlock],
    newBlocks: [CharacterBlock],
    newFrames: [LayoutEngine.CharacterFrame],
    newSize: CGSize,
    direction: CGFloat,
    alongside: (() -> Void)?
  ) {
    var oldFrames: [String: CGRect] = [:]
    for (id, view) in characterViews {
      if let presentation = view.layer.presentation() {
        let visualCenter = presentation.frame.mid
        oldFrames[id] = CGRect(
          x: visualCenter.x - presentation.bounds.width / 2,
          y: visualCenter.y - presentation.bounds.height / 2,
          width: presentation.bounds.width,
          height: presentation.bounds.height
        )
      } else {
        oldFrames[id] = view.contextualFrame
      }
    }

    animator.cancelAll()
    sizeAnimator?.stopAnimation(true)

    for (_, view) in characterViews {
      view.transform = .identity
      view.alpha = 1
    }

    let (oldMeasuredFrames, _) = LayoutEngine.measure(
      blocks: oldBlocks,
      font: font,
      letterSpacing: letterSpacing
    )
    for mf in oldMeasuredFrames where oldFrames[mf.id] == nil {
      oldFrames[mf.id] = mf.frame
    }

    widthConstraint.constant = newSize.width
    heightConstraint.constant = newSize.height
    invalidateIntrinsicContentSize()

    let diff = TextDiff.diff(old: oldBlocks, new: newBlocks)
    let newFrameLookup = Dictionary(
      uniqueKeysWithValues: newFrames.map { ($0.id, $0.frame) }
    )

    var persistentViews: [CharacterView] = []
    var enterIndex = 0

    for pair in diff.persistent {
      let id = pair.new.id
      guard let newFrame = newFrameLookup[id],
        let oldFrame = oldFrames[id]
      else { continue }

      guard let view = characterViews[id] else { continue }

      let sameCharacter = pair.old.character == pair.new.character

      if sameCharacter || mode == .morph {
        view.character = pair.new.character
        view.contextualFrame = newFrame
        let dx = oldFrame.midX - newFrame.midX
        let dy = oldFrame.midY - newFrame.midY
        view.transform = CGAffineTransform(translationX: dx, y: dy)
        view.alpha = 1
        persistentViews.append(view)
      } else {
        characterViews.removeValue(forKey: id)
        animator.animateExiting(
          view: view,
          transition: transition,
          direction: direction,
          drift: drift,
          style: style
        ) {
          view.removeFromSuperview()
        }

        let newView = makeCharacterView(id: id, character: pair.new.character)
        newView.contextualFrame = newFrame

        let stagger = TimeInterval(enterIndex) * style.stagger

        animator.animateEntering(
          view: newView,
          finalFrame: newFrame,
          transition: transition,
          direction: direction,
          drift: drift,
          stagger: stagger,
          style: style
        )
        enterIndex += 1
      }
    }

    for block in diff.exiting {
      guard let view = characterViews.removeValue(forKey: block.id) else {
        continue
      }
      animator.animateExiting(
        view: view,
        transition: transition,
        direction: direction,
        drift: drift,
        style: style
      ) {
        view.removeFromSuperview()
      }
    }

    for block in diff.entering {
      guard let newFrame = newFrameLookup[block.id] else { continue }

      let view = makeCharacterView(id: block.id, character: block.character)
      view.contextualFrame = newFrame

      let stagger = TimeInterval(enterIndex) * style.stagger

      animator.animateEntering(
        view: view,
        finalFrame: newFrame,
        transition: transition,
        direction: direction,
        drift: drift,
        stagger: stagger,
        style: style
      )
      enterIndex += 1
    }

    let sa = UIViewPropertyAnimator(
      duration: 0,
      timingParameters: style.springParameters
    )
    sa.addAnimations {
      self.superview?.layoutIfNeeded()
      alongside?()
      for view in persistentViews {
        view.transform = .identity
      }
    }
    sa.addCompletion { _ in
      for view in persistentViews {
        view.transform = .identity
      }
    }
    sizeAnimator = sa
    sa.startAnimation()
  }

  private static func detectDirection(old: String, new: String) -> CGFloat {
    let extract: (String) -> Double = { s in
      let filtered = s.filter { $0.isNumber || $0 == "." || $0 == "-" }
      return Double(filtered) ?? 0
    }
    return extract(new) >= extract(old) ? 1 : -1
  }

  private func remeasureAndResize() {
    guard !currentBlocks.isEmpty else { return }
    let (frames, newSize) = LayoutEngine.measure(
      blocks: currentBlocks,
      font: font,
      letterSpacing: letterSpacing
    )
    widthConstraint.constant = newSize.width
    heightConstraint.constant = newSize.height
    invalidateIntrinsicContentSize()
    for charFrame in frames {
      characterViews[charFrame.id]?.contextualFrame = charFrame.frame
    }
  }

  private func makeCharacterView(id: String, character: Character)
    -> CharacterView
  {
    if let existing = characterViews[id] {
      existing.removeFromSuperview()
    }
    let view = CharacterView(id: id, character: character)
    view.applyStyle(font: font, color: textColor)
    characterViews[id] = view
    addSubview(view)
    return view
  }

  private func updateExistingViews() {
    for (_, view) in characterViews {
      view.applyStyle(font: font, color: textColor)
    }
  }
}
