//
//  ConnectionProcessor.swift
//  DoctorsNote
//
//  Created by Nathan Merz on 2/16/20.
//  Copyright © 2020 Nathan Merz All rights reserved.
//

import Foundation
import AWSMobileClient

class ConnectionProcessor {
    static private let standardURL = "https://2wahxpoqf9.execute-api.us-east-2.amazonaws.com/default/PythonAPITest"
    var connectionData: Data?
    var connectionError: ConnectionError?
    let connector: Connector
    let signalWaiter = DispatchSemaphore(value: 0)
    
    init(connector: Connector) {
        self.connector = connector
        
    }
    
//    func reportMissingAuthToken() {
//        connectionError = ConnectionError(message: "Missing authentication token")
//        signalWaiter.signal()
//        return
//    }

    static func standardUrl() -> String {
        return standardURL
    }
    
    func retrieveData(urlString: String) -> ([String : Any]?, ConnectionError?) {
        retrieveJSONData(urlString: urlString)
        return processData()
    }
    
    private func postData(urlString: String, dataJSON: [String : Any]) throws -> ([String : Any]) {
        var postData = Data()
        do {
            postData = try JSONSerialization.data(withJSONObject: dataJSON, options: [])
        } catch {
            throw ConnectionError(message: "Failed to extract data from dictionary")
        }
        postJSONData(urlString: urlString, data: postData)
        let (potentialData, potentialError) = processData()
        if potentialError != nil {
            throw potentialError!
        }
        if (potentialData == nil) { //Should never happen if potentialError is nil
            throw ConnectionError(message: "Data nil with no error")
        }
        return potentialData!
    }
    
    private func processData() -> ([String : Any]?, ConnectionError?) {
        let data = connectionData
        
        if data == nil {
            if connectionError == nil {
                return (nil, ConnectionError(message: "Unknown Error"));
            }
            let returnError = ConnectionError(message: connectionError!.getMessage())
            connectionError = nil
            return (nil, returnError);
        }
        if (connectionError != nil) { //Should never be the case if data is not nil
            let returnError = ConnectionError(message: connectionError!.getMessage())
            connectionError = nil
            return (nil, returnError);
        }
        connectionError = nil
        var jsonData: [String: Any]?
        print("JSON decoding:", String(bytes: data!, encoding: .utf8)!)
        do {
            jsonData = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [String: Any]
            if jsonData == nil {
                throw ConnectionError(message: "Malformed response body")
            }
        }
        catch {
            return (nil, ConnectionError(message: "Malformed response body"))
            
        }
        print(type(of: jsonData!))
        print(jsonData!)
        return (jsonData!, nil)
    }
    
    private func retrieveJSONData(urlString: String) {
        let url = URL(string: urlString)!
        print(url)
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        connector.conductGetTask(manager: self, request: &request)
        signalWaiter.wait()
        //TODO: This waiter should be replaced: A session/task other than the singleton can be used and then set to call a completion handler https://developer.apple.com/documentation/foundation/urlsessiondatadelegate/1410027-urlsession
    }
    
    private func postJSONData(urlString: String, data: Data) {
        let url = URL(string: urlString)!
        print(url)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        //request.setValue(authToken!.tokenString, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        connector.conductPostTask(manager: self, request: &request, data: data)
        signalWaiter.wait()
        //TODO: This waiter should be replaced: A session/task other than the singleton can be used and then set to call a completion handler https://developer.apple.com/documentation/foundation/urlsessiondatadelegate/1410027-urlsession
    }
    
    func processConnection (returnData: Data?, response: URLResponse?, potentialError: Error?) {
        
        if (potentialError != nil) {
            //print("Error (possibly) locally")
            connectionError = ConnectionError(message: "Error connecting to server")
            signalWaiter.signal()
            return
        }
        if (response == nil) {
            //print("Missing response header")
            connectionError = ConnectionError(message: "Missing response")
            signalWaiter.signal()
            return
        }
        //print("Return", String(bytes: returnData!, encoding: .utf8)!)
        let urlResponse = response as! HTTPURLResponse
        if (urlResponse.statusCode != 200) {
            //print("Error on server")
            connectionError = ConnectionError(message: "Error connecting on server with return code: " + String(urlResponse.statusCode))
            //print(response ?? "nil")
            signalWaiter.signal()
            return
        }
        //print("Status code:", urlResponse.statusCode)
        //print("Return", String(bytes: returnData!, encoding: .utf8)!)
        self.connectionData = returnData!
        signalWaiter.signal()
    }
    
