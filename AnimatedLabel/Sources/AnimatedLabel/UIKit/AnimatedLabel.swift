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

  public var mode: AnimationMode = .morph {
    didSet {
      guard !currentText.isEmpty else { return }
      currentBlocks =
        mode == .replace
        ? Segmenter.segmentByPosition(currentText)
        : Segmenter.segment(currentText)
      rebuildCharacterViews()
    }
  }

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
  private var enterAnimators: [UIViewPropertyAnimator] = []

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
    let newBlocks =
      mode == .replace
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
      placeCharacters(frames: newFrames)
    } else {
      let direction: CGFloat =
        transition == .rolling
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

  private func placeCharacters(frames: [LayoutEngine.CharacterFrame]) {
    for charFrame in frames {
      let view = makeCharacterView(id: charFrame.id, character: charFrame.character)
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
    var oldFrames = captureVisualFrames()
    cancelRunningAnimations()

    let (oldMeasuredFrames, _) = LayoutEngine.measure(
      blocks: oldBlocks,
      font: font,
      letterSpacing: letterSpacing
    )
    for mf in oldMeasuredFrames where oldFrames[mf.id] == nil {
      oldFrames[mf.id] = mf.frame
    }

    // When bounds change, center stays fixed so origin shifts
    let shiftX = (bounds.width - newSize.width) / 2
    let shiftY = (bounds.height - newSize.height) / 2

    UIView.performWithoutAnimation {
      self.bounds = CGRect(origin: .zero, size: newSize)
    }

    widthConstraint.constant = newSize.width
    heightConstraint.constant = newSize.height
    invalidateIntrinsicContentSize()

    let diff = TextDiff.diff(old: oldBlocks, new: newBlocks)
    let newFrameLookup = Dictionary(
      uniqueKeysWithValues: newFrames.map { ($0.id, $0.frame) }
    )

    var persistentMoves: [(view: CharacterView, target: CGRect)] = []
    var enterIndex = 0

    for pair in diff.persistent {
      let id = pair.new.id
      guard let newFrame = newFrameLookup[id],
        let oldFrame = oldFrames[id]
      else { continue }
      guard let view = characterViews[id] else { continue }

      if mode == .morph {
        view.character = pair.new.character
        view.contextualFrame = oldFrame.offsetBy(dx: -shiftX, dy: -shiftY)
        view.alpha = 1
        persistentMoves.append((view: view, target: newFrame))
      } else {
        characterViews.removeValue(forKey: id)
        view.contextualFrame = oldFrame.offsetBy(dx: -shiftX, dy: -shiftY)
        animateExit(view, direction: direction)

        let newView = makeCharacterView(id: id, character: pair.new.character)
        setupEntering(newView, frame: newFrame, direction: direction)
        addEnteringAnimators(for: newView, staggerIndex: enterIndex)
        enterIndex += 1
      }
    }

    for block in diff.exiting {
      guard let view = characterViews.removeValue(forKey: block.id) else { continue }
      if let oldFrame = oldFrames[block.id] {
        view.contextualFrame = oldFrame.offsetBy(dx: -shiftX, dy: -shiftY)
      }
      animateExit(view, direction: direction)
    }

    for block in diff.entering {
      guard let newFrame = newFrameLookup[block.id] else { continue }
      let view = makeCharacterView(id: block.id, character: block.character)
      setupEntering(view, frame: newFrame, direction: direction)
      addEnteringAnimators(for: view, staggerIndex: enterIndex)
      enterIndex += 1
    }

    let sa = UIViewPropertyAnimator(duration: 0, timingParameters: style.springParameters)
    sa.addAnimations {
      alongside?()
      for (view, target) in persistentMoves {
        view.contextualFrame = target
      }
    }
    sa.addCompletion { _ in
      for (view, target) in persistentMoves {
        view.contextualFrame = target
      }
    }
    sizeAnimator = sa
    sa.startAnimation()
  }

  private func captureVisualFrames() -> [String: CGRect] {
    var frames: [String: CGRect] = [:]
    for (id, view) in characterViews {
      if let presentation = view.layer.presentation() {
        let center = presentation.frame.mid
        frames[id] = CGRect(
          x: center.x - presentation.bounds.width / 2,
          y: center.y - presentation.bounds.height / 2,
          width: presentation.bounds.width,
          height: presentation.bounds.height
        )
      } else {
        frames[id] = view.contextualFrame
      }
    }
    return frames
  }

  private func cancelRunningAnimations() {
    animator.cancelAll()
    sizeAnimator?.stopAnimation(true)
    for a in enterAnimators where a.state == .active {
      a.stopAnimation(true)
    }
    enterAnimators.removeAll()

    for (_, view) in characterViews {
      view.transform = .identity
      view.alpha = 1
    }
  }

  private func animateExit(_ view: CharacterView, direction: CGFloat) {
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

  private func setupEntering(
    _ view: CharacterView,
    frame: CGRect,
    direction: CGFloat
  ) {
    view.contextualFrame = frame
    view.layoutIfNeeded()
    switch transition {
    case .scale:
      view.transform = CGAffineTransform(scaleX: 0.82, y: 0.82)
    case .rolling:
      view.transform = CGAffineTransform(translationX: 0, y: direction * drift)
        .scaledBy(x: 0.82, y: 0.82)
    case .slide:
      view.transform = CGAffineTransform(translationX: direction * drift, y: 0)
    }
    view.alpha = 0
  }

  private func addEnteringAnimators(for view: CharacterView, staggerIndex: Int) {
    let delay = TimeInterval(staggerIndex) * style.stagger

    let spring = UIViewPropertyAnimator(duration: 0, timingParameters: style.springParameters)
    spring.addAnimations {
      view.transform = .identity
    }
    spring.addCompletion { _ in
      view.transform = .identity
    }
    enterAnimators.append(spring)
    spring.startAnimation(afterDelay: delay)

    let fade = UIViewPropertyAnimator(duration: style.fadeDuration, curve: .easeOut)
    fade.addAnimations {
      view.alpha = 1
    }
    fade.addCompletion { _ in
      view.alpha = 1
    }
    enterAnimators.append(fade)
    fade.startAnimation(afterDelay: delay)
  }

  private static func detectDirection(old: String, new: String) -> CGFloat {
    let extract: (String) -> Double = { s in
      let filtered = s.filter { $0.isNumber || $0 == "." || $0 == "-" }
      return Double(filtered) ?? 0
    }
    return extract(new) >= extract(old) ? 1 : -1
  }

  private func rebuildCharacterViews() {
    for (_, view) in characterViews {
      view.removeFromSuperview()
    }
    characterViews.removeAll()

    let (frames, size) = LayoutEngine.measure(
      blocks: currentBlocks,
      font: font,
      letterSpacing: letterSpacing
    )
    widthConstraint.constant = size.width
    heightConstraint.constant = size.height
    invalidateIntrinsicContentSize()
    placeCharacters(frames: frames)
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

  private func makeCharacterView(id: String, character: Character) -> CharacterView {
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
