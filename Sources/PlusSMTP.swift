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




public class SMTP {
    
    
    public struct Sender {
        
        public var name: String
        public var email: String
        
        public var string: String {
            if name.characters.count > 0 {
                return "\(name) <\(email)>"
            } else {
                return "<\(email)>"
            }
        }
        
        public init(name: String, email: String) {
            self.name = name
            self.email = email
        }
        
    }
    
    public struct Recipient {
        
        public enum `Type` {
            case to
            case cc
            case bcc
        }
        public var name: String
        public var email: String
        public var type: Type
        
        public var string: String {
            if name.characters.count > 0 {
                return "\(name) <\(email)>"
            } else {
                return "<\(email)>"
            }
        }
        
        public init(name: String, email: String, type: Type) {
            self.name = name
            self.email = email
            self.type = type
        }

    }
    
    public enum SendError : Error {
        case noRecipients
        case curlError(Int, Data, Data)
    }
    
    public var `protocol`: String = "smtp"
    public let server: String
    public var port: Int
    public let username: String
    public let password: String

    
    
    
    public init(address: String, port: Int = 587, username: String, password: String) {
        self.server = address
        self.port = port
        self.username = username
        self.password = password
    }
    
    func stringRecipients(recipients: [Recipient]) -> [String] {
        var result: [String] = []
        for rec in recipients {
            result.append(rec.email)
        }
        return result
    }
    
    func filterRecipients(recipients: [Recipient], type: Recipient.`Type`) -> [String] {
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
    

	public func send(
		subject: String,
		body: String,
		from: Sender,
		recipients: [Recipient],
		verbose: Bool = false
		) throws -> (responseHeader: Data, responseBody: Data) {
		
		let bodyData = body.data(using: .utf8)
		
		send(subject: subject, body: bodyData, from: from, recipients: recipients)
		
	}
		
    public func send(
        subject: String,
        body: Data,
        from: Sender,
        recipients: [Recipient],
        verbose: Bool = false
        ) throws -> (responseHeader: Data, responseBody: Data) {
        
        let allRecs = stringRecipients(recipients: recipients)
        
        guard allRecs.count > 0 else {
            throw SendError.noRecipients
        }
        
        let fromStr = from.string
        let toRec = filterRecipients(recipients: recipients, type: .to)
        let ccRec = filterRecipients(recipients: recipients, type: .cc)
        
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
        curl.setOption(CURLOPT_MAIL_RCPT, list: allRecs)
        curl.setOption(CURLOPT_USERNAME, s: username)
        curl.setOption(CURLOPT_PASSWORD, s: password)
        curl.setOption(CURLOPT_UPLOAD, int: 1)
        curl.setOption(CURLOPT_USE_SSL, int: Int(CURLUSESSL_ALL.rawValue))
        
        var fullBodyData = header.data(using: .utf8)!
        fullBodyData.append(body)
        let bodyBytes = [UInt8](fullBodyData)
        curl.uploadBodyBytes = bodyBytes
        
        if verbose {
            let fullBodyStr = String(data: fullBodyData, encoding: .utf8)!
            print("fullBodyStr: \(fullBodyStr)")
        }
        
        curl.setOption(CURLOPT_INFILESIZE, int: bodyBytes.count)
        
        if verbose {
            curl.setOption(CURLOPT_VERBOSE, int: 1)
        }
        
        let (result, returnHeaderBytes, returnBodyBytes) = curl.performFully()
        
        if verbose {
            print ("curl result: \(result)")
            print ("-------")
            let strHeader = String(bytes: returnHeaderBytes, encoding: .utf8)!
            let strBody = String(bytes: returnBodyBytes, encoding: .utf8)!
            print ("-------")
            print ("curl header: \(strHeader)")
            print ("-------")
            print ("curl body: \(strBody)")
        }

        let responseHeaderData = Data(bytes: returnHeaderBytes)
        let responseBodyData = Data(bytes: returnBodyBytes)
        
        if result != 0 {
            throw SendError.curlError(result, responseHeaderData, responseBodyData)
        }
        
        return (responseHeaderData, responseBodyData)
        
    }
    
}



