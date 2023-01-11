//
//  UIData.swift
//  tasotirin_FinalProject_Pixels
//
//  Created by Tavis Sotirin on 3/13/21.
//

import UIKit

// View controller extension for building closure functions while capturing input arguments
extension UIViewController {
    func buildClosure<T>(_ function: @escaping (T)->Void, _ arg: T)->()->Void {
        return {function(arg)}
    }
    
    func buildClosure<T1,T2>(_ function: @escaping (T1,T2)->Void, _ arg1: T1, _ arg2: T2)->()->Void {
        return {function(arg1,arg2)}
    }
    
    @objc func dismissAlert() {
    }
}

// Class for creating alert popups / action sheets
class AlertCreator {
    typealias alertAction = ()->()
    var view: UIViewController?
    var tapRecognizer:UITapGestureRecognizer?
    
    // Build tap recognizer to allow background tap to remove popup
    init(_ view: UIViewController) {
        self.view = view
        self.tapRecognizer = UITapGestureRecognizer(target: self.view!, action: #selector(self.dismiss))
    }
    
    // Create alert/action sheet popup using title, message, and dictionary of confirmation commands
    func displayPopUp(popTitle:String, message:String, actionList:[String:(alertAction,UIAlertAction.Style)] = [:], style prefStyle: UIAlertController.Style = .alert) {
        let alertCont = UIAlertController(title: popTitle, message: message, preferredStyle: prefStyle)
        
        if actionList.isEmpty {
            let addAction = UIAlertAction(title: "OK", style: .cancel, handler: {_ in self.removeRecognizer()})
            alertCont.addAction(addAction)
        }
        else {
            for actionTitle in actionList.keys {
                if let (action,style) = actionList[actionTitle] {
                    let addAction = UIAlertAction(title: actionTitle, style: style, handler: {_ in action(); if prefStyle == .actionSheet {self.removeRecognizer()}})
                    alertCont.addAction(addAction)
                }
            }
        }

        view?.present(alertCont, animated: true) {
            if prefStyle == .actionSheet {
                alertCont.view.superview?.addGestureRecognizer(self.tapRecognizer!)
            }
        }
    }
    
    @objc func dismiss() {
        if let _ = self.tapRecognizer {
            view?.dismiss(animated: true, completion: self.removeRecognizer)
        }
    }
    
    @objc func removeRecognizer() {
        if let gRec = self.tapRecognizer {
            self.view?.view.removeGestureRecognizer(gRec)
        }
    }
}
