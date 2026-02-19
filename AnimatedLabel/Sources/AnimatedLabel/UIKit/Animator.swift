import UIKit

final class Animator {

  private var runningAnimators: [UIViewPropertyAnimator] = []
  private var exitingViews: [CharacterView] = []

  func cancelAll() {
    for animator in runningAnimators {
      animator.stopAnimation(true)
    }
    runningAnimators.removeAll()

    for view in exitingViews {
      view.removeFromSuperview()
    }
    exitingViews.removeAll()
  }

  func animateExiting(
    view: CharacterView,
    transition: TransitionType,
    direction: CGFloat,
    drift: CGFloat,
    anchorDelta: CGPoint,
    style: AnimationStyle,
    completion: @escaping () -> Void
  ) {
    exitingViews.append(view)

    let exitAnimator = UIViewPropertyAnimator(duration: style.fadeDuration, curve: .easeIn)
    exitAnimator.addAnimations {
      switch transition {
      case .scale:
        view.transform = CGAffineTransform(scaleX: 0.82, y: 0.82)
      case .rolling:
        view.transform = CGAffineTransform(translationX: 0, y: -direction * drift)
          .scaledBy(x: 0.82, y: 0.82)
      case .slide:
        view.transform = CGAffineTransform(translationX: -direction * drift, y: 0)
      }
      view.alpha = 0
    }
    exitAnimator.addCompletion { [weak self] _ in
      self?.exitingViews.removeAll { $0 === view }
      completion()
    }
    track(exitAnimator)
    exitAnimator.startAnimation()

    if anchorDelta != .zero {
      let driftAnimator = UIViewPropertyAnimator(
        duration: 0,
        timingParameters: style.springParameters
      )
      var frame = view.contextualFrame
      frame.origin.x += anchorDelta.x
      frame.origin.y += anchorDelta.y
      driftAnimator.addAnimations {
        view.contextualFrame = frame
      }
      track(driftAnimator)
      driftAnimator.startAnimation()
    }
  }

  private func track(_ animator: UIViewPropertyAnimator) {
    runningAnimators.append(animator)
    animator.addCompletion { [weak self] _ in
      self?.runningAnimators.removeAll { $0 === animator }
    }
  }
}
