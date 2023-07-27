//
//  NNPresentationController.swift
//  NiuNiuRent
//
//  Created by Q Z on 2023/4/24.
//

import UIKit

enum NNPresentationStyle: Int {
    case alert = 0
    case actionSheet
}

enum NNPresentationAnimatedStyle: Int {
    case popup = 0
    case scale
}

typealias NNDissingHandler = (()->())?
class NNPresentationController: UIPresentationController {
    private var dimmingHandler: NNDissingHandler = nil
    private var cornerRadius: CGFloat = 0
    private var animatedStyle: NNPresentationAnimatedStyle = .popup
    private var alertStyle: NNPresentationStyle = .alert
    convenience init(_ presentedVC: UIViewController,
                     presentingVC: UIViewController,
                     cornerRadius: CGFloat,
                     animatedStyle: NNPresentationAnimatedStyle = .popup,
                     alertStyle: NNPresentationStyle = .alert,
                     handle: NNDissingHandler) {
        self.init(presentedViewController: presentedVC, presenting: presentingVC)
        presentedVC.modalPresentationStyle = .custom
        self.dimmingHandler = handle
        self.cornerRadius = cornerRadius
        self.animatedStyle = animatedStyle
        self.alertStyle = alertStyle
    }
    
    override func presentationTransitionWillBegin() {
        let presentedViewControllerView = super.presentedView
        switch alertStyle {
        case .alert:
            let presentationRoundedCornerView = makePresentationRoundedCornerView(frame: self.presentationWrappingView!.bounds.inset(by: UIEdgeInsets(top: 0, left: 0, bottom: -cornerRadius, right: 0)))
            
            let bounds = presentationRoundedCornerView.bounds.inset(by: UIEdgeInsets(top: 0, left: 0, bottom: cornerRadius, right: 0))
            let presentedViewControllerWrapperView = makePresentedViewControllerWrapperView(frame: bounds, presentedViewControllerView: presentedViewControllerView!)
            presentationRoundedCornerView.addSubview(presentedViewControllerWrapperView)
            self.presentationWrappingView!.addSubview(presentationRoundedCornerView)
        case .actionSheet:
            let presentationRoundedCornerView = makePresentationRoundedCornerView(frame: self.presentationWrappingView!.bounds)
            
            let presentedViewControllerWrapperView = makePresentedViewControllerWrapperView(frame: presentationRoundedCornerView.bounds,
                                                                                            presentedViewControllerView: presentedViewControllerView!)
            presentationRoundedCornerView.addSubview(presentedViewControllerWrapperView)
            self.presentationWrappingView!.addSubview(presentationRoundedCornerView)
        }
        
        self.containerView?.addSubview(dimmingView!)
        dimmingView!.alpha = 0
        let transitionCoordinator = self.presentingViewController.transitionCoordinator
        transitionCoordinator?.animate(alongsideTransition: { [weak self] context in
            self?.dimmingView!.alpha = 0.2
        })
    }
    
    override func presentationTransitionDidEnd(_ completed: Bool) {
        if completed != true {
            self.presentationWrappingView = nil
            self.dimmingView = nil
        }
    }
    
    override func dismissalTransitionWillBegin() {
        let transitionCoordinator = self.presentingViewController.transitionCoordinator
        transitionCoordinator?.animate(alongsideTransition: { [weak self] context in
            self?.dimmingView?.alpha = 0.0
        })
    }
    
