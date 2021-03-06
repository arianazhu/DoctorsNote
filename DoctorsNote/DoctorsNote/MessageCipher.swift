//
//  MessageCipher.swift
//  DoctorsNote
//
//  Created by Merz on 4/12/20.
//  Copyright © 2020 Team7. All rights reserved.
//

import Foundation
import CryptoKit
import CommonCrypto
import AWSMobileClient

class MessageCipher {
    private let localAESKey: Data
    
    private var ivValue: String
    
    //Export -> Base64->encode->base64->store->retrieve->non-base64->decode->nonbase64->import
    private var privateKey: SecKey? = nil
    
    init(uniqueID: String, localAESKey: Data, processor: ConnectionProcessor) throws {
        self.localAESKey = localAESKey
        ivValue = uniqueID
        let (passwordPrivateKey, _, length) = try processor.retrieveEncryptedPrivateKeys(url: "https://o2lufnhpee.execute-api.us-east-2.amazonaws.com/Development/retrievekeys")
        try setPrivateKey(encryptedPrivateKey: passwordPrivateKey, length: length)
    }
    
    //Input: Private key data in base64 format -> encrypted -> base64 String
    public func setPrivateKey(encryptedPrivateKey: String, length: Int) throws {
        
        //let toDecryptData = Data(base64Encoded: encryptedPrivateKey)!
        //let toDecrypt = String(data: toDecryptData, encoding: .utf8)!
        
        //let baseDecrypt = try decodePrivateKey(toDecrypt: toDecrypt)
        let baseDecrypt = try decodePrivateKey(toDecrypt: encryptedPrivateKey, length: length)
        let decryptedText = Data(base64Encoded: baseDecrypt)!
//        print(decryptedText.base64EncodedString())
        var unmanagedError: Unmanaged<CFError>? = nil
        let attributes = [ kSecAttrKeyType: kSecAttrKeyTypeRSA,
        kSecAttrKeySizeInBits: 2048,
        kSecAttrKeyClass: kSecAttrKeyClassPrivate
        ] as [CFString : Any]
        let newPrivateKey = SecKeyCreateWithData(decryptedText as CFData, attributes as CFDictionary, UnsafeMutablePointer<Unmanaged<CFError>?>(&unmanagedError))
        print(unmanagedError)
        privateKey = newPrivateKey
    }
    
//    public func setPrivateKey(newPrivateKey: SecKey) {
//        privateKey = newPrivateKey
//    }
    
    public func setAndReturnKeyPair(encryptedPrivateKey: String, length: Int) throws -> (Data, Data) {
        try setPrivateKey(encryptedPrivateKey: encryptedPrivateKey, length: length)
        if privateKey == nil {
            throw CipherError(message: "Could not decrypt key")
        }
        let cfExport = SecKeyCopyExternalRepresentation(privateKey!, nil)
        if cfExport == nil {
            throw CipherError(message: "Could not export key")
        }
        let privateKeyExport = (cfExport! as Data)
        let publicKey = SecKeyCopyPublicKey(privateKey!)
        let cfExportPublic = SecKeyCopyExternalRepresentation(publicKey!, nil)!
        let publicKeyExport = (cfExportPublic as Data)
        return (privateKeyExport, publicKeyExport)
        
    }
    
    private func decodePrivateKey(toDecrypt: String, length: Int) throws -> String  {
        if Data(base64Encoded: toDecrypt) == nil {
            throw CipherError(message: "Input key is note base64 encoded")
        }
        let toDecryptData = Data(base64Encoded: toDecrypt)
        if toDecryptData == nil {
            print("Not base64 encoded")
        }
        var toDecryptRaw = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: (toDecrypt.count / 128 * 128 + 128) * 4)
        toDecryptRaw.initialize(repeating: 0)
        toDecryptData!.copyBytes(to: toDecryptRaw, from: nil)
        let decrypted = UnsafeMutablePointer<UInt8>.allocate(capacity: (toDecrypt.count / 128 * 128 + 128) * 4)
        var bytesEncrypted = 0
        var AESKey = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: 256)
        localAESKey.copyBytes(to: AESKey)
