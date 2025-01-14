//
//  UITableView.swift
//  NeuroID
//
//  Created by Kevin Sites on 3/29/23.
//

import Foundation
import UIKit

private func tableViewSwizzling(element: UITableView.Type,
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

internal extension UITableView {
    static func tableviewSwizzle() {
        let table = UITableView.self
        tableViewSwizzling(element: table, originalSelector: #selector(table.reloadData), swizzledSelector: #selector(table.neuroIDReloadData))
    }

    @objc private func neuroIDReloadData() {
        neuroIDReloadData()
        if NeuroID.isStopped() {
            return
        }
        let guid = ParamsCreator.genId()
        let oldCells = visibleCells
        let newCells = visibleCells
        let currentNewViews = newCells.filter { !oldCells.contains($0) && !UIViewController().ignoreLists.contains($0.nidClassName) }

        for cell in currentNewViews {
            let cellName = cell.nidClassName
            let childViews = cell.contentView.subviewsRecursive()
            for _view in childViews {
                NIDDebugPrint(tag: "\(Constants.registrationTag.rawValue)", "Registering single view for cell.")
                NeuroIDTracker.registerSingleView(v: _view, screenName: cellName, guid: guid)
            }
        }
    }
}