    func processConversationList(url: String) -> ([Conversation]?, ConnectionError?) {
        let (potentialData, potentialError) = retrieveData(urlString: url)
        if (potentialError != nil) {
            return (nil, potentialError)
        }
        if (potentialData == nil) { //Should never happen if potentialError is nil
            return (nil, ConnectionError(message: "Data nil with no error"))
        }
        let conversationList = potentialData!
        var conversations = [Conversation]()
        if (conversationList.first?.value as? NSArray == nil) {
            return (nil, ConnectionError(message: "At least one JSON field was an incorrect format"))
        }
        for conversationDict in (conversationList.first?.value as! NSArray) {
            if (conversationDict as? [String : Any?] == nil) {
                return (nil, ConnectionError(message: "At least one JSON field was an incorrect format"))
            }
            print(conversationDict)
            let conversation = conversationDict as! [String : Any?]
            print(conversation)
           // let conversation = conversationList[conversationKey] as! [String : Any?]
            print(conversation["conversationID"] as? Int)
            print(conversation["converserID"] as? Int)
            print(conversation["lastMessageTime"] as? TimeInterval)
            print(conversation["status"] as? Int)
            if ((conversation["conversationID"] as? Int) != nil) && ((conversation["converserID"] as? Int) != nil) && ((conversation["lastMessageTime"] as? TimeInterval) != nil) && ((conversation["status"] as? Int) != nil) {
                let newConversation = Conversation(conversationID:  conversation["conversationID"] as! Int, conversationPartner: User(uid: conversation["converserID"] as! Int), lastMessageTime: Date(timeIntervalSince1970: (conversation["lastMessageTime"] as! TimeInterval)), unreadMessages: conversation["status"] as! Int != 0)
                conversations.append(newConversation)
            } else {
                return (nil, ConnectionError(message: "At least one JSON field was an incorrect format"))
            }
        }
        return (conversations, potentialError)
    }
    
    func processUser(url: String, uid: Int) -> (User?, ConnectionError?) {
        //Placeholder
        return (User(uid: -1, firstName: "place", lastName: "holder", dateOfBirth: Date(), address: "nowhere", healthSystems: [HealthSystem]()), nil)
    }
    
    func processConversation(url: String, conversationID: Int) -> (Conversation?, ConnectionError?) {
        //Placeholder
        return (Conversation(conversationID: -1, conversationPartner: User(uid: -1)!, lastMessageTime: Date(), unreadMessages: false), nil)
    }
    
    func processMessages(url: String, conversation: Conversation, numberToRetrieve: Int, startIndex: Int = 0, sinceWhen: Date = Date(timeIntervalSinceNow: TimeInterval(0))) throws -> [Message]? {
        var messageJSON = [String : Any]()
        messageJSON["conversationID"] = conversation.getConversationID()
        messageJSON["numberToRetrieve"] = numberToRetrieve
        messageJSON["startIndex"] = startIndex
        messageJSON["sinceWhen"] = sinceWhen.timeIntervalSince1970
        
        let messageList = try postData(urlString: url, dataJSON: messageJSON)
        var messages = [Message]()
        if (messageList.first?.value as? NSArray == nil) {
            throw ConnectionError(message: "At least one JSON field was an incorrect format")
        }
        
        for messageDict in (messageList.first?.value as! NSArray) {
            if (messageDict as? [String : Any?] == nil) {
                throw ConnectionError(message: "At least one JSON field was an incorrect format")
            }
            let message = messageDict as! [String : Any?]
            if ((message["messageId"] as? Int) != nil) && ((message["content"] as? String) != nil) && ((message["sender"] as? Int) != nil) {
                let newMessage = Message(messageID: message["messageId"] as! Int, conversation: Conversation(conversationID: 0)!, content: [UInt8]((message["content"] as! String).utf8), sender: User(uid: message["sender"] as! Int))
                messages.append(newMessage)
            } else {
                throw ConnectionError(message: "At least one JSON field was an incorrect format")
            }
        }
        return messages
    }
    
