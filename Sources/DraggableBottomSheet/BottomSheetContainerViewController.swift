//
//  BottomSheetViewController.swift
//  BottomSheet
//
//  Created by Yuki Orikasa on 2020/07/19.
//

import UIKit

public class BottomSheetContainerViewController: UIViewController {

    private struct Constants {
        static let cornerRadius: CGFloat = 10
        static let shadowOpacity: CGFloat = 0.2
    }

    private let animator = BottomSheetAnimator()

    public override func viewDidLoad() {
        super.viewDidLoad()

        addPanGestureRecognizer()
        definesPresentationContext = true
        view.layer.shadowOpacity = Float(Constants.shadowOpacity)
    }

    func prepare(constraint: NSLayoutConstraint, topOffset: BottomSheetAnimator.TopOffset) {
        animator.prepare(topConstraint: constraint, topOffset: topOffset) { [weak self] in
            self?.parent?.view.layoutIfNeeded()
        }
    }

    public func configureTopOffset(_ topOffset: BottomSheetAnimator.TopOffset) {
        animator.configure(topOffset: topOffset)
    }

    func ready(_ containedViewController: UIViewController) {
        addChild(containedViewController)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containedViewController.view)
        containedViewController.view.layer.cornerRadius = Constants.cornerRadius
        containedViewController.view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        containedViewController.view.frame = view.frame
        containedViewController.didMove(toParent: self)
    }

    func move(to direction: BottomSheetAnimator.Direction) {
        animator.animate(to: direction)
    }

    private func addPanGestureRecognizer() {
        let recognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        view.addGestureRecognizer(recognizer)
    }

    @objc public func handlePanGesture(_ sender: UIPanGestureRecognizer) {
        if sender.state == .began {
            view.endEditing(true)
        }
        animator.dragging(delta: sender.translation(in: sender.view).y,
                          velocity: sender.velocity(in: sender.view).y,
                          state: sender.state)
    }
}


public protocol BottomSheetPresenting: UIViewController {
    var draggableViewController: BottomSheetContainerViewController? { get set }

    func addBottomSheetView(_ viewController: BottomSheetViewController)
}

public extension BottomSheetPresenting {
    func addBottomSheetView(_ viewController: BottomSheetViewController) {
        let bottomSheetViewController = BottomSheetContainerViewController()
        bottomSheetViewController.ready(viewController)
        draggableViewController = bottomSheetViewController

        addChild(bottomSheetViewController)
        view.addSubview(bottomSheetViewController.view)
        prepareInitialSheetPosition(bottomSheetViewController)
        bottomSheetViewController.didMove(toParent: self)
    }

    private func prepareInitialSheetPosition(_ sheetViewController: BottomSheetContainerViewController) {
        let topOffset = BottomSheetAnimator.TopOffset(offsetExpanded: 88)
        let topConstraint = sheetViewController.view.topAnchor.constraint(equalTo: view.topAnchor, constant: topOffset.halfExpanded)

        NSLayoutConstraint.activate([
            sheetViewController.view.widthAnchor.constraint(equalTo: view.widthAnchor),
            sheetViewController.view.heightAnchor.constraint(equalTo: view.heightAnchor,
                                                             constant: view.frame.height),
            topConstraint
        ])

        sheetViewController.prepare(constraint: topConstraint, topOffset: topOffset)
    }

    func move(direction: BottomSheetAnimator.Direction) {
        draggableViewController?.move(to: direction)
    }
}

open class BottomSheetViewController: UIViewController {
    open override func viewDidLoad() {
        super.viewDidLoad()
        definesPresentationContext = true
        configureView()
    }

    private func configureView() {
        view.clipsToBounds = true
        view.layer.cornerRadius = 10
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    }

    public func show(_ vc: BottomSheetViewController) {
        vc.modalPresentationStyle = .overCurrentContext
        present(vc, animated: true, completion: nil)
    }

    public func move(to direction: BottomSheetAnimator.Direction) {
        if parent == nil {
            (presentingViewController as? BottomSheetViewController)?.move(to: direction)
        } else {
            (parent as? BottomSheetContainerViewController)?.move(to: direction)
        }
    }
}
