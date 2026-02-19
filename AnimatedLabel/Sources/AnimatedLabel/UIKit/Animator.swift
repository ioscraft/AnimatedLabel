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

  func animatePersistent(
    view: CharacterView,
    from oldFrame: CGRect,
    to newFrame: CGRect,
    style: AnimationStyle
  ) {
    let dx = oldFrame.midX - newFrame.midX
    let dy = oldFrame.midY - newFrame.midY

    view.contextualFrame = newFrame
    view.transform = CGAffineTransform(translationX: dx, y: dy)
    view.alpha = 1

    let animator = UIViewPropertyAnimator(
      duration: 0,
      timingParameters: style.springParameters
    )
    animator.addAnimations {
      view.transform = .identity
    }
    animator.addCompletion { _ in
      view.transform = .identity
    }
    track(animator)
    animator.startAnimation()
  }

  func animateEntering(
    view: CharacterView,
    finalFrame: CGRect,
    transition: TransitionType,
    direction: CGFloat,
    drift: CGFloat,
    stagger: TimeInterval,
    style: AnimationStyle
  ) {
    view.contextualFrame = finalFrame

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

    let springAnimator = UIViewPropertyAnimator(
      duration: 0,
      timingParameters: style.springParameters
    )
    springAnimator.addAnimations {
      view.transform = .identity
    }
    springAnimator.addCompletion { _ in
      view.transform = .identity
      view.alpha = 1
    }
    track(springAnimator)

    let fadeAnimator = UIViewPropertyAnimator(
      duration: style.fadeDuration,
      curve: .easeOut
    )
    fadeAnimator.addAnimations {
      view.alpha = 1
    }
    track(fadeAnimator)

    springAnimator.startAnimation()
    fadeAnimator.startAnimation(afterDelay: stagger)
  }

  func animateExiting(
    view: CharacterView,
    transition: TransitionType,
    direction: CGFloat,
    drift: CGFloat,
    style: AnimationStyle,
    completion: @escaping () -> Void
  ) {
    exitingViews.append(view)

    let exitAnimator = UIViewPropertyAnimator(
      duration: style.fadeDuration,
      curve: .easeIn
    )
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
  }

  private func track(_ animator: UIViewPropertyAnimator) {
    runningAnimators.append(animator)
    animator.addCompletion { [weak self] _ in
      self?.runningAnimators.removeAll { $0 === animator }
    }
  }
}
