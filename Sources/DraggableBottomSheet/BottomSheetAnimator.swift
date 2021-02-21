//
//  BottomSheetAnimator.swift
//  BottomSheet
//
//  Created by Yuki Orikasa on 2020/07/26.
//

import UIKit

public class BottomSheetAnimator {

    public enum State {
        case collapsed
        case halfExpanded
        case expanded
    }

    public struct TopOffset {
        public var collapsed: CGFloat
        public var halfExpanded: CGFloat
        public var expanded: CGFloat

        public init(offsetExpanded: CGFloat) {
            collapsed = UIScreen.main.bounds.height - 200
            halfExpanded = UIScreen.main.bounds.height - 500
            expanded = offsetExpanded
        }

        public init(offsetCollapsed: CGFloat, offsetHalfExpanded: CGFloat, offsetExpanded: CGFloat) {
            collapsed = offsetCollapsed
            halfExpanded = offsetHalfExpanded
            expanded = offsetExpanded
        }

        func offset(_ state: State) -> CGFloat {
            switch state {
            case .collapsed:
                return collapsed
            case .halfExpanded:
                return halfExpanded
            case .expanded:
                return expanded
            }
        }
    }

    public enum Direction {
        case upward
        case downward
    }

    private struct Constants {
        static let animationDuration: Double = 0.5
        static let animationDampingRatio: CGFloat = 0.8
    }

    private var runningAnimators = [UIViewPropertyAnimator]()
    private var topConstraint: NSLayoutConstraint?
    private var initialBottomConstraintConstant: CGFloat?
    private var completion: (() -> Void)?
    private var topOffset: TopOffset?

    private func swipingDirection(_ velocityY: CGFloat) -> Direction {
        return velocityY > 0 ? .downward : .upward
    }

    private func finalPosition(to direction: Direction, from currentPosition: CGFloat) -> CGFloat {
        guard let topOffset = topOffset else { return 0 }

        switch currentPosition {
        case ..<topOffset.offset(.expanded):
            return topOffset.offset(.expanded)

        case topOffset.offset(.expanded)..<topOffset.offset(.halfExpanded):
            return direction == .upward ? topOffset.offset(.expanded)
                                        : topOffset.offset(.halfExpanded)

        case topOffset.offset(.halfExpanded)...topOffset.offset(.collapsed):
            return direction == .upward ? topOffset.offset(.halfExpanded)
                                        : topOffset.offset(.collapsed)
        default:
            return topOffset.offset(.collapsed)
        }
    }

    public func prepare(topConstraint: NSLayoutConstraint,
                        topOffset: BottomSheetAnimator.TopOffset,
                        completion: @escaping () -> Void) {
        self.topConstraint = topConstraint
        self.completion = completion
        self.topOffset = topOffset
        animate(to: topOffset.offset(.collapsed))
    }

    private func canDrag(with point: CGFloat?) -> Bool {
        if let point = point, contained(point) { return true }
        return false
    }

    private func contained(_ point: CGFloat) -> Bool {
        guard let topOffset = topOffset else { return false }

        let sheetRange = topOffset.offset(.expanded)...topOffset.offset(.collapsed)
        if sheetRange.contains(point) { return true }
        return false
    }

    public func dragging(delta: CGFloat, velocity: CGFloat, state: UIGestureRecognizer.State) {
        switch state {
        case .began:
            if canDrag(with: topConstraint?.constant) {
                initialBottomConstraintConstant = topConstraint?.constant
            }
        case .changed:
            if let constant = initialBottomConstraintConstant, canDrag(with: constant + delta) {
                topConstraint?.constant = constant + delta
            }
        default:
            if let topConstraint = topConstraint?.constant {
                let position = finalPosition(to: swipingDirection(velocity), from: topConstraint)
                animate(to: position, velocity: velocity)
            }
            initialBottomConstraintConstant = nil
        }
    }

    public func animate(to direction: Direction) {
        if let topConstraint = topConstraint?.constant {
            let position = finalPosition(to: direction, from: topConstraint)
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

        let distance = abs(finalPosition - (topConstraint?.constant ?? 1))
        let dy = abs(velocity / distance)
        let parameters = UISpringTimingParameters(dampingRatio: Constants.animationDampingRatio,
                                                  initialVelocity: CGVector(dx: 0, dy: dy))
        let moveAnimator = UIViewPropertyAnimator(duration: Constants.animationDuration,
                                                  timingParameters: parameters)
        moveAnimator.addAnimations {
            self.topConstraint?.constant = finalPosition
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
