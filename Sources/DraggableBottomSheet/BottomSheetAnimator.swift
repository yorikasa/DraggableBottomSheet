//
//  BottomSheetAnimator.swift
//  BottomSheet
//
//  Created by Yuki Orikasa on 2020/07/26.
//

import UIKit

public class BottomSheetAnimator {

    private enum State {
        case collapsed
        case halfExpanded
        case expanded

        var bottomConstraint: CGFloat {
            switch self {
            case .collapsed:
                return UIScreen.main.bounds.height * 0.7
            case .halfExpanded:
                return UIScreen.main.bounds.height * 0.4
            case .expanded:
                return 0
            }
        }
    }

    private struct Constants {
        static let animationDuration: Double = 0.5
        static let animationDampingRatio: CGFloat = 0.8
    }

    private var runningAnimators = [UIViewPropertyAnimator]()
    private var bottomConstraint: NSLayoutConstraint?
    private var initialBottomConstraintConstant: CGFloat?

    private var completion: (() -> Void)?

    public enum Direction {
        case upward
        case downward
    }

    private func swipingDirection(_ velocityY: CGFloat) -> Direction {
        return velocityY > 0 ? .downward : .upward
    }

    private func finalPosition(to direction: Direction, from currentPosition: CGFloat) -> CGFloat {
        switch currentPosition {
        case ..<State.expanded.bottomConstraint:
            return State.expanded.bottomConstraint

        case State.expanded.bottomConstraint..<State.halfExpanded.bottomConstraint:
            return direction == .upward ? State.expanded.bottomConstraint
                                        : State.halfExpanded.bottomConstraint

        case State.halfExpanded.bottomConstraint...State.collapsed.bottomConstraint:
            return direction == .upward ? State.halfExpanded.bottomConstraint
                                        : State.collapsed.bottomConstraint
        default:
            return State.collapsed.bottomConstraint
        }
    }

    public func prepare(bottomConstraint: NSLayoutConstraint, completion: @escaping () -> Void) {
        self.bottomConstraint = bottomConstraint
        self.completion = completion
        animate(to: State.collapsed.bottomConstraint)
    }

    private func canDrag(with point: CGFloat?) -> Bool {
        if let point = point, contained(point) { return true }
        return false
    }

    private func contained(_ point: CGFloat) -> Bool {
        let margin = UIScreen.main.bounds.height * 0.01
        let sheetRange = (State.expanded.bottomConstraint - margin)...(State.collapsed.bottomConstraint + margin)
        if sheetRange.contains(point) { return true }
        return false
    }

    public func dragging(delta: CGFloat, velocity: CGFloat, state: UIGestureRecognizer.State) {
        switch state {
        case .began:
            if canDrag(with: bottomConstraint?.constant) {
                initialBottomConstraintConstant = bottomConstraint?.constant
            }
        case .changed:
            if let constant = initialBottomConstraintConstant, canDrag(with: constant + delta) {
                bottomConstraint?.constant = constant + delta
            }
        default:
            if let bottomConstraint = bottomConstraint?.constant {
                let position = finalPosition(to: swipingDirection(velocity), from: bottomConstraint)
                animate(to: position, velocity: velocity)
            }
            initialBottomConstraintConstant = nil
        }
    }

    public func animate(to direction: Direction) {
        if let bottomConstraint = bottomConstraint?.constant {
            let position = finalPosition(to: direction, from: bottomConstraint)
            animate(to: position)
        }
    }

    public func animate(to finalPosition: CGFloat, velocity: CGFloat = 0) {
        // Remove inactive animators first
        // Then, if there is an active animation (I don't assume there's multiple animations...)
        // get the current location (fractionComplete) of this view and stop the animation(s)
        removeRunningAnimators()
        let fraciton = runningAnimators.first?.fractionComplete
        for animator in runningAnimators {
            animator.stopAnimation(true)
        }

        let distance = abs(finalPosition - (bottomConstraint?.constant ?? 1))
        let dy = abs(velocity / distance)
        let parameters = UISpringTimingParameters(dampingRatio: Constants.animationDampingRatio,
                                                  initialVelocity: CGVector(dx: 0, dy: dy))
        let moveAnimator = UIViewPropertyAnimator(duration: Constants.animationDuration,
                                                  timingParameters: parameters)
        moveAnimator.addAnimations {
            self.bottomConstraint?.constant = finalPosition
            self.completion?()
        }

        moveAnimator.startAnimation()
        moveAnimator.fractionComplete = fraciton != nil ? 1-fraciton! : 0.0
        moveAnimator.addCompletion { position in
            self.removeRunningAnimators(of: moveAnimator.state.rawValue)
        }
        runningAnimators.append(moveAnimator)
    }

    // FIXME: I don't know why but UIViewPropertyAnimator.state returns 5 (rawValue)
    // It should be 0 (.inactive), 1 (.active) or 2 (.stopped)
    // https://developer.apple.com/documentation/uikit/uiviewanimating/1649743-state
    private func removeRunningAnimators(of rawValue: Int? = nil) {
        runningAnimators.removeAll { (animator) -> Bool in
            if rawValue != nil {
                return animator.state.rawValue == rawValue!
            } else {
                return animator.state == .inactive
            }
        }
    }
}
