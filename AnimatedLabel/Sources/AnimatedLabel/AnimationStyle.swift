import UIKit

public struct AnimationStyle: Equatable {
  public let mass: CGFloat
  public let stiffness: CGFloat
  public let damping: CGFloat
  public let initialVelocity: CGVector
  public let stagger: TimeInterval
  public let fadeDuration: TimeInterval

  public init(
    mass: CGFloat = 1,
    stiffness: CGFloat = 350,
    damping: CGFloat = 30,
    initialVelocity: CGVector = .zero,
    stagger: TimeInterval = 0.035,
    fadeDuration: TimeInterval = 0.15
  ) {
    self.mass = mass
    self.stiffness = stiffness
    self.damping = damping
    self.initialVelocity = initialVelocity
    self.stagger = stagger
    self.fadeDuration = fadeDuration
  }

  public static let `default` = AnimationStyle.snappy

  public static let smooth = AnimationStyle(
    stiffness: 170,
    damping: 26,
    stagger: 0.05,
    fadeDuration: 0.2
  )

  public static let snappy = AnimationStyle()

  public static let bouncy = AnimationStyle(
    stiffness: 300,
    damping: 22,
    stagger: 0.04,
    fadeDuration: 0.18
  )

  var springParameters: UISpringTimingParameters {
    UISpringTimingParameters(
      mass: mass,
      stiffness: stiffness,
      damping: damping,
      initialVelocity: initialVelocity
    )
  }
}