//        print("Pre decryption and decoding: ")
//        print (toDecrypt)
//        print(toDecrypt.utf8CString.count)
        var fullIV = ivValue
        while fullIV.count < 128 {
            fullIV.append(Character(UnicodeScalar(fullIV.count)!))
        }
        let decryptReturn = CCCrypt(CCOperation(kCCDecrypt), CCAlgorithm(kCCAlgorithmAES128), CCOptions(), AESKey.baseAddress, kCCKeySizeAES256, fullIV, toDecryptRaw.baseAddress, [UInt8](toDecryptData!).count, decrypted,  (toDecrypt.count / 128 * 128 + 128) * 4, &bytesEncrypted)
        
        
        
        let decryptedText = Data(bytes: decrypted, count: length)
        //let unencodedText = Data(base64Encoded: decryptedText)
        print("decoded private key: " + decryptedText.base64EncodedString())
//        print(decryptedText.base64EncodedString())
        //return String(data:decryptedText, encoding: .utf8)!
        return decryptedText.base64EncodedString()
    }
    
    public func decrypt(toDecrypt: Data) throws -> String  {
        if privateKey == nil {
            throw CipherError(message: "Private key not set.")
        }
//        print(toDecrypt.base64EncodedString())
        let unencryptedData = SecKeyCreateDecryptedData(privateKey!, .rsaEncryptionOAEPSHA512AESGCM, toDecrypt as CFData, nil)
        return String(data: unencryptedData! as Data, encoding: .utf8)!
    }
    
    public func encrypt(toEncrypt: String, publicKeyExternalBase64: String? = nil) throws -> Data {
        let publicKeyExternalRepresentation: Data
        if publicKeyExternalBase64 != nil {
            if Data(base64Encoded: publicKeyExternalBase64!) == nil {
                throw CipherError(message: "Input key is not base64 encoded")
            }
            publicKeyExternalRepresentation = Data(base64Encoded: publicKeyExternalBase64!)!
            print("Other public key:" + publicKeyExternalRepresentation.base64EncodedString())
        } else {
            if privateKey == nil {
                throw CipherError(message: "Private key must be set to encrypt messages for self")
            }
            publicKeyExternalRepresentation = SecKeyCopyExternalRepresentation(SecKeyCopyPublicKey(privateKey!)!, nil)! as Data
            print("Own public key:" + publicKeyExternalRepresentation.base64EncodedString())
//            let data = toEncrypt.data(using: .utf8)! as CFData
//            var unmanagedError: Unmanaged<CFError>? = nil
//            let encrypted = SecKeyCreateEncryptedData(SecKeyCopyPublicKey(privateKey!)!, .rsaEncryptionOAEPSHA512AESGCM, data, &unmanagedError) as Data?
//            print(unmanagedError.debugDescription)
//            print("immediate decryption: ")
//            //print(try decrypt(toDecrypt: encrypted!))
            
        }
        var unmanagedError: Unmanaged<CFError>? = nil
        let attributes = [ kSecAttrKeyType: kSecAttrKeyTypeRSA,
        kSecAttrKeySizeInBits: 2048,
        kSecAttrKeyClass: kSecAttrKeyClassPublic
        ] as [CFString : Any]
        let publicKey = SecKeyCreateWithData(publicKeyExternalRepresentation as CFData, attributes as CFDictionary, UnsafeMutablePointer<Unmanaged<CFError>?>(&unmanagedError))
        if publicKey == nil {
            throw CipherError(message: "Public key not recoverable.")
        }
        let encrypted = SecKeyCreateEncryptedData(publicKey!, .rsaEncryptionOAEPSHA512AESGCM, toEncrypt.data(using: .utf8)! as CFData, nil)! as Data
        return encrypted
    }

}

class CipherError : Error {
    private let message: String
    init(message: String) {
        self.message = message
    }
    func getMessage() -> String {
        return message
    }
}
