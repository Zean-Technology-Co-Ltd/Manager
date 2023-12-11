//
//  NNPresentationManager.swift
//  NiuNiuRent
//
//  Created by Q Z on 2023/4/24.
//

import UIKit

class NNPresentationManager: NSObject {
    class private func nn_onShowPresentVC(_ presentVC: UIViewController,
                                      cornerRadius: CGFloat,
                                              animatedStyle: NNPresentationAnimatedStyle,
                                              alertStyle: NNPresentationStyle,
                                      completion: NNDissingHandler){
        let targetVC = topViewController()
        let delegate = NNPresentationController(presentVC,
                                                presentingVC: targetVC,
                                                cornerRadius: cornerRadius,
                                                animatedStyle: animatedStyle,
                                                alertStyle: alertStyle,
                                                handle: completion)
        presentVC.transitioningDelegate = delegate
        targetVC.present(presentVC, animated: true)
    }
}

extension NNPresentationManager {
    class func nn_onShowWindowPresentVC(_ presentingVC: UIViewController){
        nn_onShowWindowPresentVC(presentingVC,
                                 cornerRadius: 0,
                                 animatedStyle: .popup,
                                 completion: nil)
    }

    
    class func nn_onShowWindowPresentVC(_ presentingVC: UIViewController,
                                      cornerRadius: CGFloat){
        nn_onShowWindowPresentVC(presentingVC,
                                 cornerRadius: cornerRadius,
                                 animatedStyle: .popup,
                                 completion: nil)
    }

    class func nn_onShowWindowPresentVC(_ presentVC: UIViewController,
                                      cornerRadius: CGFloat,
                                      style: NNPresentationAnimatedStyle,
                                      completion: NNDissingHandler){
        nn_onShowWindowPresentVC(presentVC,
                                 cornerRadius: cornerRadius,
                                 animatedStyle: .popup,
                                 completion: completion)
    }
    
    class func nn_onShowWindowPresentVC(_ presentVC: UIViewController,
                                      cornerRadius: CGFloat,
                                        animatedStyle: NNPresentationAnimatedStyle,
                                      completion: NNDissingHandler){
        nn_onShowPresentVC(presentVC,
                           cornerRadius: cornerRadius,
                           animatedStyle: animatedStyle,
                           alertStyle: .alert,
                           completion: completion)
    }
}

extension NNPresentationManager {
    class func nn_onShowActionSheetVC(_ presentVC: UIViewController){
        nn_onShowActionSheetVC(presentVC,
                               cornerRadius: 0)
    }
    
    class func nn_onShowActionSheetVC(_ presentVC: UIViewController,
                                      cornerRadius: CGFloat){
        nn_onShowActionSheetVC(presentVC,
                               cornerRadius: cornerRadius,
                               animatedStyle: .scale,
                               completion: nil)
    }

    class func nn_onShowActionSheetVC(_ presentVC: UIViewController,
                                      cornerRadius: CGFloat,
                                      animatedStyle: NNPresentationAnimatedStyle,
                                      completion: NNDissingHandler){
        nn_onShowPresentVC(presentVC,
                           cornerRadius: cornerRadius,
                           animatedStyle: animatedStyle,
                           alertStyle: .actionSheet,
                           completion: completion)
    }
    
}
