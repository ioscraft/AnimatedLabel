import UIKit

final class OptionRow: UIView {

  private var buttons: [UIButton] = []
  private(set) var selectedIndex: Int
  private let onSelectionChanged: (Int) -> Void

  init(
    title: String,
    options: [String],
    selectedIndex: Int = 0,
    onSelectionChanged: @escaping (Int) -> Void
  ) {
    self.selectedIndex = selectedIndex
    self.onSelectionChanged = onSelectionChanged
    super.init(frame: .zero)
    translatesAutoresizingMaskIntoConstraints = false

    let titleLabel = UILabel()
    titleLabel.text = title
    titleLabel.font = .systemFont(ofSize: 15)
    titleLabel.textColor = .secondaryLabel
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    addSubview(titleLabel)

    let stack = UIStackView()
    stack.axis = .horizontal
    stack.spacing = 14
    stack.translatesAutoresizingMaskIntoConstraints = false
    addSubview(stack)

    for (i, option) in options.enumerated() {
      let button = UIButton(type: .custom)
      button.setTitle(option, for: .normal)
      button.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
      button.tag = i
      button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
      stack.addArrangedSubview(button)
      buttons.append(button)
    }

    NSLayoutConstraint.activate([
      titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
      titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
      stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
      stack.centerYAnchor.constraint(equalTo: centerYAnchor),
    ])

    updateButtonStates()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { fatalError() }

  func setSelectedIndex(_ index: Int) {
    selectedIndex = index
    updateButtonStates()
  }

  @objc private func buttonTapped(_ sender: UIButton) {
    guard sender.tag != selectedIndex else { return }
    selectedIndex = sender.tag
    updateButtonStates()
    onSelectionChanged(selectedIndex)
  }

  private func updateButtonStates() {
    for (i, button) in buttons.enumerated() {
      let selected = i == selectedIndex
      button.setTitleColor(
        selected ? .label : .tertiaryLabel,
        for: .normal
      )
    }
  }
}
