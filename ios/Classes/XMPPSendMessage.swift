//
//  XMPPSendMessage.swift
//  flutter_xmpp
//
//  Created by xRStudio on 17/08/21.
//

import Foundation
import XMPPFramework

extension XMPPController {
    /// This method handles sending the message to one-one chat
    func sendMessage(messageBody:String,
                     subject: String,
                     time:String,
                     reciverJID:String,
                     messageId: String,
                     isGroup : Bool = false,
                     customElement : String,
                     withStrem : XMPPStream) {
        let vJid : XMPPJID? = XMPPJID(string: reciverJID)
        
        let vChatType : String = isGroup ? xmppChatType.GROUPCHAT : xmppChatType.CHAT
        
        let xmppMessage = XMPPMessage.init(type: vChatType.lowercased(), to: vJid)
        xmppMessage.addAttribute(withName: "xmlns", stringValue: "jabber:client")
        xmppMessage.addAttribute(withName: "id", stringValue: messageId)
        if (!subject.isEmpty && messageBody.isEmpty) {
            xmppMessage.addSubject(subject)
        } else {
            xmppMessage.addBody(messageBody)

            let code = getStatusCodeValue(messageBody)
            if !code.isEmpty, let eleStatus = getStatusCodeElement(withCode: code) {
                xmppMessage.addChild(eleStatus)
            }
        }
        
        /// Time
        if let eleTime = self.getTimeElement(withTime: time) {
            xmppMessage.addChild(eleTime)
        }
        /// Custom Element
        var isCustom : Bool = false
        if !customElement.isEmpty {
            if let ele = self.getCustomELE(withElementName: customElement) {
                xmppMessage.addChild(ele)
                isCustom = true
            }
        }
        
        if xmpp_AutoDeliveryReceipt {
            xmppMessage.addReceiptRequest()
        }
        withStrem.send(xmppMessage)
        
        addLogger(isCustom ? .sentCustomMessageToServer : .sentMessageToServer, xmppMessage)
    }
    
    func sentMessageDeliveryReceipt(withReceiptId receiptId: String, jid : String, messageId : String, withStrem : XMPPStream) {
        if receiptId.trim().isEmpty {
            print("\(#function) | ReceiptId is empty/nil.")
            return
        }
        if jid.trim().isEmpty {
            print("\(#function) | jid is empty/nil.")
            return
        }
        if messageId.trim().isEmpty {
            print("\(#function) | MessageId is empty/nil.")
            return
        }
        
        let vJid : XMPPJID? = XMPPJID(string: getJIDNameForUser(jid, withStrem: withStrem))
        let xmppMessage = XMPPMessage.init(type: xmppChatType.NORMAL, to: vJid)
        xmppMessage.addAttribute(withName: "id", stringValue: receiptId)
        
        let eleReceived: XMLElement = XMLElement.init(name: "received", xmlns: "urn:xmpp:receipts")
        eleReceived.addAttribute(withName: "id", stringValue: messageId)
        xmppMessage.addChild(eleReceived)
        
        xmppMessage.addReceiptRequest()
        withStrem.send(xmppMessage)
        
        addLogger(.sentDeliveryReceiptToServer, xmppMessage)
    }

    //MARK: - Send Ack
    func sendAck(_ withMessageId : String) {
        let vMessId : String = withMessageId.trim()
        if vMessId.isEmpty {
            print("\(#function) | MessageId is empty/nil.")
            return
        }
        let vFrom : String = ""
        let vBody : String = ""
        let dicDate = ["type" : pluginMessType.ACK,
                       "id" : vMessId,
                       "from" : vFrom,
                       "body" : vBody,
                       "msgtype" : "normal"]
        printLog("\(#function) | data: \(dicDate)")
        addLogger(.sentMessageToFlutter, dicDate)
        
        if let obj = APP_DELEGATE.objEventData {
            obj(dicDate)
        }
    }
    
    func senAckDeliveryReceipt(withMessageId : String) {
        let vMessId = withMessageId.trim()
        let vFrom : String = ""
        let vBody : String = ""
        let dicDate = ["type" : pluginMessType.ACK_DELIVERY,
                       "id" : vMessId,
                       "from" : vFrom,
                       "body" : vBody,
                       "msgtype" : "normal"]
        printLog("\(#function) | data: \(dicDate)")
        addLogger(.sentMessageToFlutter, dicDate)
        
        if let obj = APP_DELEGATE.objEventData {
            obj(dicDate)
        }
    }
    
    func broadCastMessageToFlutter(dicData : [String : Any]){
        printLog("message To push  \(dicData)")
    }
    
    func sendMemberList(withUsers arrUsers: [String]) {
        printLog("\(#function) | arrUsers: \(arrUsers)")
        addLogger(.sentMessageToFlutter, arrUsers)
        
        if let callBack = APP_DELEGATE.singalCallBack {
            callBack(arrUsers)
        }
    }
    
