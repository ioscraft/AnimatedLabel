import AnimatedLabel
import UIKit

final class ViewController: UIViewController {

  private let card: UIView = {
    let view = UIView()
    view.backgroundColor = .secondarySystemGroupedBackground
    view.layer.cornerRadius = 20
    view.layer.cornerCurve = .continuous
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()

  private let previewArea: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()

  private let pillView: UIView = {
    let view = UIView()
    view.backgroundColor = UIColor(red: 0.68, green: 0.40, blue: 0.82, alpha: 1)
    view.layer.cornerRadius = 28
    view.layer.cornerCurve = .continuous
    view.clipsToBounds = true
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()

  private let animatedLabel: AnimatedLabel = {
    let label = AnimatedLabel()
    label.font = .systemFont(ofSize: 22, weight: .bold)
    label.textColor = .white
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  }()

  private lazy var modeRow = OptionRow(
    title: "Mode",
    options: ["Morph", "Replace"]
  ) { [weak self] index in
    self?.modeChanged(index)
  }

  private lazy var transitionRow = OptionRow(
    title: "Transition",
    options: ["Scale", "Rolling", "Slide"]
  ) { [weak self] index in
    self?.transitionChanged(index)
  }

  private lazy var styleRow = OptionRow(
    title: "Animation",
    options: ["Smooth", "Snappy", "Bouncy"],
    selectedIndex: 1
  ) { [weak self] index in
    self?.styleChanged(index)
  }

  private let words = ["Send Action", "Action Sent", "Backing up", "Backed up", "Creative", "Craft", "Create", "Code"]
  private let styles: [AnimationStyle] = [.smooth, .snappy, .bouncy]
  private var currentWordIndex = 0
  private var currentMode: AnimationMode = .morph
  private var currentTransition: TransitionType = .scale

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemGroupedBackground
    setupLayout()

    animatedLabel.style = styles[1]
    animatedLabel.mode = currentMode
    animatedLabel.transition = currentTransition
    animatedLabel.setText(words[currentWordIndex])
  }

  private func setupLayout() {
    view.addSubview(card)
    card.addSubview(previewArea)
    previewArea.addSubview(pillView)
    pillView.addSubview(animatedLabel)

    pillView.addGestureRecognizer(
      UITapGestureRecognizer(target: self, action: #selector(pillTapped))
    )

    let controlStack = UIStackView(arrangedSubviews: [
      DividerView(), modeRow,
      DividerView(), transitionRow,
      DividerView(), styleRow,
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
      styleRow.heightAnchor.constraint(equalToConstant: 50),
    ])
  }

  @objc private func pillTapped() {
    currentWordIndex = (currentWordIndex + 1) % words.count
    animatedLabel.setText(words[currentWordIndex]) {
      self.view.layoutIfNeeded()
    }
  }

  private func modeChanged(_ index: Int) {
    currentMode = index == 0 ? .morph : .replace
    animatedLabel.mode = currentMode

    if currentMode == .replace {
      currentTransition = .rolling
      animatedLabel.transition = .rolling
      transitionRow.setSelectedIndex(1)
    } else {
      currentTransition = .scale
      animatedLabel.transition = .scale
      transitionRow.setSelectedIndex(0)
    }
  }

  private func transitionChanged(_ index: Int) {
    let transitions: [TransitionType] = [.scale, .rolling, .slide]
    currentTransition = transitions[index]
    animatedLabel.transition = currentTransition
  }

  private func styleChanged(_ index: Int) {
    animatedLabel.style = styles[index]
  }
}
