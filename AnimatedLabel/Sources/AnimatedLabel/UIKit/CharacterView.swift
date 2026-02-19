import UIKit

final class CharacterView: UIView {

  let id: String

  private let label = UILabel()

  var character: Character {
    didSet { label.text = String(character) }
  }

  init(id: String, character: Character) {
    self.id = id
    self.character = character
    super.init(frame: .zero)
    label.text = String(character)
    addSubview(label)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { fatalError() }

  override func layoutSubviews() {
    super.layoutSubviews()
    label.frame = bounds
  }

  func applyStyle(font: UIFont, color: UIColor) {
    label.font = font
    label.textColor = color
  }
}