    func sendRosters(withUsersJid arrJid : [String]) {
        printLog("\(#function) | arrJid: \(arrJid)")
        addLogger(.sentMessageToFlutter, arrJid)
        
        if let callBack = APP_DELEGATE.singalCallBack {
            callBack(arrJid)
        }
    }
    
    func sendLastActivity(withTime vTime: String) {
        printLog("\(#function) | time: \(vTime)")
        addLogger(.sentMessageToFlutter, vTime)
        
        if let callBack = APP_DELEGATE.singalCallBack {
            callBack(vTime)
        }
    }
    
    func sendMUCJoinStatus(_ isSuccess: Bool, _ roomName : String, _ error : String) {
        printLog("\(#function) | isSuccess: \(isSuccess)")
        addLogger(.sentMessageToFlutter, isSuccess)
        
        if( isSuccess){
            APP_DELEGATE.updateMUCJoinStatus(withRoomname: roomName, status: isSuccess, error: error)
        }
        
        if let callBack = APP_DELEGATE.singalCallBack {
            callBack(isSuccess)
        }
    }
    
    func sendMUCCreateStatus(_ isSuccess: Bool) {
        printLog("\(#function) | isSuccess: \(isSuccess)")
        addLogger(.sentMessageToFlutter, isSuccess)
        
        if let callBack = APP_DELEGATE.singalCallBack {
            callBack(isSuccess)
        }
    }
    
    func sendPresence(withJid jid: String, type: String, move: String) {
        let dicParam = ["type" : xmppConstants.presence,
                        "from" : jid,
                        "presenceType" : type,
                        "presenceMode" : move]
        addLogger(.sentMessageToFlutter, dicParam)
        
//        if let callBack = APP_DELEGATE.singalCallBack {
//            callBack(dicParam)
//        }
        APP_DELEGATE.objEventData!(dicParam)
    }
    
    
    func sendTypingStatus(withJid jid: String, status : String, withStrem : XMPPStream) {
        let vJid : XMPPJID? = XMPPJID(string: jid)
        
        let vChatType : String = xmppChatType.CHAT //? xmppChatType.GROUPCHAT : xmppChatType.CHAT
        let xmppMessage = XMPPMessage.init(type: vChatType.lowercased(), to: vJid)
        
        var vStatus : XMPPMessage.ChatState = .composing
        switch status {
        case xmppTypingStatus.Active:
            vStatus = .active
            
        case xmppTypingStatus.Composing:
            vStatus = .composing
            
        case xmppTypingStatus.Paused:
            vStatus = .paused
        
        case xmppTypingStatus.Inactive:
            vStatus = .inactive
            
        case xmppTypingStatus.Gone:
            vStatus = .gone
            
        default:
            vStatus = .gone
        }
        xmppMessage.addChatState(vStatus)
        withStrem.send(xmppMessage)
        
        addLogger(.sentMessageToServer, xmppMessage)
    }
    
    //MARK: -
    private func getTimeElement(withTime time :String) -> XMLElement? {
        let ele: XMLElement = XMLElement.init(name: eleTIME.Name, xmlns: eleTIME.Namespace)
        ele.addChild(XMLElement.init(name: eleTIME.Kay, stringValue: time))
        return ele
    }
    
    private func getCustomELE(withElementName name :String) -> XMLElement? {
        if name.trim().isEmpty {
            //print("\(#function) | custom element '\(name)' is empty/nil.")
            return nil
        }
        let ele: XMLElement = XMLElement.init(name: eleCustom.Name, xmlns: eleCustom.Namespace)
        ele.addChild(XMLElement.init(name: eleCustom.Kay, stringValue: name))
        return ele
    }

    private func getStatusCodeElement(withCode code :String) -> XMLElement? {
        let xElement: XMLElement = XMLElement.init(name: "x", xmlns: "http://jabber.org/protocol/muc#user")

        let statusElement = XMLElement.init(name: "status")
        statusElement.addAttribute(withName: "code", stringValue: code)

        xElement.addChild(statusElement)
        
        return xElement
    }

    func getStatusCodeValue(_ input: String) -> String {
         let pattern = #"\[\[([A-Za-z0-9_]+)\]\](.*?)\[\[/\1\]\]"#

        var tag : String = ""

        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let range = NSRange(input.startIndex..., in: input)

            if let match = regex.firstMatch(in: input, range: range) {
                if let tagRange = Range(match.range(at: 1), in: input) {
                    tag = String(input[tagRange])
                }
            }
        } catch { }
        
        switch (tag) {
            case "CHANGE_GROUP_AVATAR"     : return "1111";
            case "INVITE_MEMBER_TO_GROUP"  : return "1112";
            case "LEAVE_CHAT_GROUP"        : return "1113";
            case "REMOVE_MEMBER_FROM_GROUP": return "1114";
            case "MAKE_MEMBER_BE_OWNER"    : return "1115";
            case "REMOVE_AS_OWNER"         : return "1116";
            default: return "";
        }
    }
}
