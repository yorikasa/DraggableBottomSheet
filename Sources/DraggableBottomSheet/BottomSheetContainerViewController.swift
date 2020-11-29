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

    func prepare(constraint: NSLayoutConstraint) {
        animator.prepare(bottomConstraint: constraint) { [weak self] in
            self?.parent?.view.layoutIfNeeded()
        }
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

    @objc func handlePanGesture(_ sender: UIPanGestureRecognizer) {
        animator.dragging(delta: sender.translation(in: sender.view).y,
                          velocity: sender.velocity(in: sender.view).y,
                          state: sender.state)
    }
}


public protocol BottomSheetPresenting: UIViewController {
    var coordinations: [CGFloat] { get set }
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
        prepareSheetPosition(bottomSheetViewController)
        bottomSheetViewController.didMove(toParent: self)
    }

    private func prepareSheetPosition(_ sheetViewController: BottomSheetContainerViewController) {
        let topMargin: CGFloat = 88
        let bottomConstraint = sheetViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)

        NSLayoutConstraint.activate([
            sheetViewController.view.widthAnchor.constraint(equalTo: view.widthAnchor),
            sheetViewController.view.heightAnchor.constraint(equalTo: view.heightAnchor,
                                                             constant: -topMargin),
            bottomConstraint
        ])
        sheetViewController.prepare(constraint: bottomConstraint)
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