    override func dismissalTransitionDidEnd(_ completed: Bool) {
        if completed == true {
            self.presentationWrappingView = nil
            self.dimmingView = nil
        }
    }
    
    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)
        if let container = container as? UIViewController, container == self.presentedViewController{
            self.containerView?.setNeedsLayout()
        }
    }
    
    override func size(forChildContentContainer container: UIContentContainer, withParentContainerSize parentSize: CGSize) -> CGSize {
        if let container = container as? UIViewController, container == self.presentedViewController{
            var contentSize = container.preferredContentSize
            contentSize.width = contentSize.width == 0 ? UIScreen.screenWidth: contentSize.width
            return contentSize
        } else {
            return super.size(forChildContentContainer: container, withParentContainerSize: parentSize)
        }
    }
    
    override var frameOfPresentedViewInContainerView: CGRect{
        let containerViewBounds = self.containerView!.bounds
        let presentedViewContentSize = self.size(forChildContentContainer: self.presentedViewController, withParentContainerSize: containerViewBounds.size)
        var presentedViewControllerFrame = containerViewBounds
        presentedViewControllerFrame.size = presentedViewContentSize
        presentedViewControllerFrame.origin.y = containerViewBounds.maxY - presentedViewContentSize.height
        return presentedViewControllerFrame
    }
    
    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        self.dimmingView!.frame = self.containerView!.bounds
        self.presentationWrappingView!.frame = self.frameOfPresentedViewInContainerView
        if self.alertStyle == .actionSheet{
            self.presentationWrappingView!.center = self.containerView!.center
        }
    }
    
    override var presentedView: UIView?{
        return self.presentationWrappingView
    }
    
    private lazy var presentationWrappingView: UIView? = {
        let presentationWrapperView = UIView(frame: self.frameOfPresentedViewInContainerView)
        presentationWrapperView.layer.shadowOpacity = 0.14
        presentationWrapperView.layer.shadowRadius = 13
        presentationWrapperView.layer.shadowOffset = CGSize(width: 0, height: -6)
        return presentationWrapperView
    }()
    
    private lazy var dimmingView: UIView? = {
        let dimmingView = UIView(frame: self.containerView!.bounds)
        dimmingView.backgroundColor = .black
        dimmingView.isOpaque = false
        dimmingView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        dimmingView.addTapAction { [weak self] in
            if let block = self?.dimmingHandler{
                block()
            } else {
                self?.presentedViewController.dismiss(animated: true)
            }
        }
        return dimmingView
    }()

}

extension NNPresentationController{
    private func makePresentationRoundedCornerView(frame: CGRect) -> UIView {
        let presentationRoundedCornerView = UIView(frame: frame)
        presentationRoundedCornerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        presentationRoundedCornerView.layer.cornerRadius = cornerRadius
        presentationRoundedCornerView.layer.masksToBounds = true
        return presentationRoundedCornerView
    }
    
    private func makePresentedViewControllerWrapperView(frame: CGRect, presentedViewControllerView: UIView) -> UIView {
        let presentedViewControllerWrapperView = UIView(frame: frame)
        presentedViewControllerWrapperView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        presentedViewControllerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        presentedViewControllerView.frame = presentedViewControllerWrapperView.bounds;
        presentedViewControllerWrapperView.addSubview(presentedViewControllerView)
        return presentedViewControllerWrapperView
    }
    
}

extension NNPresentationController: UIViewControllerAnimatedTransitioning{
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return transitionContext!.isAnimated ? 0.25 : 0
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let fromViewController = transitionContext.viewController(forKey: .from)
        let toViewController = transitionContext.viewController(forKey: .to)
        let containerView = transitionContext.containerView
        let toView = transitionContext.view(forKey: .to)
        let fromView = transitionContext.view(forKey: .from)
        let isPresenting = fromViewController == self.presentingViewController
        var fromViewFinalFrame = transitionContext.finalFrame(for: fromViewController!)
        var toViewInitialFrame = transitionContext.initialFrame(for: toViewController!)
        let toViewFinalFrame = transitionContext.finalFrame(for: toViewController!)
        if let toView = toView{
            containerView.addSubview(toView)
        }
        
        let transitionDuration = transitionDuration(using: transitionContext)
        switch animatedStyle{
        case .popup:
            
            if isPresenting {
                toViewInitialFrame.origin = CGPoint(x: containerView.bounds.minX, y: containerView.bounds.maxY)
                toViewInitialFrame.size = toViewFinalFrame.size
                toView!.frame = toViewInitialFrame
            } else {
                fromViewFinalFrame = fromView!.frame.offsetBy(dx: 0, dy: fromView!.frame.height)
            }
            
            UIView.animate(withDuration: transitionDuration) {
                if (isPresenting){
                    toView!.frame = toViewFinalFrame
                } else {
                    fromView!.frame = fromViewFinalFrame
                }
            } completion: { finished in
                let wasCancelled = transitionContext.transitionWasCancelled
                transitionContext.completeTransition(!wasCancelled)
            }
            break
        case .scale:
            
            if isPresenting {
                toView?.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
            }else{
                fromView?.transform = CGAffineTransform.identity
            }
            UIView.animate(withDuration: transitionDuration) {
                if (isPresenting){
                    toView?.transform = CGAffineTransform.identity;
                } else {
                    fromView?.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
                }
            } completion: { finished in
                let wasCancelled = transitionContext.transitionWasCancelled
                transitionContext.completeTransition(!wasCancelled)
            }
            
        }
        
    }
}

extension NNPresentationController: UIViewControllerTransitioningDelegate{
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return self
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self
    }
}
