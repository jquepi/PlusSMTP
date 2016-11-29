//
//  PlusSMTP.swift
//  CurlTest
//
//  Created by Matej Ukmar on 29/11/2016.
//
//

import Foundation
import cURL
import PerfectCURL



protocol SMTPUser {
    var string: String { get }
}

public class SMTP {
    
    
    public struct Sender: SMTPUser {
        
        public let name: String
        public  let email: String
        
        public var string: String {
            if name.characters.count > 0 {
                return "\(name) <\(email)>"
            } else {
                return "<\(email)>"
            }
        }
        
    }
    
    public struct Recipient: SMTPUser {
        
        public enum `Type` {
            case to
            case cc
            case bcc
        }
        public let name: String
        public let email: String
        public let type: Type
        
        public var string: String {
            if name.characters.count > 0 {
                return "\(name) <\(email)>"
            } else {
                return "<\(email)>"
            }
        }
    }
    
    public enum SendError : Error {
        case noRecipients
        case curlError(Int)
    }
    
    public var `protocol`: String = "smtp"
    public let server: String
    public var port: Int = 587
    public let username: String
    public let password: String
    public let from: Sender
    public let recipients: [Recipient]
    public let subject: String
    public var mailBodyData: Data = Data()
    
    
    public func appendBody(data: Data) {
        mailBodyData.append(data)
    }
    
    public func appendBody(text: String) {
        let data = text.data(using: .utf8)!
        mailBodyData.append(data)
    }
    
    
    public init(server: String, username: String, password: String, from: Sender, recipients: [Recipient], subject: String) {
        self.server = server
        self.username = username
        self.password = password
        self.from = from
        self.recipients = recipients
        self.subject = subject
    }
    
    var allRecipients: [String] {
        var result: [String] = []
        for rec in recipients {
            result.append(rec.email)
        }
        return result
    }
    
    func filerRecipients(type: Recipient.`Type`) -> [String] {
        var result: [String] = []
        
        for rec in recipients {
            if rec.type == type {
                result.append(rec.string)
            }
        }
        return result
    }
    
    func recipientsString(_ recipients: [String]) -> String? {
        
        var result = ""
        
        for (index, rec) in recipients.enumerated() {
            if index > 0 {
                result += ", "
            }
            result += rec
        }
        if result.characters.count > 0 {
            return result
        }
        return nil
        
    }
    

    
    public func send() throws {
        
        let allRecs = allRecipients
        
        guard allRecs.count > 0 else {
            throw SendError.noRecipients
        }
        
        let fromStr = from.string
        let toRec = filerRecipients(type: .to)
        let ccRec = filerRecipients(type: .cc)
        
        let toRecStr = recipientsString(toRec)
        let ccRecStr = recipientsString(ccRec)
        
        var header = "From: \(fromStr)\r\n"

        
        if let toRecStr = toRecStr {
            header += "To: \(toRecStr)\r\n"
        }

        if let ccRecStr = ccRecStr {
            header += "Cc: \(ccRecStr)\r\n"
        }
        
        header += "Subject: \(subject)\r\n"
        
        header += "\r\n"
        
        let url = "\(self.protocol)://\(server):\(port)"
        let curl = CURL(url: url)
        
        curl.setOption(CURLOPT_MAIL_FROM, s: from.email)
        
        
        curl.setOption(CURLOPT_MAIL_RCPT, array: allRecs)
        
        curl.setOption(CURLOPT_UPLOAD, int: 1)
        
        
        curl.setOption(CURLOPT_USE_SSL, int: Int(CURLUSESSL_ALL.rawValue))
        
        
        curl.setOption(CURLOPT_USERNAME, s: username)
        curl.setOption(CURLOPT_PASSWORD, s: password)
        
        
        var fullBodyData = header.data(using: .utf8)!
        
        fullBodyData.append(mailBodyData)
        
        let bodyBytes = [UInt8](fullBodyData)
        
        curl.uploadBodyBytes = bodyBytes
        
        let fullBodyStr = String(data: fullBodyData, encoding: .utf8)!
        
        print("fullBodyStr: \(fullBodyStr)")
        
        
        curl.setOption(CURLOPT_INFILESIZE, int: bodyBytes.count)
        
        curl.setOption(CURLOPT_VERBOSE, int: 1)
        
        let (result, returnHeaderBytes, returnBodyBytes) = curl.performFully()
        
        print ("curl result: \(result)")
        
        print ("-------")
        
        let strHeader = String(bytes: returnHeaderBytes, encoding: .utf8)!
        
        let strBody = String(bytes: returnBodyBytes, encoding: .utf8)!
        
        print ("-------")
        
        print ("curl header Data: \(strHeader)")
        
        print ("-------")
        
        print ("curl body Data: \(strBody)")
        
        if result != 0 {
            throw SendError.curlError(result)
        }
        
    }
    
    
    
    
}
