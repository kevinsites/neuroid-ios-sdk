//
//  NIDSend.swift
//  NeuroID
//
//  Created by Kevin Sites on 5/31/23.
//

import Alamofire
import Foundation

public extension NeuroID {
    private static func initTimer() {
        // Send up the first payload, and then setup a repeating timer
//        self.send()
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + SEND_INTERVAL) {
            self.send()
            self.initTimer()
        }
    }

    static func getCollectionEndpointURL() -> String {
        //  Prod URL
        //    return collectorURLFromConfig ?? "https://api.neuro-id.com/v3/c"
        //    return "https://rc.api.usw2-prod1.nidops.net"
        //    return "http://localhost:8080"
        //    return "https://api.usw2-dev1.nidops.net";
        //
        //    #if DEBUG
        //    return collectorURLFromConfig ?? "https://receiver.neuro-dev.com/c"
        //    #elseif STAGING
        //    return collectorURLFromConfig ?? "https://receiver.neuro-dev.com/c"
        //    #elseif RELEASE
        //    return  "https://api.neuro-id.com/v3/c"
        //    #endif
        return "https://receiver.neuroid.cloud/c"
    }

    /**
     Publically exposed just for testing. This should not be any reason to call this directly.
     */
    static func send() {
        DispatchQueue.global(qos: .utility).async {
            if !NeuroID.isStopped() {
                groupAndPOST()
            }
        }
    }

    /**
     Publically exposed just for testing. This should not be any reason to call this directly.
     */
    static func groupAndPOST() {
        if NeuroID.isStopped() {
            return
        }
        let dataStoreEvents = DataStore.getAllEvents()

        let backupCopy = dataStoreEvents
        // Clean event queue immediately after fetching
        DataStore.removeSentEvents()
        if dataStoreEvents.isEmpty {
            return
        }

        // save captured health events to file
        saveIntegrationHealthEvents()

        /** Just send all the evnets */
        let cleanEvents = dataStoreEvents.map { nidevent -> NIDEvent in
            var newEvent = nidevent
            // Only send url on register target and create session.
            if nidevent.type != NIDEventName.registerTarget.rawValue, nidevent.type != "CREATE_SESSION" {
                newEvent.url = nil
            }
            return newEvent
        }

        post(events: cleanEvents, screen: (getScreenName() ?? backupCopy[0].url) ?? "unnamed_screen", onSuccess: { _ in
            logInfo(category: "APICall", content: "Sending successfully")
            // send success -> delete

        }, onFailure: { error in
            logError(category: "APICall", content: String(describing: error))
        })
    }

    /// Direct send to API to create session
    /// Regularly send in loop
    fileprivate static func post(events: [NIDEvent],
                                 screen: String,
                                 onSuccess: @escaping (Any) -> Void,
                                 onFailure: @escaping
                                 (Error) -> Void)
    {
        guard let url = URL(string: NeuroID.getCollectionEndpointURL()) else {
            logError(content: "NeuroID base URL found")
            return
        }

        let tabId = ParamsCreator.getTabId()

        let randomString = UUID().uuidString
        let pageid = randomString.replacingOccurrences(of: "-", with: "").prefix(12)

        let neuroHTTPRequest = NeuroHTTPRequest(
            clientId: ParamsCreator.getClientId(),
            environment: NeuroID.getEnvironment(),
            sdkVersion: ParamsCreator.getSDKVersion(),
            pageTag: NeuroID.getScreenName() ?? "UNKNOWN",
            responseId: ParamsCreator.generateUniqueHexId(),
            siteId: NeuroID.siteId ?? "",
            userId: ParamsCreator.getUserID() ?? "",
            jsonEvents: events,
            tabId: "\(tabId)",
            pageId: "\(pageid)",
            url: "ios://\(NeuroID.getScreenName() ?? "")"
        )

        if ProcessInfo.processInfo.environment[Constants.debugJsonKey.rawValue] == "true" {
            saveDebugJSON(events: "******************** New POST to NID Collector")
//            saveDebugJSON(events: dataString)
//            saveDebugJSON(events: jsonEvents):
            saveDebugJSON(events: "******************** END")
        }

        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "site_key": ParamsCreator.getClientKey(),
            "authority": "receiver.neuroid.cloud",
        ]

        AF.request(
            url,
            method: .post,
            parameters: neuroHTTPRequest,
            encoder: JSONParameterEncoder.default,
            headers: headers
        ).responseData { response in
            // 204 invalid, 200 valid
            NIDPrintLog("NID Response \(response.response?.statusCode ?? 000)")
            NIDPrintLog("NID Payload: \(neuroHTTPRequest)")
            switch response.result {
            case .success:
                NIDPrintLog("Neuro-ID post to API Successfull")
            case let .failure(error):
                NIDPrintLog("Neuro-ID FAIL to post API")
                logError(content: "Neuro-ID post Error: \(error)")
            }
        }

        // Output post data to terminal if debug
        if ProcessInfo.processInfo.environment[Constants.debugJsonKey.rawValue] == "true" {
            do {
                let data = try JSONEncoder().encode(neuroHTTPRequest)
                let str = String(data: data, encoding: .utf8)
                NIDPrintLog(str as Any)
            } catch {}
        }
    }
}
