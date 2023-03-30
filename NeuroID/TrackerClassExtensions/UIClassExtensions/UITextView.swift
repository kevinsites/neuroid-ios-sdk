//
//  UITextView.swift
//  NeuroID
//
//  Created by Kevin Sites on 3/29/23.
//

import Foundation
import UIKit

private func textViewSwizzling(element: UITextView.Type,
                               originalSelector: Selector,
                               swizzledSelector: Selector)
{
    let originalMethod = class_getInstanceMethod(element, originalSelector)
    let swizzledMethod = class_getInstanceMethod(element, swizzledSelector)

    if let originalMethod = originalMethod,
       let swizzledMethod = swizzledMethod
    {
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
}

internal extension UITextView {
    func addTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true
    }

    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        print("wow")
    }

    @objc static func startSwizzling() {
        let textField = UITextView.self

        textViewSwizzling(element: textField,
                          originalSelector: #selector(textField.paste(_:)),
                          swizzledSelector: #selector(textField.neuroIDPaste))
    }

    @objc func neuroIDPaste(caller: UIResponder) {
        neuroIDPaste(caller: caller)
        if NeuroID.isStopped() {
            return
        }
        let lengthValue = "S~C~~\(text?.count ?? 0)"
        let pasteTG = ParamsCreator.getTGParamsForInput(eventName: NIDEventName.paste, view: self, type: NIDEventName.paste.rawValue, attrParams: ["v": lengthValue, "hash": text])
        var inputEvent = NIDEvent(type: NIDEventName.paste, tg: pasteTG)

        let screenName = className ?? UUID().uuidString
        var newEvent = inputEvent
        // Make sure we have a valid url set
        newEvent.url = screenName
        DataStore.insertEvent(screen: screenName, event: newEvent)
    }
}
