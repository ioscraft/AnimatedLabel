import UIKit

final class DividerView: UIView {

  init(inset: CGFloat = 20) {
    super.init(frame: .zero)

    let line = UIView()
    line.backgroundColor = .separator
    line.translatesAutoresizingMaskIntoConstraints = false
    addSubview(line)

    NSLayoutConstraint.activate([
      heightAnchor.constraint(equalToConstant: 1),
      line.leadingAnchor.constraint(equalTo: leadingAnchor, constant: inset),
      line.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -inset),
      line.topAnchor.constraint(equalTo: topAnchor),
      line.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { fatalError() }
}
