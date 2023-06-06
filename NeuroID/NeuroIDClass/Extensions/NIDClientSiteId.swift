//
//  NIDClientSiteId.swift
//  NeuroID
//
//  Created by Kevin Sites on 5/31/23.
//

import Foundation

public extension NeuroID {
    /**
     Public user facing getClientID function
     */
    static func getClientID() -> String {
        return ParamsCreator.getClientId()
    }

    internal static func getClientKeyFromLocalStorage() -> String {
        let keyName = Constants.storageClientKey.rawValue
        let defaults = UserDefaults.standard
        let key = defaults.string(forKey: keyName)
        return key ?? ""
    }

    static func setSiteId(siteId: String) {
        self.siteId = siteId
    }
}
