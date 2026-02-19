import UIKit

extension UIView {
  var contextualFrame: CGRect {
    get {
      CGRect(
        x: center.x - bounds.width * layer.anchorPoint.x,
        y: center.y - bounds.height * layer.anchorPoint.y,
        width: bounds.width,
        height: bounds.height
      )
    }
    set {
      center = CGPoint(
        x: newValue.minX + newValue.width * layer.anchorPoint.x,
        y: newValue.minY + newValue.height * layer.anchorPoint.y
      )
      bounds = CGRect(origin: .zero, size: newValue.size)
    }
  }
}

extension CGRect {
  var mid: CGPoint {
    CGPoint(x: midX, y: midY)
  }
}
