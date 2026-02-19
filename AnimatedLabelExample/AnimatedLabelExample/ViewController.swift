import UIKit
import AnimatedLabel

class ViewController: UIViewController {

  private let animatedLabel = AnimatedLabel()
  private let pillView = UIView()

  private var currentMode: AnimationMode = .morph
  private var currentTransition: TransitionType = .scale
  private var currentStyleIndex = 1

  private let styles: [(name: String, style: AnimationStyle)] = [
    ("Smooth", .smooth),
    ("Snappy", .snappy),
    ("Bouncy", .bouncy),
  ]

  private let morphWords = ["Creative", "Craft", "Create", "Code"]
  private let rollingNumbers = ["$3.15", "$35.99", "$17.38", "$24.89"]

  private var currentMorphIndex = 0
  private var currentRollingIndex = 0

  private var modeButtons: [UIButton] = []
  private var transitionButtons: [UIButton] = []
  private var styleButtons: [UIButton] = []
  private var morphLabels: [UILabel] = []
  private var rollingLabels: [UILabel] = []
  private var contentTitleLabel: UILabel!
  private var morphContentStack: UIStackView!
  private var rollingContentStack: UIStackView!

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.97, alpha: 1)
    setupUI()

    animatedLabel.style = styles[currentStyleIndex].style
    animatedLabel.mode = currentMode
    animatedLabel.transition = currentTransition
    animatedLabel.setText(morphWords[currentMorphIndex])
  }

  private func setupUI() {
    let card = UIView()
    card.backgroundColor = .white
    card.layer.cornerRadius = 20
    card.layer.cornerCurve = .continuous
    card.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(card)

    let previewArea = UIView()
    previewArea.translatesAutoresizingMaskIntoConstraints = false
    card.addSubview(previewArea)

    pillView.backgroundColor = UIColor(red: 0.68, green: 0.40, blue: 0.82, alpha: 1)
    pillView.layer.cornerRadius = 28
    pillView.layer.cornerCurve = .continuous
    pillView.clipsToBounds = true
    pillView.translatesAutoresizingMaskIntoConstraints = false
    pillView.addGestureRecognizer(
      UITapGestureRecognizer(target: self, action: #selector(pillTapped))
    )
    previewArea.addSubview(pillView)

    animatedLabel.font = .systemFont(ofSize: 22, weight: .bold)
    animatedLabel.textColor = .white
    animatedLabel.translatesAutoresizingMaskIntoConstraints = false
    pillView.addSubview(animatedLabel)

    let modeRow = makeOptionRow(
      title: "Mode",
      options: ["Morph", "Replace"],
      buttons: &modeButtons,
      action: #selector(modeTapped)
    )

    let transitionRow = makeOptionRow(
      title: "Transition",
      options: ["Scale", "Rolling", "Slide"],
      buttons: &transitionButtons,
      action: #selector(transitionTapped)
    )

    let animRow = makeOptionRow(
      title: "Animation",
      options: styles.map(\.name),
      buttons: &styleButtons,
      action: #selector(styleTapped)
    )

    let contentRow = makeContentRow()

    let divider1 = makeDivider()
    let divider2 = makeDivider()
    let divider3 = makeDivider()
    let divider4 = makeDivider()

    let controlStack = UIStackView(arrangedSubviews: [
      divider1, modeRow,
      divider2, transitionRow,
      divider3, animRow,
      divider4, contentRow,
    ])
    controlStack.axis = .vertical
    controlStack.translatesAutoresizingMaskIntoConstraints = false
    card.addSubview(controlStack)

    NSLayoutConstraint.activate([
      card.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
      card.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
      card.centerYAnchor.constraint(equalTo: view.centerYAnchor),

      previewArea.topAnchor.constraint(equalTo: card.topAnchor),
      previewArea.leadingAnchor.constraint(equalTo: card.leadingAnchor),
      previewArea.trailingAnchor.constraint(equalTo: card.trailingAnchor),
      previewArea.heightAnchor.constraint(equalToConstant: 280),

      pillView.centerXAnchor.constraint(equalTo: previewArea.centerXAnchor),
      pillView.centerYAnchor.constraint(equalTo: previewArea.centerYAnchor),
      pillView.heightAnchor.constraint(equalToConstant: 56),

      animatedLabel.leadingAnchor.constraint(equalTo: pillView.leadingAnchor, constant: 28),
      animatedLabel.trailingAnchor.constraint(equalTo: pillView.trailingAnchor, constant: -28),
      animatedLabel.centerYAnchor.constraint(equalTo: pillView.centerYAnchor),

      controlStack.topAnchor.constraint(equalTo: previewArea.bottomAnchor),
      controlStack.leadingAnchor.constraint(equalTo: card.leadingAnchor),
      controlStack.trailingAnchor.constraint(equalTo: card.trailingAnchor),
      controlStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -8),

      modeRow.heightAnchor.constraint(equalToConstant: 50),
      transitionRow.heightAnchor.constraint(equalToConstant: 50),
      animRow.heightAnchor.constraint(equalToConstant: 50),
      contentRow.heightAnchor.constraint(equalToConstant: 50),
    ])

    updateModeButtons()
    updateTransitionButtons()
    updateStyleButtons()
    updateContentLabels()
  }

  private func makeOptionRow(
    title: String,
    options: [String],
    buttons: inout [UIButton],
    action: Selector
  ) -> UIView {
    let row = UIView()
    row.translatesAutoresizingMaskIntoConstraints = false

    let titleLabel = UILabel()
    titleLabel.text = title
    titleLabel.font = .systemFont(ofSize: 15)
    titleLabel.textColor = UIColor(white: 0.72, alpha: 1)
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    row.addSubview(titleLabel)

    let stack = UIStackView()
    stack.axis = .horizontal
    stack.spacing = 14
    stack.translatesAutoresizingMaskIntoConstraints = false
    row.addSubview(stack)

    for (i, option) in options.enumerated() {
      let button = UIButton(type: .system)
      button.setTitle(option, for: .normal)
      button.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
      button.tag = i
      button.addTarget(self, action: action, for: .touchUpInside)
      stack.addArrangedSubview(button)
      buttons.append(button)
    }

    NSLayoutConstraint.activate([
      titleLabel.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 20),
      titleLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor),
      stack.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -20),
      stack.centerYAnchor.constraint(equalTo: row.centerYAnchor),
    ])

    return row
  }

  private func makeContentRow() -> UIView {
    let row = UIView()
    row.translatesAutoresizingMaskIntoConstraints = false

    contentTitleLabel = UILabel()
    contentTitleLabel.text = "Words"
    contentTitleLabel.font = .systemFont(ofSize: 15)
    contentTitleLabel.textColor = UIColor(white: 0.72, alpha: 1)
    contentTitleLabel.translatesAutoresizingMaskIntoConstraints = false
    row.addSubview(contentTitleLabel)

    morphContentStack = makePipeSeparatedLabels(
      options: morphWords,
      labels: &morphLabels
    )
    morphContentStack.translatesAutoresizingMaskIntoConstraints = false
    row.addSubview(morphContentStack)

    let displayNumbers = rollingNumbers.map { String($0.dropFirst()) }
    rollingContentStack = makePipeSeparatedLabels(
      options: displayNumbers,
      labels: &rollingLabels
    )
    rollingContentStack.translatesAutoresizingMaskIntoConstraints = false
    rollingContentStack.isHidden = true
    row.addSubview(rollingContentStack)

    NSLayoutConstraint.activate([
      contentTitleLabel.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 20),
      contentTitleLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor),
      morphContentStack.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -20),
      morphContentStack.centerYAnchor.constraint(equalTo: row.centerYAnchor),
      rollingContentStack.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -20),
      rollingContentStack.centerYAnchor.constraint(equalTo: row.centerYAnchor),
    ])

    return row
  }

  private func makePipeSeparatedLabels(
    options: [String],
    labels: inout [UILabel]
  ) -> UIStackView {
    let stack = UIStackView()
    stack.axis = .horizontal
    stack.spacing = 6
    stack.alignment = .center

    for (i, option) in options.enumerated() {
      if i > 0 {
        let pipe = UILabel()
        pipe.text = "|"
        pipe.font = .systemFont(ofSize: 15)
        pipe.textColor = UIColor(white: 0.85, alpha: 1)
        stack.addArrangedSubview(pipe)
      }

      let label = UILabel()
      label.text = option
      label.font = .systemFont(ofSize: 15, weight: .medium)
      label.textColor = UIColor(white: 0.55, alpha: 1)
      stack.addArrangedSubview(label)
      labels.append(label)
    }

    return stack
  }

  private func makeDivider() -> UIView {
    let container = UIView()
    container.translatesAutoresizingMaskIntoConstraints = false

    let line = UIView()
    line.backgroundColor = UIColor(white: 0.92, alpha: 1)
    line.translatesAutoresizingMaskIntoConstraints = false
    container.addSubview(line)

    NSLayoutConstraint.activate([
      container.heightAnchor.constraint(equalToConstant: 1),
      line.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
      line.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
      line.topAnchor.constraint(equalTo: container.topAnchor),
      line.bottomAnchor.constraint(equalTo: container.bottomAnchor),
    ])

    return container
  }

  @objc private func pillTapped() {
    switch currentMode {
    case .morph:
      currentMorphIndex = (currentMorphIndex + 1) % morphWords.count
      animatedLabel.setText(morphWords[currentMorphIndex]) {
        self.view.layoutIfNeeded()
      }
    case .replace:
      currentRollingIndex = (currentRollingIndex + 1) % rollingNumbers.count
      animatedLabel.setText(rollingNumbers[currentRollingIndex]) {
        self.view.layoutIfNeeded()
      }
    }
    updateContentLabels()
  }

  @objc private func modeTapped(_ sender: UIButton) {
    let newMode: AnimationMode = sender.tag == 0 ? .morph : .replace
    guard newMode != currentMode else { return }
    currentMode = newMode
    animatedLabel.mode = currentMode

    if currentMode == .replace {
      currentTransition = .rolling
      animatedLabel.transition = .rolling
    } else {
      currentTransition = .scale
      animatedLabel.transition = .scale
    }

    morphContentStack.isHidden = currentMode != .morph
    rollingContentStack.isHidden = currentMode != .replace
    contentTitleLabel.text = currentMode == .morph ? "Words" : "Numbers"

    updateModeButtons()
    updateTransitionButtons()
    updateContentLabels()

    switch currentMode {
    case .morph:
      animatedLabel.setText(morphWords[currentMorphIndex]) {
        self.view.layoutIfNeeded()
      }
    case .replace:
      animatedLabel.setText(rollingNumbers[currentRollingIndex]) {
        self.view.layoutIfNeeded()
      }
    }
  }

  @objc private func transitionTapped(_ sender: UIButton) {
    let transitions: [TransitionType] = [.scale, .rolling, .slide]
    let newTransition = transitions[sender.tag]
    guard newTransition != currentTransition else { return }
    currentTransition = newTransition
    animatedLabel.transition = currentTransition
    updateTransitionButtons()
  }

  @objc private func styleTapped(_ sender: UIButton) {
    guard sender.tag != currentStyleIndex else { return }
    currentStyleIndex = sender.tag
    animatedLabel.style = styles[currentStyleIndex].style
    updateStyleButtons()
  }

  private func updateModeButtons() {
    let selectedIndex = currentMode == .morph ? 0 : 1
    for (i, button) in modeButtons.enumerated() {
      let selected = i == selectedIndex
      button.titleLabel?.font = .systemFont(ofSize: 15, weight: selected ? .bold : .regular)
      button.setTitleColor(selected ? .label : UIColor(white: 0.72, alpha: 1), for: .normal)
    }
  }

  private func updateTransitionButtons() {
    let transitions: [TransitionType] = [.scale, .rolling, .slide]
    let selectedIndex = transitions.firstIndex(of: currentTransition) ?? 0
    for (i, button) in transitionButtons.enumerated() {
      let selected = i == selectedIndex
      button.titleLabel?.font = .systemFont(ofSize: 15, weight: selected ? .bold : .regular)
      button.setTitleColor(selected ? .label : UIColor(white: 0.72, alpha: 1), for: .normal)
    }
  }

  private func updateStyleButtons() {
    for (i, button) in styleButtons.enumerated() {
      let selected = i == currentStyleIndex
      button.titleLabel?.font = .systemFont(ofSize: 15, weight: selected ? .bold : .regular)
      button.setTitleColor(selected ? .label : UIColor(white: 0.72, alpha: 1), for: .normal)
    }
  }

  private func updateContentLabels() {
    for (i, label) in morphLabels.enumerated() {
      let selected = i == currentMorphIndex
      label.font = .systemFont(ofSize: 15, weight: selected ? .bold : .regular)
      label.textColor = selected ? .label : UIColor(white: 0.55, alpha: 1)
    }
    for (i, label) in rollingLabels.enumerated() {
      let selected = i == currentRollingIndex
      label.font = .systemFont(ofSize: 15, weight: selected ? .bold : .regular)
      label.textColor = selected ? .label : UIColor(white: 0.55, alpha: 1)
    }
  }
}
