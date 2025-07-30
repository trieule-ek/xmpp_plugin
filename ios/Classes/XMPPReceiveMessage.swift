//
//  XMPPReceiveMessage.swift
//  flutter_xmpp
//
//  Created by xRStudio on 17/08/21.
//

import Foundation
import Foundation
import XMPPFramework

extension XMPPController {
    
    func handel_ChatMessage(_ rawMessage: XMPPMessage, withType type : String, withStrem : XMPPStream) {
        let stamp = extractDelayTime(from: rawMessage)
        let messageDelay = rawMessage.forName("delay", xmlns: "urn:xmpp:delay")?.attributeStringValue(forName: "stamp")
        print("\(#function) | Message delay tiem stamp \(stamp) :: \(messageDelay)")

        let message = rawMessage.mamResult?.forwardedMessage ?? rawMessage;

        printLog("handling message \(String(describing: message))")
        if APP_DELEGATE.objEventData == nil {
            print("\(#function) | Nil data of APP_DELEGATE.objEventData")
            return
        }
        
        //TODO: Message - Singal
        var objMess : Message = Message.init()
        objMess.initWithMessage(message: message)
        let vId : String = objMess.id.trim()
        if vId.count == 0 {
            print("\(#function) | Message Id nil")
            return
        }
        let subject = extractSubject(from: message)
        let urls = extractUrlsFromMessage(message)
        var mediaURL: String = ""
        if (!urls.isEmpty) {
            mediaURL = urls.joined(separator: ",");
        }
        
        let customElement : String = message.getCustomElementInfo(withKey: eleCustom.Kay)
        let vMessType : String = type
        let dicDate = ["type" : pluginMessType.Message,
                       "id" : objMess.id,
                       "from" : objMess.senderJid,
                       "body" : objMess.message,
                       "customText" : customElement,
                       "msgtype" : vMessType,
                       "senderJid": objMess.senderJid,
                       "delayTime" : stamp,
                       "subject": subject,
                       "mediaURL": mediaURL,
                       "time" : objMess.time] as [String : Any]
        APP_DELEGATE.objEventData!(dicDate)
    }

    func extractDelayTime(from message: XMPPMessage) -> String? {
        // Get <result>
        guard let resultElement = message.forName("result", xmlns: "urn:xmpp:mam:2"),
            let forwarded = resultElement.forName("forwarded", xmlns: "urn:xmpp:forward:0") else {
            return nil
        }

        // Get <delay>
        guard let delayElement = forwarded.forName("delay", xmlns: "urn:xmpp:delay"),
            let stamp = delayElement.attributeStringValue(forName: "stamp") else {
            return nil
        }
        
        // Parse the date
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let date = isoFormatter.date(from: stamp) else {
            print("Invalid date format")
            return nil
        }

        // Format Date to desired string in local timezone
        let displayFormatter = DateFormatter()
        displayFormatter.locale = Locale(identifier: "en_US_POSIX")
        displayFormatter.timeZone = TimeZone.current
        displayFormatter.dateFormat = "EEE MMM dd HH:mm:ss 'GMT+/-__:__' yyyy"
        
        return displayFormatter.string(from: date)
    }

    func extractSubject(from message: XMPPMessage) -> String? {
        guard let subject = message.forName("subject") else {
            return nil
        }
        
        return subject.stringValue
    }
    
    func handelNormalChatMessage(_ message: XMPPMessage, withStrem : XMPPStream) {
        if message.hasReceiptResponse {
            guard let messId = message.receiptResponseID else {
                print("\(#function) | ReceiptResponseId is empty/nil.")
                return
            }
            self.senAckDeliveryReceipt(withMessageId: messId)
            return
        }
        var chatStateType : String = ""

        if  message.hasChatState {

            if message.hasComposingChatState {
                chatStateType = "composing"
            } else if message.hasGoneChatState {
                chatStateType = "gone"
            } else if message.hasPausedChatState {
                chatStateType = "paused"
            } else if message.hasActiveChatState {
                chatStateType = "active"
            } else if message.hasInactiveChatState {
                chatStateType = "inactive"
            }
//         return
        }
           var objMess : Message = Message.init()
           objMess.initWithMessage(message: message)

           let vFrom : String = message.fromStr ?? ""

            let dicData = ["type" : "chatstate",
                           "id" : objMess.id,
                           "from" : vFrom,
                           "body" : objMess.message,
                           "customText" : "",
                           "msgtype" : "normal",
                           "senderJid": vFrom,
                           "time" : "",
                           "chatStateType" : chatStateType] as [String : Any]

            APP_DELEGATE.objEventData!(dicData)
            self.broadCastMessageToFlutter(dicData: dicData)

    }

    func extractUrlsFromMessage(_ message: XMPPMessage) -> [String] {
        var urls = [String]()
        let xml = message.description
        let startTag = "<url"
        let endTag = "</url>"
        var currentIndex = xml.startIndex
        
        while true {
            guard let startRange = xml.range(of: startTag, range: currentIndex..<xml.endIndex) else {
                break
            }
            
            guard let startCloseRange = xml.range(of: ">", range: startRange.upperBound..<xml.endIndex) else {
                break
            }
            
            guard let endRange = xml.range(of: endTag, range: startCloseRange.upperBound..<xml.endIndex) else {
                break
            }
            
            if startCloseRange.upperBound < endRange.lowerBound {
                let urlSubstring = xml[startCloseRange.upperBound..<endRange.lowerBound]
                let url = String(urlSubstring).trimmingCharacters(in: .whitespacesAndNewlines)
                
                if !url.isEmpty {
                    urls.append(url)
                    printLog("extractUrlsFromMessage :: Found URL: \(url)")
                }
                
                currentIndex = endRange.upperBound // Move past this tag
            } else {
                break // Invalid tag structure
            }
        }
        
        return urls
    }
}