    //TODO: Finer processing/passing of any errors returned by server to UI
    //  - Need to discuss this with team
    func processNewMessage(url: String, message: Message) -> ConnectionError? {
        var messageJSON = [String: Any]()
        messageJSON["senderID"] = message.getSender().getUID()
        messageJSON["conversationID"] = message.getConversation().getConversationID()
        messageJSON["content"] = String(bytes: message.getContent(), encoding: .utf8)
        do {
            let data = try postData(urlString: url, dataJSON: messageJSON)
            if data.count != 0 {
                return ConnectionError(message: "Non-blank return")
            }
        } catch let error {
            return error as? ConnectionError
        }
        return nil //Should have returned a blank 200 if successful, if so, no need to return an error
    }
    
    //TODO: Finer processing/passing of any errors returned by server to UI
    //  - Need to discuss this with team
    func processNewReminder(url: String, reminder: Reminder) throws {
        var reminderJSON = [String: Any]()
        reminderJSON["content"] = String(bytes: reminder.getContent(), encoding: .utf8)
        reminderJSON["remindee"] = reminder.getRemindeeID()
        reminderJSON["timeCreated"] = reminder.getTimeCreated().timeIntervalSince1970
        reminderJSON["alertTime"] = reminder.getAlertTime().timeIntervalSince1970
        let data = try postData(urlString: url, dataJSON: reminderJSON)
        if data.count != 0 {
            throw ConnectionError(message: "Non-blank return")
        }
        //Should have returned a blank 200 if successful, if so, no need to do anything
    }
    
    //TODO: Finer processing/passing of any errors returned by server to UI
    //  - Need to discuss this with team
    func processDeleteReminder(url: String, reminder: Reminder) throws {
        var reminderJSON = [String: Any]()
        reminderJSON["reminderID"] = reminder.getReminderID()

        let data = try postData(urlString: url, dataJSON: reminderJSON)
        if data.count != 0 {
            throw ConnectionError(message: "Non-blank return")
        }
        //Should have returned a blank 200 if successful, if so, no need to do anything
    }
    
    //TODO: Finer processing/passing of any errors returned by server to UI
    //  - Need to discuss this with team
    func processEditReminder(url: String, reminder: Reminder) throws {
        try processDeleteReminder(url: url, reminder: reminder);
        try processNewReminder(url: url, reminder: reminder);
    }
}

class Connector {
    var authToken: SessionToken? = nil
    let tokenGuard: TokenGuard
    let session: URLSession
    
    init (tokenGuard: TokenGuard = TokenGuard(), session: URLSession = URLSession.shared) {
        self.tokenGuard = tokenGuard
        self.session = session
    }

    func setToken(potentialTokens: Tokens?, potentialError: Error?) {
        if (potentialError != nil || potentialTokens == nil || potentialTokens!.accessToken == nil) {
            return
        }
        authToken = potentialTokens!.idToken!
        print(authToken!.tokenString)
        tokenGuard.release()
    }
    
    
    func conductGetTask(manager: ConnectionProcessor, request: inout URLRequest) {
        tokenGuard.pass()
//        if (authToken == nil) {
//            manager.reportMissingAuthToken()
//            return
//        }
        request.setValue(authToken!.tokenString, forHTTPHeaderField: "Authorization")
        let retrievalTask = session.dataTask(with: request) {returnData, responseHeader, potentialError in
            manager.processConnection(returnData: returnData, response: responseHeader, potentialError: potentialError)
        }
        retrievalTask.resume()
    }
    
    func conductPostTask(manager: ConnectionProcessor, request: inout URLRequest, data: Data) {
        tokenGuard.pass()
//        if (authToken == nil) {
//            manager.reportMissingAuthToken()
//            return
//        }
        request.setValue(authToken!.tokenString, forHTTPHeaderField: "Authorization")
        let postSession = session.uploadTask(with: request, from: data, completionHandler: manager.processConnection(returnData:response:potentialError:))
        postSession.resume()
    }
}

class ConnectionError : Error {
    private let message: String
    init(message: String) {
        self.message = message
    }
    func getMessage() -> String {
        return message
    }
}

class TokenGuard {
    let signalWaiter = DispatchSemaphore(value: 0)

    func release() {
        signalWaiter.signal()
    }
    
    func pass() {
        signalWaiter.wait()
        signalWaiter.signal()
    }
}
