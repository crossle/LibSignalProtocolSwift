//
//  KeyStore.swift
//  SignalProtocolSwift
//
//  Created by User on 01.11.17.
//  Copyright © 2017 User. All rights reserved.
//

import Foundation


/**
 Provide all local storage delegates.
 */
public protocol KeyStore {

    // MARK: Associated types

    /// The type that distinguishes different devices/users
    associatedtype Address: CustomStringConvertible

    /// The type that distinguishes different groups and devices/users
    associatedtype GroupAddress: CustomStringConvertible

    /// The type of the identity key store
    associatedtype IdentityKeyStoreType: IdentityKeyStore where IdentityKeyStoreType.Address == Address

    /// The type of the sender key store
    associatedtype SenderKeyStoreType: SenderKeyStore where SenderKeyStoreType.Address == GroupAddress

    /// The type of the session key store
    associatedtype SessionStoreType: SessionStore where SessionStoreType.Address == Address

    // MARK: variables
    
    /// The Identity Key store that stores the records for the identity key module
    var identityKeyStore: IdentityKeyStoreType { get }

    /// The Pre Key store that stores the records for the pre key module
    var preKeyStore: PreKeyStore { get }

    /// The Sender Key store that stores the records for the sender key module
    var senderKeyStore: SenderKeyStoreType { get }

    /// The Session store that stores the records for the session module
    var sessionStore: SessionStoreType { get }

    /// The Signed Pre Key store that stores the records for the signed pre key module
    var signedPreKeyStore: SignedPreKeyStore { get }

}

extension KeyStore {

    /**
     Create a new identity key pair and store it.
     - note: Possible errors:
     - `noRandomBytes` if the crypto provider can't provide random bytes.
     - `curveError` if no public key could be created from the random private key.
     - `invalidProtoBuf` if the key pair could no be serialized
     - `storageError` if the data could not be saved
     - returns: The public key data for uploading to the server
     - throws: `SignalError` errors
     */
    public func createIdentityKey() throws -> Data {
        let keyPair = try KeyPair()
        let data = try keyPair.protoData()
        try identityKeyStore.store(identityKeyData: data)
        return keyPair.publicKey.protoData()
    }

    /**
     Create a signed pre key with the given id and store it.
     - note: The following errors can be thrown:
     - `noRandomBytes`, if the crypto provider can't provide random bytes.
     - `curveError`, if no public key could be created from the random private key.
     - `invalidLength`, if the public key is more than 256 or 0 byte.
     - `invalidSignature`, if the message could not be signed.
     - `storageError`, if the identity key could not be accessed, or if the key could not be stored
     - `invalidProtobuf`, if the key could not be serialized
     - parameter id: The id of the signed pre key
     - parameter timestamp: The timestamp of the key, defaults to seconds since 1970
     - returns: The public data of the generated signed pre key for uploading
     - throws: `SignalError`
    */
    public func createSignedPrekey(id: UInt32, timestamp: UInt64 = UInt64(Date().timeIntervalSince1970)) throws -> Data {
        let privateKey = try identityKeyStore.getIdentityKey().privateKey
        let key = try SignalCrypto.generateSignedPreKey(
            identityKey: privateKey,
            id: id, timestamp: timestamp)

        try signedPreKeyStore.store(signedPreKey: key)
        return try key.publicKey.protoData()
    }

    /**
     Create a number of pre keys and store them.
     - note: The following errors can be thrown:
     - `noRandomBytes` if the crypto provider can't provide random bytes.
     - `curveError` if no public key could be created from a random private key.
     - `storageError`, if the keys could not be stored
     - `invalidProtoBuf`, if the keys could not be serialized
     - parameter start: the starting pre key ID, inclusive.
     - parameter count: the number of pre keys to generate.
     - returns: The public data of the pre keys for uploading
     - throws: `SignalError` errors
    */
    public func createPreKeys(start: UInt32, count: Int) throws -> [Data] {
        let keys = try SignalCrypto.generatePreKeys(start: start, count: count)
        for key in keys {
            try preKeyStore.store(preKey: key)
        }
        return try keys.map { try $0.publicKey.protoData() }
    }

    /**
     Create a fingerprint to compare keys with someone.
     - note: Uses the string representation of the addresses as the stable identifier for the two parties, and needs the identity of the remoteAddress to be stored in the identity store
     - note: The following errors can be thrown:
     - `storageError`, if the storage is not available
     - `invalidProtoBuf`, if the identity key is corrupt
     - `untrustedIdentity`, if the remote identity key is not in the key store
     - parameter remoteAddress: The address of the other party
     - parameter localAddress: The address of the local client
     - returns: The fingerprint to compare the keys
     - throws: `SignalError` errors
     */
    public func fingerprint(for remoteAddress: Address, localAddress: Address) throws -> Fingerprint {

        let localIdentity = try identityKeyStore.getIdentityKeyPublicData()
        guard let remoteIdentity = try identityKeyStore.identity(for: remoteAddress) else {
            throw SignalError(.untrustedIdentity, "No identity for address")
        }

        return try Fingerprint(
            localStableIdentifier: localAddress.description,
            localIdentity: localIdentity,
            remoteStableIdentifier: remoteAddress.description,
            remoteIdentity: remoteIdentity)

    }
}
