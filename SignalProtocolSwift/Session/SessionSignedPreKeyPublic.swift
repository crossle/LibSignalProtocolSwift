//
//  SessionPublicSignedPreKey.swift
//  SignalProtocolSwift iOS
//
//  Created by User on 27.01.18.
//  Copyright © 2018 User. All rights reserved.
//

import Foundation


/**
 A public signed pre key is used as part of a session bundle to establish a new session.
 The public part of the key pair is signed with the identity key of the creator
 to provide authentication.
 */
public struct SessionSignedPreKeyPublic {

    /// The id of the signed pre key
    public let id: UInt32

    /// The key pair of the signed pre key
    public let key: PublicKey

    /// The time when the key was created
    public let timestamp: UInt64

    /// The signature of the public key of the key pair
    public let signature: Data

    /**
     Create a public signed pre key from its components.
     - parameter id: The id of the signed pre key
     - parameter key: The public key of the signed pre key
     - parameter timestamp: The time when the key was created
     - parameter signature: The signature of the public key of the key pair
     */
    init(id: UInt32, timestamp: UInt64, key: PublicKey, signature: Data) {
        self.id = id
        self.key = key
        self.timestamp = timestamp
        self.signature = signature
    }
}

// MARK: Protocol Buffers

extension SessionSignedPreKeyPublic {

    /**
     Create a signed pre key from serialized data.
     - parameter data: The serialized record.
     - throws: `SignalError` of type `invalidProtoBuf` if data is corrupt or missing
     */
    public init(from data: Data) throws {
        let object: Signal_SignedPreKey.PublicPart
        do {
            object = try Signal_SignedPreKey.PublicPart(serializedData: data)
        } catch {
            throw SignalError(.invalidProtoBuf, "Could not deserialize SessionSignedPreKey ProtoBuf object: \(error)")
        }
        try self.init(from: object)
    }

    /**
     Create a signed pre key from a ProtoBuf object.
     - parameter object: The ProtoBuf object.
     - throws: `SignalError` of type `invalidProtoBuf` if data is corrupt or missing
     */
    init(from object: Signal_SignedPreKey.PublicPart) throws {
        guard object.hasID, object.hasKey,
            object.hasSignature, object.hasTimestamp else {
                throw SignalError(.invalidProtoBuf, "Missing data in SessionSignedPreKey object")
        }
        self.id = object.id
        self.key = try PublicKey(from: object.key)
        self.timestamp = object.timestamp
        self.signature = object.signature
    }

    /// Convert the public signed pre key to a ProtoBuf object
    var object: Signal_SignedPreKey.PublicPart {
        return Signal_SignedPreKey.PublicPart.with {
            $0.id = self.id
            $0.key = self.key.data
            $0.timestamp = self.timestamp
            $0.signature = self.signature
        }
    }

    /**
     Convert the signed pre key to serialized data.
     - returns: The serialized record.
     - throws: `SignalError` of type `invalidProtoBuf`
     */
    public func data() throws -> Data {
        do {
            return try object.serializedData()
        } catch {
            throw SignalError(.invalidProtoBuf, "Could not serialize SessionSignedPreKey ProtoBuf object: \(error)")
        }
    }
}

extension SessionSignedPreKeyPublic: Equatable {

    /**
     Compare two public signed pre keys for equality.
     - parameters lhs: The first public signed pre key
     - parameters rhs: The second public signed pre key
     - returns: `True`, if the public signed pre keys match
     */
    public static func ==(lhs: SessionSignedPreKeyPublic, rhs: SessionSignedPreKeyPublic) -> Bool {
        return lhs.id == rhs.id &&
            lhs.key == rhs.key &&
            lhs.signature == rhs.signature &&
            lhs.timestamp == rhs.timestamp
    }
}